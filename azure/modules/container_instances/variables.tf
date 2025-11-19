variable "name" {
  description = "The name of the container group"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the container group"
  type        = string
}

variable "location" {
  description = "The Azure location where the container group should exist"
  type        = string
}

variable "container_image" {
  description = "The container image to deploy"
  type        = string
}

variable "cpu" {
  description = "The required number of CPU cores of the container"
  type        = number
  default     = 1
}

variable "memory" {
  description = "The required memory of the container in GB"
  type        = number
  default     = 1.5
}

variable "ports" {
  description = "A list of ports to expose from the container"
  type = list(object({
    port     = number
    protocol = optional(string, "TCP")
  }))
  default = []
}

variable "environment_variables" {
  description = "A map of environment variables to set in the container"
  type        = map(string)
  default     = {}
}

variable "secure_environment_variables" {
  description = "A map of secure environment variables to set in the container"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "volumes" {
  description = "A list of volumes to mount in the container"
  type = list(object({
    name        = string
    mount_path  = string
    read_only   = optional(bool, false)
    git_repo    = optional(list(object({
      url       = string
      directory = optional(string)
      revision  = optional(string)
    })), [])
    empty_dir   = optional(list(object({
      medium     = optional(string, "Memory")
      size_limit = optional(string)
    })), [])
    secrets     = optional(map(string), {})
  }))
  default = []
}

variable "command" {
  description = "The command to run in the container"
  type        = list(string)
  default     = null
}

variable "restart_policy" {
  description = "The restart policy for the container group"
  type        = string
  default     = "Always"
  validation {
    condition     = contains(["Always", "Never", "OnFailure"], var.restart_policy)
    error_message = "The restart policy must be one of: Always, Never, OnFailure."
  }
}

variable "network_profile_id" {
  description = "The ID of the network profile to associate with the container group"
  type        = string
  default     = null
}

variable "dns_name_label" {
  description = "The DNS label/name for the container group's IP"
  type        = string
  default     = null
}

variable "enable_public_ip" {
  description = "Whether to enable a public IP address for the container group"
  type        = bool
  default     = false
}

variable "liveness_probe" {
  description = "Liveness probe configuration"
  type = object({
    exec                      = optional(list(string))
    http_get                  = optional(list(object({
      path   = string
      port   = number
      scheme = optional(string, "HTTP")
    })))
    initial_delay_seconds     = optional(number, 10)
    period_seconds            = optional(number, 30)
    failure_threshold         = optional(number, 3)
    success_threshold         = optional(number, 1)
    timeout_seconds           = optional(number, 5)
  })
  default = null
}

variable "readiness_probe" {
  description = "Readiness probe configuration"
  type = object({
    exec                      = optional(list(string))
    http_get                  = optional(list(object({
      path   = string
      port   = number
      scheme = optional(string, "HTTP")
    })))
    initial_delay_seconds     = optional(number, 10)
    period_seconds            = optional(number, 30)
    failure_threshold         = optional(number, 3)
    success_threshold         = optional(number, 1)
    timeout_seconds           = optional(number, 5)
  })
  default = null
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace to send diagnostics to"
  type        = string
  default     = null
}

variable "log_analytics_workspace_key" {
  description = "The key for the Log Analytics Workspace"
  type        = string
  default     = null
  sensitive   = true
}

variable "log_analytics_metadata" {
  description = "Additional metadata to include in the logs"
  type        = map(string)
  default     = {}
}

variable "acr_id" {
  description = "The ID of the Azure Container Registry to pull images from"
  type        = string
  default     = ""
}

variable "container_type" {
  description = "The type of container (e.g., jmeter-master, jmeter-slave)"
  type        = string
  default     = "generic"
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}