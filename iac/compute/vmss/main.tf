variable "base_name" {
  type = string
}

variable "resource_group" {
  description = "The RG VMs"
  type = object({
    id     = string
    location = string
    name   = string
  })
}

variable "vm_publisher" {
  type        = string
}

variable "vm_offer" {
  type        = string
}

variable "vm_sku" {
  type        = string
}

variable "vm_version" {
  type        = string
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

output "id" {
    value = azurerm_windows_virtual_machine_scale_set.vmss.id
}

resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                = var.vm_name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name

  #size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  sku                 = var.sku
  instances           = var.instances

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
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.subnet_id
    }
  }

/* TODO: finish this with the LB work
  rolling_upgrade_policy {
    max_batch_instance_percent              = 21
    max_unhealthy_instance_percent          = 22
    max_unhealthy_upgraded_instance_percent = 23
    pause_time_between_batches              = "PT30S"
  }  
*/
}