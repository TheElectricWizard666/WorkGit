# -----------------------------------------------------------------------------------------------------------------------
# Powershell Script for exporting members from AD Group to .csv file
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
$ADGroupName = Read-Host "What is the group name?"
Get-ADGroupMember -Identity $ADGroupName | select SamAccountName | Export-csv -path C:\Temp\ADGroupMemb.csv