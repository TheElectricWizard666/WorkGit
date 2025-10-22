# Applications 

### Get Azure AD Group
$groupName = "EM_WIN_CSP_DD_CoreConfig"
 
 
$Group = Get-MgGroup -Filter 'DisplayName -eq $groupName'

Get-MgGroup -GroupId 'dc72de7a-2453-47f2-a54e-c60ca9b8c044'

$Resource = "deviceAppManagement/mobileApps"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$Apps = (Invoke-MgGraphRequest -Method GET -Uri $uri).Value | Where-Object {$_.assignments.target.groupId -match $Group.id}
 
Write-host "Following Apps has been assigned to: $($Group.DisplayName)" -ForegroundColor cyan
  
foreach ($App in $Apps) {
 
  Write-host "$($App.DisplayName)" -ForegroundColor Yellow
   
 
}

(Invoke-MgGraphRequest -Method GET -Uri $uri).Value | Where-Object {$_.displayname -eq "Workspace App CR 2405"}