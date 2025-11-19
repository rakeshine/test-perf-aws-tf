output "id" {
  description = "The ID of the Function App"
  value       = azurerm_linux_function_app.func.id
}

output "name" {
  description = "The name of the Function App"
  value       = azurerm_linux_function_app.func.name
}

output "default_hostname" {
  description = "The default hostname of the Function App"
  value       = azurerm_linux_function_app.func.default_hostname
}

output "identity" {
  description = "The identity block of the Function App"
  value       = azurerm_linux_function_app.func.identity
}

output "outbound_ip_addresses" {
  description = "A comma separated list of outbound IP addresses"
  value       = azurerm_linux_function_app.func.outbound_ip_addresses
}

output "possible_outbound_ip_addresses" {
  description = "A comma separated list of all possible outbound IP addresses"
  value       = azurerm_linux_function_app.func.possible_outbound_ip_addresses
}

output "connection_string" {
  description = "The connection string for the Function App"
  value       = azurerm_linux_function_app.func.connection_string
  sensitive   = true
}

output "custom_domain_verification_id" {
  description = "The identifier used by App Service to perform domain ownership verification via DNS TXT record"
  value       = azurerm_linux_function_app.func.custom_domain_verification_id
}

output "storage_account_name" {
  description = "The name of the storage account used by the Function App"
  value       = azurerm_storage_account.func.name
}

output "storage_account_primary_access_key" {
  description = "The primary access key for the storage account"
  value       = azurerm_storage_account.func.primary_access_key
  sensitive   = true
}

output "app_insights_instrumentation_key" {
  description = "The Instrumentation Key for the Application Insights"
  value       = azurerm_application_insights.appinsights.instrumentation_key
  sensitive   = true
}

output "app_insights_connection_string" {
  description = "The Connection String for the Application Insights"
  value       = azurerm_application_insights.appinsights.connection_string
  sensitive   = true
}