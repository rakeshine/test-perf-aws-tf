# Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Enable DNS servers if provided
  dynamic "dns_servers" {
    for_each = var.dns_servers != [] ? [1] : []
    content {
      dns_servers = var.dns_servers
    }
  }
}

# Create Subnets
resource "azurerm_subnet" "subnets" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.address_prefixes

  # Service endpoints
  service_endpoints = lookup(each.value, "service_endpoints", [])

  # Delegation for ACI if this is the ACI subnet
  dynamic "delegation" {
    for_each = contains(lookup(each.value, "delegations", []), "Microsoft.ContainerInstance/containerGroups") ? [1] : []
    content {
      name = "delegation"

      service_delegation {
        name    = "Microsoft.ContainerInstance/containerGroups"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }

  # Private endpoint network policies
  private_endpoint_network_policies_enabled = lookup(each.value, "private_endpoint_network_policies_enabled", false)

  # Service endpoint policies
  dynamic "service_endpoint_policy" {
    for_each = lookup(each.value, "service_endpoint_policy_ids", [])
    content {
      id = service_endpoint_policy.value
    }
  }
}

# Network Security Group for Subnets
resource "azurerm_network_security_group" "nsg" {
  for_each = { for subnet in var.subnets : subnet.name => subnet if lookup(subnet, "nsg_rules", null) != null }

  name                = "nsg-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  dynamic "security_rule" {
    for_each = each.value.nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = lookup(security_rule.value, "source_port_range", null)
      source_port_ranges         = lookup(security_rule.value, "source_port_ranges", null)
      destination_port_range     = lookup(security_rule.value, "destination_port_range", null)
      destination_port_ranges    = lookup(security_rule.value, "destination_port_ranges", null)
      source_address_prefix      = lookup(security_rule.value, "source_address_prefix", null)
      source_address_prefixes    = lookup(security_rule.value, "source_address_prefixes", null)
      destination_address_prefix = lookup(security_rule.value, "destination_address_prefix", null)
      description               = lookup(security_rule.value, "description", null)
    }
  }
}

# Associate NSG with Subnets
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each = { for k, v in azurerm_network_security_group.nsg : k => v }

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = each.value.id
}

# Private DNS Zones
resource "azurerm_private_dns_zone" "dns_zones" {
  for_each = toset(var.private_dns_zones)

  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link Private DNS Zones to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "dns_links" {
  for_each = { for zone in var.private_dns_zones : zone => zone }

  name                  = "vnet-link-${replace(each.value, ".", "-")}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zones[each.value].name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = var.tags
}

# Network Profile for ACI
resource "azurerm_network_profile" "aci" {
  name                = "aci-network-profile"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  container_network_interface {
    name = "acinic"

    ip_configuration {
      name      = "ipconfig"
      subnet_id = azurerm_subnet.subnets["aci"].id
    }
  }
}