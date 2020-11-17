# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
Set-ExecutionPolicy Bypass -Scope Process -Force

#this is to set up the event log
$PixelStreamerFolder = "C:\Unreal\iac\unreal\App\WindowsNoEditor\"
$PixelStreamerExecFile = $PixelStreamerFolder + "PixelStreamer.exe"
try {
    New-EventLog -Source PixelStreamer -LogName Application -MessageResourceFile $PixelStreamerExecFile -CategoryResourceFile $PixelStreamerExecFile
}
catch {
    $logmessage = $_.Exception.Message
    Write-Output $logmessage
}
finally {
    $error.clear()    
}

# Script to start the MMService on startup
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

Set-Alias -Name git -Value "$Env:ProgramFiles\Git\bin\git.exe" -Scope Global
Set-Alias -Name node -Value "$Env:ProgramFiles\nodejs\node.exe" -Scope Global
Set-Alias -Name npm -Value "$Env:ProgramFiles\nodejs\node_modules\npm" -Scope Global

#$INCLUDE = "C:\Program Files\nodejs;C:\Program Files (x86)\Microsoft SDKs\Azure"

#$OLDPATH = [System.Environment]::GetEnvironmentVariable('PATH', 'machine')
#$NEWPATH = "$OLDPATH;$INCLUDE"
#[Environment]::SetEnvironmentVariable("PATH", "$NEWPATH", "Machine")

$logmessage = "Refreshing env"
Add-Content -Path $logoutput -Value $logmessage

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
refreshenv

$logmessage = "Refreshing env complete"
Add-Content -Path $logoutput -Value $logmessage


$logoutput = $logsfolder + '\ue4-startMMS-output' + (get-date).ToString('MMddyyhhmmss') + '.txt'
$stdout = $logsfolder + '\ue4-startMMS-stdout' + (get-date).ToString('MMddyyhhmmss') + '.txt'
$stderr = $logsfolder + '\ue4-startMMS-stderr' + (get-date).ToString('MMddyyhhmmss') + '.txt'

$logMessage = "startingMMS"
Set-Content -Path $logoutput -Value $logMessage
Write-EventLog -LogName "Application" -Source "PixelStreamer" -EventID 3201 -EntryType Information -Message $logMessage

$mmServiceFolder = "C:\Unreal\iac\unreal\Engine\Source\Programs\PixelStreaming\WebServers\Matchmaker"

if (-not (Test-Path -LiteralPath $mmServiceFolder)) {
    $logMessage = "PixelStreamer folder :" + $mmServiceFolder + " doesn't exist" 
    Write-EventLog -LogName "Application" -Source "PixelStreamer" -EventID 3202 -EntryType Error -Message $logMessage
    Add-Content -Path $logoutput -Value $logMessage
}

Set-Location -Path $mmServiceFolder 

#can we add a test to verify that the mmservice folder exists, if not, throw an event-log exception?

$mmConfigJson = (Get-Content  "config.json" -Raw) | ConvertFrom-Json
Write-Output $mmConfigJson
$logMessage = "Config.json :" + $mmConfigJson
Add-Content -Path $logoutput -Value $logMessage

$logMessage = "Starting the process run.bat"
Add-Content -Path $logoutput -Value $logMessage

#can we run this as a process and capture the execution status? Then throw an error to the event log if it fails. 
start-process "cmd.exe" "/c .\run.bat" -RedirectStandardOutput $stdout -RedirectStandardError $stderr -ErrorVariable ProcessError
if ($ProcessError) {
    $logMessage = "Error in starting MatchMaker Service"
    Write-Output $logMessage
    Write-EventLog -LogName "Application" -Source "PixelStreamer" -EventID 3105 -EntryType Error -Message $logMessage
}
else {
    $logMessage = "Started MatchMaker sucessfully run.bat" 
    Write-EventLog -LogName "Application" -Source "PixelStreamer" -EventID 3106 -EntryType Information -Message $logMessage
}

$logMessage = "MatchMaker Service started"
Add-Content -Path $logoutput -Value $logMessage

