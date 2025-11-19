variable "name" {
  description = "The name of the Function App"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Function App"
  type        = string
}

variable "location" {
  description = "The Azure region where the Function App should exist"
  type        = string
}

variable "storage_account_access_key" {
  description = "The access key for the storage account"
  type        = string
  sensitive   = true
}

variable "storage_account_id" {
  description = "The ID of the storage account to be used by the Function App"
  type        = string
}

variable "sku_name" {
  description = "The SKU name for the App Service Plan"
  type        = string
  default     = "Y1"
}

variable "app_settings" {
  description = "A map of application settings for the Function App"
  type        = map(string)
  default     = {}
}

variable "allowed_ips" {
  description = "List of IP addresses allowed to access the Function App"
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace to send logs to"
  type        = string
  default     = null
}

variable "integrate_with_vnet" {
  description = "Whether to integrate the Function App with a VNet"
  type        = bool
  default     = false
}

variable "vnet_subnet_id" {
  description = "The ID of the subnet to integrate with"
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "The ID of the Key Vault to grant access to"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}