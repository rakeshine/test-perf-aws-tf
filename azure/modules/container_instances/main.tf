# Create Container Group
resource "azurerm_container_group" "aci" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = var.enable_public_ip ? "Public" : "Private"
  os_type             = "Linux"
  restart_policy      = var.restart_policy
  network_profile_id  = var.network_profile_id
  dns_name_label      = var.dns_name_label
  tags                = var.tags

  # Container definition
  container {
    name   = var.name
    image  = var.container_image
    cpu    = var.cpu
    memory = var.memory

    # Ports to expose
    dynamic "ports" {
      for_each = var.ports
      content {
        port     = ports.value.port
        protocol = lookup(ports.value, "protocol", "TCP")
      }
    }

    # Environment variables
    dynamic "environment_variables" {
      for_each = var.environment_variables
      content {
        name  = environment_variables.key
        value = environment_variables.value
      }
    }

    # Secure environment variables
    dynamic "secure_environment_variables" {
      for_each = var.secure_environment_variables
      content {
        name  = secure_environment_variables.key
        value = secure_environment_variables.value
      }
    }

    # Volume mounts
    dynamic "volume" {
      for_each = var.volumes
      content {
        name       = volume.value.name
        mount_path = volume.value.mount_path
        read_only  = lookup(volume.value, "read_only", false)

        dynamic "git_repo" {
          for_each = lookup(volume.value, "git_repo", [])
          content {
            url       = git_repo.value.url
            directory = lookup(git_repo.value, "directory", null)
            revision  = lookup(git_repo.value, "revision", null)
          }
        }

        dynamic "empty_dir" {
          for_each = lookup(volume.value, "empty_dir", [])
          content {
            medium     = lookup(empty_dir.value, "medium", "Memory")
            size_limit = lookup(empty_dir.value, "size_limit", null)
          }
        }

        dynamic "secret" {
          for_each = lookup(volume.value, "secrets", {})
          content {
            name  = secret.key
            value = secret.value
          }
        }
      }
    }

    # Command to run
    command = var.command

    # Liveness and readiness probes
    dynamic "liveness_probe" {
      for_each = var.liveness_probe != null ? [var.liveness_probe] : []
      content {
        exec                  = lookup(liveness_probe.value, "exec", null)
        http_get              = lookup(liveness_probe.value, "http_get", null)
        initial_delay_seconds = lookup(liveness_probe.value, "initial_delay_seconds", 10)
        period_seconds        = lookup(liveness_probe.value, "period_seconds", 30)
        failure_threshold     = lookup(liveness_probe.value, "failure_threshold", 3)
        success_threshold     = lookup(liveness_probe.value, "success_threshold", 1)
        timeout_seconds       = lookup(liveness_probe.value, "timeout_seconds", 5)
      }
    }

    dynamic "readiness_probe" {
      for_each = var.readiness_probe != null ? [var.readiness_probe] : []
      content {
        exec                  = lookup(readiness_probe.value, "exec", null)
        http_get              = lookup(readiness_probe.value, "http_get", null)
        initial_delay_seconds = lookup(readiness_probe.value, "initial_delay_seconds", 10)
        period_seconds        = lookup(readiness_probe.value, "period_seconds", 30)
        failure_threshold     = lookup(readiness_probe.value, "failure_threshold", 3)
        success_threshold     = lookup(readiness_probe.value, "success_threshold", 1)
        timeout_seconds       = lookup(readiness_probe.value, "timeout_seconds", 5)
      }
    }
  }

  # Identity configuration
  identity {
    type = "SystemAssigned"
  }

  # Diagnostics
  diagnostics {
    log_analytics {
      workspace_id  = var.log_analytics_workspace_id
      workspace_key = var.log_analytics_workspace_key
      log_type     = "ContainerInsights"
      metadata     = var.log_analytics_metadata
    }
  }

  # Tags
  tags = merge(
    var.tags,
    {
      "container-type" = var.container_type
    }
  )
}

# Role assignment for managed identity
resource "azurerm_role_assignment" "acr_pull" {
  count                = var.acr_id != "" ? 1 : 0
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_group.aci.identity[0].principal_id
}