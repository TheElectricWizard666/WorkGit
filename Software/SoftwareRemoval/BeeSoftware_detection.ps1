$FilePath    = "C:\Program Files\Bee360\Bee360\Bee360.exe"
$FileVersion = "1.41.4"

if(Test-Path -Path $FilePath) {
    $FileVersionLocal = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($FilePath).FileVersion
    if ($FileVersionLocal -eq $FileVersion) {
        Write-Host "Software is up-to-date"
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