# Check current culture
$currentCulture = (Get-Culture).Name
if ($currentCulture -eq "de-CH") {
    Write-Output "$currentCulture is set. Correct."
    exit 0
}

else{
Write-Output "$currentCulture is set. Not correct."
exit 1
}