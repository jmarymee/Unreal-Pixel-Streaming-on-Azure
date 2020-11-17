// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

variable "base_name" {
  type = string
}

variable "resource_group" {
  description = "The RG for the NSG"
  type = object({
    id       = string
    location = string
    name     = string
  })
}

variable "platform_update_domain_count" {
  type = string
}

variable "platform_fault_domain_count" {
  type = string
}

variable "managed" {
  type = string
}

output "availability_set_id" {
  value = azurerm_availability_set.availset.id
}

resource "azurerm_availability_set" "availset" {
  name                         = format("%s-mm-availset-%s", var.base_name, lower(var.resource_group.location))
  resource_group_name          = var.resource_group.name
  location                     = var.resource_group.location
  platform_update_domain_count = var.platform_update_domain_count
  platform_fault_domain_count  = var.platform_fault_domain_count
  managed                      = var.managed
}
