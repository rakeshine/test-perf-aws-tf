variable "name" {
  description = "The name of the storage account"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the storage account"
  type        = string
}

variable "location" {
  description = "Specifies the supported Azure location where the resource exists"
  type        = string
}

variable "account_tier" {
  description = "The tier to use for this storage account"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "The type of replication to use for this storage account"
  type        = string
  default     = "LRS"
}

variable "blob_retention_days" {
  description = "Number of days to retain blobs"
  type        = number
  default     = 30
}

variable "file_share_retention_days" {
  description = "Number of days to retain file shares"
  type        = number
  default     = 30
}

variable "file_share_quota_gb" {
  description = "The maximum size of the file share in GB"
  type        = number
  default     = 5120 # 5TB
}

variable "allowed_ips" {
  description = "List of IP addresses to allow access to the storage account"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs to allow access to the storage account"
  type        = list(string)
  default     = []
}

variable "private_endpoint_subnet_id" {
  description = "The ID of the subnet from which private IP addresses will be allocated for the private endpoint"
  type        = string
  default     = ""
}

variable "virtual_network_id" {
  description = "The ID of the virtual network to link the private DNS zone"
  type        = string
  default     = ""
}

variable "create_private_endpoint" {
  description = "Whether to create a private endpoint for the storage account"
  type        = bool
  default     = false
}

variable "managed_identity_principal_id" {
  description = "The principal ID of the managed identity to assign roles to"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}