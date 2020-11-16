// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

variable "base_name" {
  type = string
}

variable "resource_group" {
  description = "The RG VMs"
  type = object({
    id       = string
    location = string
    name     = string
  })
}

variable "vmss_id" {
  type = string
}

variable "capacity_default" {
  type = string
}

variable "capacity_minimum" {
  type = string
}

variable "capacity_maximum" {
  type = string
}

resource "azurerm_monitor_autoscale_setting" "vmss_autoscale_settings" {
  name                = format("%s-autoscale-config", var.base_name)
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  target_resource_id  = var.vmss_id

  profile {
    name = "AutoScale"

    capacity {
      default = var.capacity_default
      minimum = var.capacity_minimum
      maximum = var.capacity_maximum
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = var.vmss_id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = var.vmss_id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}
