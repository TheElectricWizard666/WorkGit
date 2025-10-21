<#PSScriptInfo

.VERSION 4.1

.GUID 0f67a69a-b32f-4b56-a101-1394715d7fb5

.AUTHOR Michael Niehaus

.COMPANYNAME Microsoft

.COPYRIGHT 

.TAGS Windows AutoPilot

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
Version 4.1:  Marked as obsolete; use Get-AutopilotDiagnostics instead.
Version 4.0:  Added sidecar installation info.
Version 3.9:  Bug fixes.
Version 3.8:  Bug fixes.
Version 3.7:  Modified Office logic to ensure it accurately reflected what ESP thinks the status is.  Added ShowPolicies option.
Version 3.2:  Fixed sidecar detection logic
Version 3.1:  Fixed ODJ applied output
Version 3.0:  Added the ability to process logs as well
Version 2.2:  Added new IME MSI guid, new -AllSessions switch
Version 2.0:  Added -online parameter to look up app and policy details.
Version 1.0:  Original published version.

#>


<#
.SYNOPSIS
Displays Windows Autopilot ESP tracking information from the current PC.

.DESCRIPTION

*NOTE* This script has been replaced by Get-AutopilotDiagnostics, available from https://www.powershellgallery.com/packages/Get-AutopilotDiagnostics.  As a result, this script is no longer being maintained or enhanced.

This script dumps out the Windows Autopilot ESP tracking information from the registry. This should work with Windows 10 1903 and later (earlier versions have not been validated).

This script will not work on ARM64 systems due to registry redirection from the use of x86 PowerShell.exe.

.PARAMETER Online
Look up the actual policy names via the Intune Graph API

.PARAMETER AllSessions
Show all ESP sessions (where each session reflects one ESP execution, e.g. device ESP #1, device ESP #2 after a reboot, user) instead of just the last one.

.PARAMETER CABFile
Processes the information in the specified CAB file (captured by MDMDiagnosticsTool.exe -area Autopilot -cab filename.cab) instead of from the registry.

.PARAMETER ShowPolicies
Shows the policy details as recorded in the NodeCache registry keys.

.EXAMPLE
.\Get-AutopilotESPStatus.ps1

.EXAMPLE
.\Get-AutopilotESPStatus.ps1 -Online

.EXAMPLE
.\Get-AutopilotESPStatus.ps1 -AllSessions

.EXAMPLE
.\Get-AutopilotESPStatus.ps1 -CABFile C:\Autopilot.cab -Online -AllSessions

#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$False)] [String] $CABFile = $null,
    [Parameter(Mandatory=$False)] [Switch] $Online = $false,
    [Parameter(Mandatory=$False)] [Switch] $AllSessions = $false,
    [Parameter(Mandatory=$False)] [Switch] $ShowPolicies = $false
)

