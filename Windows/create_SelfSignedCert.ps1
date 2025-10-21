   $Newcert = New-SelfSignedCertificate -Subject 'CN=TEST_SOR' -KeyAlgorithm RSA -KeyLength 2048 -KeyUsage DigitalSignature -Type CodeSigningCert -CertStoreLocation Cert:\CurrentUser\My
   $thumbprint = $Newcert.Thumbprint
   $cert = (Get-ChildItem -Path cert:\CurrentUser\My\$thumbprint)

   if($cert -ne $null){
     $Secure_String_Pwd = ConvertTo-SecureString "Password1" -AsPlainText -Force

     Export-PfxCertificate -Cert $cert -FilePath $env:USERPROFILE\desktop\TESTCert.pfx -Password $Secure_String_Pwd 
     Remove-Item cert:\CurrentUser\My\$thumbprint
   }