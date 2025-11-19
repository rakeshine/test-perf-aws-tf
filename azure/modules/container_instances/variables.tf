variable "name" {
  description = "Prefix for resource names"
  type        = string
}

variable "location" {
  description = "Azure region (location)"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource Group name where ACIs will be deployed"
  type        = string
}

variable "subnet_id" {
  description = <<EOT
Optional subnet id to deploy ACA containers into (for private networking).
Format: /subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<subnet>
If empty, ACI will be created without VNet integration (public IP or no private connectivity).
EOT
  type    = string
  default = ""
}

# Master container settings
variable "master_image" {
  description = "Container image for JMeter master"
  type        = string
  default     = "yourorg/jmeter-master:latest"
}

variable "master_cpu" {
  description = "CPU for master container"
  type        = number
  default     = 1
}

variable "master_memory" {
  description = "Memory (GB) for master container"
  type        = number
  default     = 1.5
}

variable "master_ports" {
  description = "List of ports to expose on master (for example 1099,50000)"
  type        = list(number)
  default     = [1099, 50000]
}

variable "master_env" {
  description = "Map of environment variables for master container"
  type        = map(string)
  default     = {}
}

# Slave container settings
variable "slave_image" {
  description = "Container image for JMeter slave"
  type        = string
  default     = "yourorg/jmeter-slave:latest"
}

variable "slave_cpu" {
  description = "CPU for each slave container"
  type        = number
  default     = 0.5
}

variable "slave_memory" {
  description = "Memory (GB) for each slave container"
  type        = number
  default     = 1.0
}

variable "slave_ports" {
  description = "List of ports to expose on slave containers"
  type        = list(number)
  default     = [1099]
}

variable "slave_count" {
  description = "Number of slave container groups to create"
  type        = number
  default     = 2
}

variable "slave_env" {
  description = "Map of environment variables for slave containers (master host may be injected by module if master_host provided)"
  type        = map(string)
  default     = {}
}

# Optional: If you want Terraform to set JMETER_MASTER_HOST in slaves, provide it.
variable "master_host" {
  description = <<EOT
Optional IP/hostname for the JMeter master. If provided, module will add JMETER_MASTER_HOST to each slave's env.
If not provided, slaves are created without JMETER_MASTER_HOST. You can run two-phase apply to inject the IP after master is created.
EOT
  type    = string
  default = ""
}

variable "tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default     = {}
}

# If you use private container registry, supply credentials (optional)
variable "registry_server" {
  description = "Container registry server, e.g. myregistry.azurecr.io"
  type        = string
  default     = ""
}

variable "registry_username" {
  description = "Registry username (optional)"
  type        = string
  default     = ""
}

variable "registry_password" {
  description = "Registry password (optional)"
  type        = string
  default     = ""
}
