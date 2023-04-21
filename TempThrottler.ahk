;@Ahk2Exe-SetMainIcon TempThrottler.ico

/*
This powerscheme must exist for the program to function correctly...
Powercfg /DUPLICATESCHEME 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 53616665-7250-6572-666f-726d616e6365
Powercfg /CHANGENAME 53616665-7250-6572-666f-726d616e6365 "Safer Performance"
Powercfg /SETACVALUEINDEX 53616665-7250-6572-666f-726d616e6365 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 50
Powercfg /SETACVALUEINDEX 53616665-7250-6572-666f-726d616e6365 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 95
Powercfg /SETDCVALUEINDEX 53616665-7250-6572-666f-726d616e6365 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 50
Powercfg /SETDCVALUEINDEX 53616665-7250-6572-666f-726d616e6365 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 95
*/

If (A_IsAdmin = 0) {
	Run *RunAs %A_ScriptFullPath%
}
Else {
	#SingleInstance force
SetBatchLines -1

Control := 0

Menu Tray, Icon, %A_WinDir%\System32\imageres.dll, 2
;ProcessSetPriority 0

Menu, Tray, Add, Normal Mode, Reload
Menu, Tray, Add, Safer Performance, Runmed
Menu, Tray, Add, Balanced Mode, Runbal
Menu, Tray, Add, Power Saver, Runlow
Menu, Tray, Add
Menu, Tray, Add, Settings, Settings
Menu, Tray, Add, Quit, Quit
Menu, Tray, NoStandard

Thread, interrupt, 0

Process, Exist, MSIAfterburner.exe
If (Errorlevel = 0) {
	Run, MSIAfterburner.exe, C:\Program Files (x86)\MSI Afterburner, min
	}
	FileGetSize, Check, D:\HardwareMonitoring.hml
If (errorlevel = 1) {
	Gosub, Error
}
Else {
	File := FileOpen("D:\HardwareMonitoring.hml", "r")
}

RegRead, Ct, HKEY_CURRENT_USER\Software\Tempthrottler, CPUmin
RegRead, Cz, HKEY_CURRENT_USER\Software\Tempthrottler, CPUmax
RegRead, G1, HKEY_CURRENT_USER\Software\Tempthrottler, GPUmin
RegRead, G2, HKEY_CURRENT_USER\Software\Tempthrottler, GPUmax
RegRead, TO, HKEY_CURRENT_USER\Software\Tempthrottler, Timeout

Mode = Normal Mode
If (G1 = "" || Ct = "" || G2 = "" || Cz = "" || TO = "") {
Gosub, Settings
}
SetTimer, GCMon, 3000
SetTimer, Monitor, 1000

GCMon:
File.Seek(-43)
CPU := File.Read(2)
File.Seek(-22)
GPU := File.Read(2)
if (GPU ~= "i)\.") {
	Menu, Tray, Tip, %Mode%`nCPU: %CPU%° C`nGPU: Inactive
}
Else {
	Menu, Tray, Tip, %Mode%`nCPU: %CPU%° C`nGPU: %GPU%° C
}
Return

Monitor:
Process, Exist, MSIAfterburner.exe
If Errorlevel {
	If (A_TimeIdlePhysical <= TO*1000) {
		If (GPU <= G1 && CPU <= Ct) {
			Gosub, Normal
		}
		If (GPU > G1 && GPU < G2 && CPU < Cz || CPU > Ct && CPU <= Cz && GPU <= G2) {
			Gosub, Safer
		}
		If (GPU > G2 || CPU > Cz) {
			Gosub, Safest
		}
	}
	Else {
		Gosub, Safest
	}
}
Else {
	SetTimer, Monitor, Delete
	Gosub, Error
}
Return

Normal:
	If (Control != 1) {
		Run, powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c,, hide ; (High Performance)
		Menu, Tray, Icon, %A_WinDir%\System32\imageres.dll, 102
		Control := 1
	}
	Return

Safer:
	If (Control != 2) {
		Run, powercfg /s 53616665-7250-6572-666f-726d616e6365,, hide ; (Safer Performance)
		Menu, Tray, Icon, %A_WinDir%\System32\imageres.dll, 103
		Control := 2
	}
	Return

Safest:
	If (Control != 3) {
		Run, powercfg /s a1841308-3541-4fab-bc81-f71556f20b4a,, hide ; (Power Saver)
		Control := 3
	}
	If (A_TimeIdlePhysical <= TO*1000) {
		Menu, Tray, Icon, %A_WinDir%\System32\imageres.dll, 101
	}
	Else {
		Menu, Tray, Icon, %A_WinDir%\System32\imageres.dll, 74
	}
	Return

Balanced:
	If (Control != 4) {
		Run, powercfg /s 381b4222-f694-41f0-9685-ff5bb260df2e,, hide ; (Balanced)
		Menu, Tray, Icon, %A_WinDir%\System32\imageres.dll, 100
		Control := 4
	}
	Return

^F1::
	Gosub, Runlow
	Return

^F2::
	Gosub, Runmed
	Return

^F3::
	Gosub, Reload
	Return

^F4::
	Gosub, Runbal
	Return

Runmed:
	Mode = Safer Performance
	SetTimer, Monitor, Delete
	SetTimer, Fair, Delete
	SetTimer, Heatwave, 1000
	Return

Heatwave:
	If (A_TimeIdlePhysical <= TO*1000) {
		If (GPU < G2 && CPU < Ct) {
			Gosub, Safer
		}
		If (GPU >= G2 || CPU >= Ct) {
			Gosub, Safest
		}
	}
	Else {
		Gosub, Safest
	}
	Return

Runbal:
	Mode = Balanced Mode
	SetTimer, Monitor, Delete
	SetTimer, Heatwave, Delete
	Settimer, Fair, 1000

Fair:
	If (A_TimeIdlePhysical <= TO*1000) {
		If (GPU < G2 && CPU < Ct) {
			Gosub, Balanced
		}
		If (GPU >= G2 || CPU >= Ct) {
			Gosub, Safest
		}
	}
	Else {
		Gosub, Safest
	}
	Return

Runlow:
	Mode = Power Saver
	SetTimer, Monitor, Delete
	SetTimer, Heatwave, Delete
	SetTimer, Fair, Delete
	Gosub, Safest
	Return

Reload:
	FileDelete, D:\HardwareMonitoring.hml
	Sleep 2000
	Reload
	Return

Error:
	Msgbox, MSI AfterBurner is not running, Exiting
	ExitApp
	Return

Quit:
	MsgBox, 4, , Quit TempThrottler?
	IfMsgBox, No
    	Return
	IfMsgBox, Yes
	ExitApp
    	Return

Settings:
Gui -MaximizeBox -MinimizeBox
Gui, Add, Text,, GPU Min
Gui, Add, Edit, vG1 w20 xp+10 yp+15 Limit2, %G1%
Gui, Add, Text, xp-10 yp+25, CPU Min
Gui, Add, Edit, vCt w20 xp+10 yp+15 Limit2, %Ct%
Gui, Add, Text, ys, GPU Max
Gui, Add, Edit, vG2 w20 xp+10 yp+15 Limit2, %G2%
Gui, Add, Text, xp-10 yp+25, CPU Max
Gui, Add, Edit, vCz w20 xp+10 yp+15 Limit2, %Cz%
Gui, Add, Text, xm+10 yp+25, Timeout In Secs.
Gui, Add, Edit, vTO w20 xp+25 yp+15 Limit2, %TO%
Gui, Add, Button, w95 xm+0 yp+30, OK
Gui, Show, AutoSize Center, Settings
Return

ButtonOK:
Gui, Submit
RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Tempthrottler, CPUmin, %Ct%
RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Tempthrottler, CPUmax, %Cz%
RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Tempthrottler, GPUmin, %G1%
RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Tempthrottler, GPUmax, %G2%
RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Tempthrottler, Timeout, %TO%
Reload

;-EXTRAS-

#If !WinActive("ahk_exe explorer.exe") && !WinActive("ahk_exe winuae64.exe")
LAlt::
	if getkeystate("w")
		SendInput {w up}
	else
		SendInput {w down}
Return

#If WinActive("ahk_exe vlc.exe") || WinActive("ahk_exe mpv.exe")
MButton::
	Run, *RunAs taskkill.exe /f /IM vlc.exe,, hide
	Run, *RunAs taskkill.exe /f /IM mpv.exe,, hide
Return


^F12::
	Run, *RunAs taskkill.exe /f /IM dwm.exe, hide
	Run, *RunAs taskkill.exe /f /fi "username eq yendo" /im *,, hide
Return

}