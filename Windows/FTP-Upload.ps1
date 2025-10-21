# Script for uploading files to FTP-Server.
# Date: 07.11.2017
# Author: SOR

$Source="C:/Dir"    
$ftp = "ftp://..." 
$user = "..." 
$pass = "..."  
 
$webclient = New-Object System.Net.WebClient 
 
$webclient.Credentials = New-Object System.Net.NetworkCredential($user,$pass)  
 

foreach($item in (dir $Source "*.trc")){ 
    "Uploading $item..." 
    $uri = New-Object System.Uri($ftp+$item.Name) 
    $webclient.UploadFile($uri, $item.FullName) 
 } 
