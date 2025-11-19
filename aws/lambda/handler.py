import boto3
import time
import json
import zipfile
import os
import socket
from typing import Dict, List, Any, Optional

# Initialize AWS clients
s3 = boto3.client('s3')
ecs = boto3.client('ecs')

# Configuration
US_CLUSTER = "jmeter-us"
EU_CLUSTER = "jmeter-eu"
TASK_DEF_MASTER_PREFIX = "jmeter-master"
TASK_DEF_SLAVE_PREFIX = "jmeter-slave"

# Timeout and retry settings
SLAVE_READY_TIMEOUT = 300  # 5 minutes
SLAVE_CHECK_INTERVAL = 5    # Check every 5 seconds
JMETER_RMI_PORT = 1099

def get_vpc_config(region: str) -> Dict[str, Any]:
    """Get VPC configuration for the specified region."""
    subnets = [s for s in os.environ.get(f"SUBNETS_{region.upper()}", "").split(",") if s]
    security_groups = [sg for sg in os.environ.get(f"SECURITY_GROUPS_{region.upper()}", "").split(",") if sg]
    
    if not subnets or not security_groups:
        raise ValueError(f"Missing VPC configuration for {region} region")
    
    return {
        "awsvpcConfiguration": {
            "subnets": subnets,
            "securityGroups": security_groups,
            "assignPublicIp": "DISABLED"
        }
    }

def run_task(cluster: str, task_definition: str, environment: List[Dict[str, str]]) -> str:
    """Run an ECS task with the given configuration."""
    region = 'us' if 'us' in cluster.lower() else 'eu'
    response = ecs.run_task(
        cluster=cluster,
        launchType='FARGATE',
        taskDefinition=task_definition,
        networkConfiguration=get_vpc_config(region),
        overrides={
            "containerOverrides": [{
                "name": "jmeter",
                "environment": environment
            }]
        }
    )
    return response['tasks'][0]['taskArn']

def wait_for_slaves_ready(slave_ips: List[str]) -> List[str]:
    """Wait for all slave instances to be ready and accepting connections."""
    ready_ips = set()
    start_time = time.time()
    
    print(f"Waiting for {len(slave_ips)} slaves to be ready...")
    
    while time.time() - start_time < SLAVE_READY_TIMEOUT:
        for ip in slave_ips:
            if ip in ready_ips:
                continue
                
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(2)
                result = sock.connect_ex((ip, JMETER_RMI_PORT))
                sock.close()
                
                if result == 0:  # Port is open
                    print(f"Slave {ip} is ready")
                    ready_ips.add(ip)
                    
            except Exception as e:
                print(f"Error checking slave {ip}: {str(e)}")
        
        if len(ready_ips) == len(slave_ips):
            return list(ready_ips)
            
        time.sleep(SLAVE_CHECK_INTERVAL)
    
    print(f"Timeout waiting for slaves. Ready: {len(ready_ips)}/{len(slave_ips)}")
    return list(ready_ips)

def start_slaves(region: str, count: int, load_profile: str) -> List[str]:
    """Start slave tasks in the specified region."""
    if count <= 0:
        return []
        
    cluster = US_CLUSTER if region == 'us' else EU_CLUSTER
    task_definition = f"{TASK_DEF_SLAVE_PREFIX}-{load_profile}"
    environment = [
        {"name": "JMETER_MODE", "value": "slave"},
        {"name": "REGION", "value": region}
    ]
    
    print(f"Starting {count} {load_profile} slaves in {region.upper()}...")
    task_arns = []
    
    for _ in range(count):
        task_arn = run_task(cluster, task_definition, environment)
        task_arns.append(task_arn)
    
    return task_arns

def get_task_ips(cluster: str, task_arns: List[str]) -> List[str]:
    """Get private IPs of the running tasks."""
    if not task_arns:
        return []
        
    ips = []
    response = ecs.describe_tasks(cluster=cluster, tasks=task_arns)
    
    for task in response.get('tasks', []):
        for attachment in task.get('attachments', []):
            if attachment['type'] == 'ElasticNetworkInterface':
                for detail in attachment['details']:
                    if detail['name'] == 'privateIPv4Address':
                        ips.append(detail['value'])
    
    return ips

