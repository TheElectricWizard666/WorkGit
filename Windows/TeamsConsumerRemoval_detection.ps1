
<# 
.SYNOPSIS 
    Removes the MS Teams Consumer client

.DESCRIPTION
    N/A

.NOTES
  Author:         Adrian Keller
  Creation Date:  18.02.2025
#>

If ($null -eq (Get-AppxPackage -Name MicrosoftTeams -AllUsers)) {
    Write-Output "Microsoft Teams Personal App not present"
    Exit 0
}
Else {
    Write-Output "Microsoft Teams Personal App present"
    Exit 1
}
