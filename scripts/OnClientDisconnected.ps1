# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

# This is optionally used by a pixel streaming app to reset the UE4 exe when a user disconnects

#Change name for the process to your executable name
$processes = Get-Process ProjectEverywhere 
$processes.Count
if($processes.Count -gt 0)
{
    $path = $processes[0].Path
    $procID = $processes[0].Id
    $cmdline = (Get-WMIObject Win32_Process -Filter "Handle=$procID").CommandLine

    write-host "Restarting UE4 app: " + $processes[0].MainWindowTitle
    write-host "Command Line: " + $cmdline
    
    $processes[0].Kill()
    $processes[0].WaitForExit()
    
    Start-Sleep -s 1

    Start-Process -FilePath $path -ArgumentList $cmdline.Split(' ')[1]}
else
{
    write-host "ProjectEverywhere not running when trying to restart"
}