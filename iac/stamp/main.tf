// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

variable "base_name" {
  type = string
}

variable "location" {
  description = "Location of the region"
}

variable "index" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "git-pat" {
  type = string
}

#this is used for the outer loops
output "index" {
  value = var.index
}

#this is used for the outer loops
output "location" {
  value = var.location
}

resource "random_string" "admin_password" {
  length      = 15
  special     = true
  upper       = true
  number      = true
  min_special = 4
}

#base_name = var.base_name == "random" ? random_string.base_id.result : var.base_name

locals {
  safePWD = replace(replace(random_string.admin_password.result, "{", "!"), "}", "!")
}

#put this in akv
resource "azurerm_key_vault_secret" "pwd_secret" {
  name         = format("%s-%s-password", var.base_name, var.location)
  value        = local.safePWD
  key_vault_id = var.key_vault_id
}

## outputs


#create a resource group, uses the location in the variables.tf file
module "unreal-rg" {
  source    = "../rg"
  base_name = var.base_name
  location  = var.location
}

output "resource_group_name" {
  value = module.unreal-rg.resource_group.name
}

#this is used for service diagnostics
module "loganalytics" {
  source              = "../mgmt/loganalytics"
  base_name           = var.base_name
  resource_group_name = module.unreal-rg.resource_group.name
  location            = var.location
  logA_Name           = format("%s-loganalytics-%s", var.base_name, lower(var.location))
}

#create a virtual network, uses variables in the variables.tf file
module "unreal-vnet" {
  source             = "../networking/vnet"
  base_name          = var.base_name
  resource_group     = module.unreal-rg.resource_group
  vnet_address_space = var.vnet_address_space

  ### todo: consider a subnet array ###
  subnet_address_prefixes = var.subnet_address_prefixes

  log_analytics_workspace_id = module.loganalytics.id
}

module "unreal-storage" {
  source                   = "../storage"
  base_name                = var.base_name
  resource_group           = module.unreal-rg.resource_group
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  index                    = var.index
}

module "appinsights" {
  source              = "../mgmt/appinsights"
  base_name           = var.base_name
  resource_group_name = module.unreal-rg.resource_group.name
  location            = var.location

  #instrumentation_key is the output
  #app_id is the output
}

//add an external load balancer in front of the matchmaker vm
module "matchmaker-elb" {
  source            = "../networking/elb"
  base_name         = var.base_name
  lb_name           = "mm"
  resource_group    = module.unreal-rg.resource_group
  domain_name_label = format("%s-%s-%s", var.location, lower(var.base_name), "mm")

  nat_pool_frontend_port_start = 80
  nat_pool_frontend_port_end   = 90
  nat_pool_backend_port        = 90

  sku       = var.matchmaker_elb_sku
  subnet_id = module.unreal-vnet.subnet_id

  ### todo: use the function in terraform to get it from the range ###
  private_ip_address            = var.matchmaker_elb_private_ip_address
  private_ip_address_allocation = "Static"
}

#output the fqdn for the outer loop into Traffic Manager
output "matchmaker-elb-fqdn" {
  value = module.matchmaker-elb.fqdn
}

module "ue4-elb" {
  source            = "../networking/elb"
  base_name         = var.base_name
  resource_group    = module.unreal-rg.resource_group
  lb_name           = "ue4"
  domain_name_label = format("%s-%s-%s", var.location, lower(var.base_name), "ue4")

  nat_pool_frontend_port_start = 49152
  nat_pool_frontend_port_end   = 65534
  nat_pool_backend_port        = 49151

  sku       = var.ue4_elb_sku
  subnet_id = module.unreal-vnet.subnet_id

  ### todo: use the function in terraform to get it from the range ###
  private_ip_address            = var.ue4_elb_private_ip_address
  private_ip_address_allocation = "Static"
}

#output the ELB id for the outer loop into Traffic Manager
output "ue4-elb-fqdn" {
  value = module.ue4-elb.fqdn
}

