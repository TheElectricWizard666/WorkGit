﻿# Script used for Autopilot device preparation only.


$registryPaths = @{
  "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" = @{
    "DisablePrivacyExperience" = 1
    "DisableVoice" = 1
    "PrivacyConsentStatus" = 1
    "ProtectYourPC" = 3
    "HideEULAPage" = 1
  }
  "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" = @{
    "EnableFirstLogonAnimation" = 1
  }
}

foreach ($path in $registryPaths.Keys) {
  foreach ($name in $registryPaths[$path].Keys) {
    New-ItemProperty -Path $path -Name $name -Value $registryPaths[$path][$name] -PropertyType DWord -Force
  }
}