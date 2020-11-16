variable "virtual_machine_ids" {
  type = list(object({ id = string }))
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

resource "azurerm_virtual_machine_extension" "InGuestDiagnostics" {
  count                      = length(var.virtual_machine_ids)
  name                       = var.extension_name
  virtual_machine_id         = var.virtual_machine_ids[count.index].id
  publisher                  = "Microsoft.Azure.Diagnostics"
  type                       = "IaaSDiagnostics"
  type_handler_version       = "1.5"
  auto_upgrade_minor_version = true

  settings           = <<SETTINGS
    {
        "StorageAccount": "${var.storage_account_name}",
        "WadCfg": {
            "DiagnosticMonitorConfiguration": {
                "overallQuotaInMB": 10000,
                "DiagnosticInfrastructureLogs": {
                    "scheduledTransferLogLevelFilter": "Error"
                },
                "PerformanceCounters": {
                    "scheduledTransferPeriod": "PT1M",
                    "sinks": "AzureMonitorSink",
                    "PerformanceCounterConfiguration": [
                        {
                            "counterSpecifier": "\\Processor(_Total)\\% Processor Time",
                            "sampleRate": "PT1M",
                            "unit": "percent"
                        }
                    ]
                },
                "WindowsEventLog": {
                    "scheduledTransferPeriod": "PT5M",
                    "DataSource": [
                        {
                            "name": "System!*[System[(Level = 1 or Level = 2)]]"
                        },
                        {
                            "name": "Security!*[System[(Level = 1 or Level = 2)]]"
                        },
                        {
                            "name": "Application!*[System[(Level = 1 or Level = 2)]]"
                        }
                    ]
                }
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

/*
resource "azurerm_virtual_machine_extension" "Diagnosticsettings" {
  count                = "${var.do_bootstrap == true ? 1 : 0}"
  name                 = "vmext-Diag-${var.vm_hostname}"
  location             = "${var.location}"
  resource_group_name  = "${var.rg_name}"
  virtual_machine_name = "${azurerm_virtual_machine.windows-vm.name}"
  publisher            = "Microsoft.Azure.Diagnostics"
  type                 = "IaaSDiagnostics"
  type_handler_version = "1.9"
 
  settings = <<SETTINGS
    {
        "xmlCfg": "${base64encode(var.monitoring-template)}",
        "storageAccount": "${var.storage_name}"
    }
SETTINGS
 
  protected_settings = <<SETTINGS
    {
        "storageAccountName": "${var.storage_name}",
        "storageAccountKey":  "${var.storage_key}"
    }
SETTINGS
 
  tags = {
    environment = "${var.environment}"
    role = "${var.role}"
  }
}*/


/*
  settings           = <<SETTINGS
    {
      "xmlCfg": "${base64encode(templatefile("${path.module}/templates/wadcfgxml.tmpl", { vmid = azurerm_virtual_machine.Compute.id }))}",
      "storageAccount": "${data.azurerm_storage_account.InGuestDiagStorageAccount.name}"
    }
SETTINGS
  protected_settings = <<PROTECTEDSETTINGS
    {
      "storageAccountName": "${data.azurerm_storage_account.InGuestDiagStorageAccount.name}",
      "storageAccountKey": "${data.azurerm_storage_account.InGuestDiagStorageAccount.primary_access_key}",
      "storageAccountEndPoint": "https://core.windows.net"
    }
PROTECTEDSETTINGS
*/
