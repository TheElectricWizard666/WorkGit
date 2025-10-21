# -----------------------------------------------------------------------------------------------------------------------
# Powershell script gathering some basic information about the computer.
# -----------------------------------------------------------------------------------------------------------------------
#
# Initial Version         Date                 Author
# 0.1 				      03.06.2016           SOR
#
# Revision                
# -
#
# -----------------------------------------------------------------------------------------------------------------------

cls

$BackupFolder = "H:\Documents\_CompInfo"

Write-Host ""
Write-Host "Creating folder if it didn't exist..."
Write-Host ""

If (!(Test-Path $BackupFolder)) {
 
   New-Item -Path $BackupFolder -ItemType Directory -Force

}

# Gather computer information
Write-Host ""
Write-Host "Getting hardware data..."

#Get-WMIObject Win32_LogicalDisk | Format-Table -Property name,volumename,providername,size,freespace -AutoSize -Wrap | Out-File -Encoding Ascii $BackupFolder\disk_info.txt
#Get-WMIObject win32_computersystem | Format-List -Property * | Out-File -Encoding Ascii $BackupFolder\system_info.txt

# Gather Software information
Write-Host ""
Write-Host "Getting installed software..."

#Get-WMIObject win32_product | Sort-Object -Property caption | Format-Table -Property caption,version,installdate,installlocation -Wrap -autosize | Out-File -Encoding Ascii $BackupFolder\installed_software.csv 
Get-WMIObject win32_product | Sort-Object -Property * | Format-Table -Property caption | Out-File -Encoding Ascii $BackupFolder\installed_software.csv 

# Gather Updates information
Write-Host ""
Write-Host "Getting installed updates..."

#Get-WMIObject win32_QuickFixEngineering | Sort-Object -Property hotfixid | Format-Table -Property hotfixid,caption,description,installedon -autosize | Out-File -Encoding Ascii $BackupFolder\installed_updates.csv 

Write-Host ""
Write-Host "Done! Check out folder H:\Documents\_CompInfo" -ForegroundColor white -BackgroundColor green