<#
This script fixes the issue with Windows activation from M365 license.
Author: Szymon Orzechowski (Aveniq)
Date: 14.05.2025

#>
       
try {
    Write-Host "Try to activate Windows"
    $GetDigitalLicence = (Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
    cscript c:\windows\system32\slmgr.vbs -ipk $GetDigitalLicence
    Write-Host "Successfully activated Windows"
    exit 0
} catch {
    Write-Host "Failed to activate Windows"
    exit 1
}