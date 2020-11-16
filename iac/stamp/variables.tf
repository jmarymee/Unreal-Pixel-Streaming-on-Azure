// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
#each regional "stamp" variables

#networking address space for the virtual network for each region
variable "vnet_address_space" {
  default = "10.100.0.0/16"
}

#subnet address space for each region
variable "subnet_address_prefixes" {
  default = "10.100.0.0/22"
}

#Matchmaker Load Balancer Private IP Address
variable "matchmaker_elb_private_ip_address" {
  default = "10.100.0.100"
}

#Matchmaker Load Balancer SKU
variable "matchmaker_elb_sku" {
  default = "Standard"
}

#Backend Load Balancer Private IP Address
variable "ue4_elb_private_ip_address" {
  default = "10.100.0.110"
}

#Backend Load Balancer SKU
variable "ue4_elb_sku" {
  default = "Standard"
}

#the following can only be 5 characters or less
variable "vm_name" {
  default = "mm"
}

#the instances of the Matchmaker VMs that will be behind the loadbalancer
variable "vm_count" {
  default = 1
}

#matchmaker vm size
variable "matchmaker_vm_size" {
  default = "Standard_F4s_v2"
}

#matchmaker vm publisher
variable "matchmaker_vm_publisher" {
  default = "MicrosoftWindowsServer"
}

#matchmaker vm offer
variable "matchmaker_vm_offer" {
  default = "WindowsServer"
}

#matchmaker vm sku
variable "matchmaker_vm_sku" {
  default = "2019-Datacenter"
}

#matchmaker vm version
variable "matchmaker_vm_version" {
  default = "latest"
}

#Matchmaker VM login name
variable "matchmaker_admin_username" {
  default = "azureadmin"
}

variable "platform_update_domain_count" {
  default = 5
}

variable "platform_fault_domain_count" {
  default = 2
}

variable "managed" {
  default = true
}

#Backend number of instances deployed on the VMSS cluster
variable "vmss_start_instances" {
  default = 3
}

#Backend compute type deployed on the VMSS cluster. NV6 have the NVidia GPUs
variable "vmss_sku" {
  #default = "Standard_NV6"
  default = "Standard_NV12s_v3"
}

#Backend image publisher deployed on the VMSS cluster. 
variable "vmss_source_image_publisher" {
  default = "MicrosoftWindowsDesktop"
}

#Backend image offer deployed on the VMSS cluster. 
variable "vmss_source_image_offer" {
  default = "Windows-10"
}

#Backend image sku deployed on the VMSS cluster. 
variable "vmss_source_image_sku" {
  default = "20h2-pro"
}

#Backend image version deployed on the VMSS cluster. 
variable "vmss_source_image_version" {
  default = "latest"
}

#Backend VMSS cluster upgrade mode. 
variable "vmss_upgrade_mode" {
  default = "Automatic"
}

#storage account tier
variable "storage_account_tier" {
  default = "Standard"
}

#storage account replication type
variable "storage_account_replication_type" {
  default = "LRS"
}
