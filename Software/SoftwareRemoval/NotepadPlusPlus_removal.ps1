<#Script removes Notepad++.
Author: Szymon Orzechowski (IIWI)
Date: 05.11.2024
#>      

$ProgramDir = "C:\Program Files\Notepad++\"
$FilePath = "C:\Program Files\Notepad++\uninstall.exe" 
$Uninstall_Argument = "/S"


if (Test-Path -Path $FilePath) {
    $notepadpp = get-process -Name "notepad++" -ErrorAction SilentlyContinue
    if ($notepadpp) {
    $notepadpp | Stop-Process -Force  }

    Start-Process -FilePath $FilePath -ArgumentList $Uninstall_Argument -wait
        If (Test-Path -Path $ProgramDir) {
        Remove-Item -Path $ProgramDir -Recurse -Force
        }
    Write-Output "Notepad++ was removed"
    }

else {
        Write-Host "Software is not installed."
        Exit 0
}