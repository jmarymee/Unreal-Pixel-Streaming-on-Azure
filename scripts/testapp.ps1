function testmm() {

    Write-Output ""
    Write-Output "----------------------------------"
    Write-Output "Running the MatchMaker Test Script"
    Write-Output "----------------------------------"
    Write-Output "Date/Time (UTC): " + (get-date).ToString('MM/dd/yy hh:mm:ss')
    Write-Output ""

    #what is this machine information
    #name
    $thiscomputername = $env:computername
    Write-Output "Computer Name: " + $thiscomputername

    #ip
    $thisprivateip = (Test-Connection -ComputerName (hostname) -Count 1).IPV4Address.IPAddressToString
    Write-Output "IP Address: " + $thisprivateip

    #public ip
    $thispublicip = (Invoke-WebRequest -uri "http://ifconfig.me/ip" -UseBasicParsing).Content
    Write-Output "Public IP Address: " + $thispublicip

    #OSVersion
    $OSVersion = (get-itemproperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName
    Write-Output "OS Version: " $OSVersion
    
    #validate folders
    Write-Output ""
    Write-Output "Validating folders: "

    $mmBaseFolder = "C:\Unreal\iac\unreal\"
    $mmWindowsNoEditorFolder = "C:\Unreal\iac\unreal\App\WindowsNoEditor\"
    $mmLogsFolder = "c:\gaming\logs"

    if (-not (Test-Path -LiteralPath $mmBaseFolder)) {
        Write-Output $mmBaseFolder + " does not exist"
    }
    else {
        Write-Output $mmBaseFolder + " exists as expected."
    }

    if (-not (Test-Path -LiteralPath $mmLogsFolder)) {
        Write-Output $mmLogsFolder + " does not exist."
    }
    else {
        Write-Output $mmLogsFolder + " exists as expected."
    }    

    if (-not (Test-Path -LiteralPath $mmWindowsNoEditorFolder)) {
        Write-Output $mmWindowsNoEditorFolder + " does not exist"
    }
    else {
        Write-Output $mmWindowsNoEditorFolder + " exists as expected."
    }    

    #validate aliases

    #validate paths

    #check the elements in the config.json

    #check the process id of the node service
    Write-Output ""
    Write-Output "Process Information:"
    Write-Output ""

    $node = Get-Process | Where-Object { $_.Name -eq "node" } | Format-List $_.ID
    Write-Output "Node: " + $node

    Write-Output ""
    Write-Output "Firewall Port Enabled Check:"

    Write-Output "todo..."

    #validate listensing on ports for: 90 and 9999
    $NetworkProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
    $TcpConnections = $NetworkProperties.GetActiveTcpConnections()

    Write-Output ""
    Write-Output "Listening Ports:"

    Write-Output $TcpConnections | Select-Object -Exp LocalEndpoint | Where-Object { $_.Port -eq "3389" }
    Write-Output $TcpConnections | Select-Object -Exp LocalEndpoint | Where-Object { $_.Port -eq "90" }
    Write-Output $TcpConnections | Select-Object -Exp LocalEndpoint | Where-Object { $_.Port -eq "9999" }

    #get config file
    $mmServiceFolder = "C:\Unreal\iac\unreal\Engine\Source\Programs\PixelStreaming\WebServers\Matchmaker"
    Set-Location -Path $mmServiceFolder 
    $vmssConfigJson = (Get-Content  "config.json" -Raw) | ConvertFrom-Json
    Write-Output ""
    Write-Output "Json Config:"
    Write-Output $vmssConfigJson 

    Write-Output ""
    Write-Output "Check Status of Scheduled Task:"
    Get-ScheduledTask -TaskName "StartMMS"

    #Open the log files
    
}

function testbe() {

    #testing what needs to be true
    Write-Output ""
    Write-Output "----------------------------------"
    Write-Output "Running the Backend Test Script"
    Write-Output "----------------------------------"
    Write-Output "Date/Time (UTC): " + (get-date).ToString('MM/dd/yy hh:mm:ss')
    Write-Output ""

    #what is this machine information
    #name
    $thiscomputername = $env:computername
    Write-Output "Computer Name: " + $thiscomputername

    #ip
    $thisprivateip = (Test-Connection -ComputerName (hostname) -Count 1).IPV4Address.IPAddressToString
    Write-Output "IP Address: " + $thisprivateip

    #public ip
    $thispublicip = (Invoke-WebRequest -uri "http://ifconfig.me/ip" -UseBasicParsing).Content
    Write-Output "Public IP Address: " + $thispublicip

    #OSVersion
    $OSVersion = (get-itemproperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName
    Write-Output "OS Version: " $OSVersion

    #validate folders
    Write-Output ""
    Write-Output "Validating folders: "

    $ue4LogsFolder = "c:\gaming\logs"
    $ue4BaseFolder = "C:\Unreal\iac\unreal\"

    if (-not (Test-Path -LiteralPath $ue4BaseFolder)) {
        Write-Output $ue4BaseFolder + " does not exist"
    }
    else {
        Write-Output $ue4BaseFolder + " exists as expected."
    }

    if (-not (Test-Path -LiteralPath $ue4logsfolder)) {
        Write-Output $ue4Logsfolder + " does not exist."
    }
    else {
        Write-Output $ue4Logsfolder + " exists as expected."
    }

    #check the firewall is off
    Write-Output ""
    Write-Output "Firewall Disable Check:"

    $fw1 = (Get-NetFirewallProfile -Name Public).Enabled
    $fw2 = (Get-NetFirewallProfile -Name Private).Enabled
    $fw3 = (Get-NetFirewallProfile -Name Domain).Enabled

    $fwCheck = (($fw1) -or ($fw2) -or ($fw3));
    if ($fwCheck) {
        #log that the fw check failed
        Write-Output "Firewall Check Failed."
    }

    #check to see if the processes are running
    Write-Output ""
    Write-Output "Process Information:"
    Write-Output ""

    $ps = Get-Process | Where-Object { $_.Name -eq "PixelStreamer" } | Format-List $_.ID
    $node = Get-Process | Where-Object { $_.Name -eq "node" } | Format-List $_.ID

    Write-Output "PixelStreamer process info: "
    Write-Output $ps
    Write-Output "Node process info: "
    Write-Output $node

    #validate listening on ports for: 80. 7070, 8888, 8889, 4244, 19...
    $NetworkProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
    $TcpConnections = $NetworkProperties.GetActiveTcpConnections()
    
    Write-Output ""
    Write-Output "Listening Ports:"

    $test3389 = $TcpConnections | Select-Object -Exp LocalEndpoint | Where-Object { $_.Port -eq "3389" }
    Write-Output "3389 Port Count: " + $test3389.Count
    $test80 = $TcpConnections | Select-Object -Exp LocalEndpoint | Where-Object { $_.Port -eq "80" }
    Write-Output "80 Port Count: " + $test80.Count
    $test7070 = $TcpConnections | Select-Object -Exp LocalEndpoint | Where-Object { $_.Port -eq "7070" }
    Write-Output "7070 Port Count: " + $test7070.Count
    $test8888 = $TcpConnections | Select-Object -Exp LocalEndpoint | Where-Object { $_.Port -eq "8888" }
    Write-Output "8888 Port Count: " + $test8888.Count
    $test8889 = $TcpConnections | Select-Object -Exp LocalEndpoint | Where-Object { $_.Port -eq "8889" }
    Write-Output "8889 Port Count: " + $test8889.Count
    $test4244 = $TcpConnections | Select-Object -Exp LocalEndpoint | Where-Object { $_.Port -eq "4244" }
    Write-Output "4244 Port Count: " + $test4244.Count
    $test19302 = $TcpConnections | Select-Object -Exp LocalEndpoint | Where-Object { $_.Port -eq "19302" }
    Write-Output "19302 Port Count: " + $test19302.Count
    $test19303 = $TcpConnections | Select-Object -Exp LocalEndpoint | Where-Object { $_.Port -eq "19303" }    
    Write-Output "19303 Port Count: " + $test19303.Count

    #get config file
    $vmServiceFolder = "C:\Unreal\iac\unreal\Engine\Source\Programs\PixelStreaming\WebServers\SignallingWebServer"
    Set-Location -Path $vmServiceFolder 
    $vmssConfigJson = (Get-Content  "config.json" -Raw) | ConvertFrom-Json
    Write-Output ""
    Write-Output "Json Config:"
    Write-Output $vmssConfigJson 

    Write-Output ""
    Write-Output "Check Status of Scheduled Task:"
    Get-ScheduledTask -TaskName "StartVMSS"
}

#do the run, determine if this is MM or BE (back-end) via the ports or some other method?

#OSVersion
$OSVersion = (get-itemproperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName

if ($OSVersion -eq "Windows Server 2019 Datacenter") {
    testmm;
}
else {
    testbe;
}
