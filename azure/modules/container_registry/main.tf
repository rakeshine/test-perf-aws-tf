resource "azurerm_container_registry" "acr" {
  name                = replace(var.name, "/[^a-zA-Z0-9]+/", "")
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled
  tags                = var.tags

  # Enable admin account for ACR
  # Note: In production, consider using managed identity instead
  admin_enabled = true

  # Enable anonymous pull access
  # anonymous_pull_enabled = false

  # Enable data endpoint for private link scenarios
  # data_endpoint_enabled = false

  # Enable encryption
  encryption {
    enabled = true
  }

  # Enable network rule set
  network_rule_set {
    default_action = "Deny"
    
    # Example IP rule (update with your IP)
    ip_rule {
      action   = "Allow"
      ip_range = "0.0.0.0/0" # WARNING: This allows access from any IP. Restrict this in production.
    }
  }

  # Enable retention policy
  retention_policy {
    days    = 7
    enabled = true
  }

  # Enable trust policy
  trust_policy {
    enabled = true
  }
}

# Create a private DNS zone for ACR
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link the private DNS zone to the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "${var.name}-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.tags
}

# Private Endpoint for ACR
resource "azurerm_private_endpoint" "acr" {
  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }
}