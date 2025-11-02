/**
 * Main Terraform configuration for JMeter Load Testing Infrastructure
 * 
 * This configuration sets up a multi-region JMeter load testing environment with the following components:
 * - VPCs in US and EU regions
 * - ECS clusters in both regions
 * - IAM roles and policies
 * - JMeter tasks with different sizes (small, medium, large)
 * - VPC peering between regions
 */

terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.14"
    }
  }
}

# Primary AWS provider for US region
provider "aws" {
  region = var.region
}

# Secondary AWS provider for EU region
provider "aws" {
  alias  = "europe"
  region = var.secondary_region
}

# Common tags for all resources
locals {
  tags = {
    Owner = "PerformanceTesting"
  }
}

################################
# VPCs
################################

# Primary VPC (US)
module "vpc_us" {
  source = "../../modules/vpc"

  region = var.region
  name   = "${var.name}-us"

  vpc_cidr       = var.vpc_cidr_primary
  public_subnets = var.public_subnets_primary
  tags           = merge(local.tags, { Region = "us" })
}

# Secondary VPC (Europe)
module "vpc_eu" {
  source = "../../modules/vpc"

  providers = {
    aws = aws.europe
  }

  region = var.secondary_region
  name   = "${var.name}-eu"

  vpc_cidr       = var.vpc_cidr_secondary
  public_subnets = var.public_subnets_secondary
  tags           = merge(local.tags, { Region = "eu" })
}

################################
# ECS Cluster
################################

module "ecs_cluster_us" {
  source = "../../modules/ecs_cluster"

  name = "${var.name}-us"
  tags = merge(local.tags, { Region = "us" })
}

module "ecs_cluster_eu" {
  source = "../../modules/ecs_cluster"

  providers = {
    aws = aws.europe
  }

  name = "${var.name}-eu"
  tags = merge(local.tags, { Region = "eu" })
}

################################
# ECS Services
################################

# US Region - JMeter Master Service
module "ecs_service_master_small_us" {
  source = "../../modules/ecs_service"

  name                = "${var.name}-master-small"
  region              = var.region
  cluster_arn         = module.ecs_cluster_us.cluster_arn
  task_definition_arn = module.jmeter_us_small.master_task_definition_arn
  subnets             = module.vpc_us.public_subnet_ids
  security_groups     = [module.vpc_us.security_group_id]
  desired_count       = 0
  tags                = merge(local.tags, { Role = "master", Region = "us" })
}

module "ecs_service_master_medium_us" {
  source = "../../modules/ecs_service"

  name                = "${var.name}-master-medium"
  region              = var.region
  cluster_arn         = module.ecs_cluster_us.cluster_arn
  task_definition_arn = module.jmeter_us_medium.master_task_definition_arn
  subnets             = module.vpc_us.public_subnet_ids
  security_groups     = [module.vpc_us.security_group_id]
  desired_count       = 0
  tags                = merge(local.tags, { Role = "master", Region = "us" })
}

module "ecs_service_master_large_us" {
  source = "../../modules/ecs_service"

  name                = "${var.name}-master-large"
  region              = var.region
  cluster_arn         = module.ecs_cluster_us.cluster_arn
  task_definition_arn = module.jmeter_us_large.master_task_definition_arn
  subnets             = module.vpc_us.public_subnet_ids
  security_groups     = [module.vpc_us.security_group_id]
  desired_count       = 0
  tags                = merge(local.tags, { Role = "master", Region = "us" })
}

# US Region - JMeter Slave Service
module "ecs_service_slave_small_us" {
  source = "../../modules/ecs_service"

  name                = "${var.name}-slave-small"
  region              = var.region
  cluster_arn         = module.ecs_cluster_us.cluster_arn
  task_definition_arn = module.jmeter_us_small.slave_task_definition_arns[0]
  subnets             = module.vpc_us.public_subnet_ids
  security_groups     = [module.vpc_us.security_group_id]
  desired_count       = 0
  tags                = merge(local.tags, { Role = "slave", Region = "us" })
}

module "ecs_service_slave_medium_us" {
  source = "../../modules/ecs_service"

  name                = "${var.name}-slave-medium"
  region              = var.region
  cluster_arn         = module.ecs_cluster_us.cluster_arn
  task_definition_arn = module.jmeter_us_medium.slave_task_definition_arns[0]
  subnets             = module.vpc_us.public_subnet_ids
  security_groups     = [module.vpc_us.security_group_id]
  desired_count       = 0
  tags                = merge(local.tags, { Role = "slave", Region = "us" })
}

