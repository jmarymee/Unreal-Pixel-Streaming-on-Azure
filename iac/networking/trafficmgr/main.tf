// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

## variables
variable "base_name" {
  description = "Base name to use for the resources"
  type        = string
}

variable "resource_group_name" {
    type = string
}

variable "traffic_routing_method" {
    type = string
    default = "Performance"
}

variable "service_name" {
    type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

output "traffic_manager_profile_name" {
    value = azurerm_traffic_manager_profile.traffic_manager_profile.name
}

resource "azurerm_traffic_manager_profile" "traffic_manager_profile" {
  name                   = format("%s-trafficmgr-%s", var.base_name, var.service_name)
  resource_group_name    = var.resource_group_name
  traffic_routing_method = var.traffic_routing_method

  dns_config {
    relative_name = format("%s-trafficmgr-%s", var.base_name, var.service_name)
    ttl           = 100
  }

  monitor_config {
    protocol = "http"
    port     = 80
    path     = "/"
  }
}

/*
resource "azurerm_monitor_diagnostic_setting" "tm-diag" {
  name               = format("%s-tm-diag-%s", var.base_name, var.service_name)
  target_resource_id = azurerm_traffic_manager_profile.traffic_manager_profile.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "ProbeHealthStatusEvents"
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
*/