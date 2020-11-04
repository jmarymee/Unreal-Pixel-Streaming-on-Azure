Param (
  [Parameter(Mandatory = $True, HelpMessage = "subscription id from terraform")]
  [String]$subscription_id = "",
  [Parameter(Mandatory = $True, HelpMessage = "resource group name")]
  [String]$resource_group_name = "",
  [Parameter(Mandatory = $True, HelpMessage = "vmss name")]
  [String]$vmss_name = "",
  [Parameter(Mandatory = $True, HelpMessage = "application insights key")]
  [String]$application_insights_key = ""
)

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco upgrade filezilla git nodejs vcredist-all directx -y --no-progress

Set-Alias -Name git -Value "$Env:ProgramFiles\Git\bin\git.exe"

New-NetFirewallRule -DisplayName 'Matchmaker-IB-90' -Profile 'Private' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 90
New-NetFirewallRule -DisplayName 'Matchmaker-IB-9999' -Profile 'Private' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 9999

New-NetFirewallRule -DisplayName 'Matchmaker-OB-80' -Profile 'Private' -Direction Outbound -Action Allow -Protocol TCP -LocalPort 80
New-NetFirewallRule -DisplayName 'Matchmaker-OB-7070' -Profile 'Private' -Direction Outbound -Action Allow -Protocol TCP -LocalPort 7070
New-NetFirewallRule -DisplayName 'Matchmaker-OB-8888' -Profile 'Private' -Direction Outbound -Action Allow -Protocol TCP -LocalPort 8888
New-NetFirewallRule -DisplayName 'Matchmaker-OB-8889' -Profile 'Private' -Direction Outbound -Action Allow -Protocol TCP -LocalPort 8889
New-NetFirewallRule -DisplayName 'Matchmaker-OB-19302' -Profile 'Private' -Direction Outbound -Action Allow -Protocol TCP -LocalPort 19302
New-NetFirewallRule -DisplayName 'Matchmaker-OB-19303' -Profile 'Private' -Direction Outbound -Action Allow -Protocol TCP -LocalPort 19303

#export GITHUB_USER=anonuser
#export GITHUB_TOKEN=(az keyvault secret show -n thekey --vault-name uegamingakv | ConvertFrom-Json).value
#export GITHUB_REPOSITORY=Azure/Unreal-Pixel-Streaming-on-Azure

$folder = "c:\Unreal\"
if (-not (Test-Path -LiteralPath $folder)) {
  git clone -q https://github.com/Azure/Unreal-Pixel-Streaming-on-Azure.git $folder
  #git clone -q https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY} $folder
}
else {
  #rename the existing folder
  $endtag = 'unreal-' + (get-date).ToString('MMddyyhhmmss')
  Rename-Item -Path $folder  -NewName $endtag -Force
  git clone -q https://github.com/Azure/Unreal-Pixel-Streaming-on-Azure.git $folder
  #git clone -q https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY} $folder
}

#test:
$logoutput = $folder + 'mm-output-' + (get-date).ToString('MMddyyhhmmss') + '.txt'
Set-Content -Path $logoutput -Value $subscription_id
Add-Content -Path $logoutput -Value $resource_group_name
Add-Content -Path $logoutput -Value $vmss_name
Add-Content -Path $logoutput -Value $application_insights_key

$mmServiceFolder = "C:\Unreal\iac\unreal\Engine\Source\Programs\PixelStreaming\WebServers\Matchmaker"
cd $mmServiceFolder 
#$RunMMService = ".\run.bat"

#& $RunMMService

#need to change this as an exec 
start-process "cmd.exe" "/c .\run.bat"

