output "id" {
  description = "The ID of the Container Group"
  value       = azurerm_container_group.aci.id
}

output "name" {
  description = "The name of the Container Group"
  value       = azurerm_container_group.aci.name
}

output "ip_address" {
  description = "The IP address allocated to the container group"
  value       = azurerm_container_group.aci.ip_address
}

output "fqdn" {
  description = "The FQDN of the container group"
  value       = azurerm_container_group.aci.fqdn
}

output "identity" {
  description = "The identity block of the container group"
  value       = azurerm_container_group.aci.identity
}

output "container" {
  description = "The container configuration"
  value       = azurerm_container_group.aci.container
}

output "os_type" {
  description = "The OS type of the container group"
  value       = azurerm_container_group.aci.os_type
}

output "restart_policy" {
  description = "The restart policy of the container group"
  value       = azurerm_container_group.aci.restart_policy
}

output "tags" {
  description = "The tags assigned to the container group"
  value       = azurerm_container_group.aci.tags
}