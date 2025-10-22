$PLT_Hub = Get-ItemProperty -path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object -Property DisplayName -match -Value "Plantronics Hub"

$Name = $PLT_Hub.DisplayName

$Version = $PLT_Hub.DisplayVersion

$MSICode = $PLT_Hub.PSChildName

If ($Version -clt "3.25.54307.37251" -and $Version -ne $null) {
            Write-Output "$Version found: not up-to-date"
            Exit 1
            }

Elseif ($Version -cge "3.25.54307.37251")
           {
            Write-Output "Hub Software is up-to-date."
            Exit 0
           }

Elseif ($Version -eq $Null)
           {
            Write-Output "Hub Software is not installed."
            Exit 0
           }