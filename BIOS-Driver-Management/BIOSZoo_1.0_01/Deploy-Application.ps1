<#
.SYNOPSIS

PSApppDeployToolkit - This script performs the installation or uninstallation of an application(s).

.DESCRIPTION

- The script is provided as a template to perform an install or uninstall of an application(s).
- The script either performs an "Install" deployment type or an "Uninstall" deployment type.
- The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.

The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.

PSApppDeployToolkit is licensed under the GNU LGPLv3 License - (C) 2023 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham and Muhammad Mashwani).

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the
Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details. You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

.PARAMETER DeploymentType

The type of deployment to perform. Default is: Install.

.PARAMETER DeployMode

Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.

.PARAMETER AllowRebootPassThru

Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.

.PARAMETER TerminalServerMode

Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Desktop Session Hosts/Citrix servers.

.PARAMETER DisableLogging

Disables logging to file for the script. Default is: $false.

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"

.EXAMPLE

Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"

.INPUTS

None

You cannot pipe objects to this script.

.OUTPUTS

None

This script does not generate any output.

.NOTES

Toolkit Exit Code Ranges:
- 60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
- 69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
- 70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1

.LINK

https://psappdeploytoolkit.com
#>


[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall')]
    [String]$DeploymentType = 'Install',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]
    [String]$DeployMode = 'Interactive',
    [Parameter(Mandatory = $false)]
    [switch]$AllowRebootPassThru = $false,
    [Parameter(Mandatory = $false)]
    [switch]$TerminalServerMode = $false,
    [Parameter(Mandatory = $false)]
    [switch]$DisableLogging = $false,
	[Parameter(Mandatory=$false)]
    [string]$Param1
)

