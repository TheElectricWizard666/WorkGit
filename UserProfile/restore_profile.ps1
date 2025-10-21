# -----------------------------------------------------------------------------------------------------------------------
# Powershell script restoring profile settings. 
# NOTE: Script works only with Office 2010...
# -----------------------------------------------------------------------------------------------------------------------
#
# Initial Version         Date                 Author
# 0.1 TEST version        26.05.2016           SOR
#
# Revision                
# 
#
# -----------------------------------------------------------------------------------------------------------------------

# Define variables
#$BackupFolder = Read-Host  "Please type the folder in which the profile was backed up" 
$BackupFolder = "H:\Documents\Backup_Profile"
$outlook_settings = "$BackupFolder\_regkeys\outlook_settings.reg"
$MRU_Word = "$BackupFolder\_regkeys\MRU_Word.reg"
$MRU_Excel = "$BackupFolder\_regkeys\MRU_Excel.reg"
$MRU_Powerpoint = "$BackupFolder\_regkeys\MRU_Powerpoint.reg"
$Homepage = Get-Content "$BackupFolder\ie_startpage.txt"


Clear-Host


# Check if backup folder exists


$BackupFolderExists = Test-Path $BackupFolder
 
 if ($BackupFolderExists -eq $false) {
        Write-Output "Backup folder does not exist! Stoping script..."
        break
 }



# Restore Favorites folder
Copy-Item $BackupFolder\Favorites -Destination H:\ -Recurse -Container -Force


# Restore Outlook signature folder
Copy-Item $BackupFolder\Signatures -Destination $env:APPDATA\Microsoft\ -Recurse -Container -Force


# Restore Custom Office Dictionary
Copy-Item $BackupFolder\UProof -Destination $env:APPDATA\Microsoft\ -Recurse -Container -Force


# Restore Desktop folder
Copy-Item $BackupFolder\Desktop -Destination H:\ -Recurse -Container -Force


# Restore Quick Launch folder
Copy-Item "$BackupFolder\Quick Launch" -Destination "$env:APPDATA\Microsoft\Internet Explorer" -Recurse -Container -Force


# Backup Wallpaper
Copy-Item $BackupFolder\Themes -Destination $env:APPDATA\Microsoft\Windows -Recurse -Container -Force



# Restore Outlook settings

$outlook_settings_exists = Test-Path $outlook_settings
 
If ( $outlook_settings_exists -eq $false ) {
   Write-Host "Outlook settings do not exist. Continuing..."
   }

   Else {
Reg import $outlook_settings
}





# Restore reference of recently opened Word, Excel and Powerpoint files

$MRU_Powerpoint_Exists = Test-Path $MRU_Powerpoint
 
 If ($MRU_Powerpoint_Exists -eq $false) {
   Write-Host "Powerpoint settings do not exist. Continuing..."
   }
   
   Else {
reg import $MRU_Powerpoint
}

    

$MRU_Word_Exists = Test-Path $MRU_Word
 
 If ( $MRU_Word_Exists -eq $false ) {
   Write-Host "Word settings do not exist. Continuing..."
   }

   Else {
reg import $MRU_Word
}


$MRU_Excel_Exists = Test-Path $MRU_Excel
 
 If ( $MRU_Excel -eq $false ) {
   Write-Host "Excel settings do not exist. Continuing..."
   }

   Else {
reg import $MRU_Excel
}

# Restore IE Homepage

$path = 'HKCU:\Software\Microsoft\Internet Explorer\Main\'
$startpage = 'start page'
$Homepage = Get-Content "$BackupFolder\ie_startpage.txt"

Set-ItemProperty -Path $path -Name $startpage -Value $Homepage -Force
