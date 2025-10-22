# Script sets Windows Time service startup to automatic.
# Author: Szymon Orzechowski (Aveniq AG)
# Date: 24.01.2023

Set-Service W32time -startuptype automatic
Start-Service W32time