#add a lb probe/rule for mm - 90
module "mm-90-rule" {
  source                              = "../networking/addporttolb"
  base_name                           = var.base_name
  resource_group                      = module.unreal-rg.resource_group
  lb_name                             = "mm"
  loadbalancer_id                     = module.matchmaker-elb.lb_id
  backend_address_pool_id             = module.matchmaker-elb.lb_backend_address_pool_id
  probe_port                          = "90"
  probe_protocol                      = "TCP"
  rule_frontend_ip_configuration_name = "external"
  rule_protocol                       = "TCP"
  rule_frontend_port                  = "90"
  rule_backend_port                   = "90"
  load_distribution                   = "SourceIPProtocol"
}

#add a lb probe/rule for mm - 9999
module "mm-9999-rule" {
  source                              = "../networking/addporttolb"
  base_name                           = var.base_name
  resource_group                      = module.unreal-rg.resource_group
  lb_name                             = "mm"
  loadbalancer_id                     = module.matchmaker-elb.lb_id
  backend_address_pool_id             = module.matchmaker-elb.lb_backend_address_pool_id
  probe_port                          = "9999"
  probe_protocol                      = "TCP"
  rule_frontend_ip_configuration_name = "external"
  #format("%s-mm-config-%s", var.base_name, var.index)
  rule_protocol      = "TCP"
  rule_frontend_port = "9999"
  rule_backend_port  = "9999"
  load_distribution  = "SourceIPProtocol"
}

#add a lb probe/rule for UE4 80
module "ue4-80-rule" {
  source                              = "../networking/addporttolb"
  base_name                           = var.base_name
  resource_group                      = module.unreal-rg.resource_group
  lb_name                             = "ue4"
  loadbalancer_id                     = module.ue4-elb.lb_id
  backend_address_pool_id             = module.ue4-elb.lb_backend_address_pool_id
  probe_port                          = "80"
  probe_protocol                      = "TCP"
  rule_frontend_ip_configuration_name = "external"
  #format("%s-mm-config-%s", var.base_name, var.index)
  rule_protocol      = "TCP"
  rule_frontend_port = "80"
  rule_backend_port  = "80"
  load_distribution  = "SourceIPProtocol"
}

#add a lb probe/rule for UE4 7070
module "ue4-7070-rule" {
  source                              = "../networking/addporttolb"
  base_name                           = var.base_name
  resource_group                      = module.unreal-rg.resource_group
  lb_name                             = "ue4"
  loadbalancer_id                     = module.ue4-elb.lb_id
  backend_address_pool_id             = module.ue4-elb.lb_backend_address_pool_id
  probe_port                          = "7070"
  probe_protocol                      = "TCP"
  rule_frontend_ip_configuration_name = "external"
  #format("%s-mm-config-%s", var.base_name, var.index)
  rule_protocol      = "TCP"
  rule_frontend_port = "7070"
  rule_backend_port  = "7070"
  load_distribution  = "SourceIPProtocol"
}

#add a lb probe/rule for UE4 8888
module "ue4-8888-rule" {
  source                              = "../networking/addporttolb"
  base_name                           = var.base_name
  resource_group                      = module.unreal-rg.resource_group
  lb_name                             = "ue4"
  loadbalancer_id                     = module.ue4-elb.lb_id
  backend_address_pool_id             = module.ue4-elb.lb_backend_address_pool_id
  probe_port                          = "8888"
  probe_protocol                      = "TCP"
  rule_frontend_ip_configuration_name = "external"
  #format("%s-mm-config-%s", var.base_name, var.index)
  rule_protocol      = "TCP"
  rule_frontend_port = "8888"
  rule_backend_port  = "8888"
  load_distribution  = "SourceIPProtocol"
}

