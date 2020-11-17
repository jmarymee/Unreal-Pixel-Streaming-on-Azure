// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

variable "base_name" {
  type = string
}

variable "pip_name" {
  type = string
}

variable "resource_group" {
  description = "The RG VMs"
  type = object({
    id     = string
    location = string
    name   = string
  })
}

# Public IP Variables
variable "allocation_method" {
  type = string
}

variable "pip_sku" {
  default = "Standard"
}

variable "domain_name_label" {
  type = string
}

locals {
  name = format("%s-%s-pip", var.base_name, var.pip_name)
}

# Module
resource "azurerm_public_ip" "pip" {
  name                = local.name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  allocation_method   = var.allocation_method
  sku                 = var.pip_sku
  domain_name_label   = var.domain_name_label
}

# Output
output "id" {
  value = azurerm_public_ip.pip.id
}
