output "id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.jmeter.id
}

output "name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.jmeter.name
}

output "primary_access_key" {
  description = "The primary access key for the storage account"
  value       = azurerm_storage_account.jmeter.primary_access_key
  sensitive   = true
}

output "connection_string" {
  description = "The connection string for the storage account"
  value       = azurerm_storage_account.jmeter.primary_connection_string
  sensitive   = true
}

output "file_share_name" {
  description = "The name of the file share for JMeter results"
  value       = azurerm_storage_share.jmeter_results.name
}

output "file_share_url" {
  description = "The URL of the JMeter results file share"
  value       = "${azurerm_storage_account.jmeter.primary_file_endpoint}${azurerm_storage_share.jmeter_results.name}"
}

output "test_plans_container_name" {
  description = "The name of the blob container for test plans"
  value       = azurerm_storage_container.test_plans.name
}