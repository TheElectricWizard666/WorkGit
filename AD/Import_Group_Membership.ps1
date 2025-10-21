# -----------------------------------------------------------------------------------------------------------------------
# Powershell Script for importing members from .csv file to AD Group
# First column's name in the spreadsheet must be samAccountName
# -----------------------------------------------------------------------------------------------------------------------
#
# Initial Version         Date                 Author
# 1.0                     11.11.2014           SOR
#
# Revision                
#
#
# -----------------------------------------------------------------------------------------------------------------------

Import-Module ActiveDirectory
  $adGroup = Read-Host "What is the group name?"
Import-Csv "C:\Temp\ADGroupMemb.csv" | ForEach-Object {
 $samAccountName = $_."samAccountName"
 Add-ADGroupMember $adGroup $samAccountName;
 Write-Host "- "$samAccountName" added to "$adGroup
}