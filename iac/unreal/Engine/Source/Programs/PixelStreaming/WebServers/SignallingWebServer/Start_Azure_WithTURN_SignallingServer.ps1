# Copyright 1998-2018 Epic Games, Inc. All Rights Reserved.
Set-Alias -Name git -Value "$Env:ProgramFiles\Git\bin\git.exe" -Scope Global
Set-Alias -Name node -Value "$Env:ProgramFiles\nodejs\node.exe" -Scope Global
Set-Alias -Name npm -Value "$Env:ProgramFiles\nodejs\node_modules\npm" -Scope Global

if ($env:VMFQDN) {
    $PublicIp = $env:VMFQDN
}
else {
    $PublicIp = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content
}

Write-Output "Public IP: $PublicIp"

$peerConnectionOptions = "{ \""iceServers\"": [{\""urls\"": [\""stun:stun.l.google.com:19302\"",\""turn:" + $PublicIp + ":19303\""], \""username\"": \""{{{TURN_LOGIN}}}\"", \""credential\"": \""{{{TURN_PASSWORD}}}\""}] }"

$ProcessExe = "node.exe"
$Arguments = @("cirrus", "--peerConnectionOptions=""$peerConnectionOptions""", "--publicIp=$PublicIp")
# Add arguments passed to script to Arguments for executable
$Arguments += $args

Write-Output "Running: $ProcessExe $Arguments"
Start-Process -FilePath $ProcessExe -ArgumentList $Arguments -Wait -NoNewWindow
