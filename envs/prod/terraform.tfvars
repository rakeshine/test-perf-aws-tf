# Global Configuration
name             = "jmeter-perf-test"
region           = "us-east-1"
secondary_region = "eu-west-1"

# VPC Configuration
vpc_cidr_primary   = "10.10.0.0/16"
vpc_cidr_secondary = "10.20.0.0/16"

public_subnets_primary   = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
public_subnets_secondary = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]

# JMeter Configuration
ecr_image = "your-account-id.dkr.ecr.region.amazonaws.com/jmeter:latest"

# Small Instance Configuration
small_master_cpu    = 1024
small_master_memory = 2048
small_slave_cpu     = 1024
small_slave_memory  = 2048

# Medium Instance Configuration
medium_master_cpu    = 2048
medium_master_memory = 4096
medium_slave_cpu     = 2048
medium_slave_memory  = 4096

# Large Instance Configuration
large_master_cpu    = 4096
large_master_memory = 8192
large_slave_cpu     = 4096
large_slave_memory  = 8192

# Slave Count Configuration
slave_count_us = 1
slave_count_eu = 1