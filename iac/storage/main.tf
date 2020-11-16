// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

## variables
variable "base_name" {
  description = "Base name to use for the resources"
  type        = string
}

variable "resource_group" {
  description = "The RG for the storage account"
  type = object({
    id       = string
    location = string
    name     = string
  })
}

variable "account_tier" {
  type = string
}

variable "account_replication_type" {
  type = string
}

variable "index" {
  type = string
}

## outputs
output "id" {
  value = azurerm_storage_account.storageaccount.id
}

output "uri" {
  value = azurerm_storage_account.storageaccount.primary_blob_endpoint
}

output "name" {
  value = azurerm_storage_account.storageaccount.name
}

output "key" {
  value = azurerm_storage_account.storageaccount.primary_access_key
}

## locals
locals {
  base_name = var.base_name
}

## resources
resource "azurerm_storage_account" "storageaccount" {
  name                     = format("%sue4storacctformm00%s", var.base_name, var.index)
  resource_group_name      = var.resource_group.name
  location                 = var.resource_group.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
}
