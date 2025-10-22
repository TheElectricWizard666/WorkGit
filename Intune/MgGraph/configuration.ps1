# Device Configuration
 
$DCURIs = @{
    ConfigurationPolicies = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$expand=Assignments"
    DeviceConfigurations = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$expand=Assignments"
    GroupPolicyConfigurations = "https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations?`$expand=Assignments"
    mobileAppConfigurations = "https://graph.microsoft.com/beta/deviceAppManagement/mobileAppConfigurations?`$expand=Assignments"
  }
   
$AllDC = $null
foreach ($url in $DCURIs.GetEnumerator()) {
 
 
  $AllDC = (Invoke-MgGraphRequest -Method GET -Uri $url.value).Value | Where-Object {$_.assignments.target.groupId -match $Group.id} -ErrorAction SilentlyContinue
  Write-host "Following Device Configuration / "$($url.name)" has been assigned to: $($Group.DisplayName)" -ForegroundColor cyan
  foreach ($DCs in $AllDC) {
 
    #If statement because ConfigurationPolicies does not contain DisplayName. 
      if ($($DCs.displayName -ne $null)) { 
       
      Write-host "$($DCs.DisplayName)" -ForegroundColor Yellow
      } 
      else {
        Write-host "$($DCs.Name)" -ForegroundColor Yellow
      } 
  }
  } 