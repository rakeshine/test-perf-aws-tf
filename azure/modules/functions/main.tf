# Create App Service Plan
resource "azurerm_service_plan" "asp" {
  name                = "asp-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

# Create Storage Account for Function App
resource "azurerm_storage_account" "func" {
  name                     = replace("sa${var.name}${random_id.storage.hex}", "-", "")
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

# Create Application Insights
resource "azurerm_application_insights" "appinsights" {
  name                = "appi-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = var.log_analytics_workspace_id
  tags                = var.tags
}

# Create Function App
resource "azurerm_linux_function_app" "func" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = azurerm_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.func.name
  storage_account_access_key = var.storage_account_access_key
  https_only                 = true
  tags                       = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                              = true
    ftps_state                            = "Disabled"
    http2_enabled                         = true
    vnet_route_all_enabled                = true
    application_insights_connection_string = azurerm_application_insights.appinsights.connection_string
    application_insights_key              = azurerm_application_insights.appinsights.instrumentation_key

    application_stack {
      python_version = "3.9"
    }

    # IP restrictions
    dynamic "ip_restriction" {
      for_each = var.allowed_ips
      content {
        ip_address = ip_restriction.value
        name       = "Allow_${replace(ip_restriction.value, "/", "_")}"
        priority   = 100 + index(var.allowed_ips, ip_restriction.value)
        action     = "Allow"
      }
    }

    # VNet integration
    dynamic "vnet_route_all_enabled" {
      for_each = var.integrate_with_vnet ? [1] : []
      content {
        vnet_route_all_enabled = true
      }
    }
  }

  app_settings = merge(
    {
      "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.appinsights.instrumentation_key
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.appinsights.connection_string
      "FUNCTIONS_WORKER_RUNTIME" = "python"
      "WEBSITE_RUN_FROM_PACKAGE" = "1"
      "WEBSITE_VNET_ROUTE_ALL" = "1"
      "DOCKER_ENABLE_CI" = "true"
    },
    var.app_settings
  )

  # VNet integration
  dynamic "virtual_network_subnet_id" {
    for_each = var.integrate_with_vnet ? [1] : []
    content {
      subnet_id = var.vnet_subnet_id
    }
  }
}

# Role assignment for Storage Account
resource "azurerm_role_assignment" "storage" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_function_app.func.identity[0].principal_id
}

# Role assignment for Key Vault (if used)
resource "azurerm_role_assignment" "keyvault" {
  count                = var.key_vault_id != "" ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_function_app.func.identity[0].principal_id
}

# Random ID for storage account name
resource "random_id" "storage" {
  keepers = {
    resource_group = var.resource_group_name
  }
  byte_length = 8
}