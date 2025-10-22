<# 
.SYNOPSIS 
    Disable NetBIOS on all Adapters...

.DESCRIPTION
    N/A

.NOTES
  Author:         Adrian Keller
  Creation Date:  18.02.2025
#>

Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces\tcpip* -Name NetbiosOptions -Value 2 -Force -Confirm:$false

$NetBios = get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces\tcpip*
foreach ($i in $netbios) {
    if ($i.NetbiosOptions -ne 2) {
        $RegPath = $i.PSPath -replace "^.*?\::"
        Write-Error "Found active NetBios on Adapter $RegPath"
        exit 1
    } else {
        Write-Output "All fine, found no adapters with active NetBios"
        exit 0
    }
}