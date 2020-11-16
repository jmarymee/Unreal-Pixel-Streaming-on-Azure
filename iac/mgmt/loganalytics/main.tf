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

variable "location" {
  type = string
}

variable "logA_Name" {
  type = string
}

output "workspace_id" {
  value = azurerm_log_analytics_workspace.logA.workspace_id
}

output "workspace_key" {
  value     = azurerm_log_analytics_workspace.logA.primary_shared_key
  sensitive = true
}

output "id" {
  value = azurerm_log_analytics_workspace.logA.id
}

resource "azurerm_log_analytics_workspace" "logA" {
  name                = var.logA_Name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_solution" "sol_vminsights" {
  solution_name         = "VMInsights"
  resource_group_name   = var.resource_group_name
  location              = var.location
  workspace_resource_id = azurerm_log_analytics_workspace.logA.id
  workspace_name        = azurerm_log_analytics_workspace.logA.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/VMInsights"
  }
}
