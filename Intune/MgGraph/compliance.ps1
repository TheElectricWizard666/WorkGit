### Device Compliance Policy
 
$Resource = "deviceManagement/deviceCompliancePolicies"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$AllDCPId = (Invoke-MgGraphRequest -Method GET -Uri $uri).Value | Where-Object {$_.assignments.target.groupId -match $Group.id}
 
Write-host "The following Device Compliance Policies has been assigned to: $($Group.DisplayName)" -ForegroundColor Cyan
 
foreach ($DCPId in $AllDCPId) {
 
  Write-host "$($DCPId.DisplayName)" -ForegroundColor Yellow
}