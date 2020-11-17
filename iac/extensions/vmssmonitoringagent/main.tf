// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
variable "virtual_machine_scale_set_id" {
  type = string
}

variable "extension_name" {
  type = string
}

variable "workspace_id" {
  type = string
}

variable "workspace_key" {
  type = string
}

resource "azurerm_virtual_machine_scale_set_extension" "vmssmonitoringagent" {
  name                         = var.extension_name
  virtual_machine_scale_set_id = var.virtual_machine_scale_set_id
  publisher                    = "Microsoft.EnterpriseCloud.Monitoring"
  type                         = "MicrosoftMonitoringAgent"
  type_handler_version         = "1.0"
  auto_upgrade_minor_version   = true

  settings           = <<SETTINGS
  {
    "workspaceId": "${var.workspace_id}"
  }
  SETTINGS
  protected_settings = <<PROTECTED_SETTINGS
    {
    "workspaceKey": "${var.workspace_key}"
    }
  PROTECTED_SETTINGS  
}