def start_master(slave_ips: List[str], test_plan_s3: str, results_s3: str, config: Dict[str, Any]) -> str:
    """Start the JMeter master task with the given configuration."""
    slave_hosts = ",".join([f"{ip}:{JMETER_RMI_PORT}" for ip in slave_ips])
    
    environment = [
        {"name": "JMETER_MODE", "value": "master"},
        {"name": "JMETER_SLAVE_HOSTS", "value": slave_hosts},
        {"name": "TEST_PLAN_S3", "value": test_plan_s3},
        {"name": "RESULT_S3", "value": results_s3}
    ]
    
    # Add any additional config values as environment variables
    for key, value in config.items():
        if key not in ['slave_count_us', 'slave_count_eu', 'load_profile']:
            environment.append({
                "name": key.upper(),
                "value": str(value)
            })
    
    print(f"Starting master with {len(slave_ips)} slaves...")
    
    load_profile = config.get("load_profile", "small")
    task_definition = f"{TASK_DEF_MASTER_PREFIX}-{load_profile}"
    
    return run_task(US_CLUSTER, task_definition, environment)

def handle_s3_event(event: Dict[str, Any]) -> Dict[str, Any]:
    """Handle S3 event (legacy mode)."""
    record = event["Records"][0]
    bucket = record["s3"]["bucket"]["name"]
    key = record["s3"]["object"]["key"]
    
    print(f"Processing S3 event: s3://{bucket}/{key}")
    
    local_zip_path = "/tmp/test_package.zip"
    extract_dir = "/tmp/test_package"
    
    # Download and extract ZIP
    s3.download_file(bucket, key, local_zip_path)
    
    with zipfile.ZipFile(local_zip_path, 'r') as zip_ref:
        if os.path.exists(extract_dir):
            for f in os.listdir(extract_dir):
                os.remove(os.path.join(extract_dir, f))
        else:
            os.makedirs(extract_dir)
        zip_ref.extractall(extract_dir)
    
    # Read config.json
    config_path = os.path.join(extract_dir, "config.json")
    if not os.path.exists(config_path):
        raise FileNotFoundError("config.json missing from ZIP")
    
    with open(config_path, "r") as f:
        config = json.load(f)
    
    # Upload test files to S3
    test_run_bucket = "test-surge-perf"
    test_run_bucket_prefix = "test/"
    
    for filename in os.listdir(extract_dir):
        if filename.lower().endswith(('.jmx', '.csv', '.properties')):
            s3.upload_file(
                os.path.join(extract_dir, filename),
                test_run_bucket,
                test_run_bucket_prefix + filename
            )
    
    return {
        "test_plan_s3": f"s3://{test_run_bucket}/{test_run_bucket_prefix}",
        "results_s3": f"s3://{test_run_bucket}/results/result.jtl",
        "config": config
    }

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Handle Lambda function invocation."""
    print(f"Received event: {json.dumps(event, indent=2)}")
    
    try:
        result = handle_s3_event(event)
        test_plan_s3 = result["test_plan_s3"]
        results_s3 = result["results_s3"]
        config = result["config"]
        
        # Get test configuration
        load_profile = config.get("load_profile", "small")
        slave_count_us = int(config.get("slave_count_us", 0))
        slave_count_eu = int(config.get("slave_count_eu", 0))
        
        if slave_count_us <= 0 and slave_count_eu <= 0:
            raise ValueError("At least one slave count must be greater than 0")
        
        # Start slaves in both regions
        us_slave_tasks = start_slaves('us', slave_count_us, load_profile)
        eu_slave_tasks = start_slaves('eu', slave_count_eu, load_profile)
        
        # Get slave IPs
        us_slave_ips = get_task_ips(US_CLUSTER, us_slave_tasks) if us_slave_tasks else []
        eu_slave_ips = get_task_ips(EU_CLUSTER, eu_slave_tasks) if eu_slave_tasks else []
        all_slave_ips = us_slave_ips + eu_slave_ips
        
        # Wait for all slaves to be ready
        ready_slaves = wait_for_slaves_ready(all_slave_ips)
        if not ready_slaves:
            raise Exception("No slaves became ready within the timeout period")
        
        # Start master with the ready slaves
        master_arn = start_master(ready_slaves, test_plan_s3, results_s3, config)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'master': master_arn,
                'us_slaves': us_slave_tasks,
                'eu_slaves': eu_slave_tasks,
                'ready_slave_ips': ready_slaves
            })
        }
        
    except Exception as e:
        import traceback
        error_msg = str(e)
        stack_trace = traceback.format_exc()
        print(f"Error: {error_msg}\n{stack_trace}")
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_msg,
                'stack_trace': stack_trace
            })
        }