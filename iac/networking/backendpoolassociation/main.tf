// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

variable "network_interface_ids" {
  type = list(object({ id = string }))
}

variable "ip_configuration_name" {
  type = string
}

variable "backend_address_pool_id" {
  type = string
}

resource "azurerm_network_interface_backend_address_pool_association" "beapa" {
  count = length(var.network_interface_ids)

  network_interface_id    = var.network_interface_ids[count.index].id
  ip_configuration_name   = var.ip_configuration_name
  backend_address_pool_id = var.backend_address_pool_id
}
