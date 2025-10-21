#Script to remove bultin Apps in Windows 10/11


$Buildnr = (Get-CimInstance Win32_Operatingsystem).BuildNumber
$Logfile = "$env:SystemRoot\Temp\RemoveApps_$($Buildnr).log"
Set-Content -Path $Logfile -Value "Removing builtin apps and capabilities based on script input"

# If a capabilities file exist with a matching buildnumber it will remove the capabilities in it.
$FileExists = Test-Path "$($PSScriptRoot)\apps$($Buildnr).txt"
If ($FileExists) {
    $Capabilities = Get-Content "$($PSScriptRoot)\Capabilities$($Buildnr).txt"
    Add-Content -Path $Logfile -Value "Removing Windows capabilities based on input file = $Capabilities"
    ForEach ($Capability in $Capabilities) {
        "`r`nRemoving capability: $Capability".Replace("  ", " ") | Out-File -FilePath $Logfile -Append 
        Remove-WindowsCapability -online -name $Capability | Out-File -FilePath $Logfile -Append -Encoding ascii
    }
}
# Uninstall apps from textfile
$Applist = Get-Content "$($PSScriptRoot)\apps$($Buildnr).txt"
Add-Content -Path $Logfile -Value "Removing builtin apps based on input file = $Applist"
ForEach ($App in $Applist) {
    $App = $App.TrimEnd()
    $PackageFullName = (Get-AppxPackage $App).PackageFullName
    $ProPackageFullName = (Get-AppxProvisionedPackage -online | where { $_.Displayname -eq $App }).PackageName

    if ($PackageFullName) {
        "`r`nRemoving Package: $App" | Out-File -FilePath $Logfile -Append -Encoding ascii
        start-sleep -Seconds 5
        remove-AppxPackage -package $PackageFullName | Out-File -FilePath $Logfile -Append -Encoding ascii
    }
    else {
        "Unable to find package: $App" | Out-File -FilePath $Logfile -Append -Encoding ascii 
    }

    if ($ProPackageFullName) {
        "`r`nRemoving Provisioned Package: $ProPackageFullName" | Out-File -FilePath $Logfile -Append -Encoding ascii
        start-sleep -Seconds 5 
        Remove-AppxProvisionedPackage -online -packagename $ProPackageFullName | Out-File -FilePath $Logfile -Append -Encoding ascii  
    }
    else {
        "Unable to find provisioned package: $App" | Out-File -FilePath $Logfile -Append -Encoding ascii
    }
}
