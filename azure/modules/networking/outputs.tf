output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "public_subnet_ids" {
  value = { for k, v in azurerm_subnet.public : k => v.id }
}

output "route_table_id" {
  value = azurerm_route_table.public.id
}

output "nsg_id" {
  value = azurerm_network_security_group.ecs_tasks.id
}