Begin
{
    # If using a CAB file, load up the registry information
    if ($CABFile) {

        # Extract the needed files
        if (-not (Test-Path "$($env:TEMP)\ESPStatus.tmp"))
        {
            New-Item -Path "$($env:TEMP)\ESPStatus.tmp" -ItemType "directory" | Out-Null
        }
        $null = & expand.exe "$CABFile" -F:MdmDiagReport_RegistryDump.reg "$($env:TEMP)\ESPStatus.tmp\" 
        if (-not (Test-Path "$($env:TEMP)\ESPStatus.tmp\MdmDiagReport_RegistryDump.reg"))
        {
            Write-Error "Unable to extract registrion information from $CABFile"
        }
        $null = & expand.exe "$CABFile" -F:microsoft-windows-devicemanagement-enterprise-diagnostics-provider-admin.evtx "$($env:TEMP)\ESPStatus.tmp\" 
        if (-not (Test-Path "$($env:TEMP)\ESPStatus.tmp\microsoft-windows-devicemanagement-enterprise-diagnostics-provider-admin.evtx"))
        {
            Write-Error "Unable to extract event information from $CABFile"
        }

        # Edit the path in the .reg file
        $content = Get-Content -Path "$($env:TEMP)\ESPStatus.tmp\MdmDiagReport_RegistryDump.reg"
        $content = $content -replace "\[HKEY_CURRENT_USER\\", "[HKEY_CURRENT_USER\ESPStatus.tmp\USER\"
        $content = $content -replace "\[HKEY_LOCAL_MACHINE\\", "[HKEY_CURRENT_USER\ESPStatus.tmp\MACHINE\"
        $content = $content -replace '^    "','"'
        $content = $content -replace '^    @','@'
        $content = $content -replace 'DWORD:','dword:'
        "Windows Registry Editor Version 5.00`n" | Set-Content -Path "$($env:TEMP)\ESPStatus.tmp\MdmDiagReport_Edited.reg"
        $content | Add-Content -Path "$($env:TEMP)\ESPStatus.tmp\MdmDiagReport_Edited.reg"

        # Remove the registry info if it exists
        if (Test-Path "HKCU:\ESPStatus.tmp")
        {
            Remove-Item -Path "HKCU:\ESPStatus.tmp" -Recurse -Force
        }

        # Import the .reg file
        $null = & reg.exe IMPORT "$($env:TEMP)\ESPStatus.tmp\MdmDiagReport_Edited.reg" 2>&1

        # Configure the (not live) constants
        $script:provisioningPath =  "HKCU:\ESPStatus.tmp\MACHINE\software\microsoft\provisioning"
        $script:autopilotDiagPath = "HKCU:\ESPStatus.tmp\MACHINE\software\microsoft\provisioning\Diagnostics\Autopilot"
        $script:omadmPath = "HKCU:\ESPStatus.tmp\MACHINE\software\microsoft\provisioning\OMADM"
        $script:path = "HKCU:\ESPStatus.tmp\MACHINE\Software\Microsoft\Windows\Autopilot\EnrollmentStatusTracking\ESPTrackingInfo\Diagnostics"
        $script:msiPath = "HKCU:\ESPStatus.tmp\MACHINE\Software\Microsoft\EnterpriseDesktopAppManagement"
        $script:officePath = "HKCU:\ESPStatus.tmp\MACHINE\Software\Microsoft\OfficeCSP"
        $script:sidecarPath = "HKCU:\ESPStatus.tmp\MACHINE\Software\Microsoft\IntuneManagementExtension\Win32Apps"
    }
    else {
        # Configure live constants
        $script:provisioningPath =  "HKLM:\software\microsoft\provisioning"
        $script:autopilotDiagPath = "HKLM:\software\microsoft\provisioning\Diagnostics\Autopilot"
        $script:omadmPath = "HKLM:\software\microsoft\provisioning\OMADM"
        $script:path = "HKLM:\Software\Microsoft\Windows\Autopilot\EnrollmentStatusTracking\ESPTrackingInfo\Diagnostics"
        $script:msiPath = "HKLM:\Software\Microsoft\EnterpriseDesktopAppManagement"
        $script:officePath = "HKLM:\Software\Microsoft\OfficeCSP"
        $script:sidecarPath = "HKLM:\Software\Microsoft\IntuneManagementExtension\Win32Apps"
    }

    # Configure other constants
    $script:officeStatus = @{"10" = "Initialized"; "20" = "Download In Progress"; "25" = "Pending Download Retry";
        "30" = "Download Failed"; "40" = "Download Completed"; "48" = "Pending User Session"; "50" = "Enforcement In Progress"; 
        "55" = "Pending Enforcement Retry"; "60" = "Enforcement Failed"; "70" = "Success / Enforcement Completed"}
    $script:espStatus = @{"1" = "Not Installed"; "2" = "Downloading / Installing"; "3" = "Success / Installed"; "4" = "Error / Failed"}
    $script:policyStatus = @{"0" = "Not Processed"; "1" = "Processed"}
}

