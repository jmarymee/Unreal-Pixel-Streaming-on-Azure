// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

variable "base_name" {
  type = string
}

variable "resource_group" {
  description = "The RG VMs"
  type = object({
    id       = string
    location = string
    name     = string
  })
}

variable "vm_count" {
  type = number
}

variable "vm_size" {
  description = "VM Size for the client"
  type        = string
}

variable "vm_publisher" {
  type = string
}

variable "vm_offer" {
  type = string
}

variable "vm_sku" {
  type = string
}

variable "vm_version" {
  type = string
}

variable "subnet_id" {
  description = "Subnet to use for the vms"
  type        = string
}

variable "dia_stg_acct_id" {
  description = "The diag storage account id for the VMs"
  type        = string
}

variable "storage_uri" {
  type = string
}

variable "admin_username" {
  description = "user name for the VMs"
  type        = string
}

variable "admin_password" {
  description = "Password for the VMs"
  type        = string
}

variable "vm_name" {
  type = string
}

variable "lb_backend_address_pool_id" {
  type = string
}

variable "lb_nat_pool_id" {
  type = string
}

variable "ip_configuration_name" {
  type = string
}

variable "availability_set_id" {
  type = string
}

## outputs
output "admin_password" {
  value = var.admin_password
}

output "vms" {
  value = azurerm_windows_virtual_machine.vm
}

output "nics" {
  value = azurerm_network_interface.nic
}

# output "principal_id" {
#   value = azurerm_windows_virtual_machine.vm[count.index].identity[0].principal_id
# }

## resources

#create an array of public ip addresses
resource "azurerm_public_ip" "pip" {
  count               = var.vm_count
  name                = format("%s-%s-%s-pip.%s", var.base_name, "mmvm", var.resource_group.location, count.index)
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = lower(format("%s-%s-%s", "mmvm", count.index, var.base_name))
}

resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = format("%s-nic-%s.%s", var.vm_name, lower(var.resource_group.location), count.index)
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name

  ip_configuration {
    name                          = var.ip_configuration_name
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[count.index].id
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  count                    = var.vm_count
  name                     = format("%s-vm%s", var.vm_name, count.index)
  location                 = var.resource_group.location
  resource_group_name      = var.resource_group.name
  size                     = var.vm_size
  admin_username           = var.admin_username
  admin_password           = var.admin_password
  enable_automatic_updates = true
  provision_vm_agent       = true
  availability_set_id      = var.availability_set_id

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.vm_publisher
    offer     = var.vm_offer
    sku       = var.vm_sku
    version   = var.vm_version
  }

  boot_diagnostics {
    //enabled = "true"
    storage_account_uri = var.storage_uri
  }

  identity {
    type = "SystemAssigned"
  }

  custom_data = filebase64("../scripts/setupMatchMakerVM.ps1")
}

//do a role assignment for the new system identity
data "azurerm_subscription" "primary" {
}

resource "azurerm_role_assignment" "role_assignment" {
  count                = var.vm_count
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_windows_virtual_machine.vm[count.index].identity[0].principal_id
}

