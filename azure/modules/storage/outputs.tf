output "id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.sa.id
}

output "name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.sa.name
}

output "primary_access_key" {
  description = "The primary access key for the storage account"
  value       = azurerm_storage_account.sa.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "The secondary access key for the storage account"
  value       = azurerm_storage_account.sa.secondary_access_key
  sensitive   = true
}

output "connection_string" {
  description = "The connection string for the storage account"
  value       = azurerm_storage_account.sa.primary_connection_string
  sensitive   = true
}

output "file_share_name" {
  description = "The name of the file share"
  value       = azurerm_storage_share.jmeter.name
}

output "file_share_url" {
  description = "The URL of the file share"
  value       = "${azurerm_storage_account.sa.primary_file_endpoint}${azurerm_storage_share.jmeter.name}"
}

output "container_name" {
  description = "The name of the blob container"
  value       = azurerm_storage_container.test_data.name
}

output "private_endpoint_id" {
  description = "The ID of the private endpoint"
  value       = try(azurerm_private_endpoint.storage[0].id, null)
}