#add a lb probe/rule for UE4 8889
module "ue4-8889-rule" {
  source                              = "../networking/addporttolb"
  base_name                           = var.base_name
  resource_group                      = module.unreal-rg.resource_group
  lb_name                             = "ue4"
  loadbalancer_id                     = module.ue4-elb.lb_id
  backend_address_pool_id             = module.ue4-elb.lb_backend_address_pool_id
  probe_port                          = "8889"
  probe_protocol                      = "TCP"
  rule_frontend_ip_configuration_name = "external"
  #format("%s-mm-config-%s", var.base_name, var.index)
  rule_protocol      = "TCP"
  rule_frontend_port = "8889"
  rule_backend_port  = "8889"
  load_distribution  = "SourceIPProtocol"
}

module "ue4-4244-rule" {
  source                              = "../networking/addporttolb"
  base_name                           = var.base_name
  resource_group                      = module.unreal-rg.resource_group
  lb_name                             = "ue4"
  loadbalancer_id                     = module.ue4-elb.lb_id
  backend_address_pool_id             = module.ue4-elb.lb_backend_address_pool_id
  probe_port                          = "4244"
  probe_protocol                      = "TCP"
  rule_frontend_ip_configuration_name = "external"
  #format("%s-mm-config-%s", var.base_name, var.index)
  rule_protocol      = "TCP"
  rule_frontend_port = "4244"
  rule_backend_port  = "4244"
  load_distribution  = "SourceIPProtocol"
}

module "matchmaker-availset" {
  source                       = "../compute/availset"
  base_name                    = var.base_name
  resource_group               = module.unreal-rg.resource_group
  platform_update_domain_count = var.platform_update_domain_count
  platform_fault_domain_count  = var.platform_fault_domain_count
  managed                      = var.managed
}
#windows based matchmaking server with no pip as it is behind a ELB

module "matchmaker-vm" {
  vm_count        = var.vm_count
  source          = "../compute/vm"
  base_name       = var.base_name
  vm_name         = format("%s-%s", var.base_name, var.vm_name)
  resource_group  = module.unreal-rg.resource_group
  subnet_id       = module.unreal-vnet.subnet_id
  dia_stg_acct_id = module.unreal-storage.id
  storage_uri     = module.unreal-storage.uri

  availability_set_id = module.matchmaker-availset.availability_set_id

  admin_username = var.matchmaker_admin_username
  admin_password = local.safePWD

  vm_size      = var.matchmaker_vm_size
  vm_publisher = var.matchmaker_vm_publisher
  vm_offer     = var.matchmaker_vm_offer
  vm_sku       = var.matchmaker_vm_sku
  vm_version   = var.matchmaker_vm_version

  lb_backend_address_pool_id = module.matchmaker-elb.lb_backend_address_pool_id
  lb_nat_pool_id             = module.matchmaker-elb.lb_nat_pool_id
  ip_configuration_name      = format("%s-mm-config-%s", var.base_name, var.index)
}

# add the matchmaker vm to the elb
module "vm_to_backend_pool" {
  source                  = "../networking/backendpoolassociation"
  network_interface_ids   = module.matchmaker-vm.nics
  ip_configuration_name   = format("%s-mm-config-%s", var.base_name, var.index)
  backend_address_pool_id = module.matchmaker-elb.lb_backend_address_pool_id
}

#change the following to: 90,9999

#add the first NSG for the matchmaker nic
module "matchmaker_nsg" {
  source         = "../networking/nsg"
  base_name      = var.base_name
  resource_group = module.unreal-rg.resource_group
  nsg_name       = "mm-nsg"

  log_analytics_workspace_id = module.loganalytics.id
}

#associate the NSG to the NIC
module "matchmaker_nsg_association" {
  source                    = "../networking/nsgassociation"
  network_interface_ids     = module.matchmaker-vm.nics
  network_security_group_id = module.matchmaker_nsg.network_security_group_id
}

