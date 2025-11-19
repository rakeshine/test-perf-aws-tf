################################################################################
# Service
################################################################################

variable "region" {
  description = "Region where the resource(s) will be managed. Defaults to the Region set in the provider configuration"
  type        = string
  default     = null
}

variable "name" {
  description = "Name of the service (up to 255 letters, numbers, hyphens, and underscores)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "subnets" {
  description = "List of subnets for the service"
  type        = list(string)
  default     = []
}

variable "security_groups" {
  description = "List of security groups for the service"
  type        = list(string)
  default     = []
}

variable "desired_count" {
  description = "Number of instances of the task definition to place and keep running. Defaults to 0."
  type        = number
  default     = 0
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster where the resources will be provisioned"
  type        = string
  default     = ""
  nullable    = false
}

variable "task_definition_arn" {
  description = "Existing task definition ARN"
  type        = string
  default     = null
}