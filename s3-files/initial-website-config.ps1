# https://weblog.west-wind.com/posts/2017/may/25/automating-iis-feature-installation-with-powershell
# https://documentation.observeit.com/installation_guide/installing_iis_8.x_on_windows_server_2012_r2.htm
Import-Module ServerManager

Install-WindowsFeature Web-Server, Web-WebServer, Web-Common-Http, Web-Default-Doc, Web-Dir-Browsing, Web-Http-Errors, Web-Static-Content, Web-Health, Web-Http-Logging, Web-Http-Tracing, Web-Performance, Web-Stat-Compression, Web-Security, Web-Filtering, Web-App-Dev, Web-Net-Ext, Web-Net-Ext45, Web-Asp, Web-Asp-Net, Web-Asp-Net45, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Mgmt-Tools, Web-Mgmt-Console, Web-Mgmt-Compat, Web-Metabase, Web-Lgcy-Mgmt-Console, Web-Lgcy-Scripting, Web-WMI -IncludeManagementTools

Copy-Item "$env:systemdrive\s3-files\test-website" "$env:systemdrive\inetpub\test-website" -Recurse
New-Item -ItemType directory -Path "$env:systemdrive\inetpub\describe-website"

Import-Module WebAdministration

New-WebAppPool -name "SandboxAppPool"  -force

$appPool = Get-Item IIS:\AppPools\SandboxAppPool
$appPool.processModel.identityType = "NetworkService"
$appPool.enable32BitAppOnWin64 = 1
$appPool | Set-Item

$testSite = $testSite = New-WebSite `
    -Name TestSite `
    -Port 80 `
    -IPAddress $(Get-NetIpAddress -AddressFamily IPv4 | Select-Object -first 1 -ExpandProperty IPAddress) `
    -PhysicalPath "$env:systemdrive\inetpub\test-website" `
    -ApplicationPool "SandboxAppPool"

$describeSite = $describeSite = New-WebSite `
    -Name DescribeSite `
    -Port 8080 `
    -IPAddress $(Get-NetIpAddress -AddressFamily IPv4 | Select-Object -first 1 -ExpandProperty IPAddress) `
    -PhysicalPath "$env:systemdrive\inetpub\describe-website" `
    -ApplicationPool "SandboxAppPool"

# allow serving of json
Add-WebConfigurationProperty `
    -PSPath $describeSite.pspath  `
    -Filter system.webServer/staticContent `
    -Name "." `
    -Value @{
        fileExtension='.json';
        mimeType='application/json'
    }
    
# Create inbound firewall rule for servo describe access
New-NetFirewallRule `
    -DisplayName "HTTP describe access" `
    -Direction Inbound `
    -Action Allow `
    -Protocol TCP `
    -LocalPort 8080

# Schedule describe task https://devblogs.microsoft.com/scripting/use-powershell-to-create-scheduled-tasks/
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' `
    -Argument "-WindowStyle Hidden -file $env:systemdrive\s3-files\describe.ps1"

$trigger =  New-ScheduledTaskTrigger -Once `
    -At ((Get-Date).AddMinutes(1)) `
    -RepetitionInterval (New-TimeSpan -Minutes 30) `
    -RepetitionDuration (New-TimeSpan -Days 30)

Register-ScheduledTask -Action $action `
    -Trigger $trigger `
    -TaskName "Servo Describe" `
    -Description "Twice hourly updating of current tuning settings into describe.json of describe-website"

# DEV/DEBUG:
# enable failed request tracing https://stackoverflow.com/questions/49547176/is-there-a-scripted-way-to-configure-failed-request-tracing-frt-and-frt-rules
# uncomment following lines

# $describeSite | Set-ItemProperty `
#     -Name traceFailedRequestsLogging `
#     -Value @{
#         enabled     = $true
#         directory   = "%SystemDrive%\inetpub\logs\FailedReqLogFiles"
#         maxLogFiles = 100
#     }

# $Path = "*"
# Add-WebConfigurationProperty `
#     -pspath $describeSite.pspath `
#     -filter "system.webServer/tracing/traceFailedRequests" `
#     -name "." `
#     -value @{path = $Path}

# Add-WebConfigurationProperty `
#     -pspath $pspath `
#     -filter "system.webServer/tracing/traceFailedRequests/add[@path='$Path']/traceAreas" `
#     -name "." `
#     -value @{
#         provider = 'ASPNET'; 
#         areas = 'Infrastructure,Module,Page,AppServices'; 
#         verbosity = 'Verbose'
#     }

# $FailureStatusCodes = ( 500 ) # < expand set as needed
# Set-WebConfigurationProperty -pspath $describeSite.pspath `
#     -filter "system.webServer/tracing/traceFailedRequests/add[@path='$Path']/failureDefinitions" `
#     -name "statusCodes" `
#     -value $FailureStatusCodes
