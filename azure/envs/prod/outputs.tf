# VPC Outputs
output "resource_group_name" {
  description = "Resource group created by networking module"
  value       = module.networking.resource_group_name
}

output "vnet_id" {
  description = "VNet ID"
  value       = module.networking.vnet_id
}

output "public_subnet_ids" {
  description = "Map of public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "nsg_id" {
  description = "NSG ID applied to public subnets"
  value       = module.networking.nsg_id
}

# Storage Outputs
output "storage_account_name" {
  description = "Storage account name used for JMeter artifacts"
  value       = module.storage.name
}

output "test_plans_container_name" {
  description = "Blob container for test plans"
  value       = module.storage.test_plans_container_name
}

output "results_share_name" {
  description = "File share for JMeter results"
  value       = module.storage.file_share_name
}

# ACI Outputs
output "aci_master_name" {
  description = "ACI master group name"
  value       = module.aci_jmeter.master_name
}

output "aci_master_ip" {
  description = "ACI master IP address (public or private)"
  value       = module.aci_jmeter.master_ip_address
}

output "aci_slave_names" {
  description = "ACI slave group names"
  value       = module.aci_jmeter.slave_names
}

output "aci_slave_ips" {
  description = "ACI slave IP addresses"
  value       = module.aci_jmeter.slave_ips
}