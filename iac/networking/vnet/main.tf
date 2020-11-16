// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

## variables
variable "base_name" {
  description = "Base name to use for the resources"
  type        = string
}

variable "resource_group" {
  description = "The RG for the network"
  type = object({
    id     = string
    location = string
    name   = string
  })
}

 variable "vnet_address_space" {
  type        = string
}

 variable "subnet_address_prefixes" {
  type        = string
}

variable "log_analytics_workspace_id" {
  type = string
}

## Outputs
output "unreal_vnet" {
  value = ({
    id     = azurerm_virtual_network.vnet.id
    name   = azurerm_virtual_network.vnet.name
    location = azurerm_virtual_network.vnet.location
  })
}

output "subnet_id" {
  value = azurerm_subnet.subnet.id
}

#resources

#commented the following from a cost perspective. 
#resource "azurerm_network_ddos_protection_plan" "ddos" {
#  name                = format("%s-ddosplan", var.base_name)
#  location            = var.resource_group.location
#  resource_group_name = var.resource_group.name
#}

resource "azurerm_virtual_network" "vnet" {
  name                = format("%s-vnet-%s", var.base_name, lower(var.resource_group.location))
  address_space       = [var.vnet_address_space]
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name

#  ddos_protection_plan {
#    id     = azurerm_network_ddos_protection_plan.ddos.id
#    enable = true
#  }

}

resource "azurerm_subnet" "subnet" {
  name                 = format("%s-subnet-%s", var.base_name, lower(var.resource_group.location))
  resource_group_name  = var.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [var.subnet_address_prefixes]
}

resource "azurerm_monitor_diagnostic_setting" "vm-diag" {
  name               = format("%s-vm-diag-%s", var.base_name, lower(var.resource_group.location))
  target_resource_id = azurerm_virtual_network.vnet.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "VMProtectionAlerts"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"
    enabled = true

    retention_policy {
      enabled = false
    }
  }
}