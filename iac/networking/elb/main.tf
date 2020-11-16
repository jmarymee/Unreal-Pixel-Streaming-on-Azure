// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

//implement an external load balancer to put in front of the matchmaker vm for future growth
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

variable "lb_name" {
  type = string
}

variable "nat_pool_frontend_port_start" {
  type = string
}

variable "nat_pool_frontend_port_end" {
  type = string
}

variable "nat_pool_backend_port" {
  type = string
}

variable "domain_name_label" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "sku" {
  type = string
}

variable "private_ip_address" {
  type = string
}

variable "private_ip_address_allocation" {
  type = string
}

output "lb_id" {
  value = azurerm_lb.lb.id
}

output "lb_nat_pool_id" {
  value = azurerm_lb_nat_pool.lb_nat_pool.id
}

output "lb_backend_address_pool_id" {
  value = azurerm_lb_backend_address_pool.lb_backend_address_pool.id
}

output "health_probe_id" {
  value = azurerm_lb_probe.probe.id
}

output "fqdn" {
  value = azurerm_public_ip.pip.fqdn
}

resource "azurerm_public_ip" "pip" {
  name                = format("%s-%s-lb-pip", var.base_name, var.lb_name)
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  allocation_method   = "Static"
  domain_name_label   = var.domain_name_label
  sku                 = "Standard"
}

resource "azurerm_lb" "lb" {
  name                = format("%s-%s-lb", var.base_name, var.lb_name)
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  sku                 = var.sku

  frontend_ip_configuration {
    name                 = "external"
    public_ip_address_id = azurerm_public_ip.pip.id
    #subnet_id = var.subnet_id
    #private_ip_address = var.private_ip_address
    #private_ip_address_allocation = var.private_ip_address_allocation
  }
}

resource "azurerm_lb_backend_address_pool" "lb_backend_address_pool" {
  name                = format("%s-%s-backend-pool", var.base_name, var.lb_name)
  resource_group_name = var.resource_group.name
  loadbalancer_id     = azurerm_lb.lb.id
}

resource "azurerm_lb_nat_pool" "lb_nat_pool" {
  name                           = format("%s-%s-nat-pool", var.base_name, var.lb_name)
  resource_group_name            = var.resource_group.name
  loadbalancer_id                = azurerm_lb.lb.id
  frontend_ip_configuration_name = "external"
  protocol                       = "Tcp"
  frontend_port_start            = var.nat_pool_frontend_port_start
  frontend_port_end              = var.nat_pool_frontend_port_end
  backend_port                   = var.nat_pool_backend_port
}

#change this port at some point
resource "azurerm_lb_probe" "probe" {
  name                = format("%s-%s-lb-probe", var.base_name, var.lb_name)
  resource_group_name = var.resource_group.name
  loadbalancer_id     = azurerm_lb.lb.id
  port                = 3389
  protocol            = "Tcp"
}

resource "azurerm_lb_rule" "lb_rule" {
  name                           = format("%s-%s-lb-rule", var.base_name, var.lb_name)
  resource_group_name            = var.resource_group.name
  loadbalancer_id                = azurerm_lb.lb.id
  probe_id                       = azurerm_lb_probe.probe.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.lb_backend_address_pool.id
  frontend_ip_configuration_name = "external"
  protocol                       = "Tcp"
  frontend_port                  = 3389
  backend_port                   = 3389
}
