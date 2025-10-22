<#
Script checks if Adobe Reader x86 or x64 24.002.20857 exists.
Author: Szymon Orzechowski (IIWI)
Date: 05.11.2024
#>

$AppNameX64 = 'Adobe Acrobat'
$AppNameX86 = 'Adobe Acrobat Reader DC MUI'
$AppVersion = '24.002.20857'

$App = Get-WmiObject -Class Win32_Product | Where-Object { ($_.Name -eq $AppNameX86 -or $_.Name -match $AppNameX64) -and $_.Version -clt $AppVersion }


if(!($Null -eq $App)) {
    Write-Host "$($App.Version) found. Not up-to-date."
    Exit 1
} else {
    Write-Host "Software is up-to-date"
    Exit 0
}
