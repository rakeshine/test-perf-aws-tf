# JMeter Distributed Load Testing on AWS ECS

This project sets up a distributed JMeter load testing environment on AWS ECS, supporting multi-region testing with master-slave architecture.

## Architecture Overview

- **Regions**: Deploys to primary (US) and secondary (EU) AWS regions
- **VPCs**: Separate VPCs in each region with VPC peering
- **ECS Clusters**: Fargate-based clusters for containerized JMeter instances
- **S3**: Centralized storage for test plans and results
- **Lambda**: Serverless function to orchestrate test execution

## Prerequisites

1. **AWS Account** with permissions for:
   - ECS (Fargate)
   - VPC
   - IAM
   - S3
   - Lambda

2. **Terraform** v1.5.7 or later
3. **Docker** (for building the JMeter container)
4. **AWS CLI** (for deployment and management)

## Complete Setup Guide

### 1. Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** v1.5.7 or later
3. **Docker** installed and running
4. **AWS CLI** configured with credentials
5. **Python** 3.8+ for Lambda function

### 2. Environment Setup

1. Clone the repository:
   ```bash
   git clone [repository-url]
   cd jmeter-infra
   ```

2. Configure AWS credentials:
   ```bash
   aws configure
   ```

### 3. Build and Push JMeter Docker Image

1. Build the JMeter Docker image:
   ```bash
   cd jmeter
   docker build -t jmeter:latest .
   ```

2. Authenticate Docker to your ECR repository:
   ```bash
   aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws-account-id>.dkr.ecr.<region>.amazonaws.com
   ```

3. Tag and push the image:
   ```bash
   docker tag jmeter:latest <aws-account-id>.dkr.ecr.<region>.amazonaws.com/jmeter:latest
   docker push <aws-account-id>.dkr.ecr.<region>.amazonaws.com/jmeter:latest
   ```

### 4. Configure Infrastructure

1. Navigate to the production environment:
   ```bash
   cd envs/prod
   ```

2. Update `terraform.tfvars` with your configuration:
   ```hcl
   name             = "jmeter-perf-test"
   region           = "us-east-1"
   secondary_region = "eu-west-1"
   ecr_image        = "<aws-account-id>.dkr.ecr.<region>.amazonaws.com/jmeter:latest"
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

### 5. Deploy Infrastructure

1. Review the execution plan:
   ```bash
   terraform plan
   ```

2. Apply the configuration:
   ```bash
   terraform apply
   ```

### 6. Prepare Lambda Function

1. Create the Lambda deployment package:
   ```bash
   cd ../../lambda
   pip install boto3 -t .
   zip -r function.zip .
   mv function.zip ../envs/prod/
   ```

### 7. Run Load Tests

1. Create a test package:
   ```bash
   mkdir -p test-package
   # Add your config.json, test.jmx and <<test-data>>.csv files
   zip -r test-package.zip test-package/
   ```

2. Upload to S3:
   ```bash
   aws s3 cp test-package.zip s3://test-surge-perf/test-package.zip
   ```

3. Invoke the Lambda function:
   ```bash
   aws lambda invoke --function-name jmeter-test-runner --payload '{"test_plan": "test.jmx"}' response.json
   ```

## Complete Project Structure

```
.
├── envs/                          # Environment configurations
│   └── prod/                      # Production environment
│       ├── main.tf                # Main Terraform configuration
│       ├── variables.tf           # Variable definitions
│       ├── outputs.tf             # Output configurations
│       └── terraform.tfvars       # Environment-specific variables
│
├── modules/                       # Reusable Terraform modules
│   ├── ecs_cluster/              
│   │   ├── main.tf               # ECS cluster configuration
│   │   ├── variables.tf          
│   │   └── outputs.tf           
│   │
│   ├── ecs_service/              
│   │   ├── main.tf               # ECS service definitions
│   │   ├── variables.tf         
│   │   └── outputs.tfx          
│   │
│   ├── ecs_tasks_jmeter/         # JMeter-specific task definitions
│   │   ├── main.tf               # Master and slave task definitions
│   │   ├── variables.tf          # Task-specific variables
│   │   └── outputs.tf            # Task definition outputs
│   │
│   ├── iam/                     
│   │   ├── main.tf               # IAM roles and policies
│   │   ├── variables.tf         
│   │   └── outputs.tfx          
│   │
│   └── vpc/                     
│       ├── main.tf               # VPC, subnets, and networking
│       ├── variables.tf         
│       └── outputs.tfx          
│
├── jmeter/                       # JMeter Docker image
│   ├── Dockerfile                # JMeter container definition
│   └── entrypoint.sh             # Container entrypoint script
│
└── lambda/                       # Test orchestration
    ├── handler.py                # Lambda function code
    └── requirements.txt          # Python dependencies
