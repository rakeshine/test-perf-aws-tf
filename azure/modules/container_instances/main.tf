locals {
  prefix = var.name
}

# Build optional registry credentials block if provided
locals {
  use_registry = var.registry_server != "" && var.registry_username != "" && var.registry_password != ""
}

# ----------------------------
# Master: single Container Group
# ----------------------------
resource "azurerm_container_group" "master" {
  name                = "${local.prefix}-master"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"

  tags = var.tags

  dynamic "container" {
    for_each = [1]
    content {
      name   = "${local.prefix}-jmeter-master"
      image  = var.master_image
      cpu    = var.master_cpu
      memory = var.master_memory

      # expose ports
      dynamic "ports" {
        for_each = var.master_ports
        content {
          port = ports.value
        }
      }

      environment_variables = merge(
        var.master_env,
        {
          JMETER_ROLE = "master"
        }
      )

      # optional command/entrypoint can be set by users through env or baked image
      # command = []
    }
  }

  # If you want the ACI to be in a VNet (private IP), provide subnet_id
  # For private, ACI will not have a public FQDN unless explicitly configured with public IP (not recommended for master/slave)
  subnet_ids = var.subnet_id != "" ? [var.subnet_id] : []

  # If no subnet_id and you want public access you can optionally use ip_address_type = "Public"
  ip_address_type = var.subnet_id == "" ? "Public" : "Private"

  # If using public IP and want DNS name label you can add `dns_name_label = "${local.prefix}-master-${random_id.master_hex.hex}"` (not created here)

  restart_policy = "OnFailure"

  # Optional registry credentials
  dynamic "image_registry_credentials" {
    for_each = local.use_registry ? [1] : []
    content {
      server   = var.registry_server
      username = var.registry_username
      password = var.registry_password
    }
  }
}

# ----------------------------
# Slaves: N Container Groups
# ----------------------------
resource "azurerm_container_group" "slave" {
  for_each = { for i in range(var.slave_count) : i => i }

  name                = "${local.prefix}-slave-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"

  tags = var.tags

  container {
    name   = "${local.prefix}-jmeter-slave-${each.key}"
    image  = var.slave_image
    cpu    = var.slave_cpu
    memory = var.slave_memory

    dynamic "ports" {
      for_each = var.slave_ports
      content {
        port = ports.value
      }
    }

    environment_variables = merge(
      var.slave_env,
      # If user supplied master_host, inject it to the slaves so they can connect to the master immediately.
      (var.master_host != "" ? { JMETER_MASTER_HOST = var.master_host } : {})
    )
  }

  subnet_ids      = var.subnet_id != "" ? [var.subnet_id] : []
  ip_address_type = var.subnet_id == "" ? "Public" : "Private"
  restart_policy  = "OnFailure"

  dynamic "image_registry_credentials" {
    for_each = local.use_registry ? [1] : []
    content {
      server   = var.registry_server
      username = var.registry_username
      password = var.registry_password
    }
  }
}
