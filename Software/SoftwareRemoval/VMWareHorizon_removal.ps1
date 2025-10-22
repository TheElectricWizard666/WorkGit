<#
Script removes VMWare Horizon Client if it is not version 8.13.0.8174.
Author: Szymon Orzechowski (IIWI)
Date: 07.11.2024
#>


$VMWare_Reg = Get-ItemProperty -path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object -Property DisplayName -match -Value "VMware Horizon Client"

$Version = $VMWare_Reg.DisplayVersion

$MSICode = $VMWare_Reg.PSChildName


If ($Version -ne "8.13.0.8174" -and $Version -ne $null) {
            Write-Output "Removing obsolete Horizon Client"

                    # Kill Horizon Client process, if it is active
                    $Horizon = get-process -Name "vmware-view" -ErrorAction SilentlyContinue
                    if ($Horizon) {
                    $Horizon | Stop-Process -Force  }
     
                    # Remove program
                    Start-Process 'msiexec.exe' -ArgumentList "/x","$MSICode","/qn","REBOOT=ReallySuppress","/L*V C:\Windows\CCM\Logs\VMWareHorizonClient_Uninstall.log" -Wait
            
                    # Clean up registry
                    $programs = Get-ItemProperty "HKLM:SOFTWARE\_Custom\Applications\*" | Select-Object * | Where-Object { $_.PSPath -like "*VMware_HorizonClient*" }
                    foreach ($program in $programs) {
                    Set-ItemProperty -Path $program.PSPath -Name "Status" -Value "Uninstalled" -ErrorAction SilentlyContinue -Force  
                    }

            Write-Output "Horizon client $Version removed"
            }

Else {
Write-Output "Horizon client $Version found."
}