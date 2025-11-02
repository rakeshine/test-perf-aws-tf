import boto3
import time
import json
import zipfile
import os
 
s3 = boto3.client("s3")
ecs = boto3.client("ecs")
 
# Move config to environment variables
CLUSTER = os.environ.get("ECS_CLUSTER", "jmeter-cluster")
SUBNETS = [s for s in os.environ.get("SUBNETS", "").split(",") if s]  # Filter out empty strings
SECURITY_GROUPS = [sg for sg in os.environ.get("SECURITY_GROUPS", "").split(",") if sg]  # Filter out empty strings

# TODO This depends on config.json in zip file
TASK_DEF_SLAVE = "jmeter_slave"
TASK_DEF_MASTER = "jmeter_master"
 
VPC_CONFIG = {
    "awsvpcConfiguration": {
        "subnets": SUBNETS,
        "securityGroups": SECURITY_GROUPS,
        "assignPublicIp": "DISABLED"
    }
}
 
POLL_INTERVAL = 5
MAX_POLL_TIME = 300
 
def run_slave_tasks(count):
    slaves = []
    for _ in range(count):
        resp = ecs.run_task(cluster=CLUSTER,
                           taskDefinition=TASK_DEF_SLAVE,
                           launchType="FARGATE",
                           networkConfiguration=VPC_CONFIG)
        task_arn = resp["tasks"][0]["taskArn"]
        slaves.append(task_arn)
    return slaves
 
def wait_for_tasks_running(cluster, task_arns):
    elapsed = 0
    while elapsed <= MAX_POLL_TIME:
        desc = ecs.describe_tasks(cluster=cluster, tasks=task_arns)
        tasks = desc.get("tasks", [])
        running_tasks = [t for t in tasks if t["lastStatus"] == "RUNNING"]
        if len(running_tasks) == len(task_arns):
            return True
        time.sleep(POLL_INTERVAL)
        elapsed += POLL_INTERVAL
    raise TimeoutError(f"Timeout waiting for tasks to reach RUNNING after {MAX_POLL_TIME} seconds.")
 
def get_private_ips(cluster, task_arns):
    wait_for_tasks_running(cluster, task_arns)
    private_ips = []
    desc = ecs.describe_tasks(cluster=cluster, tasks=task_arns)
    for task in desc["tasks"]:
        attachments = task.get("attachments", [])
        for attach in attachments:
            if attach["type"] == "ElasticNetworkInterface":
                for detail in attach["details"]:
                    if detail["name"] == "privateIPv4Address":
                        private_ips.append(detail["value"])
    return private_ips
 
def run_master_task(slave_ips, test_plan_s3, results_s3, config_env):
    slave_hosts_str = ",".join(slave_ips)
    env_vars = [
        {"name": "JMETER_SLAVE_HOSTS", "value": slave_hosts_str},
        {"name": "TEST_PLAN_S3", "value": test_plan_s3},
        {"name": "RESULT_S3", "value": results_s3},
        {"name": "JMETER_MODE", "value": "master"},
    ]
    for key, value in config_env.items():
        env_vars.append({"name": key.upper(), "value": str(value)})
 
    resp = ecs.run_task(cluster=CLUSTER,
                       taskDefinition=TASK_DEF_MASTER,
                       launchType="FARGATE",
                       networkConfiguration=VPC_CONFIG,
                       overrides={
                           "containerOverrides": [
                               {
                                   "name": "jmeter-master",
                                   "environment": env_vars
                               }
                           ]
                       })
    return resp["tasks"][0]["taskArn"]
 
def lambda_handler(event, context):
    record = event["Records"][0]
    bucket = record["s3"]["bucket"]["name"]
    key = record["s3"]["object"]["key"]
 
    print(f"Triggered by S3 event for bucket={bucket}, key={key}")
 
    local_zip_path = "/tmp/test_package.zip"
    extract_dir = "/tmp/test_package"
 
    # Download ZIP
    s3.download_file(bucket, key, local_zip_path)
 
    # Extract ZIP
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
 
    slave_count = int(config.get("slave_count", 2))
    
    # Upload jmx and csv files from extracted folder to s3://test-surge-perf/test/
    test_run_bucket = "test-surge-perf"
    test_run_bucket_prefix = "test/"
 
    # Find relevant files
    jmx_file = None
    csv_file = None
    # Upload both JMX and the CSV files to S3 under s3://test-surge-perf/test/
    for filename in os.listdir(extract_dir):
        if filename.lower().endswith(".jmx"):
            jmx_file = filename
            s3.upload_file(os.path.join(extract_dir, jmx_file), test_run_bucket, test_run_bucket_prefix + jmx_file)
        elif filename.lower().endswith(".csv"):
            csv_file = filename
            s3.upload_file(os.path.join(extract_dir, csv_file), test_run_bucket, test_run_bucket_prefix + csv_file)
   
    test_plan_s3 = f"s3://{test_run_bucket}/{test_run_bucket_prefix}"
    results_s3 = f"s3://{test_run_bucket}/{test_run_bucket_prefix}results/result.jtl"
 
    print(f"Uploading done. Test plan at {test_plan_s3}")
 
    print(f"Starting {slave_count} slave tasks...")
    slave_tasks = run_slave_tasks(slave_count)
    slave_ips = get_private_ips(CLUSTER, slave_tasks)
 
    print(f"Slave IPs: {slave_ips}")
 
    config_env = {
        "number_of_threads": config.get("number_of_threads", 10),
        "ramp_up_time": config.get("ramp_up_time", 10),
        "duration": config.get("duration", 60)
    }
 
    master_task = run_master_task(slave_ips, test_plan_s3, results_s3, config_env)
 
    print(f"Started master task: {master_task} with slaves: {slave_tasks}")
 
    return {
        "statusCode": 200,
        "body": json.dumps({
            "master_task_arn": master_task,
            "slave_task_arns": slave_tasks,
            "slave_ips": slave_ips
        })
    }