// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

data "azurerm_client_config" "current" {}

variable "base_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "service_principal_object_id" {
  type = string
}

variable "git-pat" {
  type = string
}

output "key_vault_id" {
  value = azurerm_key_vault.akv.id
}

resource "azurerm_key_vault" "akv" {
  name                = format("akv-%s-%s", var.base_name, var.location)
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"

  #   sku {
  #     name = "premium"
  #   }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = var.service_principal_object_id

    key_permissions = [
      "create",
      "get",
    ]

    secret_permissions = [
      "set",
      "get",
      "delete",
    ]
  }
}

resource "azurerm_key_vault_secret" "pat_secret" {
  name         = "git-pat"
  value        = var.git-pat
  key_vault_id = azurerm_key_vault.akv.id
}

