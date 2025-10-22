<#Script checks if Notepad++ 8.7 or newer exists.
Author: Szymon Orzechowski (IIWI)
Date: 05.11.2024
#>


$FilePath    = "C:\Program Files\Notepad++\notepad++.exe"
$FileVersion = "8.7.0"

if(Test-Path -Path $FilePath) {
    $FileVersionLocal = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($FilePath).FileVersion
    if ($FileVersionlocal -cge $FileVersion) {
        Write-Host "Version: $($FileVersionLocal). Software is up-to-date"
        Exit 0

    }
    else {
        $File = $false
        Write-Host "Version: $($FileVersionLocal). Not up-to-date."
        Exit 1
    }
}
else {
        Write-Host "Software is not installed."
        Exit 0
}