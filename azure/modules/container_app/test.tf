# Terraform module: Container Apps Jobs (VNET-injected) for JMeter master + slaves
# Files included: main.tf, variables.tf, outputs.tf, README.md
# Note: You previously uploaded files to /mnt/data/main.tf — reference path: /mnt/data/main.tf

############################################################
# main.tf
############################################################
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group (use existing if provided)
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

# Log Analytics workspace (required for Container Apps Environment)
resource "azurerm_log_analytics_workspace" "la" {
  name                = "${var.name_prefix}-law"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Container Apps Environment (VNET-injected)
# NOTE: some provider versions use `vnet_configuration` block, others use `vnet`/`subnet`. If you hit schema issues,
# upgrade azurerm provider to latest stable and consult provider docs. The intent here is to attach the environment to a subnet.
resource "azurerm_container_app_environment" "env" {
  name                = "${var.name_prefix}-env"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  dapr_integration = false

  log_analytics {
    customer_id = azurerm_log_analytics_workspace.la.customer_id
    shared_key  = azurerm_log_analytics_workspace.la.primary_shared_key
  }

  dynamic "vnet_configuration" {
    for_each = var.subnet_id != "" ? [1] : []
    content {
      # The exact attribute name in provider can be `subnet_id` or nested fields — if provider errors, replace accordingly.
      subnet_id = var.subnet_id
    }
  }
}

# Data: ACR login server and credentials
data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.acr_resource_group
}

# Optional: Get ACR admin credentials (admin must be enabled on ACR)
data "azurerm_container_registry_admin_credentials" "acr_admin" {
  name                = data.azurerm_container_registry.acr.name
  resource_group_name = var.acr_resource_group
}

# --------------------------------------------------------------------------------
# JMeter Slave: Container Apps Job definition (Manual trigger, parallel runs supported)
# --------------------------------------------------------------------------------
resource "azurerm_container_app_job" "slave_job" {
  name                         = "${var.name_prefix}-jmeter-slave-job"
  location                     = azurerm_resource_group.this.location
  resource_group_name          = azurerm_resource_group.this.name
  container_app_environment_id = azurerm_container_app_environment.env.id

  identity {
    type = "SystemAssigned"
  }

  template {
    containers {
      name   = "jmeter-slave"
      image  = "${data.azurerm_container_registry.acr.login_server}/${var.slave_image}"
      cpu    = var.slave_cpu
      memory = var.slave_memory

      env {
        name  = "JMETER_MODE"
        value = "slave"
      }

      # command & args may be overridden by image or triggers
    }

    # retry and completion policy
    replica_retry_limit = var.replica_retry_limit
    replica_completion_count = 0
  }

  # Manual trigger (jobs will run only when you call `az containerapp job start`)
  schedule {
    trigger_type = "Manual"
  }

  registry {
    server   = data.azurerm_container_registry.acr.login_server
    username = lookup(data.azurerm_container_registry_admin_credentials.acr_admin, "username", "")
    password = lookup(data.azurerm_container_registry_admin_credentials.acr_admin, "passwords", "")[0]
  }

  tags = var.tags
}

# --------------------------------------------------------------------------------
# JMeter Master: Container Apps Job definition
# --------------------------------------------------------------------------------
resource "azurerm_container_app_job" "master_job" {
  name                         = "${var.name_prefix}-jmeter-master-job"
  location                     = azurerm_resource_group.this.location
  resource_group_name          = azurerm_resource_group.this.name
  container_app_environment_id = azurerm_container_app_environment.env.id

  identity { type = "SystemAssigned" }

  template {
    containers {
      name   = "jmeter-master"
      image  = "${data.azurerm_container_registry.acr.login_server}/${var.master_image}"
      cpu    = var.master_cpu
      memory = var.master_memory

      env {
        name  = "JMETER_MODE"
        value = "master"
      }

      env {
        name  = "SLAVE_COUNT"
        value = tostring(var.slave_default_count)
      }

      # if you prefer to pass extra environment vars, use `master_env` variable
    }

    replica_retry_limit = var.replica_retry_limit
    replica_completion_count = 1
  }

  schedule { trigger_type = "Manual" }

  registry {
    server   = data.azurerm_container_registry.acr.login_server
    username = lookup(data.azurerm_container_registry_admin_credentials.acr_admin, "username", "")
    password = lookup(data.azurerm_container_registry_admin_credentials.acr_admin, "passwords", "")[0]
  }

  tags = var.tags
}