module "ecs_service_slave_large_us" {
  source = "../../modules/ecs_service"

  name                = "${var.name}-slave-large"
  region              = var.region
  cluster_arn         = module.ecs_cluster_us.cluster_arn
  task_definition_arn = module.jmeter_us_large.slave_task_definition_arns[0]
  subnets             = module.vpc_us.public_subnet_ids
  security_groups     = [module.vpc_us.security_group_id]
  desired_count       = 0
  tags                = merge(local.tags, { Role = "slave", Region = "us" })
}

# EU Region - JMeter Slave Service Only
module "ecs_service_slave_small_eu" {
  source = "../../modules/ecs_service"

  providers = {
    aws = aws.europe
  }

  name                = "${var.name}-slave-small"
  region              = var.secondary_region
  cluster_arn         = module.ecs_cluster_eu.cluster_arn
  task_definition_arn = module.jmeter_eu_small.slave_task_definition_arns[0]
  subnets             = module.vpc_eu.public_subnet_ids
  security_groups     = [module.vpc_eu.security_group_id]
  desired_count       = 0
  tags                = merge(local.tags, { Role = "slave", Region = "eu" })
}

module "ecs_service_slave_medium_eu" {
  source = "../../modules/ecs_service"

  providers = {
    aws = aws.europe
  }

  name                = "${var.name}-slave-medium"
  region              = var.secondary_region
  cluster_arn         = module.ecs_cluster_eu.cluster_arn
  task_definition_arn = module.jmeter_eu_medium.slave_task_definition_arns[0]
  subnets             = module.vpc_eu.public_subnet_ids
  security_groups     = [module.vpc_eu.security_group_id]
  desired_count       = 0
  tags                = merge(local.tags, { Role = "slave", Region = "eu" })
}

module "ecs_service_slave_large_eu" {
  source = "../../modules/ecs_service"

  providers = {
    aws = aws.europe
  }

  name                = "${var.name}-slave-large"
  region              = var.secondary_region
  cluster_arn         = module.ecs_cluster_eu.cluster_arn
  task_definition_arn = module.jmeter_eu_large.slave_task_definition_arns[0]
  subnets             = module.vpc_eu.public_subnet_ids
  security_groups     = [module.vpc_eu.security_group_id]
  desired_count       = 0
  tags                = merge(local.tags, { Role = "slave", Region = "eu" })
}

################################
# ECR Repository
################################
module "ecr" {
  source = "../../modules/ecr"
}

################################
# IAM
################################
module "iam" {
  source = "../../modules/iam"
}

################################
# JMeter Tasks - US Region
################################

# Small JMeter tasks in US
module "jmeter_us_small" {
  source = "../../modules/ecs_tasks_jmeter"

  name   = "small"
  region = var.region

  ecs_task_exec_role_arn = module.iam.task_exec_role_arn
  ecs_task_role_arn      = module.iam.task_role_arn

  master_required = true
  slaves_count    = var.slave_count_us

  # Container configuration
  ecr_image     = var.ecr_image
  master_cpu    = var.small_master_cpu
  master_memory = var.small_master_memory
  slave_cpu     = var.small_slave_cpu
  slave_memory  = var.small_slave_memory

  tags = merge(local.tags, { Region = "us" })
}

# Medium JMeter tasks in US
module "jmeter_us_medium" {
  source = "../../modules/ecs_tasks_jmeter"

  name   = "medium"
  region = var.region

  ecs_task_exec_role_arn = module.iam.task_exec_role_arn
  ecs_task_role_arn      = module.iam.task_role_arn

  master_required = true
  slaves_count    = var.slave_count_us

  # Container configuration
  ecr_image     = var.ecr_image
  master_cpu    = var.medium_master_cpu
  master_memory = var.medium_master_memory
  slave_cpu     = var.medium_slave_cpu
  slave_memory  = var.medium_slave_memory

  tags = merge(local.tags, { Region = "us" })
}

# Large JMeter tasks in US
module "jmeter_us_large" {
  source = "../../modules/ecs_tasks_jmeter"

  name   = "large"
  region = var.region

  ecs_task_exec_role_arn = module.iam.task_exec_role_arn
  ecs_task_role_arn      = module.iam.task_role_arn

