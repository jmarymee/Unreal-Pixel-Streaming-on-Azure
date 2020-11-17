// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

## variables
variable "network_interface_ids" {
  type = list(object({ id = string }))
}

variable "network_security_group_id" {
  type = string
}

resource "azurerm_network_interface_security_group_association" "nsg_association" {
  count                     = length(var.network_interface_ids)
  network_interface_id      = var.network_interface_ids[count.index].id
  network_security_group_id = var.network_security_group_id
}
