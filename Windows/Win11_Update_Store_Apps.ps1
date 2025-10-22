<#
The script updates Windows Store Apps during Autopilot.
Author: Szymon Orzechowski Aveniq AG
Date: 17.01.2022
#>

$ret = Get-CimInstance -Namespace "Root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | Invoke-CimMethod -MethodName UpdateScanMethod