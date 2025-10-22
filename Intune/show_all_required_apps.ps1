import-module Win32LobApp
$examples = Get-Win32LobApp
$examples | Where-Object {
    $_.assignments | Where-Object {
        $_.intent -eq 'required' -and $_.target.'@odata.type' -eq '#microsoft.graph.groupAssignmentTarget'
    }
}  | select Displayname
 