```

## Quick Start

For those already familiar with the setup, here are the essential commands:

1. Build and push the JMeter Docker image:
   ```bash
   cd jmeter
   docker build -t jmeter:latest .
   docker tag jmeter:latest <aws-account-id>.dkr.ecr.<region>.amazonaws.com/jmeter:latest
   docker push <aws-account-id>.dkr.ecr.<region>.amazonaws.com/jmeter:latest
   ```

### 2. Configure Environment

1. Navigate to the production environment:
   ```bash
   cd envs/prod
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Configure your variables in `terraform.tfvars`:
   ```hcl
   name             = "jmeter-prod"
   region           = "us-east-1"
   secondary_region = "eu-west-1"
   ecr_image        = "your-account-id.dkr.ecr.region.amazonaws.com/jmeter:5.6.3"
   ```

### 3. Deploy Infrastructure

```bash
terraform plan
terraform apply
```

## Running Load Tests

1. Prepare your test package:
   ```
   test-package/
   ├── config.json
   ├── test.jmx
   └── test-data.csv
   ```

2. Create a zip file and upload to S3:
   ```bash
   zip -r test-package.zip test-package/
   aws s3 cp test-package.zip s3://test-surge-perf/test-package.zip
   ```

## Test Configuration

### config.json

Create a `config.json` file in your test package with the following structure:

```json
{
  "slave_count": 2,
  "test_plan": "test.jmx",
  "threads": 100,
  "ramp_up": 60,
  "duration": 300,
  "region": "us-east-1"
}
```

### Environment Variables

The following environment variables are used by the JMeter containers:

- `JMETER_MODE`: Set to "master" or "slave"
- `TEST_PLAN_S3`: S3 path to test plan (e.g., "s3://test-surge-perf/test")
- `RESULT_S3`: S3 path for results (e.g., "s3://test-surge-perf/results/result.jtl")
- `JMETER_SLAVE_HOSTS`: Comma-separated list of slave IPs (for master only)

## Monitoring and Troubleshooting

```json
{
  "slave_count": 2,
  "test_plan": "test.jmx",
  "threads": 100,
  "ramp_up": 60,
  "duration": 300
}
```

## Monitoring

### CloudWatch Logs
- Lambda Function: `/aws/lambda/test_run_handler_lambda`
- ECS Tasks: `/ecs/jmeter-perf-test-*`

### ECS Console
- Monitor task status and resource utilization
- View task logs in CloudWatch Logs

### S3 Results
- Test results: `s3://test-surge-perf/results/`
- Logs: `s3://test-surge-perf/logs/`

## Common Issues and Solutions

### 1. ECS Service Creation Fails
- **Symptom**: "Creation of service was not idempotent"
- **Solution**:
  ```bash
  terraform destroy
  # Wait for all resources to be deleted
  terraform apply
  ```

### 2. Lambda Deployment Issues
- **Symptom**: "Error reading ZIP file"
- **Solution**:
  ```bash
  cd lambda
  zip -r ../envs/prod/function.zip .
  cd ../envs/prod
  terraform apply
  ```

### 3. S3 Bucket Already Exists
- **Symptom**: "BucketAlreadyExists" error
- **Solution**: Use a unique bucket name in `terraform.tfvars`

### 4. ECR Authentication Issues
- **Symptom**: "no basic auth credentials"
- **Solution**:
  ```bash
  aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws-account-id>.dkr.ecr.<region>.amazonaws.com
  ```

## Cleanup

### Scale Down Services
To temporarily stop resources (preserves configuration):
```bash
# Scale down US services
aws ecs update-service --cluster jmeter-perf-test-us --service jmeter-perf-test-master --desired-count 0 --region us-east-1
aws ecs update-service --cluster jmeter-perf-test-us --service jmeter-perf-test-slave --desired-count 0 --region us-east-1

# Scale down EU services
aws ecs update-service --cluster jmeter-perf-test-eu --service jmeter-perf-test-slave --desired-count 0 --region eu-west-1
```

### Complete Teardown
To delete all resources (including S3 buckets):
```bash
cd envs/prod
# Empty S3 buckets first
aws s3 rm s3://test-surge-perf --recursive
# Destroy infrastructure
terraform destroy
```

> **Warning**: This will permanently delete all resources including S3 buckets. Ensure you have backed up any important data.

## Security Considerations

- IAM roles follow least-privilege principle
- VPC peering is secured with proper route tables
- S3 buckets have appropriate bucket policies
- All inter-container communication is secured within VPC

## Troubleshooting

1. **Tasks not starting**:
   - Check ECS service events
   - Verify IAM roles and permissions
   - Check CloudWatch logs for the Lambda function

2. **Connectivity issues**:
   - Verify security group rules
   - Check VPC peering connection status
   - Validate route tables

3. **Test failures**:
   - Check JMeter logs in CloudWatch
   - Verify test plan and data files in S3
   - Check Lambda execution logs

## License

[Your License Here]
