terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateprodjmeterinfra"
    container_name       = "tfstate"
    key                  = "jmeter-infra.prod.tfstate"
  }
}

provider "azurerm" {
  features {}
}

locals {
  name_prefix = "jmeter-${var.environment}"
}

# ----------------------
# Networking
# ----------------------
module "networking" {
  source = "../../modules/networking"

  name           = local.name_prefix
  location       = var.location
  vnet_cidr      = var.vnet_cidr
  public_subnets = var.public_subnets
  tags           = var.tags
}

# ----------------------
# Storage for test plans and results
# ----------------------
resource "random_string" "sa" {
  length  = 8
  upper   = false
  special = false
}

module "storage" {
  source = "../../modules/storage"

  name                = lower(replace("st${local.name_prefix}${random_string.sa.result}", "-", ""))
  resource_group_name = module.networking.resource_group_name
  location            = var.location
  environment         = var.environment
  tags                = var.tags
}

# ----------------------
# Container Instances: JMeter
# ----------------------
module "aci_jmeter" {
  source = "../../modules/container_instances"

  name                = local.name_prefix
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  subnet_id           = values(module.networking.public_subnet_ids)[0]

  master_image  = var.master_image
  master_cpu    = var.master_cpu
  master_memory = var.master_memory
  master_ports  = var.master_ports
  master_env    = var.master_env

  slave_image  = var.slave_image
  slave_cpu    = var.slave_cpu
  slave_memory = var.slave_memory
  slave_ports  = var.slave_ports
  slave_count  = var.slave_count
  slave_env    = var.slave_env

  # Optionally set master_host after first apply if needed
  master_host = var.master_host

  tags = var.tags
}

