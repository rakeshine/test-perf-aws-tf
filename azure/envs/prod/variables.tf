variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR block for the VNet"
  type        = string
  default     = "10.50.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = [
    "10.50.1.0/24",
    "10.50.2.0/24"
  ]
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# JMeter master settings
variable "master_image" {
  description = "Container image for JMeter master"
  type        = string
  default     = "yourorg/jmeter-master:latest"
}

variable "master_cpu" {
  description = "vCPU for master"
  type        = number
  default     = 1
}

variable "master_memory" {
  description = "Memory (GB) for master"
  type        = number
  default     = 1.5
}

variable "master_ports" {
  description = "Ports for master"
  type        = list(number)
  default     = [1099, 50000]
}

variable "master_env" {
  description = "Environment variables for master"
  type        = map(string)
  default     = {}
}

# JMeter slave settings
variable "slave_image" {
  description = "Container image for JMeter slave"
  type        = string
  default     = "yourorg/jmeter-slave:latest"
}

variable "slave_cpu" {
  description = "vCPU per slave"
  type        = number
  default     = 0.5
}

variable "slave_memory" {
  description = "Memory (GB) per slave"
  type        = number
  default     = 1
}

variable "slave_ports" {
  description = "Ports for slaves"
  type        = list(number)
  default     = [1099]
}

variable "slave_count" {
  description = "Number of slaves"
  type        = number
  default     = 2
}

variable "slave_env" {
  description = "Environment variables for slaves"
  type        = map(string)
  default     = {}
}

variable "master_host" {
  description = "Optional JMeter master host/IP propagated to slaves"
  type        = string
  default     = ""
}
