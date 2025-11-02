# VPC Outputs
output "us_vpc_id" {
  description = "ID of the US VPC"
  value       = module.vpc_us.vpc_id
}

output "eu_vpc_id" {
  description = "ID of the EU VPC"
  value       = module.vpc_eu.vpc_id
}

# ECS Cluster Outputs
output "us_cluster_name" {
  description = "Name of the ECS cluster in US"
  value       = module.ecs_cluster_us.cluster_name
}

output "eu_cluster_name" {
  description = "Name of the ECS cluster in EU"
  value       = module.ecs_cluster_eu.cluster_name
}

# JMeter Task Definition Outputs
output "jmeter_task_definitions" {
  description = "Map of JMeter task definition ARNs by region and size"
  value = {
    us = {
      small = {
        master = module.jmeter_us_small.master_task_definition_arn
        slave  = module.jmeter_us_small.slave_task_definition_arns[0]
      }
      medium = {
        master = module.jmeter_us_medium.master_task_definition_arn
        slave  = module.jmeter_us_medium.slave_task_definition_arns[0]
      }
      large = {
        master = module.jmeter_us_large.master_task_definition_arn
        slave  = module.jmeter_us_large.slave_task_definition_arns[0]
      }
    }
    eu = {
      small = {
        slave = module.jmeter_eu_small.slave_task_definition_arns[0]
      }
      medium = {
        slave = module.jmeter_eu_medium.slave_task_definition_arns[0]
      }
      large = {
        slave = module.jmeter_eu_large.slave_task_definition_arns[0]
      }
    }
  }
}

# IAM Role Outputs
output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = module.iam.task_exec_role_arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = module.iam.task_role_arn
}

# VPC Peering Output
output "vpc_peering_connection_id" {
  description = "ID of the VPC peering connection between US and EU"
  value       = aws_vpc_peering_connection.us_eu.id
}

# Security Group Outputs
output "us_security_group_id" {
  description = "ID of the security group in US"
  value       = module.vpc_us.security_group_id
}

output "eu_security_group_id" {
  description = "ID of the security group in EU"
  value       = module.vpc_eu.security_group_id
}