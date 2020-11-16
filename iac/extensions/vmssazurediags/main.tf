// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

variable "virtual_machine_scale_set_id" {
  type = string
}

variable "extension_name" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "storage_account_key" {
  type = string
}

variable "storage_account_endpoint" {
  type = string
}

resource "azurerm_virtual_machine_scale_set_extension" "VMSS-Diagnostics" {
  name                         = var.extension_name
  virtual_machine_scale_set_id = var.virtual_machine_scale_set_id
  publisher                    = "Microsoft.Azure.Diagnostics"
  type                         = "IaaSDiagnostics"
  type_handler_version         = "1.5"
  auto_upgrade_minor_version   = true

  settings           = <<SETTINGS
    {
        "StorageAccount": "${var.storage_account_name}",
        "WadCfg": {
            "DiagnosticMonitorConfiguration": {
                "overallQuotaInMB": 4096,
                "DiagnosticInfrastructureLogs": {
                    "scheduledTransferLogLevelFilter": "Verbose"
                },
                "PerformanceCounters": {
                    "scheduledTransferPeriod": "PT1M",
                    "sinks": "AzureMonitorSink",
                    "PerformanceCounterConfiguration": [
                        {
                            "counterSpecifier": "\\Processor(_Total)\\% Processor Time",
                            "sampleRate": "PT1M",
                            "unit": "percent"
                        },
                        {
                            "counterSpecifier":"\\Memory\\Available Bytes",
                            "sampleRate":"PT15S",
                            "unit": "Bytes"
                        }
                    ]
                },
                "WindowsEventLog": {
                    "scheduledTransferPeriod": "PT1M",
                    "DataSource": [
                        {
                            "name": "Application!*[System[(Level=1 or Level=2 or Level=3)]]"
                        },
                        {
                            "name": "System!*[System[(Level=1 or Level=2 or Level=3)]]"
                        },
                        {
                            "name": "Security!*[System[(Level=1 or Level=2 or Level=3)]]"
                        }
                    ]
                },
                "Logs": {
                    "scheduledTransferPeriod": "PT1M",
                    "scheduledTransferLogLevelFilter": "Verbose"
                }
            },
            "SinksConfig": {
                "Sink": [
                    {
                        "name": "AzureMonitorSink",
                        "AzureMonitor":
                        {
                          
                        }
                    }]
            }
        }
    }
    SETTINGS
  protected_settings = <<PROTECTED_SETTINGS
    {
        "storageAccountName": "${var.storage_account_name}",
        "storageAccountSasToken": "${var.storage_account_key}"
    }
    PROTECTED_SETTINGS
}
