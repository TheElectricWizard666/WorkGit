$computermodel = (gwmi win32_computersystem).Model
$currentbiosversion = Get-HPBIOSVersion
 
switch ($computermodel)
{
	"HP Elite x2 G4" { 
		$biosversion = "1.20.00"
		If($biosversion -eq $currentbiosversion){
			Write-Output "Detected"
			exit 0 
		} else {
			Write-Output "Not Detected"
			exit 1 
		}
	}
	"HP Elite x360 1040 14 inch G9 2-in-1 Notebook PC" { 
		$biosversion = "1.09.00"
		If($biosversion -eq $currentbiosversion){
			Write-Output "Detected"
			exit 0 
		} else {
			Write-Output "Not Detected"
			exit 1 
		}
	}
	"HP EliteBook 840 G5" { 
		$biosversion = "1.26.00"
		If($biosversion -eq $currentbiosversion){
			Write-Output "Detected"
			exit 0 
		} else {
			Write-Output "Not Detected"
			exit 1 
		}
	}
	"HP EliteBook 840 G6" { 
		$biosversion = "1.26.00"
		If($biosversion -eq $currentbiosversion){
			Write-Output "Detected"
			exit 0 
		} else {
			Write-Output "Not Detected"
			exit 1 
		}
	}
	"HP EliteBook 840 G7 Notebook PC" { 
		$biosversion = "1.14.00"
		If($biosversion -eq $currentbiosversion){
			Write-Output "Detected"
			exit 0 
		} else {
			Write-Output "Not Detected"
			exit 1 
		}
	}
	"HP EliteBook 850 G5" { 
		$biosversion = "1.26.00"
		If($biosversion -eq $currentbiosversion){
			Write-Output "Detected"
			exit 0 
		} else {
			Write-Output "Not Detected"
			exit 1 
		}
	}
	"HP EliteBook 850 G6" { 
		$biosversion = "1.25.00"
		If($biosversion -eq $currentbiosversion){
			Write-Output "Detected"
			exit 0 
		} else {
			Write-Output "Not Detected"
			exit 1 
		}
	}
	"HP EliteBook 850 G7 Notebook PC" { 
		$biosversion = "1.14.00"
		If($biosversion -eq $currentbiosversion){
			Write-Output "Detected"
			exit 0 
		} else {
			Write-Output "Not Detected"
			exit 1 
		}
	}
	"HP EliteBook 850 G8 Notebook PC" { 
		$biosversion = "1.15.02"
		If($biosversion -eq $currentbiosversion){
			Write-Output "Detected"
			exit 0 
		} else {
			Write-Output "Not Detected"
			exit 1 
		}
	}
	"HP EliteBook 860 16 inch G10 Notebook PC" { 
		$biosversion = "1.03.00"
		If($biosversion -eq $currentbiosversion){
			Write-Output "Detected"
			exit 0 
		} else {
			Write-Output "Not Detected"
			exit 1 
		}
	}
	"HP EliteBook 860 16 inch G9 Notebook PC" { 
		$biosversion = "1.09.00"
		If($biosversion -eq $currentbiosversion){
			Write-Output "Detected"
			exit 0 
		} else {
			Write-Output "Not Detected"
			exit 1 
		}
	}
	"HP EliteBook 865 16 inch G10 Notebook PC" { 
		$biosversion = "1.03.05"
		If($biosversion -eq $currentbiosversion){
			Write-Output "Detected"
			exit 0 
		} else {
			Write-Output "Not Detected"
			exit 1 
		}
	}
	"HP EliteBook x360 1030 G7 Notebook PC" { 
		$biosversion = "1.14.00"
		If($biosversion -eq $currentbiosversion){
			Write-Output "Detected"
			exit 0 
		} else {
			Write-Output "Not Detected"
			exit 1 
		}
	}
	"HP EliteBook x360 1040 G6" { 
		$biosversion = "1.26.00"
		If($biosversion -eq $currentbiosversion){
			Write-Output "Detected"
			exit 0 
		} else {
			Write-Output "Not Detected"
			exit 1 
		}
	}
	"HP EliteBook x360 1040 G7 Notebook PC" { 
		$biosversion = "1.14.20"
		If($biosversion -eq $currentbiosversion){
			Write-Output "Detected"
			exit 0 
		} else {
			Write-Output "Not Detected"
			exit 1 
		}
	}
	"HP EliteBook x360 1040 G8 Notebook PC" { 
		$biosversion = "1.14.20"
		If($biosversion -eq $currentbiosversion){
			Write-Output "Detected"
			exit 0 
		} else {
			Write-Output "Not Detected"
			exit 1 
		}
	}
	"HP ZBook Firefly 14 G7 Mobile Workstation" { 
		$biosversion = "1.14.20"
		If($biosversion -eq $currentbiosversion){
			Write-Output "Detected"
			exit 0 
		} else {
			Write-Output "Not Detected"
			exit 1 
		}
	}
	"HP ZBook Studio 16 inch G10 Mobile Workstation PC" { 
		$biosversion = "1.02.00"
		If($biosversion -eq $currentbiosversion){
			Write-Output "Detected"
			exit 0 
		} else {
			Write-Output "Not Detected"
			exit 1 
		}
	}
}