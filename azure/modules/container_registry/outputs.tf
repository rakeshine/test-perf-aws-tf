output "id" {
  description = "The ID of the Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "login_server" {
  description = "The URL that can be used to log into the container registry"
  value       = azurerm_container_registry.acr.login_server
}

output "admin_username" {
  description = "The Username associated with the Container Registry Admin account"
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "admin_password" {
  description = "The Password associated with the Container Registry Admin account"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

output "private_endpoint_connection" {
  description = "The private endpoint connection for the container registry"
  value       = azurerm_private_endpoint.acr.private_service_connection
}

output "private_dns_zone_id" {
  description = "The ID of the private DNS zone"
  value       = azurerm_private_dns_zone.acr.id
}