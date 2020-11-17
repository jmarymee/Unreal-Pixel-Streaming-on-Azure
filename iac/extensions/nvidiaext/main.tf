// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

variable "virtual_machine_scale_set_id" {
  type = string
}

variable "extension_name" {
  type = string
}

resource "azurerm_virtual_machine_scale_set_extension" "ue4_nvidia_drivers" {
  name                         = "NvidiaGpuDriverWindows"
  virtual_machine_scale_set_id = var.virtual_machine_scale_set_id
  publisher                    = "Microsoft.HpcCompute"
  type                         = "NvidiaGpuDriverWindows"
  type_handler_version         = "1.3"
  auto_upgrade_minor_version   = true
}
