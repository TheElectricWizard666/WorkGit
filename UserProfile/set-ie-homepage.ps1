$path = 'HKCU:\Software\Microsoft\Internet Explorer\Main\'
$startpage = 'start page'
$secondary_startpages = 'Secondary Start Pages'
$Homepage = Get-Content "$BackupFolder\ie_startpage.txt"

Set-ItemProperty -Path $path -Name $startpage -Value $Homepage -Force
