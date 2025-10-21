# Define the path to your PowerShell script
$scriptPath = "C:\Path\To\Your\Script.ps1"

# Define the task name and description
$taskName = "RunMyScriptAtLogon"
$taskDescription = "Run custom script at user logon"

# Create a new scheduled task
Register-ScheduledTask -TaskName $taskName -Action (New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File '$scriptPath'") -Trigger (New-ScheduledTaskTrigger -AtLogOn) -User "DOMAIN\Username" -Description $taskDescription

Write-Host "Scheduled task '$taskName' created to run '$scriptPath' at user logon."