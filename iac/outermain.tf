#######################################
## terraform configuration
#######################################
terraform {
  required_version = ">=0.12.6"

#  backend "azurerm" {
    #resource_group_name   = "foo"
    #storage_account_name  = "foo"
    #container_name        = "foo"
    #key                   = "foo"
#  }  
}

#######################################
## Provider
#######################################
provider "azurerm" {
  version = "~>2.13"
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

## resources
resource "random_string" "base_id" {
  length  = 5
  special = false
  upper   = false
  number  = true
}

//stamp directory is the instance for a region
//location is the Azure Region
//index is used in the file name of the storage account
module "region_1" {
    source                    = "./stamp"
    base_name                 = local.base_name
    location                  = "eastus"
    index                     = "1"
}

module "region_2" {
    source                    = "./stamp"
    base_name                 = local.base_name
    location                  = "westeurope"
    index                     = "2"
}

#get the fields necessary for the traffic manager
module "tm" {
    source = "./networking/trafficmgr"
    base_name                 = local.base_name

    #put the PM in the first region
    resource_group_name = module.region_1.resource_group_name

    #the next line can be Weighted or Geographic for example
    traffic_routing_method = "Geographic"

    #starting with two regions add more if desired
    region1_public_ip_address_id = module.region_1.public_ip_address
    region2_public_ip_address_id = module.region_2.public_ip_address
}

/* TODO
    -turn on accelerated networking on the vms and vmss
    -decide on faster disks for vms or vmss
    -turn on log analytics and capture diags
    -turn on process for autoupdate on vmss and vms
    -consider how to make the tm add geo points
*/