################################################################################
# JMeter Task definition
################################################################################

variable "region" {
  description = "Region where the resource(s) will be managed. Defaults to the Region set in the provider configuration"
  type        = string
  default     = null
}

variable "name" {
  description = "Name prefix for the task definitions (up to 255 letters, numbers, hyphens, and underscores)"
  type        = string
  validation {
    condition     = contains(["small", "medium", "large"], var.name)
    error_message = "The name must be one of 'small', 'medium', or 'large'."
}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "master_required" {
  description = "Whether to create the master task definition"
  type        = bool
  default     = false
}

variable "slaves_count" {
  description = "Number of slave task definitions to create"
  type        = number
  default     = 1
}

variable "ecr_image" {
  description = "The ECR image URI to use for the container"
  type        = string
}

variable "ecs_task_exec_role_arn" {
  description = "ARN of the IAM role that allows ECS to make calls to your load balancer on your behalf"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the IAM role that the container can assume for AWS API calls"
  type        = string
  default     = null
}

variable "master_cpu" {
  description = "CPU units for the master container (1024 units = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "master_memory" {
  description = "Memory for the master container in MiB"
  type        = number
  default     = 2048
}

variable "slave_cpu" {
  description = "CPU units for each slave container (1024 units = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "slave_memory" {
  description = "Memory for each slave container in MiB"
  type        = number
  default     = 2048
}

variable "server_port" {
  description = "Port that the JMeter server will listen on"
  type        = number
  default     = 1099
}

variable "server_rmi_localport" {
  description = "Local port for RMI communication"
  type        = number
  default     = 50000
}

variable "environment_variables" {
  description = "List of environment variables to pass to the containers"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "master_port_mappings" {
  description = "List of port mappings for the master container"
  type = list(object({
    containerPort = number
    hostPort      = number
    protocol      = string
  }))
  default = [
    {
      containerPort = 1099
      hostPort      = 1099
      protocol      = "tcp"
    },
    {
      containerPort = 50000
      hostPort      = 50000
      protocol      = "tcp"
    }
  ]
}

variable "slave_port_mappings" {
  description = "List of port mappings for the slave container"
  type = list(object({
    containerPort = number
    hostPort      = number
    protocol      = string
  }))
  default = [
    {
      containerPort = 1099
      hostPort      = 1099
      protocol      = "tcp"
    },
    {
      containerPort = 50000
      hostPort      = 50000
      protocol      = "tcp"
    }
  ]
}
