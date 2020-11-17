// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

## variables
variable "base_name" {
  description = "Base name to use for the resources"
  type        = string
}

variable "location" {
  type = string
}

## outputs
output "resource_group" {
  value = ({
    id       = azurerm_resource_group.rg.id
    name     = local.rg_name
    location = var.location
  })
}

## locals
locals {
  rg_name = format("%s-%s-unreal-rg", var.base_name, lower(var.location))
}

## resources
resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
}
