$certDate = [System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI db).bytes)

if ($certDate -match 'Windows UEFI CA 2023') {
    Write-Output $true
    Exit 0
} else {
    Write-Output $false
    Exit 1
}
