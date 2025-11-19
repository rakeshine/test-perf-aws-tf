variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "vnet-jmeter"
}

variable "vnet_address_space" {
  description = "The address space that is used by the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "A map of subnets to create"
  type = map(object({
    name                                    = string
    address_prefixes                        = list(string)
    service_endpoints                       = optional(list(string), [])
    delegations                             = optional(list(string), [])
    private_endpoint_network_policies       = optional(string, "Disabled")
    private_link_service_network_policies   = optional(string, "Enabled")
    nsg_rules = optional(list(object({
      name                         = string
      priority                     = number
      direction                    = string
      access                       = string
      protocol                     = string
      source_port_range            = optional(string)
      source_port_ranges           = optional(list(string))
      destination_port_range       = optional(string)
      destination_port_ranges      = optional(list(string))
      source_address_prefix        = optional(string)
      source_address_prefixes      = optional(list(string))
      destination_address_prefix   = optional(string)
      destination_address_prefixes = optional(list(string))
      description                  = optional(string)
    })), [])
  }))
  default = {
    aci = {
      name             = "aci"
      address_prefixes = ["10.0.1.0/24"]
      delegations      = ["Microsoft.ContainerInstance/containerGroups"]
      nsg_rules = [
        {
          name                       = "AllowJMeterMaster"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = [1099, 60000]
          source_address_prefix       = "VirtualNetwork"
          destination_address_prefix  = "VirtualNetwork"
          description               = "Allow JMeter master to communicate with slaves"
        },
        {
          name                       = "AllowSSH"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "22"
          source_address_prefix       = "*"
          destination_address_prefix  = "*"
          description               = "Allow SSH access for debugging"
        }
      ]
    }
  }
}

variable "private_dns_zones" {
  description = "List of private DNS zones to create"
  type        = list(string)
  default = [
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.azurecr.io"
  ]
}

variable "dns_servers" {
  description = "List of DNS servers to use for the VNet"
  type        = list(string)
  default     = []
}

variable "location" {
  description = "The location/region where the virtual network is created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the virtual network"
  type        = string
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}