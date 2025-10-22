Install-Module -Name Microsoft.Graph.DeviceManagement -Force -AllowClobber
Install-Module -Name Microsoft.Graph.Groups -Force -AllowClobber
Import-Module -Name Microsoft.Graph.Groups
Import-Module -Name Microsoft.Graph.DeviceManagement
 
Connect-MgGraph -Scopes "DeviceManagementApps.Read.All,DeviceManagementApps.ReadWrite.All,DeviceManagementConfiguration.ReadWrite.All,DeviceManagementManagedDevices.PrivilegedOperations.All,DeviceManagementManagedDevices.ReadWrite.All,DeviceManagementRBAC.ReadWrite.All,DeviceManagementServiceConfig.ReadWrite.All,DeviceLocalCredential.Read.All,Directory.Read.All,Group.ReadWrite.All,openid,User.Read" 
Connect-MgGraph -TenantID "3c0849c3-e244-444b-9506-091a27cc5d7a"



Get-MgDeviceAppManagementManagedAppPolicy

Get-mgApplication


Get-MgApplication | Format-List Id, DisplayName, AppId, SignInAudience, PublisherDomain
Get-MgApplicationCount -ConsistencyLevel eventual

Get-MgDeviceAppMgtMobileApp | Get-Member
Get-MgDeviceAppMgtMobileApp | Select-Object -Property Id, Assignments

Get-MgDeviceAppMgtMobileApp | select  DisplayName, Publisher, PublishingState, Id, Assignments | Where-Object {($_.DisplayName -Like "*Citrix*")} | ft

Get-MgDeviceAppMgtMobileApp | select DisplayName, Publisher, PublishingState, Id, Assignments | Where-Object {($_.Publisher -Like "Microsoft*") -and ($_.DisplayName -Like "Microsoft*")} | ft

get-command -Module Microsoft.Graph.DeviceManagement