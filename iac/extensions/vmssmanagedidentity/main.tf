// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

variable "virtual_machine_scale_set_id" {
  type = string
}

resource "azurerm_virtual_machine_scale_set_extension" "ManagedIdentityWindowsExtension" {
  name                         = "ManagedIdentityWindowsExtension"
  virtual_machine_scale_set_id = var.virtual_machine_scale_set_id
  publisher                    = "Microsoft.ManagedIdentity"
  type                         = "ManagedIdentityExtensionForWindows"
  type_handler_version         = "1.0"
  auto_upgrade_minor_version   = true

  settings           = <<SETTINGS
  {
      "port": 50342
  }
  SETTINGS
  protected_settings = <<PROTECTED_SETTINGS
    {
    }
  PROTECTED_SETTINGS  
}
