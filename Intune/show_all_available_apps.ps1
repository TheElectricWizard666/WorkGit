import-module Win32LobApp
$examples = Get-Win32LobApp
$examples | Where-Object {
    $_.assignments | Where-Object {
        $_.intent -eq 'available' -and $_.target.'@odata.type' -eq '#microsoft.graph.groupAssignmentTarget'
    }
}  | select displayname,displayversion
 