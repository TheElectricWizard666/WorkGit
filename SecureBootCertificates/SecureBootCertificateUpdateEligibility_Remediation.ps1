$logPath = "C:\Windows\CCM\Logs\SecureBootOptInFix.log"

function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$timestamp - $message"
}

Write-Log "Starting remediation script..."

$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Secureboot" 

try {
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
        Write-Log "Created registry path: $regPath"
    }

    Set-ItemProperty -Path $regPath -Name "MicrosoftUpdateManagedOptIn" -Type DWord -Value 0x5944 -Force
    Write-Log "Set MicrosoftUpdateManagedOptIn to 0x5944"

    # Optional telemetry setting
    # Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 1 -Force
    # Write-Log "Set AllowTelemetry to 1"

    Write-Log "Remediation completed successfully."
}
catch {
    Write-Log "Error: $_"
}
