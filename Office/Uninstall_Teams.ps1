# Uninstall modern Teams (UWP app) for current user
Get-AppxPackage -Name "MSTeams" | Remove-AppxPackage -AllUsers

# Download latest 64-bit Teams installer
$teams64Url = "https://go.microsoft.com/fwlink/?linkid=2187327" # Official 64-bit Teams MSI
$installerPath = "$env:TEMP\Teams64.msi"
Invoke-WebRequest -Uri $teams64Url -OutFile $installerPath

# Install 64-bit Teams
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$installerPath`" /qn"

Write-Output "Modern and 32-bit Teams removed. 64-bit Teams installed."