<#
Script configuring Windows and Adobe Acrobat security options as they are recommended by Microsoft Defender for Endpoint.
Author: Szymon Orzechowski (Aveniq AG)
Date: 14.08.2023
#>

$ErrorActionPreference = "SilentlyContinue"

$keypath1 = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"

$keypath2 = "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown"

$keypath3 = "HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown"



# Enable "Local Security Authority (LSA) protection" 
Try {
If (!(Test-Path $keyPath1)) {
New-Item -Path $keyPath1 -force | Out-Null
    }

New-ItemProperty -Path $keypath1 -Name "RunAsPPL" -Value "1" -PropertyType Dword -Force | Out-Null
}

Catch {
$ErrorMessage = $_.Exception.Message
$FailedItem = $_.Exception.ItemName
}



# Disable the local storage of passwords and credentials
Try {
If (!(Test-Path $keyPath1)) {
New-Item -Path $keyPath1 -force | Out-Null
    }

New-ItemProperty -Path $keypath1 -Name "DisableDomainCreds" -Value "1" -PropertyType Dword -Force | Out-Null
}

Catch {
$ErrorMessage = $_.Exception.Message
$FailedItem = $_.Exception.ItemName
}

# Disable JavaScript on Adobe Acrobat & Adobe Reader DC


Try {
If (!(Test-Path $keyPath2)) {
New-Item -Path $keyPath2 -force | Out-Null
    }

New-ItemProperty -Path $keypath2 -Name "bDisableJavaScript" -Value "1" -PropertyType Dword -Force| Out-Null
}

Catch {
$ErrorMessage = $_.Exception.Message
$FailedItem = $_.Exception.ItemName
}

Try {
If (!(Test-Path $keyPath3)) {
New-Item -Path $keyPath3 -force | Out-Null
    }

New-ItemProperty -Path $keypath3 -Name "bDisableJavaScript" -Value "1" -PropertyType Dword -Force| Out-Null
}

Catch {
$ErrorMessage = $_.Exception.Message
$FailedItem = $_.Exception.ItemName
}




# Disable Flash on Adobe Reader DC - REG_DWORD=0
Try {
If (!(Test-Path $keyPath3)) {
New-Item -Path $keyPath3 -force | Out-Null
    }

New-ItemProperty -Path $keypath3 -Name "bEnableFlash" -Value "0" -PropertyType Dword -Force | Out-Null
}

Catch {
$ErrorMessage = $_.Exception.Message
$FailedItem = $_.Exception.ItemName
}



