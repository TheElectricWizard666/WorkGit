
<# 
.SYNOPSIS 
    Disable NetBIOS on all Adapters...

.DESCRIPTION
    N/A

.NOTES
  Author:         Adrian Keller
  Creation Date:  18.02.2025
#>

$NetBios = get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces\tcpip*

foreach ($i in $netbios) {
    if ($i.NetbiosOptions -ne 2) {
        $RegPath = $i.PSPath -replace "^.*?\::"
        Write-Error "Found active NetBios on Adapter $RegPath"
        exit 1
    }
}
