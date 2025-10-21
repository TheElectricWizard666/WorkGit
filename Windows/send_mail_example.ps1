##############################################################################
$From = "MafiaDiPolonia@rizag.ch"
$To = "florian.fazzone@rizag.ch"
$Cc = "YourBoss@mafia.com"
$Attachment = "H:\Downloads\Sedex-Adapter (SHS).docx"
$Subject = "WIR HABEN GEHÖRT DASS DU ETWAS GEGEN POLLEN HAST!!!"
$Body = "Willst du sterben? Sag nochmals etwas gegen Pollen. Du bekommst alle nötigen Informationen im nächsten Mail."
$SMTPServer = "opensmtp.root.riz"
$SMTPPort = "25"

Send-MailMessage -From $From -to $To -Cc $Cc -Subject $Subject `
-Body $Body -SmtpServer $SMTPServer -port $SMTPPort -Encoding utf8
#-Attachments $Attachment
 #-Credential (Get-Credential)
##############################################################################