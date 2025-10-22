# Checks certificate opt-in registry key.

$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Secureboot"
$valueName = "MicrosoftUpdateManagedOptIn"
$requiredValue = 0x5944
 
if (Test-Path -Path $regPath) {
    $key = Get-Item -Path $regPath
    if ($key.GetValue($valueName) -ne $null) {
        if ($key.GetValue($valueName) -eq $requiredValue) {
            Write-Host "RegKey exists, $valueName exists, and value is $requiredValue"
            Exit 0
        } else {
            Write-Host "RegKey exists, $valueName exists but value is not $requiredValue"
            Exit 1
        }
    } else {
        Write-Host "RegKey exists, but $valueName does not exist"
        Exit 1
    }
} else {
    Write-Host "RegKey does not exist"
    Exit 1
}