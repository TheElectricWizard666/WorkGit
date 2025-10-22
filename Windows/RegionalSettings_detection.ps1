<#
This script checks if the digit grouping symbol for Numbers and Currency is set to `'`.
#>

# Registry path for user formatting
$IntlRegPath = "HKCU:\Control Panel\International"
$NumbersGrouping = "sMonThousandSep"     # Currency digit grouping
$CurrencyGrouping = "sThousand"          # Number digit grouping
$GroupingValue = "'"                     # Expected value

# Check current settings
if (Test-Path -Path $IntlRegPath) {
    $key = Get-Item -Path $IntlRegPath

    $numValue = $key.GetValue($NumbersGrouping)
    $curValue = $key.GetValue($CurrencyGrouping)

    if ($numValue -ne $GroupingValue -or $curValue -ne $GroupingValue) {
        Write-Output "One or both values are incorrect."
        Exit 1
    } else {
        Write-Output "Both values are correct."
        Exit 0
    }
} else {
    Write-Output "Registry path not found."
    Exit 1
}