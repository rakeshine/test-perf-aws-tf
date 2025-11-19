# storage.tf
resource "azurerm_storage_account" "jmeter" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  tags = merge(var.tags, ({
    environment = var.environment
  }))
}

resource "azurerm_storage_container" "test_plans" {
  name                  = "test-plans"
  storage_account_name  = azurerm_storage_account.jmeter.name
  container_access_type = "private"
}

resource "azurerm_storage_share" "jmeter_results" {
  name                 = "jmeter-results"
  storage_account_name = azurerm_storage_account.jmeter.name
  quota                = 50 # GB
}