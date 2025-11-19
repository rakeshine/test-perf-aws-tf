resource "azurerm_storage_account" "sa" {
  name                     = replace(lower(var.name), "/[^a-z0-9]/", "")
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  min_tls_version          = "TLS1_2"
  tags                     = var.tags

  # Enable blob soft delete
  blob_properties {
    delete_retention_policy {
      days = var.blob_retention_days
    }
    versioning_enabled = true
  }

  # Enable file share soft delete
  share_properties {
    retention_policy {
      days = var.file_share_retention_days
    }
  }

  # Enable network rules
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = var.allowed_ips
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  identity {
    type = "SystemAssigned"
  }
}

# Create a file share for JMeter test plans and results
resource "azurerm_storage_share" "jmeter" {
  name                 = "jmeter"
  storage_account_name = azurerm_storage_account.sa.name
  quota               = var.file_share_quota_gb
}

# Create a container for JMeter test data
resource "azurerm_storage_container" "test_data" {
  name                  = "test-data"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

# Role assignment for the storage account
resource "azurerm_role_assignment" "storage_contributor" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.managed_identity_principal_id
}

# Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage" {
  name                = "${azurerm_storage_account.sa.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${azurerm_storage_account.sa.name}-psc"
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.0.id]
  }
}

# Private DNS Zone for Storage Account
resource "azurerm_private_dns_zone" "storage" {
  count               = var.create_private_endpoint ? 1 : 0
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Private DNS Zone Virtual Network Link
resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  count                 = var.create_private_endpoint ? 1 : 0
  name                  = "${azurerm_storage_account.sa.name}-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.tags
}