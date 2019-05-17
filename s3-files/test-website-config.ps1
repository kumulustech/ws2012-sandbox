# https://weblog.west-wind.com/posts/2017/may/25/automating-iis-feature-installation-with-powershell
# https://documentation.observeit.com/installation_guide/installing_iis_8.x_on_windows_server_2012_r2.htm
Import-Module ServerManager

Install-WindowsFeature Web-Server, Web-WebServer, Web-Common-Http, Web-Default-Doc, Web-Dir-Browsing, Web-Http-Errors, Web-Static-Content, Web-Health, Web-Http-Logging, Web-Performance, Web-Stat-Compression, Web-Security, Web-Filtering, Web-App-Dev, Web-Net-Ext, Web-Net-Ext45, Web-Asp, Web-Asp-Net, Web-Asp-Net45, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Mgmt-Tools, Web-Mgmt-Console, Web-Mgmt-Compat, Web-Metabase, Web-Lgcy-Mgmt-Console, Web-Lgcy-Scripting, Web-WMI –IncludeManagementTools

Copy-Item "$env:systemdrive\s3-files\test-website" "$env:systemdrive\inetpub\test-website"

Import-Module WebAdministration

New-WebAppPool -name "SandboxAppPool"  -force

$appPool = Get-Item -name "SandboxAppPool" 
$appPool.processModel.identityType = "NetworkService"
# $appPool.enable32BitAppOnWin64 = 1
$appPool | Set-Item

$site = $site = New-WebSite -Name TestSite -Port 80 -HostHeader TestSite -PhysicalPath "$env:systemdrive\inetpub\test-website" -ApplicationPool "SandboxAppPool"