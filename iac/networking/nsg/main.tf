// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

## variables
variable "base_name" {
  description = "the base name for the resources"
  type        = string
}

variable "resource_group" {
  description = "The RG for the NSG"
  type = object({
    id       = string
    location = string
    name     = string
  })
}

variable "nsg_name" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

output "network_security_group_id" {
  value = azurerm_network_security_group.nsg.id
}

output "network_security_group_name" {
  value = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_group" "nsg" {
  name                = format("%s-%s", var.base_name, var.nsg_name)
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
}

resource "azurerm_monitor_diagnostic_setting" "nsg-diag" {
  name                       = "vm-diag"
  target_resource_id         = azurerm_network_security_group.nsg.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "NetworkSecurityGroupEvent"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "NetworkSecurityGroupRuleCounter"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
}
