output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "container_registry_login_server" {
  description = "The login server URL of the container registry"
  value       = module.container_registry.login_server
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = module.storage.name
}

output "jmeter_master_fqdn" {
  description = "The FQDN of the JMeter master container instance"
  value       = module.jmeter_master.fqdn
}

output "jmeter_master_ip_address" {
  description = "The IP address of the JMeter master container instance"
  value       = module.jmeter_master.ip_address
}

output "jmeter_slaves_fqdns" {
  description = "The FQDNs of the JMeter slave container instances"
  value       = [for slave in module.jmeter_slaves : slave.fqdn]
}

output "function_app_name" {
  description = "The name of the Azure Function App"
  value       = module.function_app.name
}

output "function_app_default_hostname" {
  description = "The default hostname of the Azure Function App"
  value       = module.function_app.default_hostname
}

output "container_instances" {
  description = "Details of all container instances"
  value = concat(
    [{
      name       = module.jmeter_master.name
      fqdn       = module.jmeter_master.fqdn
      ip_address = module.jmeter_master.ip_address
      role       = "master"
    }],
    [for i, slave in module.jmeter_slaves : {
      name       = slave.name
      fqdn       = slave.fqdn
      ip_address = slave.ip_address
      role       = "slave-${i}"
    }]
  )
}