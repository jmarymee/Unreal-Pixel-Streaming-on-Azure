// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

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

variable "lb_name" {
    type = string
}
variable "loadbalancer_id" {
    type = string
}
variable "backend_address_pool_id" {
    type = string
}

variable "probe_port" {
    type = string
}
variable "probe_protocol" {
    type = string
}
variable "load_distribution" {
    type = string
}
variable "rule_frontend_ip_configuration_name" {
    type = string
}
variable "rule_protocol" {
    type = string
}
variable "rule_frontend_port" {
    type = string
}
variable "rule_backend_port" {
    type = string
}

resource "azurerm_lb_probe" "probe" {
  name                = format("%s-%s-lb-probe-%s", var.base_name, var.lb_name, var.probe_port)
  resource_group_name = var.resource_group.name
  loadbalancer_id     = var.loadbalancer_id
  port                = var.probe_port
  protocol            = var.probe_protocol
}

resource "azurerm_lb_rule" "lb_rule" {
  name                           = format("%s-%s-lb-rule-%s", var.base_name, var.lb_name, var.probe_port)
  resource_group_name            = var.resource_group.name
  loadbalancer_id                = var.loadbalancer_id
  probe_id                       = azurerm_lb_probe.probe.id
  backend_address_pool_id        = var.backend_address_pool_id
  frontend_ip_configuration_name = var.rule_frontend_ip_configuration_name
  protocol                       = var.rule_protocol
  frontend_port                  = var.rule_frontend_port
  backend_port                   = var.rule_backend_port
  load_distribution              = var.load_distribution
}