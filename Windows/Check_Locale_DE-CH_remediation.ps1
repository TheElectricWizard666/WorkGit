# Check current culture
$currentCulture = (Get-Culture).Name
if ($currentCulture -eq "de-CH") {
    Write-Output "Culture already set to de-CH. No changes needed."
    exit 0
}

else{
# Set DE-CH culture and language
Set-Culture -CultureInfo "de-CH"
Set-WinUILanguageOverride -Language "de-CH"
Set-WinSystemLocale -SystemLocale "de-CH"
$UserLanguageList = New-WinUserLanguageList "de-CH"
Set-WinUserLanguageList $UserLanguageList -Force

# Registry path for user formatting
$intlPath = "HKCU:\Control Panel\International"

# Number formatting
Set-ItemProperty -Path $intlPath -Name "sDecimal" -Value "."
Set-ItemProperty -Path $intlPath -Name "sThousand" -Value "'"
Set-ItemProperty -Path $intlPath -Name "sGrouping" -Value "3;0"

# Currency formatting
Set-ItemProperty -Path $intlPath -Name "sCurrency" -Value "CHF"
Set-ItemProperty -Path $intlPath -Name "sMonDecimalSep" -Value "."
Set-ItemProperty -Path $intlPath -Name "sMonThousandSep" -Value "'"
Set-ItemProperty -Path $intlPath -Name "sMonGrouping" -Value "3;0"
Set-ItemProperty -Path $intlPath -Name "iCurrDigits" -Value 2
Set-ItemProperty -Path $intlPath -Name "iCurrency" -Value 0
Set-ItemProperty -Path $intlPath -Name "iNegCurr" -Value 8

# Optional: Prevent override from language profile
$userProfilePath = "$intlPath\User Profile"
If (-Not (Test-Path $userProfilePath)) {
    New-Item -Path $userProfilePath -Force | Out-Null
}
New-ItemProperty -Path $userProfilePath -Name "UserLocaleFromLanguageProfileOptOut" -Value 1 -PropertyType DWORD -Force

Write-Output "DE-CH locale and formatting applied successfully."
exit 0
}