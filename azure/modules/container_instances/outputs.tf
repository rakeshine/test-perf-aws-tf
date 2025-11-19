# Master info
output "master_name" {
  value = azurerm_container_group.master.name
}

# container group's FQDN / IP - only meaningful if public IP assigned or private subnet used
output "master_ip_address" {
  description = "Master IP address (private or public depending on subnet selection). May be empty if not assigned by Azure immediately."
  value       = try(azurerm_container_group.master.ip_address, "")
}

# Slave container group names and IPs
output "slave_names" {
  value = [for s in azurerm_container_group.slave : s.name]
}

output "slave_ips" {
  description = "List of slave ip_address objects (string) where available. Empty strings for missing values."
  value       = [for s in azurerm_container_group.slave : try(s.ip_address, "") ]
}

output "container_group_ids" {
  value = {
    master = azurerm_container_group.master.id
    slaves = { for k, v in azurerm_container_group.slave : k => v.id }
  }
}
