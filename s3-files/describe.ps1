Import-Module WebAdministration
@{
    "HKLM:\System\CurrentControlSet\Services\Http\Parameters" = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\Http\Parameters"
    "WebConfig" = @{
        'MACHINE/WEBROOT/APPHOST' = @{
            "system.webServer/caching" = Get-WebConfiguration -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/caching"
        }
    }
} | ConvertTo-Json | Out-File -FilePath ("{0}\describe.json" -f (Get-ItemProperty IIS:\Sites\DescribeSite -name physicalPath))