Try {
    ## Set the script execution policy for this process
    Try {
        Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop'
    }
    Catch {
    }

    ##*===============================================
    ##* VARIABLE DECLARATION
    ##*===============================================
    ## Variables: Application
	[string]$appVendor = 'Aveniq'
	[string]$appName = 'BIOSZoo'
	[string]$appVersion = '1.0'
	[string]$appArch = 'x64'
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '27.12.2023'
	[string]$appScriptAuthor = 'Mel Alexander Steiner'
	[string]$packageIdentifier = "$($appVendor)_$($appName)_$($appVersion)_$($appArch)_$($appLang)_$($appRevision)"
    ##*===============================================
    
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = $packageIdentifier
	[string]$installTitle = $packageIdentifier
	
	## Variables: Installer Files
	[string]$MSIProductCode = '' # Product Code e.g {0EB47F41-0FF3-472D-ADA1-2389E96A56C4}
	#[string]$MSIProductCode1 = '' # Product Code
	[string]$MSIName = '' #MSI 
	#[string]$MSIName1 = '' #MSI 
	[string]$ExeName = '' #EXE
	#[string]$ExeName1 = '' #EXE
	[string]$TransformName = '' #MST
	#[string]$TransformName1 = '' #MST
	
    $Date=Date
    #only for .exe
    [string]$LOG = $configToolkitLogDir + "\$installName" + "_$DeploymentType.log"

    ##* Do not modify section below
    #region DoNotModify

    ## Variables: Exit Code
    [Int32]$mainExitCode = 0

    ## Variables: Script
    [String]$deployAppScriptFriendlyName = 'Deploy Application'
    [Version]$deployAppScriptVersion = [Version]'3.9.1'
    [String]$deployAppScriptDate = '20/01/2023'
    [Hashtable]$deployAppScriptParameters = $PsBoundParameters

    ## Variables: Environment
    If (Test-Path -LiteralPath 'variable:HostInvocation') {
        $InvocationInfo = $HostInvocation
    }
    Else {
        $InvocationInfo = $MyInvocation
    }
    [String]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

    ## Dot source the required App Deploy Toolkit Functions
    Try {
        [String]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
        If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) {
            Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]."
        }
        If ($DisableLogging) {
            . $moduleAppDeployToolkitMain -DisableLogging
        }
        Else {
            . $moduleAppDeployToolkitMain
        }
    }
    Catch {
        If ($mainExitCode -eq 0) {
            [Int32]$mainExitCode = 60008
        }
        Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
        ## Exit the script, returning the exit code to SCCM
        If (Test-Path -LiteralPath 'variable:HostInvocation') {
            $script:ExitCode = $mainExitCode; Exit
        }
        Else {
            Exit $mainExitCode
        }
    }

    #endregion
    ##* Do not modify section above
    ##*===============================================
    ##* END VARIABLE DECLARATION
    ##*===============================================

    If ($deploymentType -ine 'Uninstall') {
        ##*===============================================
        ##* PRE-INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Pre-Installation'


        ## <Perform Pre-Installation tasks here>
		## Show Welcome Message, close Internet Explorer if required, verify there is enough disk space to complete the install, and persist the prompt
        Show-InstallationWelcome -CloseApps 'Trebuchet.App,wfica32,winword,excel,powerpnt,outlook,msedge,ONENOTE' -PersistPrompt -BlockExecution -AllowDefer -DeferTimes 3 -MinimizeWindows $false -TopMost $true
				
        ##*===============================================
        ##* INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Installation'
		
		$currentbiosversion = Get-HPBIOSVersion
		$latestbiosversion = (Get-HPBIOSUpdates -Latest).Ver
		$testingdate = (Get-HPBIOSUpdates | Where ver -eq $currentbiosversion).Date
		$oneversionabovecurrentversion = ((Get-HPBIOSUpdates | where Date -gt $testingdate) | Select-Object -Last 1).ver
		$computermodel = (gwmi win32_computersystem).Model

		switch ($computermodel)
		{
			"HP Elite x2 G4" { $biosversion = "1.20.00" }
			"HP Elite x360 1040 14 inch G9 2-in-1 Notebook PC" { $biosversion = "1.09.00" }
			"HP EliteBook 840 G5" { $biosversion = "1.26.00" }
			"HP EliteBook 840 G6" { $biosversion = "1.26.00" }
			"HP EliteBook 840 G7 Notebook PC" { $biosversion = "1.14.00" }
			"HP EliteBook 850 G5" { $biosversion = "1.26.00" }
			"HP EliteBook 850 G6" { $biosversion = "1.25.00" }
			"HP EliteBook 850 G7 Notebook PC" { $biosversion = "1.14.00" }
			"HP EliteBook 850 G8 Notebook PC" { $biosversion = "1.15.02" }
			"HP EliteBook 860 16 inch G10 Notebook PC" { $biosversion = "1.03.00" }
			"HP EliteBook 860 16 inch G9 Notebook PC" { $biosversion = "1.09.00" }
			"HP EliteBook 865 16 inch G10 Notebook PC" { $biosversion = "1.03.05" }
			"HP EliteBook x360 1030 G7 Notebook PC" { $biosversion = "1.14.00" }
			"HP EliteBook x360 1040 G6" { $biosversion = "1.26.00" }
			"HP EliteBook x360 1040 G7 Notebook PC" { $biosversion = "1.14.20" }
			"HP EliteBook x360 1040 G8 Notebook PC" { $biosversion = "1.14.20" }
			"HP ZBook Firefly 14 G7 Mobile Workstation" { $biosversion = "1.14.20" }
			"HP ZBook Studio 16 inch G10 Mobile Workstation PC" { $biosversion = "1.02.00" }
		}

		#Get BIOS Password
		$key = Get-Content "$dirFiles\AES.key"
		$securestring = $Param1 | ConvertTo-SecureString -Key $key

		$decrypted = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securestring)
		$BIOSpassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($decrypted)

		#Test if BIOS Password works
		if ((Get-HPBIOSSettingValue "Internal Speakers") -eq "Enable") {  
			Set-HPBIOSSettingValue -Name "Internal Speakers" -Value "Disable" -password $BIOSpassword
		}
		 
		if ((Get-HPBIOSSettingValue "Internal Speakers") -eq "Disable") {
			Write-Host "BIOS password is correct."

			# Setting back BIOS Setting to original setting 
			Set-HPBIOSSettingValue -Name "Internal Speakers" -Value "Enable" -password $BIOSpassword
		} else {
			exit 1
		}


		If($biosversion -gt $currentbiosversion){
			Write-Host "Newer BIOS Version available"

			#Downloadpath for BIOS Update
			$downloadPath = "$env:Programdata\HP\CMSL\Downloads"

			#Check if Power is connected
			$chassisType = Get-WmiObject -Class Win32_SystemEnclosure -ComputerName $env:COMPUTERNAME -Property ChassisTypes
			if ($chassisType.ChassisTypes[0] -in "3", "4", "5", "6", "7", "13", "15", "16", "18", "24", "30", "35") {
				Write-Host "Device is connected to external power source."
			}
			elseif ((Get-WmiObject -Class BatteryStatus -Namespace root\wmi -ComputerName $env:COMPUTERNAME).PowerOnLine) { 
				Write-Host "Device is connected to external power source."   
			}
			else {
				exit 1
			}

			#Suspend Bitlocker for 1 reboot
			$bitlockerprotection = Get-BitlockerVolume -MountPoint "C:"
			If($bitlockerprotection.ProtectionStatus -eq "On"){
				Suspend-BitLocker -MountPoint "C:" -RebootCount 1 -ErrorAction Stop
			}
			
			#Download the HP BIOS Update
			$biosInstallerName = (Get-HPBIOSUpdates -Latest).bin
			$biosout = Join-Path $downloadPath $biosInstallerName
			$dlcount = 1
			If(!(Test-Path $biosout -PathType Leaf)){
				while ($dlcount -le 3) {
					Get-HPBIOSUpdates -Version $oneversionabovecurrentversion -Download -Overwrite -saveAs $biosout -Quiet

					if (!(Test-Path $biosout -PathType Leaf)) {
						$dlcount++
					}

				}
			}

			#Update the BIOS to the latest version
			Get-HPBIOSUpdates -Flash -Password $BIOSpassword -Yes -Quiet -Bitlocker suspend
		}

		If($biosversion -eq $currentbiosversion){
			Write-Host "Newest BIOS Version already installed"
		}
		
        ##*===============================================
        ##* POST-INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Post-Installation'

        ## <Perform Post-Installation tasks here>
		
		## Function Set-Brandingkeys
        Set-Brandingkeys $DeploymentType

        ## Function Write-ToEventLog
        Write-ToEventLog "Application" "AveniqInstaller" "100" "$installName -- Installation operation completed successfully. -- $ExecuteResult. Detailed Information see LOGFILE" "Information" 

    }
    ElseIf ($deploymentType -ieq 'Uninstall') {
        ##*===============================================
        ##* PRE-UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Pre-Uninstallation'

        ## <Perform Pre-Uninstallation tasks here>
		## Show Welcome Message, close Internet Explorer if required, verify there is enough disk space to complete the install, and persist the prompt

        ##*===============================================
        ##* UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Uninstallation'
		
		
        ## <Perform Uninstallation tasks here>
		## MSI uninstallation
        ## Execute-MSI -Action Uninstall -Path $MSIProductCode -private:$installName
		
		## EXE uninstallation
		## Execute-Process -Path "$dirFiles\uninstall.exe" -Parameters "/s"
		
        ##*===============================================
        ##* POST-UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Post-Uninstallation'

        ## <Perform Post-Uninstallation tasks here>
		## Remove File
		## Remove-Folder -Path "$envWinDir\Downloaded Program Files"
		## Remove-EmptyFolder "$envProgramFiles\Microsoft"
		
		## Remove Registry
		## Remove-RegistryKey -Key 'HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Pulse Secure 9.1'
		
		## Remove File
		## Remove-File -Path 'C:\Windows\Downloaded Program Files\Temp.inf'
		
		## Set-ActiveSetup -Key $installName -PurgeActiveSetupKey
		
		## Function Set-Brandingkeys
		Set-Brandingkeys $DeploymentType
		
		## Function Write-ToEventLog
        Write-ToEventLog "Application" "AveniqInstaller" "100" "$installName -- Removal completed successfully. -- $ExecuteResult. Detailed Information see LOGFILE" "Information"

    }
    ##*===============================================
    ##* END SCRIPT BODY
    ##*===============================================

    ## Call the Exit-Script function to perform final cleanup operations
    Exit-Script -ExitCode $mainExitCode
}
Catch {
    [Int32]$mainExitCode = 60001
    [String]$mainErrorMessage = "$(Resolve-Error)"
    Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
    Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
    Exit-Script -ExitCode $mainExitCode
}
