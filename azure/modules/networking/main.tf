locals {
  name_prefix = var.name
}

# -----------------------------------------
# Resource Group
# -----------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = var.tags
}

# -----------------------------------------
# Virtual Network (VPC Equivalent)
# -----------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = "${local.name_prefix}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags
}

# -----------------------------------------
# Public Subnets
# -----------------------------------------
resource "azurerm_subnet" "public" {
  for_each             = { for idx, cidr in var.public_subnets : idx => cidr }
  name                 = "${local.name_prefix}-public-${each.key}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value]
}

# -----------------------------------------
# Public Route Table
# -----------------------------------------
resource "azurerm_route_table" "public" {
  name                = "${local.name_prefix}-public-rt"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  tags = var.tags
}

resource "azurerm_route" "public_internet" {
  name                   = "internet-route"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.public.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "Internet"
}

resource "azurerm_subnet_route_table_association" "public" {
  for_each       = azurerm_subnet.public
  route_table_id = azurerm_route_table.public.id
  subnet_id      = each.value.id
}

# -----------------------------------------
# Storage Account (S3 Equivalent)
# -----------------------------------------
/*
resource "azurerm_storage_account" "sa" {
  name                     = replace("${local.name_prefix}sa", "-", "")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
} */


# -----------------------------------------
# Network Security Group (SG Equivalent)
# -----------------------------------------
resource "azurerm_network_security_group" "ecs_tasks" {
  name                = "${local.name_prefix}-ecs-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # JMeter RMI
  security_rule {
    name                       = "jmeter-rmi"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1099"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # JMeter GUI
  security_rule {
    name                       = "jmeter-gui"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "50000"
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "*"
  }

  # Allow all outbound
  security_rule {
    name                       = "allow-outbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Attach NSG to each public subnet
resource "azurerm_subnet_network_security_group_association" "public" {
  for_each                  = azurerm_subnet.public
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.ecs_tasks.id
}
