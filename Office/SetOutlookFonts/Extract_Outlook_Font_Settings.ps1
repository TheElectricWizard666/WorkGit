$Path = "registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Office\16.0\Common\mailsettings"
$Name1 = "ReplyFontComplex"
$Name2 = "ComposeFontComplex"
$Name3 = "ReplyFontSimple"
$Name4 = "ComposeFontSimple"
$Name5 = "TextFontComplex"
$Name6 = "TextFontSimple"

(Get-ItemProperty -Path $Path -Name $Name1 -ErrorAction Stop | Select-Object -ExpandProperty $Name1 | ForEach-Object { '{0:X2}' -f $_ }) -join ','
(Get-ItemProperty -Path $Path -Name $Name2 -ErrorAction Stop | Select-Object -ExpandProperty $Name2 | ForEach-Object { '{0:X2}' -f $_ }) -join ','
(Get-ItemProperty -Path $Path -Name $Name3 -ErrorAction Stop | Select-Object -ExpandProperty $Name3 | ForEach-Object { '{0:X2}' -f $_ }) -join ','
(Get-ItemProperty -Path $Path -Name $Name4 -ErrorAction Stop | Select-Object -ExpandProperty $Name4 | ForEach-Object { '{0:X2}' -f $_ }) -join ','
(Get-ItemProperty -Path $Path -Name $Name5 -ErrorAction Stop | Select-Object -ExpandProperty $Name5 | ForEach-Object { '{0:X2}' -f $_ }) -join ','
(Get-ItemProperty -Path $Path -Name $Name6 -ErrorAction Stop | Select-Object -ExpandProperty $Name6 | ForEach-Object { '{0:X2}' -f $_ }) -join ','