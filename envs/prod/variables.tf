variable "name" {
  description = "Name of the environment"
  type        = string
  default     = "jmeter"
}

variable "region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region"
  type        = string
  default     = "eu-west-2"
}

# VPC Configuration
variable "vpc_cidr_primary" {
  description = "CIDR block for primary VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "vpc_cidr_secondary" {
  description = "CIDR block for secondary VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnets_primary" {
  description = "List of public subnets for primary region"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "public_subnets_secondary" {
  description = "List of public subnets for secondary region"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

# JMeter Configuration
variable "master_count" {
  description = "Number of JMeter master instances to run in the primary region"
  type        = number
  default     = 1
}

variable "slave_count_us" {
  description = "Number of JMeter slave instances to run in the US region"
  type        = number
  default     = 2
}

variable "slave_count_eu" {
  description = "Number of JMeter slave instances to run in the EU region"
  type        = number
  default     = 2
}

variable "ecr_image" {
  description = "ECR image URI for JMeter container"
  type        = string
  default     = ""
}

variable "small_master_cpu" {
  description = "CPU units for the JMeter tasks"
  type        = number
  default     = 1024
}

variable "small_master_memory" {
  description = "Memory for the JMeter tasks (in MiB)"
  type        = number
  default     = 2048
}

variable "small_slave_cpu" {
  description = "CPU units for the JMeter tasks"
  type        = number
  default     = 1024
}

variable "small_slave_memory" {
  description = "Memory for the JMeter tasks (in MiB)"
  type        = number
  default     = 2048
}

variable "medium_master_cpu" {
  description = "CPU units for the JMeter tasks"
  type        = number
  default     = 1024
}

variable "medium_master_memory" {
  description = "Memory for the JMeter tasks (in MiB)"
  type        = number
  default     = 2048
}

variable "medium_slave_cpu" {
  description = "CPU units for the JMeter tasks"
  type        = number
  default     = 1024
}

variable "medium_slave_memory" {
  description = "Memory for the JMeter tasks (in MiB)"
  type        = number
  default     = 2048
}

variable "large_master_cpu" {
  description = "CPU units for the JMeter tasks"
  type        = number
  default     = 1024
}

variable "large_master_memory" {
  description = "Memory for the JMeter tasks (in MiB)"
  type        = number
  default     = 2048
}

variable "large_slave_cpu" {
  description = "CPU units for the JMeter tasks"
  type        = number
  default     = 1024
}

variable "large_slave_memory" {
  description = "Memory for the JMeter tasks (in MiB)"
  type        = number
  default     = 2048
}