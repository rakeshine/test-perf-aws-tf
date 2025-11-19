variable "name" {
  description = "The name of the container registry"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the container registry"
  type        = string
}

variable "location" {
  description = "Specifies the supported Azure location where the resource exists"
  type        = string
}

variable "sku" {
  description = "The SKU name of the container registry"
  type        = string
  default     = "Standard"
}

variable "admin_enabled" {
  description = "Specifies whether admin is enabled"
  type        = bool
  default     = true
}

variable "virtual_network_id" {
  description = "The ID of the virtual network to link the private DNS zone"
  type        = string
  default     = ""
}

variable "private_endpoint_subnet_id" {
  description = "The ID of the subnet from which private IP addresses will be allocated for the private endpoint"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}