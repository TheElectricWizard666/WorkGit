# -----------------------------------------------------------------------------------------------------------------------
# Powershell Script for copying members from one AD Group to another
# 
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
$existingGroup = Read-Host "What is the source group name?"
$NewGroup = Read-Host "What is the target group name?"
Get-ADGroupMember $existingGroup  | ForEach-Object {
$samAccountName = $_."samAccountName"
Add-ADGroupMember $newGroup $samAccountName;
Write-Host "- "$samAccountName" added to "$newGroup
}