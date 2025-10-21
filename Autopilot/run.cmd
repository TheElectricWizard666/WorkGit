if not exist C:\HWID md C:\HWID
powershell.exe -executionpolicy bypass -file Get-WindowsAutoPilotInfo.ps1 -OutputFile C:\hwid\AutopilotHWID.csv