<#
Script removes Adobe Reader x86 or x64 if it is lower than 24.002.20857.
Author: Szymon Orzechowski (IIWI)
Date: 05.11.2024
#>


$AdobeReader = Get-ItemProperty -path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object -Property DisplayName -match -Value "Adobe Acrobat Reader"

$Versions = $AdobeReader.DisplayVersion
$MSICodes = $AdobeReader.PSChildName

If ($Versions -clt "24.002.20857" -and $Versions -ne $null) {
            Write-Output "Removing obsolete Adobe Reader x86 $VersionX86"

                    # Kill Adobe Reader process, if it is active
                    $acroread = get-process -Name "AcroRd32" -ErrorAction SilentlyContinue
                    if ($acroread) {
                    $acroread | Stop-Process -Force  }
     
                    # Remove program
                    foreach ($MSICode in $MSICodes) {
                    Start-Process 'msiexec.exe' -ArgumentList "/x","$MSICode","/qn","REBOOT=ReallySuppress","/L*V C:\Windows\CCM\Logs\AdobeReader_Uninstall.log" -Wait
                    }  
                              
                    # Clean up registry
                    $programs = Get-ItemProperty "HKLM:SOFTWARE\_Custom\Applications\*" | Select-Object * | Where-Object { $_.PSPath -like "*Adobe_Acrobat*" }
                    foreach ($program in $programs) {
                    Set-ItemProperty -Path $program.PSPath -Name "Status" -Value "Uninstalled" -ErrorAction SilentlyContinue -Force  
                    }

            Write-Output "Adobe Reader $VersionX86 removed"
            }
 
            
Elseif ($Versions -cge "24.002.20857")
       {
        Write-Output "Adobe Reader is updated."
       }

Elseif ($Versions -eq $Null)
       {
        Write-Output "Adobe Reader is not installed."
       }

