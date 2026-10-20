#Requires AutoHotkey v2.0
; =====================================================================
;  Log Templates is now called WATCHLOG (Watchlog.ahk, in this folder).
;  This small file only starts Watchlog, so an old shortcut to
;  Log Templates.ahk (like the one in the Startup folder) still works.
;  Watchlog moves those shortcuts, saved passwords and settings over by
;  itself. Once every PC has run Watchlog once, this file can be deleted.
; =====================================================================
watchlog := A_ScriptDir "\Watchlog.ahk"
if FileExist(watchlog)
    Run '"' A_AhkPath '" "' watchlog '"', A_ScriptDir
else
    MsgBox "Log Templates is now called Watchlog, but Watchlog.ahk isn't in this folder yet:`n" A_ScriptDir
        . "`n`nIf the folder is in OneDrive, let it finish syncing, then try again.", "Watchlog", "Icon!"