module "matchmaker_security_rule_90" {
  source                      = "../networking/security_rule"
  resource_group              = module.unreal-rg.resource_group
  network_security_group_name = module.matchmaker_nsg.network_security_group_name

  security_rule_name                       = "Open90"
  security_rule_priority                   = 1000
  security_rule_direction                  = "Inbound"
  security_rule_access                     = "Allow"
  security_rule_protocol                   = "Tcp"
  security_rule_source_port_range          = "*"
  security_rule_destination_port_range     = "90"
  security_rule_source_address_prefix      = "*"
  security_rule_destination_address_prefix = "*"
}

#add this security rule to open another port in the NSG for the return from the UE4
module "matchmaker_security_rule_9999" {
  source                      = "../networking/security_rule"
  resource_group              = module.unreal-rg.resource_group
  network_security_group_name = module.matchmaker_nsg.network_security_group_name

  security_rule_name                       = "Open9999"
  security_rule_priority                   = 1010
  security_rule_direction                  = "Inbound"
  security_rule_access                     = "Allow"
  security_rule_protocol                   = "Tcp"
  security_rule_source_port_range          = "*"
  security_rule_destination_port_range     = "9999"
  security_rule_source_address_prefix      = "*"
  security_rule_destination_address_prefix = "*"
}

module "mm_outbound_rule_7070" {
  source                      = "../networking/security_rule"
  resource_group              = module.unreal-rg.resource_group
  network_security_group_name = module.matchmaker_nsg.network_security_group_name

  security_rule_name                       = "Open7070"
  security_rule_priority                   = 1000
  security_rule_direction                  = "Outbound"
  security_rule_access                     = "Allow"
  security_rule_protocol                   = "Tcp"
  security_rule_source_port_range          = "*"
  security_rule_destination_port_range     = "7070"
  security_rule_source_address_prefix      = "*"
  security_rule_destination_address_prefix = "*"
}

module "mm_outbound_rule_888x" {
  source                      = "../networking/security_rule"
  resource_group              = module.unreal-rg.resource_group
  network_security_group_name = module.matchmaker_nsg.network_security_group_name

  security_rule_name                       = "Open888x"
  security_rule_priority                   = 1010
  security_rule_direction                  = "Outbound"
  security_rule_access                     = "Allow"
  security_rule_protocol                   = "Tcp"
  security_rule_source_port_range          = "*"
  security_rule_destination_port_range     = "8888-8889"
  security_rule_source_address_prefix      = "*"
  security_rule_destination_address_prefix = "*"
}

module "mm_outbound_rule_80" {
  source                      = "../networking/security_rule"
  resource_group              = module.unreal-rg.resource_group
  network_security_group_name = module.matchmaker_nsg.network_security_group_name

  security_rule_name                       = "Open80"
  security_rule_priority                   = 1020
  security_rule_direction                  = "Outbound"
  security_rule_access                     = "Allow"
  security_rule_protocol                   = "Tcp"
  security_rule_source_port_range          = "*"
  security_rule_destination_port_range     = "80"
  security_rule_source_address_prefix      = "*"
  security_rule_destination_address_prefix = "*"
}

module "mm_outbound_rule_19302" {
  source                      = "../networking/security_rule"
  resource_group              = module.unreal-rg.resource_group
  network_security_group_name = module.matchmaker_nsg.network_security_group_name

  security_rule_name                       = "Open19302"
  security_rule_priority                   = 1030
  security_rule_direction                  = "Outbound"
  security_rule_access                     = "Allow"
  security_rule_protocol                   = "Tcp"
  security_rule_source_port_range          = "*"
  security_rule_destination_port_range     = "19302-19303"
  security_rule_source_address_prefix      = "*"
  security_rule_destination_address_prefix = "*"
}

//create a nsg for the UE4 components
module "ue4_nsg" {
  source         = "../networking/nsg"
  base_name      = var.base_name
  resource_group = module.unreal-rg.resource_group
  nsg_name       = "ue4-nsg"

