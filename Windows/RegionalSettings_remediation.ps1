<#
This script sets the digit grouping symbol for Numbers and Currency to `'`.
#>

# Registry path for user formatting
$IntlRegPath = "HKCU:\Control Panel\International"
$NumbersGrouping = "sMonThousandSep"     # Currency digit grouping
$CurrencyGrouping = "sThousand"          # Number digit grouping
$GroupingValue = "'"                     # Expected value

# Ensure the registry path exists
if (Test-Path -Path $IntlRegPath) {
    try {
        Set-ItemProperty -Path $IntlRegPath -Name $NumbersGrouping -Value $GroupingValue
        Set-ItemProperty -Path $IntlRegPath -Name $CurrencyGrouping -Value $GroupingValue
        Write-Output "Registry values updated successfully."
        Exit 0
    } catch {
        Write-Output "Failed to update registry values: $_"
        Exit 1
    }
} else {
    Write-Output "Registry path not found."
    Exit 1
}