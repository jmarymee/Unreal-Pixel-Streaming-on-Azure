// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#this module is to create the global components
# implement global rg
# implement matchmaker tm profile
# implement backend tm profile

## variables
variable "base_name" {
  description = "Base name to use for the resources"
  type        = string
}

variable "location" {
  type = string
}

variable "git-pat" {
  type        = string
  description = "(optional) describe your variable"
}

## locals
locals {
  rg_name = format("%s-%s-unreal-global-rg", var.base_name, lower(var.location))
}

output "global_resource_group_name" {
  value = azurerm_resource_group.rg_global.name
}

output "mm_traffic_manager_profile_name" {
  value = module.tm-profile-mm.traffic_manager_profile_name
}

output "ue4_traffic_manager_profile_name" {
  value = module.tm-profile-ue4.traffic_manager_profile_name
}

#create the global resource group for the traffic manager resource
resource "azurerm_resource_group" "rg_global" {
  name     = local.rg_name
  location = var.location
}

module "loganalytics_global" {
  source              = "../mgmt/loganalytics"
  base_name           = var.base_name
  resource_group_name = azurerm_resource_group.rg_global.name
  location            = var.location

  //add a name variable here for the global
  logA_Name = format("%s-loganalytics-global-%s", var.base_name, lower(var.location))
}

data "external" "user" {
  program = ["powershell.exe", "./global/getobjectid.ps1"]
}

module "akv_global" {
  source              = "../mgmt/akv"
  base_name           = var.base_name
  resource_group_name = azurerm_resource_group.rg_global.name
  location            = var.location

  git-pat                     = var.git-pat
  service_principal_object_id = data.external.user.result.object_id
}

output "key_vault_id" {
  value = module.akv_global.key_vault_id
}

#Traffic Manager implementation:

#Set up the matchmaker traffic manager profile
module "tm-profile-mm" {
  source    = "../networking/trafficmgr"
  base_name = var.base_name

  #put the PM in the first region
  resource_group_name = azurerm_resource_group.rg_global.name

  service_name = "mm"
  #the next line can be Weighted or Geographic for example
  traffic_routing_method = "Performance"

  log_analytics_workspace_id = module.loganalytics_global.workspace_id
}

#first set up the backend traffic manager profile
module "tm-profile-ue4" {
  source    = "../networking/trafficmgr"
  base_name = var.base_name

  #put the PM in the first region
  resource_group_name = azurerm_resource_group.rg_global.name

  service_name = "ue4"
  #the next line can be Weighted or Geographic for example
  traffic_routing_method = "Performance"

  log_analytics_workspace_id = module.loganalytics_global.workspace_id
}
