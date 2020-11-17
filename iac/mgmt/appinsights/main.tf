// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

## variables
variable "base_name" {
  description = "Base name to use for the resources"
  type        = string
}

variable "resource_group_name" {
  type        = string
}

variable "location" {
  type        = string
}

resource "azurerm_application_insights" "appI" {
  name                = format("%s-appinsights-%s", var.base_name, lower(var.location))
  resource_group_name = var.resource_group_name
  location            = var.location
  application_type    = "web"
  retention_in_days   = 30
}

output "instrumentation_key" {
  value = azurerm_application_insights.appI.instrumentation_key
}

output "app_id" {
  value = azurerm_application_insights.appI.app_id
}