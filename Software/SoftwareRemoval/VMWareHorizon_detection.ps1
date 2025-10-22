$VMWare_X64 = Get-ItemProperty -path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object -Property DisplayName -match -Value "VMware Horizon Client"

$Name = $VMWare_X64.DisplayName

$Version = $VMWare_X64.DisplayVersion

If ($Version -ne "8.13.0.8174" -and $Version -ne $null) {
            Write-Output "VMWare Horizon not up-to-date"
            Exit 1
            }

Elseif ($Version -eq "8.13.0.8174")
           {
            Write-Output "VMWare Horizon is up-to-date."
            Exit 0
           }

Elseif ($Version -eq $Null)
           {
            Write-Output "VMWare Horizon is not installed."
            Exit 0
           }