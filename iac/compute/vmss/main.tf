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

variable "sku" {
  type = string
}

variable "instances" {
  type = string
}

variable "upgrade_mode" {
  type = string
}

variable "lb_backend_address_pool_id" {
  type = string
}

variable "lb_nat_pool_id" {
  type = string
}

variable "health_probe_id" {
  type = string
}

variable "network_security_group_id" {
  type = string
}

output "id" {
  value = azurerm_windows_virtual_machine_scale_set.vmss.id
}

output "name" {
  value = azurerm_windows_virtual_machine_scale_set.vmss.name
}

resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                = var.vm_name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name

  admin_username = var.admin_username
  admin_password = var.admin_password

  sku       = var.sku
  instances = var.instances

  health_probe_id = var.health_probe_id
  upgrade_mode    = var.upgrade_mode

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = var.vm_publisher
    offer     = var.vm_offer
    sku       = var.vm_sku
    version   = var.vm_version
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name                      = format("vmss-nic-%s", lower(var.resource_group.location))
    primary                   = true
    network_security_group_id = var.network_security_group_id

    ip_configuration {
      name                                   = "external"
      primary                                = true
      subnet_id                              = var.subnet_id
      load_balancer_backend_address_pool_ids = [var.lb_backend_address_pool_id]
      load_balancer_inbound_nat_rules_ids    = [var.lb_nat_pool_id]

      public_ip_address {
        name              = "vmss_public_ip"
        domain_name_label = lower(format("%s-%s", "vmss", var.base_name))
      }
    }
  }
  custom_data = filebase64("../scripts/setupBackendVMSS.ps1")
}

//do a role assignment for the new system identity
data "azurerm_subscription" "primary" {
}

resource "azurerm_role_assignment" "role_assignment" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_windows_virtual_machine_scale_set.vmss.identity[0].principal_id
}