  log_analytics_workspace_id = module.loganalytics.id
}

module "ue4_security_rule_7070" {
  source                      = "../networking/security_rule"
  resource_group              = module.unreal-rg.resource_group
  network_security_group_name = module.ue4_nsg.network_security_group_name

  security_rule_name                       = "Open7070"
  security_rule_priority                   = 1000
  security_rule_direction                  = "Inbound"
  security_rule_access                     = "Allow"
  security_rule_protocol                   = "Tcp"
  security_rule_source_port_range          = "*"
  security_rule_destination_port_range     = "7070"
  security_rule_source_address_prefix      = "*"
  security_rule_destination_address_prefix = "*"
}

module "ue4_security_rule_888x" {
  source                      = "../networking/security_rule"
  resource_group              = module.unreal-rg.resource_group
  network_security_group_name = module.ue4_nsg.network_security_group_name

  security_rule_name                       = "Open888x"
  security_rule_priority                   = 1010
  security_rule_direction                  = "Inbound"
  security_rule_access                     = "Allow"
  security_rule_protocol                   = "Tcp"
  security_rule_source_port_range          = "*"
  security_rule_destination_port_range     = "8888-8889"
  security_rule_source_address_prefix      = "*"
  security_rule_destination_address_prefix = "*"
}

module "ue4_security_rule_80" {
  source                      = "../networking/security_rule"
  resource_group              = module.unreal-rg.resource_group
  network_security_group_name = module.ue4_nsg.network_security_group_name

  security_rule_name                       = "Open80"
  security_rule_priority                   = 1020
  security_rule_direction                  = "Inbound"
  security_rule_access                     = "Allow"
  security_rule_protocol                   = "Tcp"
  security_rule_source_port_range          = "*"
  security_rule_destination_port_range     = "80"
  security_rule_source_address_prefix      = "*"
  security_rule_destination_address_prefix = "*"
}

module "ue4_security_rule_1930x" {
  source                      = "../networking/security_rule"
  resource_group              = module.unreal-rg.resource_group
  network_security_group_name = module.ue4_nsg.network_security_group_name

  security_rule_name                       = "Open1930x"
  security_rule_priority                   = 1030
  security_rule_direction                  = "Inbound"
  security_rule_access                     = "Allow"
  security_rule_protocol                   = "Tcp"
  security_rule_source_port_range          = "*"
  security_rule_destination_port_range     = "19302-19303"
  security_rule_source_address_prefix      = "*"
  security_rule_destination_address_prefix = "*"
}

module "ue4_security_rule_4244" {
  source                      = "../networking/security_rule"
  resource_group              = module.unreal-rg.resource_group
  network_security_group_name = module.ue4_nsg.network_security_group_name

  security_rule_name                       = "Open4244"
  security_rule_priority                   = 1040
  security_rule_direction                  = "Inbound"
  security_rule_access                     = "Allow"
  security_rule_protocol                   = "Tcp"
  security_rule_source_port_range          = "*"
  security_rule_destination_port_range     = "4244"
  security_rule_source_address_prefix      = "*"
  security_rule_destination_address_prefix = "*"
}

module "ue4_outbound_security_rule_90" {
  source                      = "../networking/security_rule"
  resource_group              = module.unreal-rg.resource_group
  network_security_group_name = module.ue4_nsg.network_security_group_name

  security_rule_name                       = "Open90"
  security_rule_priority                   = 1020
  security_rule_direction                  = "Outbound"
  security_rule_access                     = "Allow"
  security_rule_protocol                   = "Tcp"
  security_rule_source_port_range          = "*"
  security_rule_destination_port_range     = "90"
  security_rule_source_address_prefix      = "*"
  security_rule_destination_address_prefix = "*"
}