  master_required = true
  slaves_count    = var.slave_count_us

  # Container configuration
  ecr_image     = var.ecr_image
  master_cpu    = var.large_master_cpu
  master_memory = var.large_master_memory
  slave_cpu     = var.large_slave_cpu
  slave_memory  = var.large_slave_memory

  tags = merge(local.tags, { Region = "us" })
}

################################
# JMeter Tasks - EU Region
################################

# Small JMeter tasks in EU
module "jmeter_eu_small" {
  source = "../../modules/ecs_tasks_jmeter"

  providers = {
    aws = aws.europe
  }

  name   = "small"
  region = var.secondary_region

  ecs_task_exec_role_arn = module.iam.task_exec_role_arn
  ecs_task_role_arn      = module.iam.task_role_arn

  master_required = false
  slaves_count    = var.slave_count_eu

  ecr_image    = var.ecr_image
  slave_cpu    = var.small_slave_cpu
  slave_memory = var.small_slave_memory

  tags = merge(local.tags, { Region = "eu" })
}

# Medium JMeter tasks in EU
module "jmeter_eu_medium" {
  source = "../../modules/ecs_tasks_jmeter"

  providers = {
    aws = aws.europe
  }

  name   = "medium"
  region = var.secondary_region

  ecs_task_exec_role_arn = module.iam.task_exec_role_arn
  ecs_task_role_arn      = module.iam.task_role_arn

  master_required = false
  slaves_count    = var.slave_count_eu

  ecr_image    = var.ecr_image
  slave_cpu    = var.medium_slave_cpu
  slave_memory = var.medium_slave_memory

  tags = merge(local.tags, { Region = "eu" })
}

# Large JMeter tasks in EU
module "jmeter_eu_large" {
  source = "../../modules/ecs_tasks_jmeter"

  providers = {
    aws = aws.europe
  }

  name   = "large"
  region = var.secondary_region

  ecs_task_exec_role_arn = module.iam.task_exec_role_arn
  ecs_task_role_arn      = module.iam.task_role_arn

  master_required = false
  slaves_count    = var.slave_count_eu

  ecr_image    = var.ecr_image
  slave_cpu    = var.large_slave_cpu
  slave_memory = var.large_slave_memory

  tags = merge(local.tags, { Region = "eu" })
}
################################
# VPC Peering
################################

# VPC Peering between US and EU
resource "aws_vpc_peering_connection" "us_eu" {
  provider    = aws
  vpc_id      = module.vpc_us.vpc_id
  peer_vpc_id = module.vpc_eu.vpc_id
  peer_region = var.secondary_region

  auto_accept = false

  tags = merge(local.tags, {
    Name = "${var.name}-us-eu-peering"
  })
}

# Accept the peering connection in the EU region
resource "aws_vpc_peering_connection_accepter" "eu_accept" {
  provider                  = aws.europe
  vpc_peering_connection_id = aws_vpc_peering_connection.us_eu.id
  auto_accept               = true

  tags = merge(local.tags, {
    Name = "${var.name}-eu-accept-peering"
  })
}
################################
# S3 Bucket, Lambda and its Policy
################################
# S3 Buckets
resource "aws_s3_bucket" "test_surge" {
  bucket = "test-surge-perf"
  tags = {
    Name = "perf-testing"
  }
}

# Lambda IAM Role and Policy
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_s3_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "lambda_s3_access_policy"
  description = "Allows Lambda to read from S3 and write to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ],
        Effect = "Allow",
        Resource = [
          "${aws_s3_bucket.test_surge.arn}",
          "${aws_s3_bucket.test_surge.arn}/*"
        ]
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

# AWS Lambda Function
resource "aws_lambda_function" "test_run_handler_lambda" {
  filename      = "function.zip"
  function_name = "test_run_handler_lambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  memory_size   = 1024
  timeout       = 30

  environment {
    variables = {
      ECS_CLUSTER     = module.ecs_cluster_us.cluster_name 
      SUBNETS         = join(",", module.vpc_us.public_subnet_ids)
      SECURITY_GROUPS = module.vpc_us.security_group_id
    }
  }
}

# S3 Bucket Notification Configuration to trigger Lambda
resource "aws_s3_bucket_notification" "s3_lambda_trigger" {
  bucket = aws_s3_bucket.test_surge.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.test_run_handler_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".zip"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

# Grant S3 permission to invoke Lambda
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_run_handler_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.test_surge.arn
}