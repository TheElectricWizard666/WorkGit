<#
.SYNOPSIS

PSAppDeployToolkit - Provides the ability to extend and customise the toolkit by adding your own functions that can be re-used.

.DESCRIPTION

This script is a template that allows you to extend the toolkit with your own custom functions.

This script is dot-sourced by the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.

PSApppDeployToolkit is licensed under the GNU LGPLv3 License - (C) 2023 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham and Muhammad Mashwani).

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the
Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details. You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

.EXAMPLE

powershell.exe -File .\AppDeployToolkitHelp.ps1

.INPUTS

None

You cannot pipe objects to this script.

.OUTPUTS

None

This script does not generate any output.

.NOTES

.LINK

https://psappdeploytoolkit.com
#>


[CmdletBinding()]
Param (
)

##*===============================================
##* VARIABLE DECLARATION
##*===============================================

# Variables: Script
[string]$appDeployToolkitExtName = 'PSAppDeployToolkitExt'
[string]$appDeployExtScriptFriendlyName = 'App Deploy Toolkit Extensions'
[version]$appDeployExtScriptVersion = [version]'3.9.1'
[string]$appDeployExtScriptDate = '20/01/2023'
[hashtable]$appDeployExtScriptParameters = $PSBoundParameters

##*===============================================
##* FUNCTION LISTINGS
##*===============================================

# <Your custom functions go here>
Function Set-Brandingkeys {
	<#
	.SYNOPSIS
		sets brandingkeys.
	.DESCRIPTION
		sets brandingkeys.
	.EXAMPLE
		Set-Brandingkeys -Install
	.LINK
	    www.clearbyte.ch
	#>
[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
	    [ValidateSet('Install','Uninstall')]
	    [string]$DeploymentType = 'Install'
	)
		Begin {
			## Get the name of this function and write header
			[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
			Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		}
		Process {
				Try {
				$datum = Get-Date -Format dd.MM.yyyy
				$time=(Get-Date).ToLongTimeString()

                switch ($DeploymentType.ToUpper())                         
                {                        
                    'INSTALL' {
				                Set-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\_Custom\Applications\$installName" -Name 'Status' -Value 'Installed' -Type String
				                Set-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\_Custom\Applications\$installName" -Name 'InstallDate' -Value $datum -Type String
				                Set-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\_Custom\Applications\$installName" -Name 'InstallTime' -Value $time -Type String
				                Set-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\_Custom\Applications\$installName" -Name 'Version' -Value $appVersion -Type String

                                }                        
                    'UNINSTALL' {
                                Set-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\_Custom\Applications\$installName" -Name 'Status' -Value 'Uninstalled' -Type String

                                }                        
                    Default {Write-Log -Message "Failed to process brandingkeys. Deployment Type unknown." -Severity 3 -Source ${CmdletName}
                            throw "Failed to process brandingkeys. Deployment Type unknown."}                        
                }    


				}
			Catch {
				Write-Log -Message "Failed to process brandingkeys." -Severity 3 -Source ${CmdletName}
				
		}
			
			
			
		}
		End {
			Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
		}
	}
	
Function Write-ToEventLog ([string]$WriteToEventLog_LogName,[string]$WriteToEventLog_Source,[string]$WriteToEventLog_EventID,[string]$WriteToEventLog_Message,[string]$WriteToEventLog_EntryType){
<#
.SYNOPSIS
	Writes eventlog entry evntvwr.
.DESCRIPTION
	Writes eventlog entry evntvwr.
.PARAMETER WriteToEventLog_LogName
	Name of the Log in Eventviewer. e.g Application, Security, Setup, System etc.
.PARAMETER WriteToEventLog_Source
	Name of the source in eventviewer. 
.PARAMETER WriteToEventLog_EventID
	Eventlog-ID. 
.PARAMETER WriteToEventLog_Message
	The message to report.
.PARAMETER WriteToEventLog_EntryType
	The Type of the message e.g information, Warning, Error.
.EXAMPLE
	WriteToEventLog "Application" "AveniqInstaller" "100" "$installName -- Installation operation completed successfully. -- $ExecuteResult. Detailed Information see LOGFILE" "Information" 
.NOTES
	-
.LINK
    wwww.clearbyte.ch
#>
	#Check if Log exists
	If ([System.Diagnostics.EventLog]::Exists($WriteToEventLog_LogName)){
		#Check if Source exists
		If ([System.Diagnostics.EventLog]::SourceExists($WriteToEventLog_Source)){
			#Write to Event Log
			write-eventlog -LogName $WriteToEventLog_LogName -Source $WriteToEventLog_Source -EventID $WriteToEventLog_EventID -Message $WriteToEventLog_Message -EntryType $WriteToEventLog_EntryType
		}
		#Create Source and Write to Event log
		Else {
			new-eventlog -LogName $WriteToEventLog_LogName -Source $WriteToEventLog_Source -ErrorAction SilentlyContinue
			#Write to Event Log
			write-eventlog -LogName $WriteToEventLog_LogName -Source $WriteToEventLog_Source -EventID $WriteToEventLog_EventID -Message $WriteToEventLog_Message -EntryType $WriteToEventLog_EntryType
		}
	}
	#Create Log and Source
	Else {
		new-eventlog -LogName $WriteToEventLog_LogName -Source $WriteToEventLog_Source -ErrorAction SilentlyContinue
		#Write to Event Log
		write-eventlog -LogName $WriteToEventLog_LogName -Source $WriteToEventLog_Source -EventID $WriteToEventLog_EventID -Message $WriteToEventLog_Message -EntryType $WriteToEventLog_EntryType
		Limit-EventLog -LogName $WriteToEventLog_LogName -MaximumSize 256MB -OverflowAction OverwriteAsNeeded -Confirm:$false
	}
}

Function Remove-EmptyFolder {
<#
.SYNOPSIS
	Remove an empty directory tree.
.DESCRIPTION
	Remove empty folder including empty subdirs.
.PARAMETER Path
	Path to the folder to remove.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Remove-Folder -Path "$WinDir\Downloaded Program Files"
.NOTES
	-
.LINK
    wwww.clearbyte.ch
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Path,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
			If (Test-Path -LiteralPath $Path -PathType 'Container') {
				Try {

                         Get-ChildItem -LiteralPath $Path -Force -Recurse| Where-Object {
                            $_.PSIsContainer -and `
                            @(Get-ChildItem -LiteralPath $_.Fullname -Force -Recurse | Where { -not $_.PSIsContainer }).Count -eq 0} |
                        Remove-Item -ErrorAction SilentlyContinue -Recurse -Force


                        $directoryInfo = Get-ChildItem "$Path" | Measure-Object
                        If ($directoryInfo.count -eq 0)
                        {
                            Remove-Folder "$Path"
                        }
                   	
				}
				Catch {
					Write-Log -Message "Failed to delete folder(s) recursively from path [$path]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
					If (-not $ContinueOnError) {
						Throw "Failed to delete folder(s) recursively from path [$path]: $($_.Exception.Message)"
					}
				}
			}
			Else {
				Write-Log -Message "Folder [$Path] does not exists..." -Source ${CmdletName}
			}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}

##*===============================================
##* END FUNCTION LISTINGS
##*===============================================

##*===============================================
##* SCRIPT BODY
##*===============================================

If ($scriptParentPath) {
    Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] dot-source invoked by [$(((Get-Variable -Name MyInvocation).Value).ScriptName)]" -Source $appDeployToolkitExtName
}
Else {
    Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] invoked directly" -Source $appDeployToolkitExtName
}

##*===============================================
##* END SCRIPT BODY
##*===============================================
