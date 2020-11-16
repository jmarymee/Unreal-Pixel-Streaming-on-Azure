// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

variable "virtual_machine_ids" {
  type = list(object({ id = string }))
}

variable "extension_name" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vmss_name" {
  type = string
}

variable "application_insights_key" {
  type = string
}

variable "git-pat" {
  type = string
}

locals {
  source        = "./setupMatchMakerVM.ps1"
  command       = "powershell -ExecutionPolicy Unrestricted -NoProfile -NonInteractive -command cp c:/AzureData/CustomData.bin c:/AzureData/install.ps1; c:/AzureData/install.ps1 -subscription_id ${var.subscription_id} -resource_group_name ${var.resource_group_name} -vmss_name ${var.vmss_name} -application_insights_key ${var.application_insights_key} -pat ${var.git-pat};"
  short_command = "powershell -ExecutionPolicy Unrestricted -NoProfile -NonInteractive -command cp c:/AzureData/CustomData.bin c:/AzureData/install.ps1; c:/AzureData/install.ps1 -subscription_id ${var.subscription_id} -resource_group_name ${var.resource_group_name} -vmss_name ${var.vmss_name} -application_insights_key ${var.application_insights_key};"

  #if git-pat is "" then don't add that parameter
  paramstring = var.git-pat != "" ? local.command : local.short_command
}

resource "azurerm_virtual_machine_extension" "mmextension" {
  count                = length(var.virtual_machine_ids)
  name                 = var.extension_name
  virtual_machine_id   = var.virtual_machine_ids[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings           = <<SETTINGS
  {
    "commandToExecute": "${local.paramstring}"
  }
  SETTINGS
  protected_settings = <<PROTECTED_SETTINGS
    {
    }
  PROTECTED_SETTINGS  
}
