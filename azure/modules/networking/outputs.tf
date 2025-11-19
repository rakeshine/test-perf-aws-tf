output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_address_space" {
  description = "The address space of the virtual network"
  value       = azurerm_virtual_network.vnet.address_space
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value = {
    for k, v in azurerm_subnet.subnets : k => v.id
  }
}

output "network_security_group_ids" {
  description = "Map of subnet names to network security group IDs"
  value = {
    for k, v in azurerm_network_security_group.nsg : k => v.id
  }
}

output "private_dns_zone_ids" {
  description = "Map of private DNS zone names to their IDs"
  value = {
    for k, v in azurerm_private_dns_zone.dns_zones : k => v.id
  }
}

output "network_profile_id" {
  description = "The ID of the network profile for ACI"
  value       = azurerm_network_profile.aci.id
}

output "network_profile_name" {
  description = "The name of the network profile for ACI"
  value       = azurerm_network_profile.aci.name
}