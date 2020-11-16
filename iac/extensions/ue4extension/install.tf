// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

variable "virtual_machine_scale_set_id" {
  type = string
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

variable "mm_lb_fqdn" {
  type = string
}

variable "git-pat" {
  type = string
}

variable "admin_password" {
  type = string
}

locals {
  source          = "./setupBackendVMSS.ps1"
  command         = "powershell -ExecutionPolicy Unrestricted -NoProfile -NonInteractive -command cp c:/AzureData/CustomData.bin c:/AzureData/install.ps1; c:/AzureData/install.ps1 -subscription_id ${var.subscription_id} -resource_group_name ${var.resource_group_name} -vmss_name ${var.vmss_name} -application_insights_key ${var.application_insights_key} -mm_lb_fqdn ${var.mm_lb_fqdn} -admin_password ${var.admin_password} -pat ${var.git-pat};"
  shorter_command = "powershell -ExecutionPolicy Unrestricted -NoProfile -NonInteractive -command cp c:/AzureData/CustomData.bin c:/AzureData/install.ps1; c:/AzureData/install.ps1 -subscription_id ${var.subscription_id} -resource_group_name ${var.resource_group_name} -vmss_name ${var.vmss_name} -application_insights_key ${var.application_insights_key} -mm_lb_fqdn ${var.mm_lb_fqdn} -admin_password ${var.admin_password};"

  #if git-pat is "" then don't add that parameter
  paramstring = var.git-pat != "" ? local.command : local.shorter_command
}

resource "azurerm_virtual_machine_scale_set_extension" "ue4extension" {
  name                         = var.extension_name
  virtual_machine_scale_set_id = var.virtual_machine_scale_set_id
  publisher                    = "Microsoft.Compute"
  type                         = "CustomScriptExtension"
  type_handler_version         = "1.10"

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
