#Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.
Param (
  [Parameter(Mandatory = $True, HelpMessage = "subscription id from terraform")]
  [String]$subscription_id = "",
  [Parameter(Mandatory = $True, HelpMessage = "resource group name")]
  [String]$resource_group_name = "",
  [Parameter(Mandatory = $True, HelpMessage = "vmss name")]
  [String]$vmss_name = "",  
  [Parameter(Mandatory = $True, HelpMessage = "application insights key")]
  [String]$application_insights_key = "",
  [Parameter(Mandatory = $True, HelpMessage = "matchmaker load balancer fqdn")]
  [String]$mm_lb_fqdn = "",
  [Parameter(Mandatory = $True, HelpMessage = "Specify the password for the <run as> user.")]
  [String]$admin_password = "",  
  [Parameter(Mandatory = $False, HelpMessage = "github personal access token")]
  [String]$pat = ""
)

#set the base github path for the unreal code
$gitpath = "https://github.com/Azure/Unreal-Pixel-Streaming-on-Azure.git"

#handle if a Personal Access Token is being passed
if ($pat.Length -gt 0) {
  #handle if a PAT was passed and use that in the url
  $gitpath = "https://" + $pat + "@github.com/Azure/Unreal-Pixel-Streaming-on-Azure.git"
}

$logsfolder = "c:\gaming\logs"
if (-not (Test-Path -LiteralPath $logsfolder)) {
  Write-Output "creating directory :" + $logsfolder
  $fso = new-object -ComObject scripting.filesystemobject
  if (-not (Test-Path -LiteralPath "C:\gaming")) {
    $fso.CreateFolder("c:\gaming\")
    Write-Output "created gaming folder"
  }
  $fso.CreateFolder($logsfolder)
}
else {
  Write-Output "Path already exists :" + $logsfolder
}

$logoutput = $logsfolder + '\ue4-setupVMSS-output-' + (get-date).ToString('MMddyyhhmmss') + '.txt'
Write-Output $logoutput

$logmessage = "Starting at: " + (get-date).ToString('hh:mm:ss')
Add-Content -Path $logoutput -Value $logmessage

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
Set-ExecutionPolicy Bypass -Scope Process -Force

$logmessage = "Downloading Chocolatey"
Add-Content -Path $logoutput -Value $logmessage

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

$logmessage = "Downloading Chocolatey complete"
Add-Content -Path $logoutput -Value $logmessage

$logmessage = "Installing prerequisites"
Add-Content -Path $logoutput -Value $logmessage

$logmessage = "Installing Azure CLI"
Add-Content -Path $logoutput -Value $logmessage

choco upgrade git nodejs vcredist2017 directx azure-cli -y --no-progress
Set-Alias -Name git -Value "$Env:ProgramFiles\Git\bin\git.exe" -Scope Global
Set-Alias -Name node -Value "$Env:ProgramFiles\nodejs\node.exe" -Scope Global
Set-Alias -Name npm -Value "$Env:ProgramFiles\nodejs\node_modules\npm" -Scope Global

$INCLUDE = "C:\Program Files\nodejs;C:\Program Files (x86)\Microsoft SDKs\Azure"

$OLDPATH = [System.Environment]::GetEnvironmentVariable('PATH', 'machine')
$NEWPATH = "$OLDPATH;$INCLUDE"
[Environment]::SetEnvironmentVariable("PATH", "$NEWPATH", "Machine")

$logmessage = "Refreshing env"
Add-Content -Path $logoutput -Value $logmessage

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
refreshenv

$logmessage = "Refreshing env complete"
Add-Content -Path $logoutput -Value $logmessage

$logmessage = "Installing prerequisites complete"
Add-Content -Path $logoutput -Value $logmessage

#sleep for 45 seconds to wait for install processes to complete
Start-Sleep -s 45

$logmessage = "Disabling Windows Firewalls"
Add-Content -Path $logoutput -Value $logmessage
#Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\services\SharedAccess\Parameters\FirewallPolicy\DomainProfile' -name "EnableFirewall" -Value 0
#Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\services\SharedAccess\Parameters\FirewallPolicy\PublicProfile' -name "EnableFirewall" -Value 0
#Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\services\SharedAccess\Parameters\FirewallPolicy\Standardprofile' -name "EnableFirewall" -Value 0 

Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False

#check if the disable of the firewall was successful, if not write an event to the event log
[string]$Domain = Invoke-command { netsh advfirewall show domain state }
[string]$Private = Invoke-command { netsh advfirewall show private state }
[string]$Public = Invoke-command { netsh advfirewall show public state }

$endsInOn = ($Domain.Contains("ON") -or $Private.Contains("ON") -or $Public.Contains("ON"));
if ($endsInOn) {
  #log the error
  $logmessage = "Disabling Windows Firewalls ***Failed***"
  Add-Content -Path $logoutput -Value $logmessage

  #event log the error
  Write-EventLog -LogName "Application" -Source "PixelStreamer" -EventID 3109 -EntryType Error -Message $logmessage
}

$logmessage = "Disabling Windows Firewalls complete"
Add-Content -Path $logoutput -Value $logmessage

$logmessage = "Cloning the github repo"
Add-Content -Path $logoutput -Value $logmessage

$folder = "c:\Unreal\"
if (-not (Test-Path -LiteralPath $folder)) {
  $logmessage = $folder + "doesn't exist. Adding."
  Add-Content -Path $logoutput -Value $logmessage
  git clone -q $gitpath $folder
}
else {
  #rename the existing folder if exists
  $logmessage = $folder + " already exists. Renaming."
  Add-Content -Path $logoutput -Value $logmessage

  $endtag = 'unreal-' + (get-date).ToString('MMddyyhhmmss')
  try {
    Rename-Item -Path $folder  -NewName $endtag -Force
  }
  catch {
    $logmessage = $_.Exception.Message
    Write-Output $logmessage
    Add-Content -Path $logoutput -Value $logmessage
  }
  finally {
    $error.clear()
  }
  git clone -q $gitpath $folder
}

$logmessage = "Cloning the github repo complete"
Add-Content -Path $logoutput -Value $logmessage

$logmessage = "Downloading WindowsNoEditor binaries from blob storage"
Add-Content -Path $logoutput -Value $logmessage

Invoke-WebRequest https://unrealbackendfiles.blob.core.windows.net/ourpublicblobs/WindowsNoEditor_ProjectEverywhere.zip -OutFile C:\WindowsNoEditor.zip

$logmessage = "Downloading WindowsNoEditor binaries from blob storage complete"
Add-Content -Path $logoutput -Value $logmessage

$blobDestination = $folder + 'iac\unreal\app'
$zipFileName = 'C:\WindowsNoEditor.zip'

$logmessage = "Extracting WindowsNoEditor to " + $blobDestination
Add-Content -Path $logoutput -Value $logmessage
Expand-Archive -LiteralPath $zipFileName -DestinationPath $blobDestination -force

$logmessage = "Extracting WindowsNoEditor Complete"
Add-Content -Path $logoutput -Value $logmessage

try{
  $scriptfile = $folder + 'scripts\OnClientDisconnected.ps1'
  $logmessage = "Copying OnClientDisconnected :" + $scriptfile
  Add-Content -Path $logoutput -Value $logmessage
  $destFolder =  $folder + 'iac\unreal\app\WindowsNoEditor\ProjectEveryWhere'
  Copy-Item $scriptfile $destFolder
  $logmessage = "Copying OnClientDisconnected Complete"
  Add-Content -Path $logoutput -Value $logmessage
}
catch{
  $logmessage = $_.Exception.Message
  Write-Output $logmessage
  Add-Content -Path $logoutput -Value $logmessage
}
finally {
  $error.clear()
}

$vmServiceFolder = "C:\Unreal\iac\unreal\Engine\Source\Programs\PixelStreaming\WebServers\SignallingWebServer"
Set-Location -Path $vmServiceFolder 

$logmessage = "Current folder " + $vmServiceFolder
Add-Content -Path $logoutput -Value $logmessage


$logmessage = "Writing paramters from extension " + $vmServiceFolder
Add-Content -Path $logoutput -Value $logmessage

$vmssConfigJson = (Get-Content  "config.json" -Raw) | ConvertFrom-Json
Write-Output $vmssConfigJson

$logMessage = "current config :" + $vmssConfigJson
Add-Content -Path $logoutput -Value $logMessage

$vmssConfigJson.resourceGroup = $resource_group_name
$vmssConfigJson.subscriptionId = $subscription_id
$vmssConfigJson.virtualMachineScaleSet = $vmss_name
$vmssConfigJson.appInsightsId = $application_insights_key
$vmssConfigJson.matchmakerAddress = $mm_lb_fqdn
$vmssConfigJson.publicIp = $thispublicip

$vmssConfigJson | ConvertTo-Json | set-content "config.json"
$vmssConfigJson = (Get-Content  "config.json" -Raw) | ConvertFrom-Json
Write-Output $vmssConfigJson

$logMessage = "Writing parameters from extension complete. Updated config :" + $vmssConfigJson
Add-Content -Path $logoutput -Value $logMessage

$logmessage = "Creating a job schedule "
Add-Content -Path $logoutput -Value $logmessage

#$User = "azureadmin"
#$PWord = ConvertTo-SecureString -String $admin_password -AsPlainText -Force
#$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

$filePath = "C:\Unreal\scripts\startVMSS.ps1"
$trigger = New-JobTrigger -AtStartup -RandomDelay 00:00:10
try {
  #Register-ScheduledJob -Trigger $trigger -FilePath $filePath -Name "StartVMSS" -Credential $Cred
  $User = "azureadmin"
  $PS = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-executionpolicy bypass -noprofile -file $filePath"
  Register-ScheduledTask -Trigger $trigger -User $User -TaskName "StartVMSS" -Action $PS -RunLevel Highest -Force
}
catch {
  $logmessage = "Exception: " + $_.Exception
  Write-Output $logmessage
  Add-Content -Path $logoutput -Value $logmessage
}
finally {
  $error.clear()    
}

$logmessage = "Creating a job schedule complete"
Add-Content -Path $logoutput -Value $logmessage

$logmessage = "Starting the VMSS Process "
Add-Content -Path $logoutput -Value $logmessage

#invoke the script to start it this time
Set-ExecutionPolicy Bypass -Scope CurrentUser -Force
#Start-ScheduledTask -TaskName "StartVMSS" -AsJob
Invoke-Expression -Command $filePath

$logmessage = "Completed at: " + (get-date).ToString('hh:mm:ss')
Add-Content -Path $logoutput -Value $logmessage
