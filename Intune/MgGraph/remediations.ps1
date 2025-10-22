### Remediation scripts 
 
$uri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts"
$REMSC = Invoke-MgGraphRequest -Method GET -Uri $uri
$AllREMSC = $REMSC.value 
Write-host "Following Remediation Script has been assigned to: $($Group.DisplayName)" -ForegroundColor cyan
  
foreach ($Script in $AllREMSC) {
 
$SCRIPTAS = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/$($Script.Id)/assignments").value 
 
  if ($SCRIPTAS.target.groupId -match $Group.Id) {
  Write-host "$($Script.DisplayName)" -ForegroundColor Yellow
  }
 
}