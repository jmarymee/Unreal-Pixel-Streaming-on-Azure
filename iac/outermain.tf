// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#######################################
## terraform configuration
#######################################
#terraform {
#  required_version = ">=0.12.6"

#  backend "azurerm" {
#resource_group_name   = "foo"
#storage_account_name  = "foo"
#container_name        = "foo"
#key                   = "foo"
#  }  
#}

#######################################
## Provider
#######################################
provider "azurerm" {
  #version = "=2.20.0"
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

## variables
variable "base_name" {
  description = "Base name to use for the resources"
  type        = string
  default     = "random"
}

## locals
locals {
  #this variable is used on all naming to avoid name collisions
  base_name = var.base_name == "random" ? random_string.base_id.result : var.base_name
}

/*
data "azurerm_subscription" "subscription" {
  subscription_id = var.subscription_id
}*/

## resources
resource "random_string" "base_id" {
  length  = 5
  special = false
  upper   = false
  number  = true
}

//a Git personal access token to access the repo
variable "git-pat" {
  type        = string
  description = "a Git personal access token to access the repo"
}

#this needs to be first to initialize the traffic manager for all subsequent regions deployed
module "global_region" {
  source    = "./global"
  base_name = local.base_name
  location  = "eastus"
  git-pat   = var.git-pat
}

//stamp directory is the instance for a region
//location is the Azure Region for the Stamp
//index is used in the file name of some of the resources
//Remember the requirement is for NV6 VMs, and not all regions contain those VMs, see https://azure.microsoft.com/regions/services/

module "region_1" {
  source       = "./stamp"
  base_name    = local.base_name
  location     = "eastus"
  index        = "1"
  key_vault_id = module.global_region.key_vault_id
  git-pat      = var.git-pat

  #variables for the TM
  global_resource_group_name       = module.global_region.global_resource_group_name
  mm_traffic_manager_profile_name  = module.global_region.mm_traffic_manager_profile_name
  ue4_traffic_manager_profile_name = module.global_region.ue4_traffic_manager_profile_name
}

module "region_2" {
  source       = "./stamp"
  base_name    = local.base_name
  location     = "westus"
  index        = "2"
  key_vault_id = module.global_region.key_vault_id
  git-pat      = var.git-pat

  #variables for the TM
  global_resource_group_name       = module.global_region.global_resource_group_name
  mm_traffic_manager_profile_name  = module.global_region.mm_traffic_manager_profile_name
  ue4_traffic_manager_profile_name = module.global_region.ue4_traffic_manager_profile_name
}

module "region_3" {
  source       = "./stamp"
  base_name    = local.base_name
  location     = "westeurope"
  index        = "3"
  key_vault_id = module.global_region.key_vault_id
  git-pat      = var.git-pat

  #variables for the TM
  global_resource_group_name       = module.global_region.global_resource_group_name
  mm_traffic_manager_profile_name  = module.global_region.mm_traffic_manager_profile_name
  ue4_traffic_manager_profile_name = module.global_region.ue4_traffic_manager_profile_name
}

module "region_4" {
  source       = "./stamp"
  base_name    = local.base_name
  location     = "southeastasia"
  index        = "4"
  key_vault_id = module.global_region.key_vault_id
  git-pat      = var.git-pat

  #variables for the TM
  global_resource_group_name       = module.global_region.global_resource_group_name
  mm_traffic_manager_profile_name  = module.global_region.mm_traffic_manager_profile_name
  ue4_traffic_manager_profile_name = module.global_region.ue4_traffic_manager_profile_name
}