# Optional: Role assignment so container apps can pull from ACR using managed identity (alternative to admin creds)
resource "azurerm_role_assignment" "acr_pull" {
  for_each = var.use_managed_identity ? {
    master = azurerm_container_app_job.master_job.identity[0].principal_id
    slave  = azurerm_container_app_job.slave_job.identity[0].principal_id
  } : {}

  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = each.value
}

############################################################
# outputs.tf
############################################################
output "container_app_environment_id" {
  value = azurerm_container_app_environment.env.id
}

output "master_job_name" {
  value = azurerm_container_app_job.master_job.name
}

output "slave_job_name" {
  value = azurerm_container_app_job.slave_job.name
}

############################################################
# variables.tf
############################################################
variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name to create resources in"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
  default     = "eastus"
}

variable "acr_name" {
  description = "ACR name to pull images from"
  type        = string
}

variable "acr_resource_group" {
  description = "Resource group where ACR exists"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for VNET integration (required for VNET-injected environment). Provide full resource ID."
  type        = string
  default     = ""
}

variable "master_image" {
  description = "ACR image path for jmeter master (repository:tag)"
  type        = string
}

variable "slave_image" {
  description = "ACR image path for jmeter slave (repository:tag)"
  type        = string
}

variable "master_cpu" {
  type    = number
  default = 1
}

variable "master_memory" {
  type    = string
  default = "2Gi"
}

variable "slave_cpu" {
  type    = number
  default = 0.5
}

variable "slave_memory" {
  type    = string
  default = "1Gi"
}

variable "slave_default_count" {
  type    = number
  default = 3
}

variable "replica_retry_limit" {
  description = "Number of retries for job replica failures"
  type        = number
  default     = 0
}

variable "use_managed_identity" {
  description = "If true, grant the Container Apps managed identities AcrPull role on ACR"
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

############################################################
# README.md
############################################################
# Container Apps Jobs module (VNET-injected)

This module creates a Container Apps Environment injected into a VNET-subnet (if `subnet_id` provided), and two Container Apps Jobs:

- jmeter-master-job (manual trigger)
- jmeter-slave-job (manual trigger; run multiple replicas via CLI)

**Note:** Container Apps Jobs are billed only while running. After completion, compute is deallocated.

## Usage example

```hcl
module "jmeter_jobs" {
  source = "./modules/containerapps-jmeter-vnet-module"

  name_prefix         = "jmeter"
  resource_group_name = "rg-jmeter"
  location            = "eastus"
  subnet_id           = "/subscriptions/<sub>/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet1/subnets/aca-subnet"

  acr_name            = "myacr"
  acr_resource_group  = "rg-acr"

  master_image        = "jmeter/master:latest"
  slave_image         = "jmeter/slave:latest"

  slave_default_count = 5

  tags = {
    project = "loadtest"
  }
}
```

## Triggering jobs

Start 5 slave replicas:

```bash
az containerapp job start --resource-group rg-jmeter --name jmeter-slave-job --count 5
```

Start master job:

```bash
az containerapp job start --resource-group rg-jmeter --name jmeter-master-job
```

## Notes & provider compatibility

- The azurerm provider evolves — if you get schema errors for `vnet_configuration` inside `azurerm_container_app_environment`, upgrade the provider and consult the provider docs. The intent is to pass `subnet_id` so the environment is VNET-bound.
- You uploaded a file earlier at `/mnt/data/main.tf`. If you want me to adapt or merge that file into this module, I can do so using that path.
