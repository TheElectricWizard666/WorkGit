$path = 'HKCU:\Software\Microsoft\Internet Explorer\Main\'
$startpage = 'start page'
$secondary_startpages = 'Secondary Start Pages'

(Get-Itemproperty -Path $path -Name $startpage).$startpage | out-file -Encoding Ascii -append H:\Documents\Backup_Profile\ie_startpage.txt

#(Get-Itemproperty -Path $path -Name $secondary_startpages).$secondary_startpages | out-file -Encoding Ascii -append H:\ie_startpage.txt

