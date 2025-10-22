<# 
.SYNOPSIS 
    Gets intune assigments for a specified group

.DESCRIPTION
    Detailed script description

.NOTES
  Author:         Adrian Keller
  Creation Date:  12.02.2025
#>


# https://doitpsway.com/get-all-intune-policies-using-powershell-and-graph-api
# https://doitpsway.com/get-all-intune-policies-assigned-to-the-specified-account-using-powershell

Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase, System.Windows.Forms
Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public class ProcessDPI {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool SetProcessDPIAware();      
}
'@
$null = [ProcessDPI]::SetProcessDPIAware()

#DONE
function GetApplications {
    Function CreateGetApplicationPSObject {
        param(
            [parameter(Mandatory = $true)]
            [string]$Application,
            [parameter(Mandatory = $true)]
            [string]$Version,
            [parameter(Mandatory = $true)]
            [string]$Type,
            [parameter(Mandatory = $true)]
            [bool]$Assigned,
            [parameter(Mandatory = $true)]
            [bool]$AssignedToSearchGroup,
            [parameter(Mandatory = $true)]
            [string]$Groupname,
            [parameter(Mandatory = $true)]
            [string]$Assignedintent,
            [parameter(Mandatory = $true)]
            [string]$Assignedtype,
            [parameter(Mandatory = $true)]
            [string]$Assignsource,
            [parameter(Mandatory = $true)]
            [string]$ID,
            [parameter(Mandatory = $true)]
            [string]$URL
        )
    
        $obj = @()
        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "Application" -Value $Application
        $obj | Add-Member -MemberType NoteProperty -Name "Version" -Value $Version
        $obj | Add-Member -MemberType NoteProperty -Name "Type" -Value $Type
        $obj | Add-Member -MemberType NoteProperty -Name "Assigned" -Value $Assigned
        $obj | Add-Member -MemberType NoteProperty -Name "AssignedToSearchGroup" -Value $AssignedToSearchGroup
        $obj | Add-Member -MemberType NoteProperty -Name "Groupname" -Value $Groupname
        $obj | Add-Member -MemberType NoteProperty -Name "Assignedintent" -Value $Assignedintent
        $obj | Add-Member -MemberType NoteProperty -Name "Assignedtype" -Value $Assignedtype
        $obj | Add-Member -MemberType NoteProperty -Name "Assignsource" -Value $Assignsource
        $obj | Add-Member -MemberType NoteProperty -Name "ID" -Value $ID
        $obj | Add-Member -MemberType NoteProperty -Name "URL" -Value $URL
        return $obj
    
    }
    
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    # APPLICATIONS
    # -------------------------------------------------------------------------------------------------------------------------
    # https://endpoint.microsoft.com/?feature.msaljs=false#view/Microsoft_Intune_DeviceSettings/AppsMenu/~/allApps
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    # Single app
    # $id = "80f7a5f9-800c-4252-8a9e-9c04a3de6689"
    # $AllApps = (Invoke-MgGraphRequest -Method GET -uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($id)/assignments").value
    # -------------------------------------------------------------------------------------------------------------------------
    write-host ""
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host "- APPLICATIONS -----------------------------------------------------------------" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    Write-host " Searching for applications assigned to: $($GroupInfo.DisplayName)" -ForegroundColor Magenta
    $AllApps = (Invoke-MgGraphRequest -Method GET -uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?`$expand=Assignments").value
    Write-host " Number of applications found: $($AllApps.DisplayName.Count)" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    Start-Sleep 3
    write-host ""
    $PSObjectResult = @()
    $listApps = @()
    $outputname = "Applications.csv"
    $Appcount = 0
        
    Foreach ($Config in $AllApps) {
        $assign = $false
        $assignintent = ""
        $assigntype = ""
        $assignsource = ""
        $type = ""
        $version = ""
        $Appcount ++
        $url = "https://intune.microsoft.com/?feature.msaljs=true#view/Microsoft_Intune_Apps/SettingsMenu/~/0/appId/$($config.id)"
        write-host "---+ Checking application $($appcount) of $($AllApps.DisplayName.Count): [$($config.displayname)] +---"
    
        switch ($Config.'@odata.type') { # defining application type
            "#microsoft.graph.win32LobApp"                  {$type = "Windows app (Win32)"}
            "#microsoft.graph.microsoftStoreForBusinessApp" {$type= "Microsoft Store for Business app"}
            "#microsoft.graph.officeSuiteApp"               {$type = "Microsoft 365 Apps (Windows 10 and later)"}
            "#microsoft.graph.iosStoreApp"                  {$type = "iOS store app"}
            "#microsoft.graph.androidManagedStoreApp"       {$type = "Managed Google Play store app"}
            "#microsoft.graph.androidLobApp"                {$type = "Android line-of-business app"}
            "#microsoft.graph.iosLobApp"                    {$type = "iOS line-of-business app"}
            "#microsoft.graph.windowsMicrosoftEdgeApp"      {$type = "Microsoft Edge (Windows 10 and later)"}
            "#microsoft.graph.webApp"                       {$type = "Web link"}
            "#microsoft.graph.winGetApp"                    {$type = "Microsoft Store app (new)"}
            "#microsoft.graph.managedIOSStoreApp"           {$type = "iOS store app"}
            "#microsoft.graph.managedAndroidStoreApp"       {$type = "Android store app"}
            "#microsoft.graph.iosVppApp"                    {$type = "iOS VPP app"}
            "#microsoft.graph.macOSOfficeSuiteApp"          {$type = "Microsoft 365 Apps (macOS)"}
            "#microsoft.graph.macOSMicrosoftEdgeApp"        {$type = "macOS Microsoft Edge App"}
            "#microsoft.graph.macOSPkgApp"                  {$type = "MacOSPkgApp"}
            Default                                         {$type = "$($Config.'@odata.type')"}    
        }
    
    
        if ($config.assignments.Count -gt 0) { # Assigment for application found
            foreach ($assignment in $config.assignments) {
                if (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $assignintent = "$($assignment.intent)"
                    $assignSource = $($assignment.source)
                    $assigntype = "Include"
                    $groupName = $groupDisplayName
                    $version = $($config.displayVersion)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateGetApplicationPSObject -Application $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName)  -Assignedintent $assignintent -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup -URL $url
    
                } elseif (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $assignSource = $($assignment.source)
                    $assigntype = "Exclude"
                    $assignintent = "$($assignment.intent)"
                    $groupName = $groupDisplayName
                    $version = $($config.displayVersion)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateGetApplicationPSObject -Application $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedintent $assignintent -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup -URL $url
    
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Yellow"
                    $assignSource = $($assignment.source)
                    $assigntype = "Include"
                    $assignintent = "$($assignment.intent)"
                    $targetgroupid = $($assignment.target.groupId)
                    $Error.Clear()
                    $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                    if ($error.Count -gt 0) {
                        Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                        $groupName = "Please CHECK - Groupname not found"
                    }
                    $version = $($config.displayVersion)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateGetApplicationPSObject -Application $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedintent $assignintent -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup -URL $url
    
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Magenta"
                    $assignSource = $($assignment.source)
                    $assigntype = "Exclude"
                    $assignintent = "$($assignment.intent)"
                    $targetgroupid = $($assignment.target.groupId)
                    $Error.Clear()
                    $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                    if ($error.Count -gt 0) {
                        Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                        $groupName = "Please CHECK - Groupname not found"
                    }
                    $version = $($config.displayVersion)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateGetApplicationPSObject -Application $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedintent $assignintent -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup -URL $url
                }
    
                $listApps += $PSObjectResult
                if ($output) {
                    write-host "[$($assigntype)]::: assignment: Version: $version - Type: $($type) - Groupname: $($groupName) - Intent: $($assignintent) - Assignedtype: $($assigntype) - Assignsource: $($assignSource) - ID: $($config.id)" -ForegroundColor $foreground
                }
            }         
    
        } else { # No assigment found for application
                
            $assign = $false
            $foreground = "cyan"
            $version = $($config.displayVersion)
            if ([string]::IsNullOrEmpty($version)) {
                $version = "N/A"
            }
            if ($output) {
                write-host "[NO]::: assignment: Version $($version) - Type: $($type) - ID: $($config.id)" -ForegroundColor $foreground
            }
            $PSObjectResult = CreateGetApplicationPSObject -Application $($config.displayName) -Version $($version)  -Type $type -Assigned $assign -Groupname "-" -Assignedintent "-" -Assignedtype "-" -Assignsource "-" -ID $($Config.id) -AssignedToSearchGroup $false -URL $url
            $listApps += $PSObjectResult
        }
    }
    
        # Adding Applications to DataGrid
        # $DataGridApps.AddChild($obj)
    
        # Generate CSV
        if ($csv) {
            if (!(Test-Path $outputpath -PathType Container)) {
                New-Item -path $outputpath -ItemType Directory -Force | Out-Null
            }

            $listApps | export-csv -Path $outputpath\$outputname

        }
        
        # Show Grid
        if ($outgrid) {
            $listApps | Out-GridView
        }
}

# START OF DEVICE COMPLIANCE
#DONE
Function GetDeviceCompliancePolicies {
    Function CreateDeviceCompliancePSObject {
        param(
            [parameter(Mandatory = $true)]
            [string]$Name,
            [parameter(Mandatory = $true)]
            [string]$Version,
            [parameter(Mandatory = $true)]
            [string]$Type,
            [parameter(Mandatory = $true)]
            [bool]$Assigned,
            [parameter(Mandatory = $true)]
            [bool]$AssignedToSearchGroup,
            [parameter(Mandatory = $true)]
            [string]$Groupname,
            [parameter(Mandatory = $true)]
            [string]$Assignedtype,
            [parameter(Mandatory = $true)]
            [string]$Assignsource,
            [parameter(Mandatory = $true)]
            [string]$ID
        )
    
        $obj = @()
        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "Name" -Value $Name
        $obj | Add-Member -MemberType NoteProperty -Name "Version" -Value $Version
        $obj | Add-Member -MemberType NoteProperty -Name "Type" -Value $Type
        $obj | Add-Member -MemberType NoteProperty -Name "Assigned" -Value $Assigned
        $obj | Add-Member -MemberType NoteProperty -Name "AssignedToSearchGroup" -Value $AssignedToSearchGroup
        $obj | Add-Member -MemberType NoteProperty -Name "Groupname" -Value $Groupname
        $obj | Add-Member -MemberType NoteProperty -Name "Assignedtype" -Value $Assignedtype
        $obj | Add-Member -MemberType NoteProperty -Name "Assignsource" -Value $Assignsource
        $obj | Add-Member -MemberType NoteProperty -Name "ID" -Value $ID
        return $obj
    
    }
    
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    # DEVICE COMPLIANCE POLICIES
    # -------------------------------------------------------------------------------------------------------------------------
    # https://endpoint.microsoft.com/?feature.msaljs=false#view/Microsoft_Intune_DeviceSettings/DevicesComplianceMenu/~/policies
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    write-host ""
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host "- DEVICE COMPLIANCE ------------------------------------------------------------" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    Write-host " Searching for device compliance policies assigned to: $($groupDisplayName)" -ForegroundColor Magenta
    $AllDCPId = (Invoke-MgGraphRequest -Method GET -uri "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies?`$expand=Assignments").value
    Write-host " Number of Device Compliance policies found: $($AllDCPId.DisplayName.Count)" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host ""
    Start-Sleep 3
    $PolicyExportFolderName = "DeviceCompliancePolicies"
    $listDeviceCompliance = @()
    $PSObjectResult = @()
    $config = ""
    $type = ""
    $compliancecount = 0
    $outputname = "DeviceCompliancePolicies.csv"
        
    Foreach ($Config in $AllDCPId) {
        
        $compliancecount ++
        write-host "---+ Device compliance policy $($compliancecount) of $($AllDCPId.DisplayName.Count): [$($config.displayname)] +---"

        if ($export) {
            if (!(Test-Path $outputpath\$PolicyExportFolderName -PathType Container)) {
                New-Item -Path $outputpath\$PolicyExportFolderName -ItemType Directory -Force | Out-Null
            }
            if ($output) {
                write-host "[Export]::: policy: [$($config.displayName)] to: $outputpath\$PolicyExportFolderName\$($config.displayName).json" -ForegroundColor Gray
            }
            $config | ConvertTo-Json -Depth 10 | Out-File $outputpath\$PolicyExportFolderName\$($config.displayName).json -Force
        }
    
        switch ($Config.'@odata.type') {
            "#microsoft.graph.windows10CompliancePolicy"    {$type = "Windows 10/11 compliance policy"}
            "#microsoft.graph.androidCompliancePolicy"      {$type = "Android compliance policy"}
            "#microsoft.graph.macOSCompliancePolicy"        {$type = "macOS compliance policy"}
            Default                                         {$type = $($Config.'@odata.type')}
        }
           
        if ($config.assignments.Count -gt 0) { # Assigment for device compliance found
            foreach ($assignment in $config.assignments) {
                $PSObjectResult = @()
                if (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $assignSource = $($assignment.source)
                    $assigntype = "Include"
                    $groupName = $groupDisplayName
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateDeviceCompliancePSObject -Name $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
        
                } elseif (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $assignSource = $($assignment.source)
                    $assigntype = "Exclude"
                    $groupName = $groupDisplayName
                    $version = $($config.dVersion)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateDeviceCompliancePSObject -Name $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
        
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Yellow"
                    $assignSource = $($assignment.source)
                    $assigntype = "Include"
                    $targetgroupid = $($assignment.target.groupId)
                    $Error.Clear()
                    $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                    if ($error.Count -gt 0) {
                        Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                        $groupName = "Please CHECK - Groupname not found"
                    }
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateDeviceCompliancePSObject -Name $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
        
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Magenta"
                    $assignSource = $($assignment.source)
                    $assigntype = "Exclude"
                    $targetgroupid = $($assignment.target.groupId)
                    $Error.Clear()
                    $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                    if ($error.Count -gt 0) {
                        Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                        $groupName = "Please CHECK - Groupname not found"
                    }
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateDeviceCompliancePSObject -Name $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
                }
        
                $listDeviceCompliance += $PSObjectResult
                if ($output) {
                        write-host "[$($assigntype)]::: assignment: Version: $version - Type: $($type) - Groupname: $($groupName) - Assignedtype: $($assigntype) - Assignsource: $($assignSource) - ID: $($config.id)" -ForegroundColor $foreground
                }
            }         
        
        } else { # No assigment found for device compliance
                    
            $assign = $false
            $foreground = "cyan"
            $version = $($config.Version)
            if ([string]::IsNullOrEmpty($version)) {
                $version = "N/A"
            }
            if ($output) {
                write-host "[NO]::: assignment: Version $($version) - Type: $($type) - ID: $($config.id)" -ForegroundColor $foreground
            }
            $PSObjectResult = CreateDeviceCompliancePSObject -Name $($config.displayName) -Version $($version)  -Type $type -Assigned $assign -Groupname "-" -Assignedtype "-" -Assignsource "-" -ID $($Config.id) -AssignedToSearchGroup $false
            $listDeviceCompliance += $PSObjectResult
        }
    
        # Adding Applications to DataGrid
        # $DataGridDeviceCompliance.AddChild($obj)
    }

    # Generate CSV
    if ($csv) {
        if (!(Test-Path $outputpath -PathType Container)) {
            New-Item -path $outputpath -ItemType Directory -Force | Out-Null
        }
    
        $listDeviceCompliance | export-csv -Path $outputpath\$outputname
    
    }
            
    # Show Grid
    if ($outgrid) {
        $listDeviceCompliance | Out-GridView
    }
}
# END OF DEVICE COMPLIANCE

# START OF DEVICE CONFIGURATION PROFILES
#DONE
Function GetDeviceConfigurationProfiles {

    Function CreateDeviceConfigurationPolicyPSObject {
        param(
            [parameter(Mandatory = $true)]
            [string]$Name,
            [parameter(Mandatory = $true)]
            [string]$Version,
            [parameter(Mandatory = $true)]
            [string]$Type,
            [parameter(Mandatory = $true)]
            [bool]$Assigned,
            [parameter(Mandatory = $true)]
            [bool]$AssignedToSearchGroup,
            [parameter(Mandatory = $true)]
            [string]$Groupname,
            [parameter(Mandatory = $true)]
            [string]$Assignedtype,
            [parameter(Mandatory = $true)]
            [string]$Assignsource,
            [parameter(Mandatory = $true)]
            [string]$ID
        )
    
        $obj = @()
        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "Name" -Value $Name
        $obj | Add-Member -MemberType NoteProperty -Name "Version" -Value $Version
        $obj | Add-Member -MemberType NoteProperty -Name "Type" -Value $Type
        $obj | Add-Member -MemberType NoteProperty -Name "Assigned" -Value $Assigned
        $obj | Add-Member -MemberType NoteProperty -Name "AssignedToSearchGroup" -Value $AssignedToSearchGroup
        $obj | Add-Member -MemberType NoteProperty -Name "Groupname" -Value $Groupname
        $obj | Add-Member -MemberType NoteProperty -Name "Assignedtype" -Value $Assignedtype
        $obj | Add-Member -MemberType NoteProperty -Name "Assignsource" -Value $Assignsource
        $obj | Add-Member -MemberType NoteProperty -Name "ID" -Value $ID
        return $obj
    
    }

    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    # DEVICE CONFIGURATION PROFILES
    # -------------------------------------------------------------------------------------------------------------------------
    # https://endpoint.microsoft.com/?feature.msaljs=false#view/Microsoft_Intune_DeviceSettings/DevicesMenu/~/configurationProfiles
    # https://endpoint.microsoft.com/?feature.msaljs=false#view/Microsoft_Intune_DeviceSettings/DevicesMenu/~/windows10UpdateRings
    # Profile Types:
    # - Domain Join
    # - Windows Health Monitoring
    # - Custom
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    write-host ""
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host "- DEVICE CONFIGURATION POLICIES ------------------------------------------------" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    Write-host " Searching for device configuration policies assigned to: $($groupDisplayName)" -ForegroundColor Magenta
    $AllDeviceConfig = (Invoke-MgGraphRequest -Method GET -uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$expand=Assignments").value
    Write-host " Number of device configurations policies found: $($AllDeviceConfig.DisplayName.Count)" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host ""
    Start-Sleep 3
    $PolicyExportFolderName = "DeviceConfigurationPolicies"
    $listDeviceConfigurationPolicyConfiguration = @()
    $PSObjectResult = @()
    $config = ""
    $type = ""
    $devicepolicycount = 0
    $outputname = "DeviceConfigurationPolicies.csv"
    
    Foreach ($Config in $AllDeviceConfig) {

        $devicepolicycount ++
        write-host "---+ Device configuration policy $($devicepolicycount) of $($AllDeviceConfig.DisplayName.Count): [$($config.displayname)] +---"

        # FOR TROUBLESHOOTING
        <#if (!($config.displayName -match "COS_WIN_ClientCertificate")) {
            continue

        }#>

        if ($export) {
            if (!(Test-Path $outputpath\$PolicyExportFolderName -PathType Container)) {
                New-Item -Path $outputpath\$PolicyExportFolderName -ItemType Directory -Force | Out-Null
            }
            if ($output) {
                write-host "[Exporting]::: policy: [$($config.displayName)] to: $outputpath\$PolicyExportFolderName\$($config.displayName).json" -ForegroundColor Gray
            }
            $config | ConvertTo-Json -Depth 10 | Out-File $outputpath\$PolicyExportFolderName\$($config.displayName).json -Force
        }
    
        switch ($Config.'@odata.type') {
            "#microsoft.graph.windows10CustomConfiguration"                     {$type = "Windows 10 custom configuration"}                        
            "#microsoft.graph.windows81TrustedRootCertificate"                  {$type = "Windows 8.1 trusted root certificate"}                        
            "#microsoft.graph.windowsWifiEnterpriseEAPConfiguration"            {$type = "Windows Wi-Fi configuration - Windows Wi-Fi enterprise EAP configuration"}
            "#microsoft.graph.windowsHealthMonitoringConfiguration"             {$type = "Windows health monitoring configuration"}
            "#microsoft.graph.windows10GeneralConfiguration"                    {$type = "Windows 10 general configuration"}
            "#microsoft.graph.windows81SCEPCertificateProfile"                  {$type = "Windows 8.1+ SCEP certificate profile"}
            "#microsoft.graph.windowsKioskConfiguration"                        {$type = "Windows Kiosk"}
            "#microsoft.graph.sharedPCConfiguration"                            {$type = "Shared PC configuration"}
            "#microsoft.graph.windowsDomainJoinConfiguration"                   {$type = "Windows Domain Join device configuration"}
            "#microsoft.graph.windows10DeviceFirmwareConfigurationInterface"    {$type = "Windows device firmware configuration interface"}
            "#microsoft.graph.windowsDeliveryOptimizationConfiguration"         {$type = "Windows Delivery Optimization configuration"}
            "#microsoft.graph.windows10TeamGeneralConfiguration"                {$type = "Windows 10 team general configuration)"}
            "#microsoft.graph.editionUpgradeConfiguration"                      {$type = "Windows 10 Edition Upgrade configuration"}
            "#microsoft.graph.windows10EasEmailProfileConfiguration"            {$type = "Windows 10 EAS email profile configuration"}
            "#microsoft.graph.windows10EndpointProtectionConfiguration"         {$type = "Windwos 10 endpoint protection configuration"}
            "#microsoft.graph.windowsIdentityProtectionConfiguration"           {$type = "Windows identity protection configuration"}
            "#microsoft.graph.windows10NetworkBoundaryConfiguration"            {$type = "Windows 10 Network Boundary Configuration"}
            "#microsoft.graph.windows10PkcsCertificateProfile"                  {$type = "Windows 10 Desktop and Mobile PKCS certificate profile"}
            "#microsoft.graph.windows10ImportedPFXCertificateProfile"           {$type = "Windows 10 Desktop and Mobile PFX Import certificate profile"}
            "#microsoft.graph.windowsUpdateForBusinessConfiguration"            {$type = "Windows Update for Business configuration"}
            "#microsoft.graph.macOSSoftwareUpdateConfiguration"                 {$type = "macOS software update configuration"}
            "#microsoft.graph.windowsWiredNetworkConfiguration"                 {$type = "Windows wired network configuration"}
            "#microsoft.graph.macOSGeneralDeviceConfiguration"                  {$type = "macOS general device configuration"}
            "#microsoft.graph.macOSEnterpriseWiFiConfiguration"                 {$type = "macOS enterprise Wi-Fi configuration"}
            "#microsoft.graph.macOSTrustedRootCertificate"                      {$type = "macOS trusted root certificate"}
            "#microsoft.graph.macOSPkcsCertificateProfile"                      {$type = "macOS PKCS certificate profile"}
            "#microsoft.graph.macOSScepCertificateProfile"                      {$type = "macOS SCEP certificate profile"}
            "#microsoft.graph.macOSDeviceFeaturesConfiguration"                 {$type = "macOS device features configuration profile"}
            "#microsoft.graph.macOSCustomConfiguration"                         {$type = "macOS custom configuration"}
            "#microsoft.graph.iosGeneralDeviceConfiguration"                    {$type = "iOS general device configuration"}
            Default {$type = "$($Config.'@odata.type')"}
        }
       
        if ($config.assignments.Count -gt 0) { # Assigment for device configuration found
            foreach ($assignment in $config.assignments) {
                $PSObjectResult = @()
                if (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $assignSource = $($assignment.source)
                    $assigntype = "Include"
                    $groupName = $groupDisplayName
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateDeviceConfigurationPolicyPSObject -Name $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
        
                } elseif (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $assignSource = $($assignment.source)
                    $assigntype = "Exclude"
                    $groupName = $groupDisplayName
                    $version = $($config.dVersion)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateDeviceConfigurationPolicyPSObject -Name $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
        
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Yellow"
                    $assignSource = $($assignment.source)
                    $assigntype = "Include"
                    $targetgroupid = $($assignment.target.groupId)
                    $Error.Clear()
                    $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                    if ($error.Count -gt 0) {
                        Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                        $groupName = "Please CHECK - Groupname not found"
                    }
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateDeviceConfigurationPolicyPSObject -Name $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
        
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Magenta"
                    $assignSource = $($assignment.source)
                    $assigntype = "Exclude"
                    $targetgroupid = $($assignment.target.groupId)
                    $Error.Clear()
                    $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                    if ($error.Count -gt 0) {
                        Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                        $groupName = "Please CHECK - Groupname not found"
                    }
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateDeviceConfigurationPolicyPSObject -Name $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
                }
        
                $listDeviceConfigurationPolicyConfiguration += $PSObjectResult
                if ($output) {
                        write-host "[$($assigntype)]::: assignment: Version: $version - Type: $($type) - Groupname: $($groupName) - Assignedtype: $($assigntype) - Assignsource: $($assignSource) - ID: $($config.id)" -ForegroundColor $foreground
                }
            }         
        
        } else { # No assigment found for device configuration
                    
            $assign = $false
            $foreground = "cyan"
            $version = $($config.Version)
            if ([string]::IsNullOrEmpty($version)) {
                $version = "N/A"
            }
            if ($output) {
                write-host "[NO]::: assignment: Version $($version) - Type: $($type) - ID: $($config.id)" -ForegroundColor $foreground
            }
            $PSObjectResult = CreateDeviceConfigurationPolicyPSObject -Name $($config.displayName) -Version $($version)  -Type $type -Assigned $assign -Groupname "-" -Assignedtype "-" -Assignsource "-" -ID $($Config.id) -AssignedToSearchGroup $false
            $listDeviceConfigurationPolicyConfiguration += $PSObjectResult
        }

        # Adding Applications to DataGrid
        # $DataGridDeviceConfiguration.AddChild($obj)
    }

    # Generate CSV
    if ($csv) {
        if (!(Test-Path $outputpath -PathType Container)) {
            New-Item -path $outputpath -ItemType Directory -Force | Out-Null
        }
    
        $listDeviceConfigurationPolicyConfiguration | export-csv -Path $outputpath\$outputname
    
    }
            
    # Show Grid
    if ($outgrid) {
        $listDeviceConfigurationPolicyConfiguration | Out-GridView
    }
}
# END OF DEVICE CONFIGURATION PROFILES

# START OF DEVICE CONFIGURATION ADMINISTRATIVE TEMPLATES
#DONE
Function GetDeviceConfigurationProfilesADM {

    Function CreateDeviceConfigurationPolicyPSObjectADM {
        param(
            [parameter(Mandatory = $true)]
            [string]$Name,
            [parameter(Mandatory = $true)]
            [string]$Version,
            [parameter(Mandatory = $true)]
            [bool]$Assigned,
            [parameter(Mandatory = $true)]
            [bool]$AssignedToSearchGroup,
            [parameter(Mandatory = $true)]
            [string]$Groupname,
            [parameter(Mandatory = $true)]
            [string]$Assignedtype,
            [parameter(Mandatory = $true)]
            [string]$ID
        )
    
        $obj = @()
        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "Name" -Value $Name
        $obj | Add-Member -MemberType NoteProperty -Name "Version" -Value $Version
        $obj | Add-Member -MemberType NoteProperty -Name "Type" -Value "Administrative Templates"
        $obj | Add-Member -MemberType NoteProperty -Name "Assigned" -Value $Assigned
        $obj | Add-Member -MemberType NoteProperty -Name "AssignedToSearchGroup" -Value $AssignedToSearchGroup
        $obj | Add-Member -MemberType NoteProperty -Name "Groupname" -Value $Groupname
        $obj | Add-Member -MemberType NoteProperty -Name "Assignedtype" -Value $Assignedtype
        $obj | Add-Member -MemberType NoteProperty -Name "ID" -Value $ID
        return $obj
    
    }

    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    # DEVICE CONFIGURATION ADMINISTRATIVE TEMPLATES
    # -------------------------------------------------------------------------------------------------------------------------
    # https://endpoint.microsoft.com/?feature.msaljs=false#view/Microsoft_Intune_DeviceSettings/DevicesMenu/~/configurationProfiles
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    write-host ""
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host "- DEVICE CONFIGURATION ADMINISTRATIVE TEMPLATES --------------------------------" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    Write-host " Searching for device configuration ADM policies assigned to: $($groupDisplayName)" -ForegroundColor Magenta
    $AllADMT = (Invoke-MgGraphRequest -Method GET -uri "https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations?`$expand=Assignments").value
    Write-host " Number of device configurations ADM policies found: $($AllADMT.DisplayName.Count)" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host ""
    Start-Sleep 3
    $PolicyExportFolderName = "DeviceConfigurationPoliciesADM"
    $listDeviceConfigurationPolicyConfigurationADM = @()
    $PSObjectResult = @()
    $config = ""
    $type = ""
    $devicepolicycountADM = 0
    $config = ""
    $type = "Administrative Templates"
    $outputname = "DeviceConfigurationPoliciesADM.csv"
    
    Foreach ($Config in $AllADMT) {

        $devicepolicycount ++
        write-host "---+ Device compliance $($devicepolicycountADM) of $($AllADMT.DisplayName.Count): [$($config.displayname)] +---"

        if ($export) {
            if (!(Test-Path $outputpath\$PolicyExportFolderName -PathType Container)) {
                New-Item -Path $outputpath\$PolicyExportFolderName -ItemType Directory -Force | Out-Null
            }
            if ($output) {
                write-host "Exporting policy: [$($config.displayName)] to: $outputpath\$PolicyExportFolderName\$($config.displayName).json" -ForegroundColor Gray
            }
            $config | ConvertTo-Json -Depth 10 | Out-File $outputpath\$PolicyExportFolderName\$($config.displayName).json -Force
        }


        if ($config.assignments.Count -gt 0) { # Assigment for device configuration found
            foreach ($assignment in $config.assignments) {
                $PSObjectResult = @()
                if (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $assigntype = "Include"
                    $groupName = $groupDisplayName
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateDeviceConfigurationPolicyPSObjectADM -Name $($config.displayName) -Version $($version) -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
        
                } elseif (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $assigntype = "Exclude"
                    $groupName = $groupDisplayName
                    $version = $($config.dVersion)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateDeviceConfigurationADMPolicyPSObject -Name $($config.displayName) -Version $($version) -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
        
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Yellow"
                    $assigntype = "Include"
                    $targetgroupid = $($assignment.target.groupId)
                    $Error.Clear()
                    $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                    if ($error.Count -gt 0) {
                        Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                        $groupName = "Please CHECK - Groupname not found"
                    }
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateDeviceConfigurationPolicyPSObjectADM -Name $($config.displayName) -Version $($version) -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
        
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Magenta"
                    $assigntype = "Exclude"
                    $targetgroupid = $($assignment.target.groupId)
                    $Error.Clear()
                    $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                    if ($error.Count -gt 0) {
                        Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                        $groupName = "Please CHECK - Groupname not found"
                    }
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateDeviceConfigurationPolicyPSObjectADM -Name $($config.displayName) -Version $($version) -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
                }
        
                $listDeviceConfigurationPolicyConfigurationADM += $PSObjectResult
                if ($output) {
                        write-host "[$($assigntype)]::: assignment: Version: $version - Type: $($type) - Groupname: $($groupName) - Assignedtype: $($assigntype) - ID: $($config.id)" -ForegroundColor $foreground
                }
            }         
        
        } else { # No assigment found for device configuration
                    
            $assign = $false
            $foreground = "cyan"
            $version = $($config.Version)
            if ([string]::IsNullOrEmpty($version)) {
                $version = "N/A"
            }
            if ($output) {
                write-host "[NO]::: assignment: Version $($version) - Type: $($type) - ID: $($config.id)" -ForegroundColor $foreground
            }
            $PSObjectResult = CreateDeviceConfigurationPolicyPSObjectADM -Name $($config.displayName) -Version $($version)  -Assigned $assign -Groupname "-" -Assignedtype "-" -ID $($Config.id) -AssignedToSearchGroup $false
            $listDeviceConfigurationPolicyConfigurationADM += $PSObjectResult
        }

        # Adding Applications to DataGrid
        # $DataGridDeviceConfiguration.AddChild($obj)
    }

    # Generate CSV
    if ($csv) {
        if (!(Test-Path $outputpath -PathType Container)) {
            New-Item -path $outputpath -ItemType Directory -Force | Out-Null
        }  
        $listDeviceConfigurationPolicyConfigurationADM | export-csv -Path $outputpath\$outputname
    }
            
    # Show Grid
    if ($outgrid) {
        $listDeviceConfigurationPolicyConfigurationADM | Out-GridView
    }
}
# END OF DEVICE CONFIGURATION ADMINISTRATIVE TEMPLATES

# START OF DEVICE CONFIGURATION POWERSHELL SCRIPTS
#DONE
Function GetPoshScripts {
    Function CreateDeviceConfigurationPolicyPSObjectPosh {
        param(
            [parameter(Mandatory = $true)]
            [string]$Name,
            [parameter(Mandatory = $true)]
            [bool]$Assigned,
            [parameter(Mandatory = $true)]
            [bool]$AssignedToSearchGroup,
            [parameter(Mandatory = $true)]
            [string]$Groupname,
            [parameter(Mandatory = $true)]
            [string]$Assignedtype,
            [parameter(Mandatory = $true)]
            [string]$ID
        )
    
        $obj = @()
        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "Name" -Value $Name
        $obj | Add-Member -MemberType NoteProperty -Name "Type" -Value "PowerShell Scripts"
        $obj | Add-Member -MemberType NoteProperty -Name "Assigned" -Value $Assigned
        $obj | Add-Member -MemberType NoteProperty -Name "AssignedToSearchGroup" -Value $AssignedToSearchGroup
        $obj | Add-Member -MemberType NoteProperty -Name "Groupname" -Value $Groupname
        $obj | Add-Member -MemberType NoteProperty -Name "Assignedtype" -Value $Assignedtype
        $obj | Add-Member -MemberType NoteProperty -Name "ID" -Value $ID
        return $obj
    
    }
    
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    # DEVICE CONFIGURATION POWERSHELL SCRIPTS
    # -------------------------------------------------------------------------------------------------------------------------
    # https://intune.microsoft.com/?feature.msaljs=true#view/Microsoft_Intune_DeviceSettings/DevicesMenu/~/scripts
    # -------------------------------------------------------------------------------------------------------------------------
    write-host ""
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host "- DEVICE CONFIGURATION POWERSHELL SCRIPTS --------------------------------------" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    Write-host " Searching for device configuration powershell scripts assigned to: $($groupDisplayName)" -ForegroundColor Magenta
    $DMS = (Invoke-MgGraphRequest -Method GET -uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts?`$expand=Assignments").value
    Write-host " Number of device configuration powershell scripts  found: $($DMS.DisplayName.Count)" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host ""
    Start-Sleep 3
    $PolicyExportFolderName = "DeviceConfigurationPowerShellScripts"
    $listDeviceConfigurationPolicyConfigurationPosh = @()
    $PSObjectResult = @()
    $config = ""
    $devicepolicycountPosh = 0
    $obj = @()
    $config = ""
    $type = "PowerShell Scripts"
    $outputname = "DeviceConfigurationPowerShellScripts.csv"
        
        
    Foreach ($Config in $DMS) {
    
        $devicepolicycountPosh ++
        write-host "---+ Device compliance $($devicepolicycountPosh) of $($DMS.DisplayName.Count): [$($config.displayname)] +---"
    
        if ($export) {
            if (!(Test-Path $outputpath\$PolicyExportFolderName -PathType Container)) {
                New-Item -Path $outputpath\$PolicyExportFolderName -ItemType Directory -Force | Out-Null
            }
            if ($output) {
                write-host "Exporting policy: [$($config.displayName)] to: $outputpath\$PolicyExportFolderName\$($config.displayName).json" -ForegroundColor Gray
            }
            $config | ConvertTo-Json -Depth 10 | Out-File $outputpath\$PolicyExportFolderName\$($config.displayName).json -Force
        }
    
    
        if ($config.assignments.Count -gt 0) { # Assigment for device configuration found
            foreach ($assignment in $config.assignments) {
                $PSObjectResult = @()
                if (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $assigntype = "Include"
                    $groupName = $groupDisplayName
                    if ($error.Count -gt 0) {
                        Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                        $groupName = "Please CHECK - Groupname not found"
                    }
                    $PSObjectResult = CreateDeviceConfigurationPolicyPSObjectPosh -Name $($config.displayName) -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
            
                } elseif (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $assigntype = "Exclude"
                    $groupName = $groupDisplayName
                    $PSObjectResult = CreateDeviceConfigurationPolicyPSObjectPosh -Name $($config.displayName) -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
            
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Yellow"
                    $assigntype = "Include"
                    $targetgroupid = $($assignment.target.groupId)
                    $Error.Clear()
                    $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                    if ($error.Count -gt 0) {
                        Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                        $groupName = "Please CHECK - Groupname not found"
                    }
                    $PSObjectResult = CreateDeviceConfigurationPolicyPSObjectPosh -Name $($config.displayName) -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
            
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Magenta"
                    $assigntype = "Exclude"
                    $targetgroupid = $($assignment.target.groupId)
                    $Error.Clear()
                    $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                    if ($error.Count -gt 0) {
                        Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                        $groupName = "Please CHECK - Groupname not found"
                    }
                    $PSObjectResult = CreateDeviceConfigurationPolicyPSObjectPosh -Name $($config.displayName) -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
                }
            
                $listDeviceConfigurationPolicyConfigurationPosh += $PSObjectResult
                if ($output) {
                        write-host "[$($assigntype)]::: assignment: Type: $($type) - Groupname: $($groupName) - Assignedtype: $($assigntype) - ID: $($config.id)" -ForegroundColor $foreground
                }
            }         
            
        } else { # No assigment found for device configuration
                        
            $assign = $false
            $foreground = "cyan"
            if ($output) {
                write-host "[NO]::: assignment: Type: $($type) - ID: $($config.id)" -ForegroundColor $foreground
            }
            $PSObjectResult = CreateDeviceConfigurationPolicyPSObjectPosh -Name $($config.displayName) -Assigned $assign -Groupname "-" -Assignedtype "-" -ID $($Config.id) -AssignedToSearchGroup $false
            $listDeviceConfigurationPolicyConfigurationPosh += $PSObjectResult
        }
    
            # Adding Applications to DataGrid
            # $DataGridDeviceConfiguration.AddChild($obj)
    }

    # Generate CSV
    if ($csv) {
        if (!(Test-Path $outputpath -PathType Container)) {
            New-Item -path $outputpath -ItemType Directory -Force | Out-Null
        }  
        $listDeviceConfigurationPolicyConfigurationPosh | export-csv -Path $outputpath\$outputname
    }
            
    # Show Grid
    if ($outgrid) {
        $listDeviceConfigurationPolicyConfigurationPosh | Out-GridView
    }
}
# END OF DEVICE CONFIGURATION POWERSHELL SCRIPTS

# START OF DEVICE CONFIGURATION SHELL SCRIPTS
#DONE
Function GetShellScripts {
    
    Function CreateDeviceConfigurationPolicyPSObjectShell {
        param(
            [parameter(Mandatory = $true)]
            [string]$Name,
            [parameter(Mandatory = $true)]
            [bool]$Assigned,
            [parameter(Mandatory = $true)]
            [bool]$AssignedToSearchGroup,
            [parameter(Mandatory = $true)]
            [string]$Groupname,
            [parameter(Mandatory = $true)]
            [string]$Assignedtype,
            [parameter(Mandatory = $true)]
            [string]$ID
        )
    
        $obj = @()
        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "Name" -Value $Name
        $obj | Add-Member -MemberType NoteProperty -Name "Type" -Value "PowerShell Scripts"
        $obj | Add-Member -MemberType NoteProperty -Name "Assigned" -Value $Assigned
        $obj | Add-Member -MemberType NoteProperty -Name "AssignedToSearchGroup" -Value $AssignedToSearchGroup
        $obj | Add-Member -MemberType NoteProperty -Name "Groupname" -Value $Groupname
        $obj | Add-Member -MemberType NoteProperty -Name "Assignedtype" -Value $Assignedtype
        $obj | Add-Member -MemberType NoteProperty -Name "ID" -Value $ID
        return $obj
    
    }
    
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    # DEVICE CONFIGURATION SHELL SCRIPTS
    # -------------------------------------------------------------------------------------------------------------------------
    # https://intune.microsoft.com/?feature.msaljs=true#view/Microsoft_Intune_DeviceSettings/DevicesMenu/~/scripts
    # -------------------------------------------------------------------------------------------------------------------------
    write-host ""
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host "- DEVICE CONFIGURATION SHELL SCRIPTS (NO LINUX)--------------------------------------" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    Write-host " Searching for device configuration shell scripts assigned to: $($groupDisplayName)" -ForegroundColor Magenta
    $DMSShell = (Invoke-MgGraphRequest -Method GET -uri "https://graph.microsoft.com/beta/deviceManagement/deviceShellScripts?`$expand=Assignments").value
    Write-host " Number of device configuration shell scripts  found: $($DMSShell.DisplayName.Count)" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host ""
    Start-Sleep 3
    $PolicyExportFolderName = "DeviceConfigurationShellScripts"
    $listDeviceConfigurationPolicyConfigurationShell = @()
    $PSObjectResult = @()
    $config = ""
    $devicepolicycountShell = 0
    $obj = @()
    $config = ""
    $type = "Shell Scripts"
    $outputname = "DeviceConfigurationShellScripts.csv"
        
    Foreach ($Config in $DMSShell) {

        $devicepolicycountShell ++
        write-host "---+ Device compliance $($devicepolicycountShell) of $($DMSShell.DisplayName.Count): [$($config.displayname)] +---"
    
        if ($export) {
            if (!(Test-Path $outputpath\$PolicyExportFolderName -PathType Container)) {
                New-Item -Path $outputpath\$PolicyExportFolderName -ItemType Directory -Force | Out-Null
            }
            if ($output) {
                write-host "Exporting policy: [$($config.displayName)] to: $outputpath\$PolicyExportFolderName\$($config.displayName).json" -ForegroundColor Gray
            }
            $config | ConvertTo-Json -Depth 10 | Out-File $outputpath\$PolicyExportFolderName\$($config.displayName).json -Force
        }
    
    
        if ($config.assignments.Count -gt 0) { # Assigment for device configuration found
            foreach ($assignment in $config.assignments) {
                $PSObjectResult = @()
                if (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $assigntype = "Include"
                    $groupName = $groupDisplayName
                    if ($error.Count -gt 0) {
                        Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                        $groupName = "Please CHECK - Groupname not found"
                    }
                    $PSObjectResult = CreateDeviceConfigurationPolicyPSObjectShell -Name $($config.displayName) -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
            
                } elseif (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $assigntype = "Exclude"
                    $groupName = $groupDisplayName
                    $PSObjectResult = CreateDeviceConfigurationPolicyPSObjectShell -Name $($config.displayName) -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
            
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Yellow"
                    $assigntype = "Include"
                    $targetgroupid = $($assignment.target.groupId)
                    $Error.Clear()
                    $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                    if ($error.Count -gt 0) {
                        Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                        $groupName = "Please CHECK - Groupname not found"
                    }
                    $PSObjectResult = CreateDeviceConfigurationPolicyPSObjectShell -Name $($config.displayName) -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
            
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Magenta"
                    $assigntype = "Exclude"
                    $targetgroupid = $($assignment.target.groupId)
                    $Error.Clear()
                    $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                    if ($error.Count -gt 0) {
                        Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                        $groupName = "Please CHECK - Groupname not found"
                    }
                    $PSObjectResult = CreateDeviceConfigurationPolicyPSObjectShell -Name $($config.displayName) -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
                }
            
                $listDeviceConfigurationPolicyConfigurationShell += $PSObjectResult
                if ($output) {
                        write-host "[$($assigntype)]::: assignment: Type: $($type) - Groupname: $($groupName) - Assignedtype: $($assigntype) - ID: $($config.id)" -ForegroundColor $foreground
                }
            }         
            
        } else { # No assigment found for device configuration
                        
            $assign = $false
            $foreground = "cyan"
            if ($output) {
                write-host "[NO]::: assignment: Type: $($type) - ID: $($config.id)" -ForegroundColor $foreground
            }
            $PSObjectResult = CreateDeviceConfigurationPolicyPSObjectShell -Name $($config.displayName) -Assigned $assign -Groupname "-" -Assignedtype "-" -ID $($Config.id) -AssignedToSearchGroup $false
            $listDeviceConfigurationPolicyConfigurationShell += $PSObjectResult
        }
    
            # Adding Applications to DataGrid
            # $DataGridDeviceConfiguration.AddChild($obj)
    }

    # Generate CSV
    if ($csv) {
        if (!(Test-Path $outputpath -PathType Container)) {
            New-Item -path $outputpath -ItemType Directory -Force | Out-Null
        }  
        $listDeviceConfigurationPolicyConfigurationShell | export-csv -Path $outputpath\$outputname
    }
            
    # Show Grid
    if ($outgrid) {
        $listDeviceConfigurationPolicyConfigurationShell | Out-GridView
    }
}
# END OF DEVICE CONFIGURATION SHELL SCRIPTS

# START OF DEVICE CONFIGURATION SETTINGS CATALOG
#DONE
Function GetDeviceConfigurationProfilesSettingsCatalog {

    Function CreateDeviceConfigurationSettingsPolicyPSObject {
        param(
            [parameter(Mandatory = $true)]
            [string]$Name,
            [parameter(Mandatory = $true)]
            [string]$Version,
            [parameter(Mandatory = $true)]
            [string]$Type,
            [parameter(Mandatory = $true)]
            [bool]$Assigned,
            [parameter(Mandatory = $true)]
            [bool]$AssignedToSearchGroup,
            [parameter(Mandatory = $true)]
            [string]$Groupname,
            [parameter(Mandatory = $true)]
            [string]$Assignedtype,
            [parameter(Mandatory = $true)]
            [string]$Assignsource,
            [parameter(Mandatory = $true)]
            [string]$ID
        )
    
        $obj = @()
        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "Name" -Value $Name
        $obj | Add-Member -MemberType NoteProperty -Name "Version" -Value $Version
        $obj | Add-Member -MemberType NoteProperty -Name "Type" -Value $Type
        $obj | Add-Member -MemberType NoteProperty -Name "Assigned" -Value $Assigned
        $obj | Add-Member -MemberType NoteProperty -Name "AssignedToSearchGroup" -Value $AssignedToSearchGroup
        $obj | Add-Member -MemberType NoteProperty -Name "Groupname" -Value $Groupname
        $obj | Add-Member -MemberType NoteProperty -Name "Assignedtype" -Value $Assignedtype
        $obj | Add-Member -MemberType NoteProperty -Name "Assignsource" -Value $Assignsource
        $obj | Add-Member -MemberType NoteProperty -Name "ID" -Value $ID
        return $obj
    
    }

   # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    # DEVICE CONFIGURATION SETTINGS CATALOG
    # -------------------------------------------------------------------------------------------------------------------------
    # https://endpoint.microsoft.com/?feature.msaljs=false#view/Microsoft_Intune_DeviceSettings/DevicesMenu/~/configurationProfiles
    # https://endpoint.microsoft.com/?feature.msaljs=false#view/Microsoft_Intune_Workflows/SecurityManagementMenu/~/firewall
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    write-host ""
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host "- DEVICE CONFIGURATION SETTINGS CATALOG ----------------------------------------" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    $AllSettingsCatalog = (Invoke-MgGraphRequest -Method GET -uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$expand=Assignments").value
    Write-host " Number of device configurations settings policies found: $($AllSettingsCatalog.Name.Count)" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host ""
    Start-Sleep 3
    $PolicyExportFolderName = "DeviceSettingsConfigurationPolicies"
    $listDeviceConfigurationPolicySettingsConfiguration = @()
    $PSObjectResult = @()
    $config = ""
    $type = "Settings Catalog"
    $devicesettingspolicycount = 0
    $outputname = "DeviceSettingsConfigurationPolicies.csv"

    Foreach ($Config in $AllSettingsCatalog) {

        $devicesettingspolicycount ++
        write-host "---+ Device configuration policy $($devicesettingspolicycount) of $($AllSettingsCatalog.Name.Count): [$($config.name)] +---"

        if ($export) {
            if (!(Test-Path $outputpath\$PolicyExportFolderName -PathType Container)) {
                New-Item -Path $outputpath\$PolicyExportFolderName -ItemType Directory -Force | Out-Null
            }
            if ($output) {
                write-host "Exporting policy: [$($config.Name)] to: $outputpath\$PolicyExportFolderName\$($config.Name).json" -ForegroundColor Gray
            }
            $config | ConvertTo-Json -Depth 10 | Out-File $outputpath\$PolicyExportFolderName\$($config.Name).json -Force
        }
       
        if ($config.assignments.Count -gt 0) { # Assigment for device configuration found
            foreach ($assignment in $config.assignments) {
                $PSObjectResult = @()
                if (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $assignSource = $($assignment.source)
                    $assigntype = "Include"
                    $groupName = $groupDisplayName
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateDeviceConfigurationSettingsPolicyPSObject -Name $($config.Name) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
        
                } elseif (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $assignSource = $($assignment.source)
                    $assigntype = "Exclude"
                    $groupName = $groupDisplayName
                    $version = $($config.dVersion)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateDeviceConfigurationSettingsPolicyPSObject -Name $($config.Name) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
        
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Yellow"
                    $assignSource = $($assignment.source)
                    $assigntype = "Include"
                    $targetgroupid = $($assignment.target.groupId)
                    $Error.Clear()
                    $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                    if ($error.Count -gt 0) {
                        Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                        $groupName = "Please CHECK - Groupname not found"
                    }
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateDeviceConfigurationSettingsPolicyPSObject -Name $($config.Name) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
        
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Magenta"
                    $assignSource = $($assignment.source)
                    $assigntype = "Exclude"
                    $targetgroupid = $($assignment.target.groupId)
                    $Error.Clear()
                    $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                    if ($error.Count -gt 0) {
                        Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                        $groupName = "Please CHECK - Groupname not found"
                    }
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateDeviceConfigurationSettingsPolicyPSObject -Name $($config.Name) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
                }
        
                $listDeviceConfigurationPolicySettingsConfiguration += $PSObjectResult
                if ($output) {
                        write-host "[$($assigntype)]::: assignment: Version: $version - Type: $($type) - Groupname: $($groupName) - Assignedtype: $($assigntype) - Assignsource: $($assignSource) - ID: $($config.id)" -ForegroundColor $foreground
                }
            }         
        
        } else { # No assigment found for device configuration
                    
            $assign = $false
            $foreground = "cyan"
            $version = $($config.Version)
            if ([string]::IsNullOrEmpty($version)) {
                $version = "N/A"
            }
            if ($output) {
                write-host "[NO]::: assignment: Version $($version) - Type: $($type) - ID: $($config.id)" -ForegroundColor $foreground
            }
            $PSObjectResult = CreateDeviceConfigurationSettingsPolicyPSObject -Name $($config.Name) -Version $($version)  -Type $type -Assigned $assign -Groupname "-" -Assignedtype "-" -Assignsource "-" -ID $($Config.id) -AssignedToSearchGroup $false
            $listDeviceConfigurationPolicySettingsConfiguration += $PSObjectResult
        }

        # Adding Applications to DataGrid
        # $DataGridDeviceConfiguration.AddChild($obj)
    }


    # Generate CSV
    if ($csv) {
        if (!(Test-Path $outputpath -PathType Container)) {
            New-Item -path $outputpath -ItemType Directory -Force | Out-Null
        }
    
        $listDeviceConfigurationPolicySettingsConfiguration | export-csv -Path $outputpath\$outputname
    
    }
            
    # Show Grid
    if ($outgrid) {
        $listDeviceConfigurationPolicySettingsConfiguration | Out-GridView
    }

}
# END
# END OF DEVICE CONFIGURATION SETTINGS CATALOG

#TBD
<#Function GetWindowsUpdateProfiles {#>
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    # Windows Feature Update profiles
    # -------------------------------------------------------------------------------------------------------------------------
    # https://endpoint.microsoft.com/?feature.msaljs=false#view/Microsoft_Intune_DeviceSettings/DevicesMenu/~/featureUpdateDeployments
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    <#write-host ""
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host "- WINDOWS FEATURE UPDATE PROFILES ----------------------------------------------" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    $AllFeatureUpdatePols = (Invoke-MgGraphRequest -Method GET -uri "https://graph.microsoft.com/beta/deviceManagement/windowsFeatureUpdateProfiles?`$expand=Assignments").value
    $list = @()
    $obj = @()
    $config = ""
    $type = ""
    write-host ""
    Write-host "Number of Windows Feature Update Profiles found: $($AllFeatureUpdatePolicies.Count)" -ForegroundColor red
    write-host ""

    Foreach ($Config in $AllFeatureUpdatePols) {

        if ($config.assignments.Count -gt 0) {
            foreach ($assignment in $config.assignments) {
                Write-Host $($assignment.target.groupid) - $config.displayName - $group.id
                if (($assignment.target.groupId -eq $group.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) {
                    $assign = $true
                    $foreground = "green"
                }
            }
        } else {
            $assign = $false
            $foreground = "red"
        }

        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "ProfileName" -Value $($Config.displayName)
        $obj | Add-Member -MemberType NoteProperty -Name "FeatureUpdateVersion" -Value ($Config.featureUpdateVersion)
        $obj | Add-Member -MemberType NoteProperty -Name "EndofSupport" -Value ($Config.endOfSupportDate)
        $obj | Add-Member -MemberType NoteProperty -Name "Assigned" -Value $assign
        $obj | Add-Member -MemberType NoteProperty -Name "Description" -Value $($config.description)
        $list += $obj
        # Adding Data to DataGrid
        # $DataGridFeatureUpdates.AddChild($obj)
  
        write-host "$($Config.displayname) - Standard"-ForegroundColor $foreground
    }
}#>

<#TBD
Function GetWindowsQualityProfiles {
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    # Windows Quality Update profiles
    # -------------------------------------------------------------------------------------------------------------------------
    # https://endpoint.microsoft.com/#view/Microsoft_Intune_DeviceSettings/DevicesMenu/~/windows10QualityUpdate
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    write-host ""
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host "- WINDOWS QUALITY UPDATE PROFILES ----------------------------------------------" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    $AllQualityUpdatePols = (Invoke-MgGraphRequest -Method GET -uri "https://graph.microsoft.com/beta/deviceManagement/windowsQualityUpdateProfiles?`$expand=Assignments").value
    $list = @()
    $obj = @()
    $config = ""
    $type = ""
    write-host ""
    Write-host "Number of Windows Quality Update Profiles found: $($AllQualityUpdatePolicies.Count)" -ForegroundColor red
    write-host ""

    Foreach ($Config in $AllQualityUpdatePols) {
    
        if ($config.assignments.Count -gt 0) {
            foreach ($assignment in $config.assignments) {
                Write-Host $($assignment.target.groupid) - $config.displayName - $group.id
                if (($assignment.target.groupId -eq $group.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) {
                    $assign = $true
                    $foreground = "green"
                }
            }
        } else {
            $assign = $false
            $foreground = "red"
        }

        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "ProfileName" -Value $($Config.displayName)
        $obj | Add-Member -MemberType NoteProperty -Name "QualityUpdateRelease" -Value $($config.expeditedUpdateSettings.qualityUpdateRelease)
        $obj | Add-Member -MemberType NoteProperty -Name "DaysUntilForcedReboot" -Value $($config.expeditedUpdateSettings.daysUntilForcedReboot)
        $obj | Add-Member -MemberType NoteProperty -Name "Assigned" -Value $assign
        $obj | Add-Member -MemberType NoteProperty -Name "Description" -Value $($config.description)
        $list += $obj
        # Adding Data to DataGrid
        # $DataGridQualityUpdates.AddChild($obj)
  
        write-host "$($Config.displayname) - Standard"-ForegroundColor $foreground
    }
}#>

# START OF AUTOPILOT PROFILES
#DONE
Function GetAutoPilotProfiles {

    Function CreateAutoPilotDeploymentProfilesPolicyPSObject {
        param(
            [parameter(Mandatory = $true)]
            [string]$Name,
            [parameter(Mandatory = $true)]
            [string]$Version,
            [parameter(Mandatory = $true)]
            [string]$Type,
            [parameter(Mandatory = $true)]
            [bool]$Assigned,
            [parameter(Mandatory = $true)]
            [bool]$AssignedToSearchGroup,
            [parameter(Mandatory = $true)]
            [string]$Groupname,
            [parameter(Mandatory = $true)]
            [string]$Assignedtype,
            [parameter(Mandatory = $true)]
            [string]$Assignsource,
            [parameter(Mandatory = $true)]
            [string]$ID
        )
    
        $obj = @()
        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "Name" -Value $Name
        $obj | Add-Member -MemberType NoteProperty -Name "Version" -Value $Version
        $obj | Add-Member -MemberType NoteProperty -Name "Type" -Value $Type
        $obj | Add-Member -MemberType NoteProperty -Name "Assigned" -Value $Assigned
        $obj | Add-Member -MemberType NoteProperty -Name "AssignedToSearchGroup" -Value $AssignedToSearchGroup
        $obj | Add-Member -MemberType NoteProperty -Name "Groupname" -Value $Groupname
        $obj | Add-Member -MemberType NoteProperty -Name "Assignedtype" -Value $Assignedtype
        $obj | Add-Member -MemberType NoteProperty -Name "Assignsource" -Value $Assignsource
        $obj | Add-Member -MemberType NoteProperty -Name "ID" -Value $ID
        return $obj
    
    }

    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    # Windows Autopilot Deployment Profiles
    # -------------------------------------------------------------------------------------------------------------------------
    # https://endpoint.microsoft.com/?feature.msaljs=false#view/Microsoft_Intune_Enrollment/AutopilotDeploymentProfiles.ReactView
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    write-host ""
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host "- WINDOWS AUTOPILOT DEPLOYMENT PROFILES ----------------------------------------" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    $AllAutoPilotProfiles = (Invoke-MgGraphRequest -Method GET -uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles?`$expand=Assignments").value
    Write-host " Number of windows deplyoment profiles found: $($AllAutoPilotProfiles.DisplayName.Count)" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host ""
    Start-Sleep 3
    $PolicyExportFolderName = "AutopilotDeploymentProfile"
    $listautopilotdeplyomentprofiles = @()
    $PSObjectResult = @()
    $config = ""
    $type = ""
    $autopilotdeplyomentprofilescount = 0
    $outputname = "AutopilotDeploymentProfile.csv"


    Foreach ($Config in $AllAutoPilotProfiles) {

        $autopilotdeplyomentprofilescount ++
        write-host "---+ Device configuration policy $($autopilotdeplyomentprofilescount) of $($AllAutoPilotProfiles.DisplayName.Count): [$($config.displayname)] +---"

        if ($export) {
            if (!(Test-Path $outputpath\$PolicyExportFolderName -PathType Container)) {
                New-Item -Path $outputpath\$PolicyExportFolderName -ItemType Directory -Force | Out-Null
            }
            if ($output) {
                write-host "Exporting policy: [$($config.displayName)] to: $outputpath\$PolicyExportFolderName\$($config.displayName).json" -ForegroundColor Gray
            }
            $config | ConvertTo-Json -Depth 10 | Out-File $outputpath\$PolicyExportFolderName\$($config.displayName).json -Force
        }
    
        switch ($Config.'@odata.type') {
            "#microsoft.graph.azureADWindowsAutopilotDeploymentProfile"         {$type = "Windows Autopilot Deployment Profile"}                        
            Default {$type = "$($Config.'@odata.type')"}
        }
       
        if ($config.assignments.Count -gt 0) { # Assigment for device configuration found
            foreach ($assignment in $config.assignments) {
                $PSObjectResult = @()
                if (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $assignSource = $($assignment.source)
                    $assigntype = "Include"
                    $groupName = $groupDisplayName
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateAutoPilotDeploymentProfilesPolicyPSObject -Name $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
        
                } elseif (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $assignSource = $($assignment.source)
                    $assigntype = "Exclude"
                    $groupName = $groupDisplayName
                    $version = $($config.dVersion)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateAutoPilotDeploymentProfilesPolicyPSObject -Name $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
        
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Yellow"
                    $assignSource = $($assignment.source)
                    $assigntype = "Include"
                    $targetgroupid = $($assignment.target.groupId)
                    $Error.Clear()
                    $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                    if ($error.Count -gt 0) {
                        Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                        $groupName = "Please CHECK - Groupname not found"
                    }
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateAutoPilotDeploymentProfilesPolicyPSObject -Name $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
        
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Magenta"
                    $assignSource = $($assignment.source)
                    $assigntype = "Exclude"
                    $targetgroupid = $($assignment.target.groupId)
                    $Error.Clear()
                    $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                    if ($error.Count -gt 0) {
                        Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                        $groupName = "Please CHECK - Groupname not found"
                    }
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateAutoPilotDeploymentProfilesPolicyPSObject -Name $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
                }
        
                $listautopilotdeplyomentprofiles += $PSObjectResult
                if ($output) {
                        write-host "[$($assigntype)]::: assignment: Version: $version - Type: $($type) - Groupname: $($groupName) - Assignedtype: $($assigntype) - Assignsource: $($assignSource) - ID: $($config.id)" -ForegroundColor $foreground
                }
            }         
        
        } else { # No assigment found for device configuration
                    
            $assign = $false
            $foreground = "cyan"
            $version = $($config.Version)
            if ([string]::IsNullOrEmpty($version)) {
                $version = "N/A"
            }
            if ($output) {
                write-host "[NO]::: assignment: Version $($version) - Type: $($type) - ID: $($config.id)" -ForegroundColor $foreground
            }
            $PSObjectResult = CreateAutoPilotDeploymentProfilesPolicyPSObject -Name $($config.displayName) -Version $($version)  -Type $type -Assigned $assign -Groupname "-" -Assignedtype "-" -Assignsource "-" -ID $($Config.id) -AssignedToSearchGroup $false
            $listautopilotdeplyomentprofiles += $PSObjectResult
        }

        # Adding Applications to DataGrid
        # $DataGridDeviceConfiguration.AddChild($obj)
    }

    # Generate CSV
    if ($csv) {
        if (!(Test-Path $outputpath -PathType Container)) {
            New-Item -path $outputpath -ItemType Directory -Force | Out-Null
        }
    
        $listautopilotdeplyomentprofiles | export-csv -Path $outputpath\$outputname
    
    }
            
    # Show Grid
    if ($outgrid) {
        $listautopilotdeplyomentprofiles | Out-GridView
    }
}
# END OF AUTOPILOT PROFILES

# START OF ESP PAGES
# DONE
Function GetESPPages {

    Function CreateESPPagesPolicyPSObject {
        param(
            [parameter(Mandatory = $true)]
            [string]$Name,
            [parameter(Mandatory = $true)]
            [string]$Version,
            [parameter(Mandatory = $true)]
            [string]$Type,
            [parameter(Mandatory = $true)]
            [bool]$Assigned,
            [parameter(Mandatory = $true)]
            [bool]$AssignedToSearchGroup,
            [parameter(Mandatory = $true)]
            [string]$Groupname,
            [parameter(Mandatory = $true)]
            [string]$Assignedtype,
            [parameter(Mandatory = $true)]
            [string]$Assignsource,
            [parameter(Mandatory = $true)]
            [string]$ID
        )
    
        $obj = @()
        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "Name" -Value $Name
        $obj | Add-Member -MemberType NoteProperty -Name "Version" -Value $Version
        $obj | Add-Member -MemberType NoteProperty -Name "Type" -Value $Type
        $obj | Add-Member -MemberType NoteProperty -Name "Assigned" -Value $Assigned
        $obj | Add-Member -MemberType NoteProperty -Name "AssignedToSearchGroup" -Value $AssignedToSearchGroup
        $obj | Add-Member -MemberType NoteProperty -Name "Groupname" -Value $Groupname
        $obj | Add-Member -MemberType NoteProperty -Name "Assignedtype" -Value $Assignedtype
        $obj | Add-Member -MemberType NoteProperty -Name "Assignsource" -Value $Assignsource
        $obj | Add-Member -MemberType NoteProperty -Name "ID" -Value $ID
        return $obj
    
    }

    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    # Enrollment Status Page
    # -------------------------------------------------------------------------------------------------------------------------
    # https://endpoint.microsoft.com/?feature.msaljs=false#view/Microsoft_Intune_Enrollment/EnrollmentStatusPageProfileListBlade
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    write-host ""
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host "- ENROLLMENT STATUS PAGE -------------------------------------------------------" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    $AllEnrollPages = (Invoke-MgGraphRequest -Method GET -uri "https://graph.microsoft.com/beta/deviceManagement/deviceEnrollmentConfigurations?`$expand=Assignments").value
    Write-host " Number of enrollemnt status pages found: $($AllEnrollPages.DisplayName.Count)" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host ""
    Start-Sleep 3
    $PolicyExportFolderName = "EnrollmentPages"
    $listesppages = @()
    $PSObjectResult = @()
    $config = ""
    $type = ""
    $esppagescount = 0
    $outputname = "EnrollmentPages.csv"

    Foreach ($Config in $AllEnrollPages) {

        $esppagescount ++
        write-host "---+ Device configuration policy $($esppagescount) of $($AllEnrollPages.DisplayName.Count): [$($config.displayname)] +---"

        if ($export) {
            if (!(Test-Path $outputpath\$PolicyExportFolderName -PathType Container)) {
                New-Item -Path $outputpath\$PolicyExportFolderName -ItemType Directory -Force | Out-Null
            }
            if ($output) {
                write-host "Exporting policy: [$($config.displayName)] to: $outputpath\$PolicyExportFolderName\$($config.displayName).json" -ForegroundColor Gray
            }
            $config | ConvertTo-Json -Depth 10 | Out-File $outputpath\$PolicyExportFolderName\$($config.displayName).json -Force
        }
    
        switch ($Config.'@odata.type') {
            "#microsoft.graph.windows10EnrollmentCompletionPageConfiguration"       {$type = "Windows 10 Enrollment Status Page Configuration"}                        
            "#microsoft.graph.deviceEnrollmentPlatformRestrictionsConfiguration"    {$type = "Device Enrollment Configuration that restricts the types of devices a user can enroll"}
            "#microsoft.graph.deviceEnrollmentLimitConfiguration"                   {$type = "Device Enrollment Configuration that restricts the types of devices a user can enroll"}
            "#microsoft.graph.deviceEnrollmentPlatformRestrictionConfiguration"     {$type = "Device Enrollment Configuration that restricts the types of devices a user can enroll"}
            "#microsoft.graph.deviceEnrollmentWindowsHelloForBusinessConfiguration" {$type = "Device enrollment Windows Hello for Business configuration"}
            Default {$type = "$($Config.'@odata.type')"}
        }
       
        if ($config.assignments.Count -gt 0) { # Assigment for device configuration found
            foreach ($assignment in $config.assignments) {
                $PSObjectResult = @()
                if (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $assignSource = $($assignment.source)
                    $assigntype = "Include"
                    $groupName = $groupDisplayName
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateESPPagesPolicyPSObject -Name $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
        
                } elseif (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $assignSource = $($assignment.source)
                    $assigntype = "Exclude"
                    $groupName = $groupDisplayName
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateESPPagesPolicyPSObject -Name $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
        
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Yellow"
                    $assignSource = $($assignment.source)
                    $assigntype = "Include"
                    $targetgroupid = $($assignment.target.groupId)
                    if ([string]::IsNullOrEmpty($assignment.target.groupId)) {
                        $groupname = "All users and devices"
                    } else {
                        $Error.Clear()
                        $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                        if ($error.Count -gt 0) {
                            Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                            $groupName = "Please CHECK - Groupname not found"
                        }
                    }
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateESPPagesPolicyPSObject -Name $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
        
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Magenta"
                    $assignSource = $($assignment.source)
                    $assigntype = "Exclude"
                    $targetgroupid = $($assignment.target.groupId)
                    if ([string]::IsNullOrEmpty($assignment.target.groupId)) {
                        $groupname = "All users and devices"
                    } else {
                        $Error.Clear()
                        $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                        if ($error.Count -gt 0) {
                            Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                            $groupName = "Please CHECK - Groupname not found"
                        }
                    }
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateESPPagesPolicyPSObject -Name $($config.displayName) -Version $($version) -Type $type -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -Assignsource $assignSource -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup
                }
        
                $listesppages += $PSObjectResult
                if ($output) {
                        write-host "[$($assigntype)]::: assignment: Version: $version - Type: $($type) - Groupname: $($groupName) - Assignedtype: $($assigntype) - Assignsource: $($assignSource) - ID: $($config.id)" -ForegroundColor $foreground
                }
            }         
        
        } else { # No assigment found for device configuration
                    
            $assign = $false
            $foreground = "cyan"
            $version = $($config.Version)
            if ([string]::IsNullOrEmpty($version)) {
                $version = "N/A"
            }
            if ($output) {
                write-host "[NO]::: assignment: Version $($version) - Type: $($type) - ID: $($config.id)" -ForegroundColor $foreground
            }
            $PSObjectResult = CreateESPPagesPolicyPSObject -Name $($config.displayName) -Version $($version)  -Type $type -Assigned $assign -Groupname "-" -Assignedtype "-" -Assignsource "-" -ID $($Config.id) -AssignedToSearchGroup $false
            $listesppages += $PSObjectResult
        }

        # Adding Applications to DataGrid
        # $DataGridDeviceConfiguration.AddChild($obj)
    }

    # Generate CSV
    if ($csv) {
        if (!(Test-Path $outputpath -PathType Container)) {
            New-Item -path $outputpath -ItemType Directory -Force | Out-Null
        }
    
        $listesppages | export-csv -Path $outputpath\$outputname
    
    }
            
    # Show Grid
    if ($outgrid) {
        $listesppages | Out-GridView
    }
}
# END OF ESP PAGES


<#Function GetEndPointSecurityProfiles {
    
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    # Endpoint Security: 
    # Bitlocker
    # Endpoint detection and response
    # Attack surface reduction
    # Account protection
    # Security Baselines
    # 
    # -------------------------------------------------------------------------------------------------------------------------
    # https://endpoint.microsoft.com/?feature.msaljs=false#view/Microsoft_Intune_Workflows/SecurityManagementMenu/~/diskencryption
    # https://endpoint.microsoft.com/?feature.msaljs=false#view/Microsoft_Intune_Workflows/SecurityManagementMenu/~/edr
    # https://endpoint.microsoft.com/?feature.msaljs=false#view/Microsoft_Intune_Workflows/SecurityManagementMenu/~/asr
    # https://endpoint.microsoft.com/?feature.msaljs=false#view/Microsoft_Intune_Workflows/SecurityManagementMenu/~/accountprotection
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    write-host ""
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host "- ENDPOINT SECURITY ------------------------------------------------------------" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    $AllEndPointSecProfiles = (Invoke-MgGraphRequest -Method GET -uri "https://graph.microsoft.com/beta/deviceManagement/intents?`$expand=Assignments").value
    $list = @()
    $obj = @()
    $config = ""
    $type = ""
    $count = 0
    $outputname = "EndpointSecurityPolicies.csv"
    
    foreach ($template in $AllEndPointSecProfiles){
        $assign = $false

        write-host "$($template.displayName) - $($template.description)"

        $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/intents/$($template.id)/settings"
        $templateDetail = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/templates/$($template.templateId)"
        $config = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/intents/$($template.id)/assignments").value

        if ($templateDetail.templateSubtype -eq "none") {
            switch ($templateDetail.templateType) {
                "microsoftEdgeSecurityBaseline" {$type = "Microsoft Edge Security baseline"}
                "securityBaseline" {$type = "Security Baseline for Windows 10 and later"}
                default {write-host "Profiletype not found for profile: $($template.displayName) - $($Config.'@odata.type')" -ForegroundColor yellow}
            }

        } else {

            switch ($templateDetail.templateSubtype) {
                "attackSurfaceReduction" {$type = "Attack surface reduction"}
                "accountProtection" {$type = "Account protection"}
                "endpointDetectionReponse" {$type = "Endpoint detection and response"}
                "diskEncryption" {$type = "Disk encryption"}
                Default {write-host "Profiletype not found for profile: $($template.displayName) - $($Config.'@odata.type')" -ForegroundColor yellow}
            }

        }

        if ($config.target.groupId -gt 0) {
            foreach ($assignment in $config) {
                write-host "Target Group ID - $($assignment.target.groupId) - GroupID: $($group.id) - Assignmenttype: $($assignment.target.deviceAndAppManagementAssignmentFilterType)"
                if (($assignment.target.groupId -eq $group.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) {
                    $assign = $true
                    $color = "green"
                    ++$count
                    break
                } else {
                    $assign = $false
                    $color = "red"
                }
            }
        } else {
            $assign = $false
            $color = "red"
        }

        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "ProfileName" -Value $($template.displayName)
        $obj | Add-Member -MemberType NoteProperty -Name "Type" -Value $($Type)
        $obj | Add-Member -MemberType NoteProperty -Name "Assigned" -Value $assign
        $obj | Add-Member -MemberType NoteProperty -Name "Description" -Value $($template.description)
        $list += $obj

        # Adding Data to DataGrid
        # $DataGridEndpointSecurity.AddChild($obj)
    
        write-host "Profilename: $($template.displayName) - Profiltype: $($Type) - Assigned: $($assign) - Description: $($template.description)" -ForegroundColor $color

    }


    # Generate CSV
    if ($csv) {
        if (!(Test-Path $outputpath -PathType Container)) {
            New-Item -path $outputpath -ItemType Directory -Force | Out-Null
        }
    
        $listesppages | export-csv -Path $outputpath\$outputname
    
    }
            
    # Show Grid
    if ($outgrid) {
        $listesppages | Out-GridView
    }


}#>

# START OF REMEDIATION SCRIPTS
# DONE
Function GetRemediationScripts {
    
    Function CreateRemediationScriptsPSObject {
        param(
            [parameter(Mandatory = $true)]
            [string]$Name,
            [parameter(Mandatory = $true)]
            [string]$Version,
            [parameter(Mandatory = $true)]
            [bool]$Assigned,
            [parameter(Mandatory = $true)]
            [bool]$AssignedToSearchGroup,
            [parameter(Mandatory = $true)]
            [string]$Groupname,
            [parameter(Mandatory = $true)]
            [string]$Assignedtype,
            [parameter(Mandatory = $true)]
            [string]$type,
            [parameter(Mandatory = $true)]
            [string]$interval,
            [parameter(Mandatory = $true)]
            [string]$time,
            [parameter(Mandatory = $true)]
            [string]$ID
        )
    
        $obj = @()
        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "Name" -Value $Name
        $obj | Add-Member -MemberType NoteProperty -Name "Version" -Value $Version
        $obj | Add-Member -MemberType NoteProperty -Name "Assigned" -Value $Assigned
        $obj | Add-Member -MemberType NoteProperty -Name "AssignedToSearchGroup" -Value $AssignedToSearchGroup
        $obj | Add-Member -MemberType NoteProperty -Name "Groupname" -Value $Groupname
        $obj | Add-Member -MemberType NoteProperty -Name "Assignedtype" -Value $Assignedtype
        $obj | Add-Member -MemberType NoteProperty -Name "ScheduleType" -Value $type
        $obj | Add-Member -MemberType NoteProperty -Name "Interval" -Value $interval
        $obj | Add-Member -MemberType NoteProperty -Name "Time" -Value $interval
        $obj | Add-Member -MemberType NoteProperty -Name "ID" -Value $ID
        return $obj
    
    }
    
    
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    # Remediation Scripts
    # -------------------------------------------------------------------------------------------------------------------------
    # https://endpoint.microsoft.com/?feature.msaljs=false#view/Microsoft_Intune_Enrollment/UXAnalyticsMenu/~/proactiveRemediations
    # -------------------------------------------------------------------------------------------------------------------------
    # -------------------------------------------------------------------------------------------------------------------------
    write-host ""
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    write-host "- REMEDIATION SCRIPTS ----------------------------------------------------------" -ForegroundColor Magenta
    write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
    $AllRemediationScripts = (Invoke-MgGraphRequest -Method GET -uri "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts?`$expand=Assignments").value
    Write-host " Number of remediation scripts found: $($AllRemediationScripts.DisplayName.Count)" -ForegroundColor Magenta
    $listremediatonscripts = @()
    $obj = @()
    $config = ""
    $PolicyExportFolderName = "Remediationscripts"
    $outputname = "RemediationScripts.csv"
    $remediationscriptcount = 0
    
    Foreach ($Config in $AllRemediationScripts) {
    
        $version = "" 
        $assign = ""
        $assigntype = ""
        $AssignedToSearchGroup = ""
        
        <#if (!($config.displayName -match "HPConnect -EM_WIN_HPC_DD_Broad")) {
            continue
        }#>
    
        $remediationscriptcount ++
        write-host "---+ Remediation script $($remediationscriptcount) of $($AllRemediationScripts.DisplayName.Count): [$($config.displayname)] +---"
    
        if ($export) {
            if (!(Test-Path $outputpath\$PolicyExportFolderName -PathType Container)) {
                New-Item -Path $outputpath\$PolicyExportFolderName -ItemType Directory -Force | Out-Null
            }
            if ($output) {
                write-host "Exporting policy: [$($config.displayName)] to: $outputpath\$PolicyExportFolderName\$($config.displayName).json" -ForegroundColor Gray
            }
            $config | ConvertTo-Json -Depth 10 | Out-File $outputpath\$PolicyExportFolderName\$($config.displayName).json -Force
        }
    
        if ($config.assignments.Count -gt 0) { # Assigment for device configuration found
            foreach ($assignment in $config.assignments) {
                
                switch ($assignment.runSchedule.'@odata.type') {
                    "#microsoft.graph.deviceHealthScriptRunOnceSchedule"       {$type = "Run once schedule"}                        
                    "#microsoft.graph.deviceHealthScriptDailySchedule"         {$type = "Daily"}
                    "#microsoft.graph.deviceHealthScriptHourlySchedule"        {$type = "Hourly"}
                    Default {$type = "$($Config.'@odata.type')"}
                }
    
                if ($type -match "hourly") {
                    $time = "N/A"
                } else {
                    $time = $($assignment.runSchedule.time)
                    if ($null -eq $time) {
                        $time = "N/A"
                    }
                }
    
                write-host "Time: $($time) - Type: $($type) - Interval: $($assignment.runSchedule.interval) " -ForegroundColor Blue
                $PSObjectResult = @()
                if (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $interval = $($assignment.runSchedule.interval)
                    $foreground = "Green"
                    $assigntype = "Include"
                    $groupName = $groupDisplayName
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateRemediationScriptsPSObject -Name $($config.displayName) -Version $($version) -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup -interval $($interval)  -type $($type) -time $($time)
        
                } elseif (($assignment.target.groupId -eq $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for group found
                    $assign = $true
                    $AssignedToSearchGroup = $true
                    $foreground = "Green"
                    $interval = $($assignment.runSchedule.interval)
                    $assigntype = "Exclude"
                    $groupName = $groupDisplayName
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateRemediationScriptsPSObject -Name $($config.displayName) -Version $($version) -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup -interval $($interval) -type $($type) -time $($time)
        
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -notlike "*exclusion*")) { # /// include assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $interval = $($assignment.runSchedule.interval)
                    $foreground = "Yellow"
                    $assigntype = "Include"
                    $targetgroupid = $($assignment.target.groupId)
                    if ([string]::IsNullOrEmpty($assignment.target.groupId)) {
                        $groupname = "All users and devices"
                    } else {
                        $Error.Clear()
                        $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                        if ($error.Count -gt 0) {
                            Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                            $groupName = "Please CHECK - Groupname not found"
                        }
                    }
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateRemediationScriptsPSObject -Name $($config.displayName) -Version $($version) -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup -interval $($interval) -type $($type) -time $($time)
        
                } elseif (($assignment.target.groupId -ne $GroupInfo.id) -and ($assignment.target.'@odata.type' -like "*exclusion*")) { # /// exclude assigmnent for another group found
                    $assign = $true
                    $AssignedToSearchGroup = $false
                    $foreground = "Magenta"
                    $assigntype = "Exclude"
                    $targetgroupid = $($assignment.target.groupId)
                    $interval = "N/A"
                    $type = "N/A"
                    $time = "N/A"
                    if ([string]::IsNullOrEmpty($assignment.target.groupId)) {
                        $groupname = "All users and devices"
                    } else {
                        $Error.Clear()
                        $groupName = (Get-MgGroup -Filter "id eq '$targetgroupid'" -ErrorAction SilentlyContinue).displayname
                        if ($error.Count -gt 0) {
                            Write-host "!---- ERROR OCCURED: $($Error[0].Exception.Message) ---!" -ForegroundColor Red
                            $groupName = "Please CHECK - Groupname not found"
                        }
                    }
                    $version = $($config.Version)
                    if ([string]::IsNullOrEmpty($version)) {
                        $version = "N/A"
                    }
                    $PSObjectResult = CreateRemediationScriptsPSObject -Name $($config.displayName) -Version $($version) -Assigned $assign -Groupname $($groupName) -Assignedtype $assigntype -ID $($Config.id) -AssignedToSearchGroup $AssignedToSearchGroup -interval $interval -type $type -time $($time)
                }
        
                $listremediatonscripts += $PSObjectResult
                if ($output) {
                        write-host "[$($assigntype)]::: assignment: Version: $version - Groupname: $($groupName) - Assignedtype: $($assigntype) - ID: $($config.id) - Type: $($type) - Interval: $($interval) - Time: $($time)" -ForegroundColor $foreground
                }
            }         
        
        } else { # No assigment found for device configuration
                    
            $assign = $false
            $foreground = "cyan"
            $type = "N/A"
            $interval = "N/A"
            $time = "N/A"
            $version = $($config.Version)
            if ([string]::IsNullOrEmpty($version)) {
                $version = "N/A"
            }
            if ($output) {
                write-host "[NO]::: assignment: Version $($version) - ID: $($config.id)" -ForegroundColor $foreground
            }
            $PSObjectResult = CreateRemediationScriptsPSObject -Name $($config.displayName) -Version $($version) -Assigned $assign -Groupname "N/A" -Assignedtype "NOT Assigned" -ID $($Config.id) -AssignedToSearchGroup $false -interval $interval -type $type -time $($time)
            $listremediatonscripts += $PSObjectResult
        }
    
 
        # Adding Applications to DataGrid
        # $DataGridDeviceConfiguration.AddChild($obj)
    }

    # Generate CSV
    if ($csv) {
        if (!(Test-Path $outputpath -PathType Container)) {
            New-Item -path $outputpath -ItemType Directory -Force | Out-Null
        }
                
        $listremediatonscripts | export-csv -Path $outputpath\$outputname
                
    }
                        
    # Show Grid
    if ($outgrid) {
        $listremediatonscripts | Out-GridView
    }
}
# END OF REMEDIATION SCRIPTS

Function Read-YesNoChoice {
	<#
        .SYNOPSIS
        Prompt the user for a Yes No choice.

        .DESCRIPTION
        Prompt the user for a Yes No choice and returns 0 for no and 1 for yes.

        .PARAMETER Title
        Title for the prompt

        .PARAMETER Message
        Message for the prompt
		
		.PARAMETER DefaultOption
        Specifies the default option if nothing is selected

        .INPUTS
        None. You cannot pipe objects to Read-YesNoChoice.

        .OUTPUTS
        Int. Read-YesNoChoice returns an Int, 0 for no and 1 for yes.

        .EXAMPLE
        PS> $choice = Read-YesNoChoice -Title "Please Choose" -Message "Yes or No?"
		
		Please Choose
		Yes or No?
		[N] No  [Y] Yes  [?] Help (default is "N"): y
		PS> $choice
        1
		
		.EXAMPLE
        PS> $choice = Read-YesNoChoice -Title "Please Choose" -Message "Yes or No?" -DefaultOption 1
		
		Please Choose
		Yes or No?
		[N] No  [Y] Yes  [?] Help (default is "Y"):
		PS> $choice
        1

        .LINK
        Online version: https://www.chriscolden.net/2024/03/01/yes-no-choice-function-in-powershell/
    #>
	
	Param (
        [Parameter(Mandatory=$true)][String]$Title,
		[Parameter(Mandatory=$true)][String]$Message,
		[Parameter(Mandatory=$false)][Int]$DefaultOption = 0
    )
	
	$No = New-Object System.Management.Automation.Host.ChoiceDescription '&No', 'No'
	$Yes = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes', 'Yes'
	$Options = [System.Management.Automation.Host.ChoiceDescription[]]($No, $Yes)
	
	return $host.ui.PromptForChoice($Title, $Message, $Options, $DefaultOption)
}




# ====================================================================================================================
# MAIN
# ====================================================================================================================

# --------------------------------------------------------------------------------------------------------------------
# Updating MSGraph Environment (We need beta...)
# --------------------------------------------------------------------------------------------------------------------
# Update-MSGraphEnvironment -SchemaVersion beta | Out-Null

# --------------------------------------------------------------------------------------------------------------------
# Connecting to MSGraph
# --------------------------------------------------------------------------------------------------------------------
# Connect-MSGraph -ForceInteractive | Out-Null
Connect-MgGraph -NoWelcome
Import-Module Microsoft.Graph.Groups -Force

#--------------------------------------------------------------------------------------------------------------------
# Define group to search for...
# --------------------------------------------------------------------------------------------------------------------#
### Get Entra ID Group
#$groupDisplayName = "EM_WIN_CSP_UD_CoreConfig"
#$GroupInfo = Get-MgGroup -Filter "DisplayName eq '$groupDisplayName'"

$GroupInfo = Get-MgGroup -Filter "startswith(DisplayName,'EM_WIN')" -All | Out-GridView -OutputMode Single -Title "Select the group to query...."
if ($null -eq $GroupInfo) {
    write-host "No group selected, EXIT" -ForegroundColor Red
    break
}

$csv = $false
$outputpath = "c:\temp"

$choice = Read-YesNoChoice -Title "Grid output?" -Message "Yes or No?"
switch($choice)
{
	# No
	0 {
		$outgrid = $false
	}
	# Yes
	1 {
		$outgrid = $true
	}
}

$choice = Read-YesNoChoice -Title "Screen ouput?" -Message "Yes or No?"
switch($choice)
{
	# No
	0 {
		$output = $false
	}
	# Yes
	1 {
		$output = $true
	}
}

$choice = Read-YesNoChoice -Title "Policy export?" -Message "Yes or No?"
switch($choice)
{
	# No
	0 {
		$export = $false
	}
	# Yes
	1 {
		$export = $true
        write-host "The policy export is located @ c:\temp" -ForegroundColor Green
	}
}

write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
write-host "- SEARCHING ASSIGNMENTS FOR ENTRA ID GROUP -------------------------------------" -ForegroundColor Magenta
write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
write-host "--> $($GroupInfo.DisplayName) <--" -ForegroundColor Magenta
write-host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
write-host ""

# Running Functions....
GetApplications
#GetDeviceCompliancePolicies
#GetDeviceConfigurationProfiles
#GetDeviceConfigurationProfilesADM
#GetPoshScripts
#GetDeviceConfigurationProfilesSettingsCatalog
#GetAutoPilotProfiles
#GetESPPages
#GetRemediationScripts


Write-Host "------------------------------------------------------------------------------------" -ForegroundColor Green
Write-Host "SCRIPT IS FINISHED" -ForegroundColor Green
Write-Host "------------------------------------------------------------------------------------" -ForegroundColor Green

##GetDeviceConfigurationProfilesShared
##GetEndPointSecurityProfiles
##GetWindowsUpdateProfiles
##GetWindowsQualityProfiles




# ----------------------------------------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------------------------
# OLD XAML CODE
# ----------------------------------------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------------------------
# XAML Preparation....
# --------------------------------------------------------------------------------------------------------------------

<## Use of variable scriptDirectory
If (Test-Path -LiteralPath 'variable:HostInvocation') { 
    $InvocationInfo = $HostInvocation 
} Else { 
    $InvocationInfo = $MyInvocation 
}
[string]$Global:scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

# Location XAML GUI
Write-Host "Loading XAML"
#if(Test-Path "$scriptDirectory\GUI\MainWindow.xaml"){
    #$inputXML = Get-Content "$scriptDirectory\GUI\MainWindow.xaml" -Raw
    $inputXML = Get-Content "C:\Users\tyd373ut\OneDrive - Aveniq AG\Dokumente\Code\WpfApp1\MainWindow.xaml"
    #$inputXML = Get-Content "C:\Users\tyd373ut\OneDrive - Aveniq AG\Dokumente\Code\WpfApp1\MainWindow.xaml"
    $inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:Name", 'Name' -replace '^<Win.*', '<Window'
    [xml]$xaml=$inputXML
#} else {
#    throw "Initialize: Cannot load Window - XAML not found: $scriptDirectory\GUI\MainWindow.xaml"
#}

##*=============================================#region Load XAML##*=============================================
try {
    #create an object the XamlReader class understands    
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    #pass the XmlNodeReader object to the Load() static method on the XamlReader class to create our window    
    $MainGui = [Windows.Markup.XamlReader]::Load($reader)
    #reference powershell variables to GUI elements    
    $xaml.SelectNodes("//*[@Name]") | ForEach-Object {
        Set-Variable -Name ($_.Name) -Value $MainGui.FindName($_.Name)
    }
}catch [System.Exception] {
    throw
}
#endregion Load XAML##*=============================================

# XAML Functions

# On click, Assign
$btn_enable.Add_Click({

    #Getting all Datagrids...
    $Datagrids = (get-variable datagrid*)

    #Looping trough Datagrids...
    foreach ($datagrid in $Datagrids) {

        if ($($datagrid.value.name) -eq "DataGridApps") {
            # Applications
            #write-host $($datagrid.value.name)
            # Calling function AddAppAssignment
            foreach ($item in $datagrid.value.SelectedItems) {
                write-host "Assigning application '$($item.application)' for group '$($groupName)'"
                AddAppAssignment -AppId $($item.AppID)
            }
        } elseif ($($datagrid.value.name) -eq "DataGridDeviceConfiguration") {
            # Device Configuration
            #write-host $($datagrid.value.name)
            # Calling function AddAppAssignment
            foreach ($item in $datagrid.value.SelectedItems) {
                if ($($item.Type) -eq "Administrative Templates") {

                    write-host "Admin Templates not supported at the moment" -ForegroundColor Red
                    continue
                }

                if ($($item.Type) -eq "Settings Catalog") {

                    write-host "Settings Catalog not supported at the moment" -ForegroundColor Red
                    continue
                }
                write-host "Assigning device configuration '$($item.ProfileName)' for group '$($groupName)'"
                AddDeviceConfigurationPolicyAssignment -DeviceConfigID $($item.id)
            }

        } elseif ($($datagrid.value.name) -eq "DataGridPoshScripts") {
            # PowerShell Scripts
            #write-host $($datagrid.value.name)

        } elseif ($($datagrid.value.name) -eq "DataGridFeatureUpdates") {
            # Feature Updates
            #write-host $($datagrid.value.name)

        } elseif ($($datagrid.value.name) -eq "DataGridQualityUpdates") {
            # Quality Updates
            #write-host $($datagrid.value.name)

        } elseif ($($datagrid.value.name) -eq "DataGridAutoPilot") {
            # AutoPilot Profiles
            #write-host $($datagrid.value.name)

        } elseif ($($datagrid.value.name) -eq "DataGridESP") {
            # ESP Profiles
            #write-host $($datagrid.value.name)

        } elseif ($($datagrid.value.name) -eq "DataGridEndpointSecurity") {
            # Endpoint Security
            #write-host $($datagrid.value.name)

        } elseif ($($datagrid.value.name) -eq "DataGridRemediationScripts") {
            # Remediations Scripts
            #write-host $($datagrid.value.name)
            write-host $item.id
            foreach ($item in $datagrid.value.SelectedItems) {
                $item
                write-host "Assigning application '$($item.application)' for group '$($groupName)'"
                AddRemediationScriptPolicyAssignment -DeviceConfigID $($item.id)
            }
            

        } elseif ($($datagrid.value.name) -eq "DataGridDeviceCompliance") {
            # Device Compliance
            #write-host $($datagrid.value.name)

        } else {
            write-host "No DataGridValue found...$($datagrid.value.name)"
        }
    }   
})

# On click, Un-assign
$btn_disable.Add_Click({
    #Getting all Datagrids...
    $Datagrids = (get-variable datagrid*)

    #Looping trough Datagrids...
    foreach ($datagrid in $Datagrids) {
    
        if ($($datagrid.value.name) -eq "DataGridApps") {
            # Applications
            #write-host $($datagrid.value.name)
            # Calling function AddAppAssignment
            foreach ($item in $datagrid.value.SelectedItems) {
                write-host "Un-assigning application '$($item.application)' for group '$($groupName)'"
                RemoveAppAssignment -Appid $($item.AppID)
            }
        } elseif ($($datagrid.value.name) -eq "DataGridDeviceConfiguration") {
            # Device Configuration
            #write-host $($datagrid.value.name)
            foreach ($item in $datagrid.value.SelectedItems) {
                if ($($item.Type) -eq "Administrative Templates") {

                    write-host "Admin Templates not supported at the moment" -ForegroundColor red
                    continue
                }

                if ($($item.Type) -eq "Settings Catalog") {

                    write-host "Settings Catalog not supported at the moment" -ForegroundColor red
                    continue
                }

                write-host "Un-assigning device configuration '$($item.ProfileName)' for group '$($groupName)'"
                RemoveDeviceConfigurationPolicyAssignment -DeviceConfigID $item.id
            }
        } elseif ($($datagrid.value.name) -eq "DataGridPoshScripts") {
            # PowerShell Scripts
            #write-host $($datagrid.value.name)
    
        } elseif ($($datagrid.value.name) -eq "DataGridFeatureUpdates") {
            # Feature Updates
            #write-host $($datagrid.value.name)
    
        } elseif ($($datagrid.value.name) -eq "DataGridQualityUpdates") {
            # Quality Updates
            #write-host $($datagrid.value.name)
    
        } elseif ($($datagrid.value.name) -eq "DataGridAutoPilot") {
            # AutoPilot Profiles
            #write-host $($datagrid.value.name)
    
        } elseif ($($datagrid.value.name) -eq "DataGridESP") {
            # ESP Profiles
            #write-host $($datagrid.value.name)
    
        } elseif ($($datagrid.value.name) -eq "DataGridEndpointSecurity") {
            # Endpoint Security
            #write-host $($datagrid.value.name)
    
        } elseif ($($datagrid.value.name) -eq "DataGridRemediationScripts") {
            # Remediations Scripts
            #write-host $($datagrid.value.name)
    
        } elseif ($($datagrid.value.name) -eq "DataGridDeviceCompliance") {
            # Device Compliance
            #write-host $($datagrid.value.name)
   
        } else {
            write-host "No DataGridValue found...$($datagrid.value.name)"
        }
    }   
})
    #>








#$MainGui.ShowDialog() | Out-Null
