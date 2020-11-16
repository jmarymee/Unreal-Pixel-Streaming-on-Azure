# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
Set-ExecutionPolicy Bypass -Scope Process -Force

$PixelStreamerFolder = "C:\Unreal\iac\unreal\App\WindowsNoEditor\"
$PixelStreamerExecFile = $PixelStreamerFolder + "ProjectEverywhere.exe"

try {
   New-EventLog -Source PixelStreamer -LogName Application -MessageResourceFile $PixelStreamerExecFile -CategoryResourceFile $PixelStreamerExecFile
}
catch {
   #do nothing, this is ok
}
finally {
   $error.clear()    
}
 
# Script to start the PixelStreamer and VMSS Srevice.
$logsfolder = "c:\gaming\logs"
if (-not (Test-Path -LiteralPath $logsfolder)) {
   Write-Output "creating directory :" + $logsfolder
   $fso = new-object -ComObject scripting.filesystemobject
   if (-not (Test-Path -LiteralPath "C:\gaming")) {
      $fso.CreateFolder("c:\gaming\")
      Write-Output "created gaming folder"
   }
   $fso.CreateFolder($logsfolder)
   Write-EventLog -LogName "Application" -Source "PixelStreamer" -EventID 3100 -EntryType Information -Message "Created logs folder"
}
else {
   Write-Output "Path already exists :" + $logsfolder
   Write-EventLog -LogName "Application" -Source "PixelStreamer" -EventID 3101 -EntryType Information -Message "log folder alredy exists"
}

Set-Alias -Name git -Value "$Env:ProgramFiles\Git\bin\git.exe" -Scope Global
Set-Alias -Name node -Value "$Env:ProgramFiles\nodejs\node.exe" -Scope Global
Set-Alias -Name npm -Value "$Env:ProgramFiles\nodejs\node_modules\npm" -Scope Global

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False

# Creating output files for logs
$logoutput = $logsfolder + '\ue4-startVMSS-output' + (get-date).ToString('MMddyyhhmmss') + '.txt'
$stdout = $logsfolder + '\ue4-signalservice-stdout' + (get-date).ToString('MMddyyhhmmss') + '.txt'
$stderr = $logsfolder + '\ue4-signalservice-stderr' + (get-date).ToString('MMddyyhhmmss') + '.txt'

Set-Content -Path $logoutput -Value "startingVMSS"

if (-not (Test-Path -LiteralPath $PixelStreamerFolder)) {
   $logMessage = "PixelStreamer folder :" + $PixelStreamerFolder + " doesn't exist" 
   Write-EventLog -LogName "Application" -Source "PixelStreamer" -EventID 3102 -EntryType Error -Message $logMessage
   Add-Content -Path $logoutput -Value $logMessage
}

Set-Location -Path $PixelStreamerFolder 
$logMessage = "current folder :" + $PixelStreamerFolder 
Add-Content -Path $logoutput -Value $logMessage

$arg1 = "-AudioMixer"
$arg2 = "-PixelStreamingIP=localhost"
$arg3 = "-PixelStreamingPort=8888"
$arg4 = "-RenderOffScreen"

& $PixelStreamerExecFile $arg1 $arg2 $arg3 $arg4 -ErrorVariable ProcessError
if ($ProcessError) {
   $logMessage = "Error in starting Pixel Streamer"
   Write-EventLog -LogName "Application" -Source "PixelStreamer" -EventID 3102 -EntryType Error -Message "PixelStream Service Failed to Start."
}
else {
   $logMessage = "started :" + $PixelStreamerExecFile  
   Write-EventLog -LogName "Application" -Source "PixelStreamer" -EventID 3103 -EntryType Information -Message "PixelStream Service Started."
}

Add-Content -Path $logoutput -Value $logMessage

$vmServiceFolder = "C:\Unreal\iac\unreal\Engine\Source\Programs\PixelStreaming\WebServers\SignallingWebServer"
if (-not (Test-Path -LiteralPath $vmServiceFolder)) {
   $logMessage = "SignalService folder :" + $vmServiceFolder + " doesn't exist" 
   Write-EventLog -LogName "Application" -Source "PixelStreamer" -EventID 3104 -EntryType Error -Message $logMessage
   Add-Content -Path $logoutput -Value $logMessage
}

Set-Location -Path $vmServiceFolder 
$logMessage = "current folder :" + $vmServiceFolder
Add-Content -Path $logoutput -Value $logMessage

$vmssConfigJson = (Get-Content  "config.json" -Raw) | ConvertFrom-Json
Write-Output $vmssConfigJson
$logMessage = "Config.json :" + $vmssConfigJson
Add-Content -Path $logoutput -Value $logMessage

try {
   $resourceGroup = $vmssConfigJson.resourceGroup
   $vmssName = $vmssConfigJson.virtualMachineScaleSet
    
   $thispublicip = (Invoke-WebRequest -uri "http://ifconfig.me/ip" -UseBasicParsing).Content
   $logMessage = "Public IP Address for lookup of FQDN: " + $thispublicip;
   Add-Content -Path $logoutput -Value $logMessage

   az login --identity
   $json = az vmss list-instance-public-ips -g $resourceGroup -n $vmssName | ConvertFrom-Json
   $vmss = $json | where { $_.ipAddress -eq $thispublicip }
   $fqdn = $vmss.dnsSettings.fqdn
   $env:VMFQDN = $fqdn;
   $logMessage = "Success in getting FQDN: " + $fqdn;
   Add-Content -Path $logoutput -Value $logMessage
}
catch {
   Write-Host "Error getting FQDN: " + $_
   $logMessage = "Error getting FQDN for VM: " + $_
   Add-Content -Path $logoutput -Value $logMessage
}

#need to change this as an exec 
#start-process "cmd.exe" "/c .\runAzure.bat" -ErrorVariable ProcessError
start-process "cmd.exe" "/c .\runAzure.bat"  -RedirectStandardOutput $stdout -RedirectStandardError $stderr -ErrorVariable ProcessError
if ($ProcessError) {
   $logMessage = "Error in starting Signal Service"
   Write-EventLog -LogName "Application" -Source "PixelStreamer" -EventID 3105 -EntryType Error -Message $logMessage
}
else {
   $logMessage = "Started vmss sucessfully runAzure.bat" 
   Write-EventLog -LogName "Application" -Source "PixelStreamer" -EventID 3106 -EntryType Information -Message $logMessage
}
Add-Content -Path $logoutput -Value $logMessage
