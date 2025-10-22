$SiteCode = "PAH"

# Get all maintenance tasks for the specified site
$MaintenanceTasks = Get-CMSiteMaintenanceTask -SiteCode $SiteCode

# Loop through each task and disable it if it's enabled
foreach ($Task in $MaintenanceTasks) {
    if ($Task.Enabled -eq $false) {
        $Task | Set-CMSiteMaintenanceTask -Enabled $true
        Write-Output "Enabled task: $($Task.TaskName)"
    }
}