Process
{
    #------------------------
    # Functions
    #------------------------

    Function ProcessApps() {
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$True)] [Microsoft.Win32.RegistryKey] $currentKey,
        [Parameter(Mandatory=$true)] $currentUser
    )

    Begin {
        Write-Host "Apps:"
    }

    Process {
        Write-Host "  $($currentKey.PSChildName)"
        $currentKey.Property | % {
            if ($_.StartsWith("./Device/Vendor/MSFT/EnterpriseDesktopAppManagement/MSI/")) {
                $msiKey = [URI]::UnescapeDataString(($_.Split("/"))[6])
                $fullPath = "$msiPath\$currentUser\MSI\$msiKey"
                if (Test-Path $fullPath) {
                    $status = Get-ItemPropertyValue -Path $fullPath -Name Status
                    $msiFile = Get-ItemPropertyValue -Path $fullPath -Name CurrentDownloadUrl
                }
                else
                {
                    $status = "Not found"
                    $msiFile = "Unknown"
                } 
                if ($msiFile -match "IntuneWindowsAgent.msi")
                {
                    $msiKey = "Intune Management Extensions ($($msiKey))"
                }
                elseif ($Online) {
                    $found = $apps | ? {$_.ProductCode -contains $msiKey}
                    $msiKey = "$($found.DisplayName) ($($msiKey))"
                }
                if ($status -eq 70) {
                    Write-Host "    MSI $msiKey : $status ($($officeStatus[$status.ToString()]))" -ForegroundColor Green
                }
                else {
                    Write-Host "    MSI $msiKey : $status ($($officeStatus[$status.ToString()]))" -ForegroundColor Yellow
                }
            }
            elseif ($_.StartsWith("./Vendor/MSFT/Office/Installation/")) {
                # Report the main status based on what ESP is tracking
                $status = Get-ItemPropertyValue -Path $currentKey.PSPath -Name $_

                # Then try to get the detailed Office status
                $officeKey = [URI]::UnescapeDataString(($_.Split("/"))[5])
                $fullPath = "$officepath\$officeKey"
                if (Test-Path $fullPath) {
                    $oStatus = (Get-ItemProperty -Path $fullPath).FinalStatus

                    if ($oStatus -eq $null)
                    {
                        $oStatus = (Get-ItemProperty -Path $fullPath).Status
                        if ($oStatus -eq $null)
                        {
                            $oStatus = "None"
                        }
                    }
                }
                else {
                    $oStatus = "None"
                }
                if ($officeStatus.Keys -contains $oStatus.ToString())
                {
                    $officeStatusText = $officeStatus[$oStatus.ToString()]
                }
                else {
                    $officeStatusText = $oStatus
                }
                if ($status -eq 1) {
                    Write-Host "    Office $officeKey : $status ($($policyStatus[$status.ToString()]) / $officeStatusText)" -ForegroundColor Green
                }
                else {
                    Write-Host "    Office $officeKey : $status ($($policyStatus[$status.ToString()]) / $officeStatusText)" -ForegroundColor Yellow
                }
            }
            else
            {
                Write-Host "    $_ : Unknown app"
            }
        }
    }

    }

    Function ProcessModernApps() {
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$True)] [Microsoft.Win32.RegistryKey] $currentKey,
        [Parameter(Mandatory=$true)] $currentUser
    )

    Begin {
        Write-Host "Modern Apps:"
    }

    Process {
        Write-Host "  $($currentKey.PSChildName)"
        $currentKey.Property | % {
            $status = (Get-ItemPropertyValue -path $currentKey.PSPath -Name $_).ToString()
            if ($_.StartsWith("./User/Vendor/MSFT/EnterpriseModernAppManagement/AppManagement/")) {
                $appID = [URI]::UnescapeDataString(($_.Split("/"))[7])
                $type = "User UWP"
            }
            elseif ($_.StartsWith("./Device/Vendor/MSFT/EnterpriseModernAppManagement/AppManagement/")) {
                $appID = [URI]::UnescapeDataString(($_.Split("/"))[7])
                $type = "Device UWP"
            }
            else
            {
                $appID = $_
                $type = "Unknown UWP"
            }
            if ($status -eq "1") {
                Write-Host "    $type $appID : $status ($($policyStatus[$status]))" -ForegroundColor Green
            }
            else {
                Write-Host "    $type $appID : $status ($($policyStatus[$status]))" -ForegroundColor Yellow
            }
        }
    }

    }

    Function ProcessSidecar() {
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$True)] [Microsoft.Win32.RegistryKey] $currentKey,
        [Parameter(Mandatory=$true)] $currentUser
    )

    Begin {
        Write-Host "Sidecar apps:"
    }

    Process {
        Write-Host "  $($currentKey.PSChildName)"
        $currentKey.Property | % {
            $win32Key = [URI]::UnescapeDataString(($_.Split("/"))[9])
            $status = Get-ItemPropertyValue -path $currentKey.PSPath -Name $_
            if ($Online) {
                $found = $apps | ? {$win32Key -match $_.Id }
                $win32Key = "$($found.DisplayName) ($($win32Key))"
            }
            $appGuid = $win32Key.Substring(9)
            $sidecarApp = "$sidecarPath\$currentUser\$appGuid"
            $exitCode = $null
            if (Test-Path $sidecarApp)
            {
                $exitCode = (Get-ItemProperty -Path $sidecarApp).ExitCode
            }
            if ($status -eq "3") {
                if ($exitCode -ne $null) {
                    Write-Host "    Win32 $win32Key : $status ($($espStatus[$status.ToString()]), rc = $exitCode)" -ForegroundColor Green
                }
                else {
                    Write-Host "    Win32 $win32Key : $status ($($espStatus[$status.ToString()]))" -ForegroundColor Green
                }
            }
            else {
                if ($exitCode -ne $null)
                {
                    Write-Host "    Win32 $win32Key : $status ($($espStatus[$status.ToString()]), rc = $exitCode)" -ForegroundColor Yellow
                }
                else {
                    Write-Host "    Win32 $win32Key : $status ($($espStatus[$status.ToString()]))" -ForegroundColor Yellow
                }
            }
        }
    }

    }

    Function ProcessPolicies() {
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$True)] [Microsoft.Win32.RegistryKey] $currentKey
    )

    Begin {
        Write-Host "Policies:"
    }

    Process {
        Write-Host "  $($currentKey.PSChildName)"
        $currentKey.Property | % {
            $status = Get-ItemPropertyValue -path $currentKey.PSPath -Name $_
            Write-Host "    Policy $_ : $status ($($policyStatus[$status.ToString()]))"
        }
    }

    }


    Function ProcessCerts() {
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$True)] [Microsoft.Win32.RegistryKey] $currentKey
    )

    Begin {
        Write-Host "Certificates:"
    }

    Process {
        Write-Host "  $($currentKey.PSChildName)"
        $currentKey.Property | % {
            $certKey = [URI]::UnescapeDataString(($_.Split("/"))[6])
            $status = Get-ItemPropertyValue -path $currentKey.PSPath -Name $_
            if ($Online) {
                $found = $policies | ? { $certKey.Replace("_","-") -match $_.Id }
                $certKey = "$($found.DisplayName) ($($certKey))"
            }
            if ($status -eq "1") {
                Write-Host "    Cert $certKey : $status ($($policyStatus[$status.ToString()]))" -ForegroundColor Green
            }
            else {
                Write-Host "    Cert $certKey : $status ($($policyStatus[$status.ToString()]))" -ForegroundColor Yellow
            }
        }
    }

    }

    Function ProcessNodeCache() {

    Begin {
        Write-Host " "
        Write-Host "Policies processed:"
    }
    
    Process {
        $nodeCount = 0
        while ($true) {
            # Get the nodes in order.  This won't work after a while because the older numbers are deleted as new ones are added
            # but it will work out OK shortly after provisioning.  The alternative would be to get all the subkeys and then sort
            # them numerically instead of alphabetically, but that can be saved for later...
            $node = Get-ItemProperty "$provisioningPath\NodeCache\CSP\Device\MS DM Server\Nodes\$nodeCount" -ErrorAction SilentlyContinue
            if ($node -eq $null)
            {
                break
            }
            $nodeCount += 1
            $node | Select NodeUri, ExpectedValue
        }
    }

    }

    Function ProcessSidecarInfo() {

        Process {
            Get-ChildItem -path "$msiPath\S-0-0-00-0000000000-0000000000-000000000-000\MSI" | % {
                $file = Get-ItemPropertyValue -Path $_.PSPath -Name CurrentDownloadUrl
                if ($file -match "IntuneWindowsAgent.msi")
                {
                    $productCode = Get-ItemPropertyValue -Path $_.PSPath -Name ProductCode
                    Write-Host " "
                    Write-Host "INTUNE MANAGEMENT EXTENSIONS installation details:"
                    if ($CABFile) {
                        Get-WinEvent -Path "$($env:TEMP)\ESPStatus.tmp\microsoft-windows-devicemanagement-enterprise-diagnostics-provider-admin.evtx" -Oldest | ? {($_.Message -match $productCode -and $_.Id -in 1905,1906,1920,1922) -or $_.Id -eq 72}
                    }
                    else {
                        Get-WinEvent -LogName Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin -Oldest | ? {($_.Message -match $productCode -and $_.Id -in 1905,1906,1920,1922) -or $_.Id -eq 72}
                    }
                }
            }
        }
    
        }
    
    Function GetIntuneObjects() {
        param
        (
            [Parameter(Mandatory=$true)] [String] $uri
        )

        Process {

            Write-Verbose "GET $uri"
            try {
                $response = Invoke-MSGraphRequest -Url $uri -HttpMethod Get

                $objects = $response.value
                $objectsNextLink = $response."@odata.nextLink"
    
                while ($objectsNextLink -ne $null){
                    $response = (Invoke-MSGraphRequest -Url $devicesNextLink -HttpMethod Get)
                    $objectsNextLink = $response."@odata.nextLink"
                    $objects += $response.value
                }

                return $objects
            }
            catch {
                Write-Error $_.Exception
                return $null
                break
            }

        }
    }

    #------------------------
    # Main code
    #------------------------

    # Display Autopilot diag details
    if (Test-Path $autopilotDiagPath)
    {
    	Write-Host ""
    	Write-Host "AUTOPILOT DIAGNOSTICS"
    	Write-Host ""

        $values = Get-ItemProperty "$autopilotDiagPath"
        Write-Host "TenantDomain:   $($values.CloudAssignedTenantDomain)"
        Write-Host "TenantID:       $($values.CloudAssignedTenantId)"
        Write-Host "OobeConfig:     $($values.CloudAssignedOobeConfig)"
        $values = Get-ItemProperty "$autopilotDiagPath\EstablishedCorrelations"
        Write-Host "EntDMID:        $($values.EntDMID)"
        if (Test-Path "$omadmPath\SyncML\ODJApplied")
        {
            Write-Host "ODJ applied:    YES"
        }
    }

    # Display sidecar info
    ProcessSidecarInfo

    # Display the list of policies
    if ($ShowPolicies)
    {
        ProcessNodeCache | Format-Table -Wrap
    }
    
    # Make sure the tracking path exists
    if (-not (Test-Path $path)) {
        Write-Host "ESP diagnostics info does not (yet) exist."
        exit 0
    }

    # If online, make sure we are able to authenticate
    if ($Online) {

        # Make sure we can connect
        $module = Import-Module Microsoft.Graph.Intune -PassThru -ErrorAction Ignore
        if (-not $module) {
            Write-Host "Installing module Microsoft.Graph.Intune"
            Install-Module Microsoft.Graph.Intune -Force
        }
        Import-Module Microsoft.Graph.Intune
        $graph = Connect-MSGraph
        Write-Host "Connected to tenant $($graph.TenantId)"

        # Get a list of apps
        Write-Host "Getting list of apps"
        $script:apps = GetIntuneObjects("https://graph.microsoft.com/beta/deviceAppManagement/mobileApps")

        # Get a list of policies (for certs)
        Write-Host "Getting list of policies"
        $script:policies = GetIntuneObjects("https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations")
    }
    
    # Process device ESP sessions
    Write-Host " "
    Write-Host "DEVICE ESP:"
    Write-Host " "

    if (Test-Path "$path\ExpectedMSIAppPackages") {
        $items = Get-ChildItem "$path\ExpectedMSIAppPackages"
        if ($AllSessions) {
            $items | ProcessApps -currentUser "S-0-0-00-0000000000-0000000000-000000000-000"
        }
        elseif ($items.Count -gt 0) {
            $items[$items.Count - 1] | ProcessApps -currentUser "S-0-0-00-0000000000-0000000000-000000000-000"
        }
    }
    if (Test-Path "$path\ExpectedModernAppPackages") {
        $items = Get-ChildItem "$path\ExpectedModernAppPackages"
        if ($AllSessions) {
            $items | ProcessModernApps -currentUser "S-0-0-00-0000000000-0000000000-000000000-000"
        }
        elseif ($items.Count -gt 0) {
            $items[$items.Count - 1] | ProcessModernApps -currentUser "S-0-0-00-0000000000-0000000000-000000000-000"
        }
    }
    if (Test-Path "$path\Sidecar") {
        $items = Get-ChildItem "$path\Sidecar"
        if ($AllSessions) {
            $items | ProcessSidecar -currentUser "00000000-0000-0000-0000-000000000000"
        }
        elseif ($items.Count -gt 0) {
            $items[$items.Count - 1] | ProcessSidecar -currentUser "00000000-0000-0000-0000-000000000000"
        }
    }
    if (Test-Path "$path\ExpectedPolicies") {
        $items = Get-ChildItem "$path\ExpectedPolicies" 
        if ($AllSessions) {
            $items | ProcessPolicies
        }
        elseif ($items.Count -gt 0) {
            $items[$items.Count - 1] | ProcessPolicies
        }
    }
    if (Test-Path "$path\ExpectedSCEPCerts") {
        $items = Get-ChildItem "$path\ExpectedSCEPCerts"
        if ($AllSessions) {
            $items | ProcessCerts
        }
        elseif ($items.Count -gt 0) {
            $items[$items.Count - 1] | ProcessCerts
        }
    }

    # Process user ESP sessions
    Get-ChildItem "$path" | ? { $_.PSChildName.StartsWith("S-") } | % {
        $userPath = $_.PSPath
        $userSid = $_.PSChildName
        Write-Host " "
        Write-Host "USER ESP for $($userSid):"
        Write-Host " "
        if (Test-Path "$userPath\ExpectedMSIAppPackages") {
            $items = Get-ChildItem "$userPath\ExpectedMSIAppPackages" 
            if ($AllSessions) {
                $items | ProcessApps -currentUser $userSid
            }
            elseif ($items.Count -gt 0) {
                $items[$items.Count - 1] | ProcessApps -currentUser $userSid
            }
        }
        if (Test-Path "$userPath\ExpectedModernAppPackages") {
            $items = Get-ChildItem "$userPath\ExpectedModernAppPackages"
            if ($AllSessions) {
                $items | ProcessModernApps -currentUser $userSid
            }
            elseif ($items.Count -gt 0) {
                $items[$items.Count - 1] | ProcessModernApps -currentUser $userSid
            }
        }
        if (Test-Path "$userPath\Sidecar") {
            $items = Get-ChildItem "$userPath\Sidecar"
            if ($AllSessions) {
                $items | ProcessSidecar -currentUser $userSid
            }
            elseif ($items.Count -gt 0) {
                $items[$items.Count - 1] | ProcessSidecar -currentUser $userSid
            }
        }
        if (Test-Path "$userPath\ExpectedPolicies") {
            $items = Get-ChildItem "$userPath\ExpectedPolicies"
            if ($AllSessions) {
                $items | ProcessPolicies
            }
            elseif ($items.Count -gt 0) {
                $items[$items.Count - 1] | ProcessPolicies
            }
        }
        if (Test-Path "$userPath\ExpectedSCEPCerts") {
            $items = Get-ChildItem "$userPath\ExpectedSCEPCerts"
            if ($AllSessions) {
                $items | ProcessCerts
            }
            elseif ($items.Count -gt 0) {
                $items[$items.Count - 1] | ProcessCerts
            }
        }
    }

    Write-Host ""
}

End {

    # Remove the registry info if it exists
    if (Test-Path "HKCU:\ESPStatus.tmp")
    {
        Remove-Item -Path "HKCU:\ESPStatus.tmp" -Recurse -Force
    }
}

