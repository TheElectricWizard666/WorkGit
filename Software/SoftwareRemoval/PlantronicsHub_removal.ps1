$PLT_Hub = Get-ItemProperty -path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object -Property DisplayName -match -Value "Plantronics Hub"
$PLT_Hub_x64 = Get-ItemProperty -path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object -Property DisplayName -match -Value "Plantronics Hub"

$Version = $PLT_Hub.DisplayVersion
$Version_x64 = $PLT_Hub_x64.DisplayVersion

$MSICode = $PLT_Hub.PSChildName
$MSICode_x64 = $PLT_Hub_x64.PSChildName

$UninstPath = Get-ChildItem -Path "C:\ProgramData\Package Cache\*" -Include PlantronicsHubBootstrapper.exe -Recurse -ErrorAction SilentlyContinue


If ($Version_x64 -clt "3.25.54307.37251" -and $Version -ne $null) {
            Write-Output "Removing obsolete Hub Software"

                    # Kill Plantronics process, if it is active
                    $Hub = get-process -Name "PLTHub" -ErrorAction SilentlyContinue
                    if ($Hub) {
                    $Hub | Stop-Process -Force  }
                    #Write-Output "PLTHub process killed"
                    # Remove program

                    #$InstalledMSI = Get-WmiObject Win32_Product | Where-Object { $_.Name -like "*Plantronics*" }
                    Start-Process 'msiexec.exe' -ArgumentList "/x","$MSICode_x64","/qn","REBOOT=ReallySuppress","/L*V C:\Windows\CCM\Logs\PlantronicsHub_Uninstall.log" -Wait
                    #Write-Output "Plantronics uninstalled."

                    If($UninstPath.Exists) {
                        Start-Process -FilePath "$UninstPath" -ArgumentList "/uninstall","/quiet","/norestart","/log C:\Windows\CCM\Logs\PlantronicsHubBootstrapper_Uninstall.log" -Wait
                        #Write-Output "Plantronics Hub Bootstrapper uninstalled."

                        }
        
                    # Clean up registry
                    $programs = Get-ItemProperty "HKLM:SOFTWARE\_Custom\Applications\*" | Select-Object * | Where-Object { $_.PSPath -like "*HubSoftware*" }
                    foreach ($program in $programs) {
                    Set-ItemProperty -Path $program.PSPath -Name "Status" -Value "Uninstalled" -ErrorAction SilentlyContinue -Force  
                    }

            Write-Output "PLTHub $Version removed"
            }

Else {
Write-Output "PLTHub not found."
}