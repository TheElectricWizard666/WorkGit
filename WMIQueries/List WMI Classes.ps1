Get-WMIObject -List| Where{$_.name -match "^Win32_"} | Sort Name | Format-Table Name 
#| out-file -Encoding Ascii "H:\Documents\_CompInfo\WMI_Classes.txt"