module "ue4_outbound_security_rule_9999" {
  source                      = "../networking/security_rule"
  resource_group              = module.unreal-rg.resource_group
  network_security_group_name = module.ue4_nsg.network_security_group_name

  security_rule_name                       = "Open9999"
  security_rule_priority                   = 1030
  security_rule_direction                  = "Outbound"
  security_rule_access                     = "Allow"
  security_rule_protocol                   = "Tcp"
  security_rule_source_port_range          = "*"
  security_rule_destination_port_range     = "9999"
  security_rule_source_address_prefix      = "*"
  security_rule_destination_address_prefix = "*"
}

module "ue4_outbound_security_rule_19302" {
  source                      = "../networking/security_rule"
  resource_group              = module.unreal-rg.resource_group
  network_security_group_name = module.ue4_nsg.network_security_group_name

  security_rule_name                       = "Open19302"
  security_rule_priority                   = 1040
  security_rule_direction                  = "Outbound"
  security_rule_access                     = "Allow"
  security_rule_protocol                   = "Tcp"
  security_rule_source_port_range          = "*"
  security_rule_destination_port_range     = "19302-19303"
  security_rule_source_address_prefix      = "*"
  security_rule_destination_address_prefix = "*"
}

module "ue4_outbound_security_rule_4244" {
  source                      = "../networking/security_rule"
  resource_group              = module.unreal-rg.resource_group
  network_security_group_name = module.ue4_nsg.network_security_group_name

  security_rule_name                       = "OpenOutbound4244"
  security_rule_priority                   = 1050
  security_rule_direction                  = "Outbound"
  security_rule_access                     = "Allow"
  security_rule_protocol                   = "Tcp"
  security_rule_source_port_range          = "*"
  security_rule_destination_port_range     = "4244"
  security_rule_source_address_prefix      = "*"
  security_rule_destination_address_prefix = "*"
}

module "compute-vmss" {
  source         = "../compute/vmss"
  base_name      = var.base_name
  vm_name        = format("%s%s", var.base_name, "vmss")
  resource_group = module.unreal-rg.resource_group
  subnet_id      = module.unreal-vnet.subnet_id

  admin_username = var.matchmaker_admin_username
  admin_password = local.safePWD

  sku          = var.vmss_sku
  instances    = var.vmss_start_instances
  upgrade_mode = var.vmss_upgrade_mode

  vm_publisher = var.vmss_source_image_publisher
  vm_offer     = var.vmss_source_image_offer
  vm_sku       = var.vmss_source_image_sku
  vm_version   = var.vmss_source_image_version

  lb_backend_address_pool_id = module.ue4-elb.lb_backend_address_pool_id
  lb_nat_pool_id             = module.ue4-elb.lb_nat_pool_id
  health_probe_id            = module.ue4-elb.health_probe_id

  network_security_group_id = module.ue4_nsg.network_security_group_id
}

/*
variable "subscription_id"
variable "resource_group_id" 
variable "vmss_name" 
variable "application_insights_key" 
*/

data "azurerm_subscription" "current" {
}

module "mm-extension" {
  source                   = "../extensions/mmextension"
  virtual_machine_ids      = module.matchmaker-vm.vms
  extension_name           = "mm-extension"
  subscription_id          = data.azurerm_subscription.current.subscription_id
  resource_group_name      = module.unreal-rg.resource_group.name
  vmss_name                = module.compute-vmss.name
  application_insights_key = module.appinsights.instrumentation_key
  git-pat                  = var.git-pat
}

/*
module "mm-vm-monitoring-extension" {
  source              = "../extensions/vmmonitoringagent"
  virtual_machine_ids = module.matchmaker-vm.vms
  extension_name      = "MonitoringAgentWindows"
  workspace_id        = module.loganalytics.workspace_id
  workspace_key       = module.loganalytics.workspace_key
}

module "mm-vm-DependencyAgentWindows" {
  source              = "../extensions/vmdependencyagent"
  virtual_machine_ids = module.matchmaker-vm.vms
}

module "mm-vm-diag-extension" {
  source                   = "../extensions/vmazurediags"
  virtual_machine_ids      = module.matchmaker-vm.vms
  extension_name           = "mm-vm-diag-extension"
  storage_account_name     = module.unreal-storage.name
  storage_account_key      = module.unreal-storage.key
  storage_account_endpoint = module.unreal-storage.uri
}
*/

