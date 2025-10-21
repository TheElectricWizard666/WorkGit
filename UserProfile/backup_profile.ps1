# -----------------------------------------------------------------------------------------------------------------------
# Powershell script backing up profile settings. 
# NOTE: Script backs up only Office 2010 data...
# -----------------------------------------------------------------------------------------------------------------------
#
# Initial Version         Date                 Author
# 0.1 				      26.05.2016           SOR
#
# Revision                
# -
#
# -----------------------------------------------------------------------------------------------------------------------

# Define variables
#$BackupFolder = Read-Host  "Please type in which location should the backup folder be created?" 
$BackupFolder = "H:\Documents\Backup_Profile"
$outlook_settings = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem'
$MRU_Word = 'HKCU:\Software\Microsoft\Office\14.0\word\File MRU'
$MRU_Excel = 'HKCU:\Software\Microsoft\Office\14.0\Excel\File MRU'
$MRU_Powerpoint = 'HKCU:\Software\Microsoft\Office\14.0\Powerpoint\File MRU'


Clear-Host


# Create directory structure if it doesn't exists


Write-Host ""
Write-Host "Creating folder if it didn't exist..."
Write-Host ""

If (!(Test-Path $BackupFolder)) {
 
   New-Item -Path $BackupFolder -ItemType Directory -Force

}
 
 cd $BackupFolder
   New-Item -Path "_RegKeys" -ItemType Directory -Force
    

Write-Host ""
Write-Host "Performing backup tasks..."


# Backup Favorites folder


try {
Copy-Item H:\Favorites -Destination $BackupFolder -Recurse -Container -Force


# Backup Outlook signature folder
Copy-Item $env:APPDATA\Microsoft\Signatures -Destination $BackupFolder -Recurse -Container -Force


# Backup Custom Office Dictionary
Copy-Item $env:APPDATA\Microsoft\UProof -Destination $BackupFolder -Recurse -Container -Force


# Backup Wallpaper
Copy-Item $env:APPDATA\Microsoft\Windows\Themes -Destination $BackupFolder -Recurse -Container -Force


# Backup Desktop folder
Copy-Item H:\Desktop -Destination $BackupFolder -Recurse -Container -Force


# Backup Quick Launch folder
Copy-Item "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch" -Destination $BackupFolder -Recurse -Container -Force

}

catch 
{
$ErrorMessage = $_.Exception.Message
$FailedItem = $_.Exception.ItemName
Write-Output $ErrorMessage
break
}

Write-Host "All the folders were successfully copied..."


# Backup Outlook settings


Write-Host ""
Write-Host "Attempting to save MS Outlook settings..."

$outlook_settings_exists = Test-Path $outlook_settings
 
If ( $outlook_settings_exists -eq $false ) {
   Write-Host "Outlook was not configured on this computer. Continuing..."
   }

Else {
Reg export 'HKCU\Software\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem' "$BackupFolder\_RegKeys\outlook_settings.reg" /y
}



# Backup reference of recently opened Word, Excel and Powerpoint files

Write-Host ""
Write-Host "Attempting to save MS Powerpoint settings..."

$MRU_Powerpoint_Exists = Test-Path $MRU_Powerpoint
 
 If ($MRU_Powerpoint_Exists -eq $false) {
   Write-Host "Looks like PowerPoint was never used, because there are no Powerpoint Recent Files . Continuing..."
   }
   
   Else {
Reg export 'HKCU\Software\Microsoft\Office\14.0\Powerpoint\File MRU' "$BackupFolder\_RegKeys\MRU_Powerpoint.reg" /y
}


Write-Host ""
Write-Host "Attempting to save MS Word settings..."

$MRU_Word_Exists = Test-Path $MRU_Word
 
 If ( $MRU_Word_Exists -eq $false ) {
   Write-Host "Looks like Word was never used, because there are no Word Recent Files . Continuing..."
   }

   Else {
Reg export 'HKCU\Software\Microsoft\Office\14.0\Word\File MRU' "$BackupFolder\_RegKeys\MRU_Word.reg" /y
}


Write-Host ""
Write-Host "Attempting to save MS Excel settings..."

$MRU_Excel_Exists = Test-Path $MRU_Excel
 
 If ( $MRU_Excel -eq $false ) {
   Write-Host "Looks like Excel was never used, because there are no Excel Recent Files . Continuing..."
   }

   Else {
Reg export 'HKCU\Software\Microsoft\Office\14.0\Excel\File MRU' "$BackupFolder\_RegKeys\MRU_Excel.reg" /y
}




# Backup IE Startpage

$path = 'HKCU:\Software\Microsoft\Internet Explorer\Main\'
$startpage = 'start page'
#$secondary_startpages = 'Secondary Start Pages'

(Get-Itemproperty -Path $path -Name $startpage).$startpage | out-file -Encoding Ascii -append H:\Documents\Backup_Profile\ie_startpage.txt


Write-Host ""
Write-Host ""
Write-Host "Profile was successfully backed up. This windows will close automatically in 20 sec..."
Start-Sleep -s 20