module "ue4-extension" {
  source                       = "../extensions/ue4extension"
  virtual_machine_scale_set_id = module.compute-vmss.id
  extension_name               = "ue4-extension"
  subscription_id              = data.azurerm_subscription.current.subscription_id
  resource_group_name          = module.unreal-rg.resource_group.name
  vmss_name                    = module.compute-vmss.name
  application_insights_key     = module.appinsights.instrumentation_key
  mm_lb_fqdn                   = module.matchmaker-elb.fqdn
  git-pat                      = var.git-pat
  admin_password               = local.safePWD
}

module "ue4-nvidia-extension" {
  source                       = "../extensions/nvidiaext"
  virtual_machine_scale_set_id = module.compute-vmss.id
  extension_name               = "ue4_nvidia_driver"
}

/*
module "ue4-vmss-ManagedIdentity" {
  source                       = "../extensions/vmssmanagedidentity"
  virtual_machine_scale_set_id = module.compute-vmss.id
}
*/

/*
module "ue4-vmss-MonitoringAgentWindows" {
  source                       = "../extensions/vmssmonitoringagent"
  virtual_machine_scale_set_id = module.compute-vmss.id
  extension_name               = "MonitoringAgentWindows"
  workspace_id                 = module.loganalytics.workspace_id
  workspace_key                = module.loganalytics.workspace_key
}

module "ue4-vmss-DependencyAgentWindows" {
  source                       = "../extensions/vmssdependencyagent"
  virtual_machine_scale_set_id = module.compute-vmss.id
}

module "ue4-vmss-diag-extension" {
  source                       = "../extensions/vmssazurediags"
  virtual_machine_scale_set_id = module.compute-vmss.id
  extension_name               = "ue4-vmss-diag-extension"
  storage_account_name         = module.unreal-storage.name
  storage_account_key          = module.unreal-storage.key
  storage_account_endpoint     = module.unreal-storage.uri
}
*/

# now add this stamp to the Traffic Manager
#add the regional TM endpoint for the matchmaker service
variable "global_resource_group_name" {
  type = string
}

variable "mm_traffic_manager_profile_name" {
  type = string
}

variable "ue4_traffic_manager_profile_name" {
  type = string
}

module "add_tm_region_mm" {
  source    = "../networking/trafficmgraddreg"
  base_name = var.base_name

  #this needs to be the rg where the tm profile is:
  resource_group_name = var.global_resource_group_name

  traffic_manager_profile_name = var.mm_traffic_manager_profile_name
  index                        = var.index
  service_name                 = "mm"

  pip_fqdn          = module.matchmaker-elb.fqdn
  endpoint_location = var.location
}

#add the regional TM endpoint for the backend
module "add_tm_region_ue4" {
  source              = "../networking/trafficmgraddreg"
  base_name           = var.base_name
  resource_group_name = var.global_resource_group_name

  traffic_manager_profile_name = var.ue4_traffic_manager_profile_name
  index                        = var.index
  service_name                 = "ue4"

  pip_fqdn          = module.ue4-elb.fqdn
  endpoint_location = var.location
}

/* disabled as code is now in code on the VMSS Servers
module "compute-autoscale" {
  source = "../compute/autoscale"
  base_name = var.base_name
  resource_group = module.unreal-rg.resource_group
  vmss_id = module.compute-vmss.id
  capacity_default = var.capacity_default
  capacity_minimum = var.capacity_minimum
  capacity_maximum = var.capacity_maximum
}
*/
