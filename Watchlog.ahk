#Requires AutoHotkey v2.0
#SingleInstance Force
; Speed: AutoHotkey pauses 100 ms after every window switch by default,
; and keeps a running record of every line it runs. Neither is needed here.
SetWinDelay 10
SetControlDelay 0
ListLines False
KeyHistory 0

; =====================================================================
;  WATCHLOG  v3.21.0   (called Log Templates before v3.0.1)
;  Copyright (c) 2026 Jakob Blair Vanness. All rights reserved.
;  Used only with the copyright holder's permission. No copying,
;  sharing, changing or redistributing it, in whole or in part, without
;  written permission. Provided "as is", without warranty. The full
;  licence is in LICENCE.txt and in tray menu > About Watchlog.
;
;  This is the program. You shouldn't need to edit it.
;  The first time it runs on a PC that had Log Templates, it moves
;  everything over to the new name by itself (see MOVING FROM LOG
;  TEMPLATES below): saved passwords, the data folder, the Startup
;  shortcut. Nobody has to type their passwords again.
;    templates.txt     = wording of every template (or the team's shared
;                        copy on SharePoint, picked in tray > Settings)
;    my-templates.txt  = your own extra templates (optional)
;    settings.ini      = your personal settings (logins, apps). No
;                        passwords: those are in Windows Credential Manager.
;  They live in the same folder as this file.
;  After saving any of them, the script reloads by itself in a couple of
;  seconds (Ctrl+Alt+R still works too).
; =====================================================================

; The version shows on the tray icon (hover over it), at the top of the
; tray menu, in a note in the corner every time it loads, and on the cheat sheet.
VERSION := "3.29.0"
VERSION_DATE := "Oct 31, 2026"
; Colours of the dark look (see LOOK at the end of the file)
global LOOK_BG := "1B1F24", LOOK_FIELD := "2A3038", LOOK_FG := "E6EAEE", LOOK_MUTED := "9AA5B1", LOOK_ACCENT := "4C9AFF"
; Who owns Watchlog: shown in About Watchlog, the tutorial, the cheat sheet and Security and status
COPYRIGHT := "Copyright (c) 2026 Jakob Blair Vanness. All rights reserved."
; The exe installs itself here (no administrator rights needed)
CAPS_MENU := "Caps Lock guard (red tag, no accidental Caps Lock)"
HOME_MENU := "Watchlog home  (Ctrl+Alt+M)"
INSTALL_DIR := EnvGet("LOCALAPPDATA") "\Programs\Watchlog"
INSTALL_EXE := INSTALL_DIR "\Watchlog.exe"
UNINSTALL_KEY := "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\Watchlog"
; Where settings.ini, templates.txt and my-templates.txt live. Run as a
; script it's the script's own folder, as always. The exe keeps them in
; Documents\Watchlog (which OneDrive syncs between bays), unless the exe
; sits next to a settings.ini (a portable copy).
HomeDir := A_ScriptDir
if A_IsCompiled && !FileExist(A_ScriptDir "\settings.ini")
    HomeDir := A_MyDocuments "\Watchlog"
TemplatesFile := HomeDir "\templates.txt"
IconFile := A_IsCompiled ? "" : A_ScriptDir "\Watchlog.ico"   ; the exe carries its own icon
MyTemplatesFile := HomeDir "\my-templates.txt"
AutoFile := HomeDir "\autocorrect.txt"
SettingsFile := HomeDir "\settings.ini"
NotesFile := A_MyDocuments "\Quick Notes.md"
; Kept on this PC only (not synced): the activity log and the last good
; copy of the team templates
DataDir := EnvGet("LOCALAPPDATA") "\Watchlog"
RegKey := "HKCU\Software\Watchlog"
ActivityFile := DataDir "\activity.log"
TeamCopyFile := DataDir "\team templates (last good copy).txt"
LastUsedFile := DataDir "\last used.ini"   ; boxes that remember (bay), this PC only
SavedFile := DataDir "\time saved.ini"      ; the time saved tracker (numbers only)
AlertFile := DataDir "\alertgrid.ini"      ; where the Alert Grid clicks go (numbers only), this PC only
ITrakFile := DataDir "\itrak.ini"           ; where the iTrak new-daily-log click goes (numbers only), this PC only
; the keys kept in alertgrid.ini (all numbers, plus Basis=client from v3.18.0)
ALERT_KEYS := ["RowX", "RowY", "MenuDX", "MenuDY", "SubmitX", "SubmitY", "OkX", "OkY"
    , "ClearX", "ClearY", "NoMoreX", "NoMoreY", "NoMoreBox", "GridW", "GridH", "MenuLine", "Basis"]
CallPadFile := DataDir "\call pad.txt"            ; the call pad text, this PC only, wiped at end of shift
CallHistFile := DataDir "\call pad history.txt"   ; earlier calls this shift, this PC only
LayoutFile := DataDir "\layout.ini"        ; where the windows were (numbers only), this PC only
CapsGuard := IniRead(LastUsedFile, "Caps", "Guard", "1") != "0"   ; Caps Lock guard on/off, this PC
CapsWasOn := false
CapsGui := ""
CopyMemory := Map()   ; facial rec copies, in memory only (see NoteCopy)
Cfg := Map()
TemplateList := []
Entries := []        ; full-entry daily logs: {name, loc, topic, ref, syn, end, src}
; Shortcut keys that can be changed in Customize Watchlog > Shortcut keys
; (see RegisterHotkeys): id, standard key, what it does
HotkeyDefs := [{id: "find", key: "^!Space", label: "find a template", fn: (*) => ShowPicker()}
    , {id: "callpad", key: "^!n", label: "call pad  (also Numpad +)", fn: (*) => ShowCallPad()}
    , {id: "quicknote", key: "^!q", label: "add a quick note", fn: (*) => QuickNote()}
    , {id: "notes", key: "^!o", label: "open notes", fn: (*) => ShowNotes()}
    , {id: "journal", key: "^!j", label: "shift journal", fn: (*) => ShowJournal()}
    , {id: "start", key: "^!l", label: "start of shift", fn: (*) => StartOfShift()}
    , {id: "end", key: "$^!+l", label: "end of shift", fn: (*) => EndOfShift()}
    , {id: "home", key: "^!m", label: "Watchlog home", fn: (*) => ShowHome()}
    , {id: "editor", key: "$^!e", label: "template editor", fn: (*) => ShowEditor()}
    , {id: "wininfo", key: "^!i", label: "window info", fn: (*) => WindowInfo()}
    , {id: "savelayout", key: "^!+s", label: "save window layout", fn: (*) => SaveLayout()}
    , {id: "restorelayout", key: "^!w", label: "put windows back", fn: (*) => RestoreLayout()}
    , {id: "sdslogout", key: "^!k", label: "log out of SDS", fn: (*) => SDSLogout()}
    , {id: "alertclear", key: "^!a", label: "clear all Alert Grid alerts", fn: (*) => ClearAlerts()}
    , {id: "alertteach", key: "^!+a", label: "teach Alert Grid the clicks", fn: (*) => TeachAlerts()}
    , {id: "itraknew", key: "^!d", label: "new daily log in iTrak", fn: (*) => ITrakNewLog()}
    , {id: "itrakteach", key: "^!+i", label: "teach iTrak the click", fn: (*) => TeachITrak()}
    , {id: "entrypick", key: "^!f", label: "full-entry log (Break, Table Drop...)", fn: (*) => ShowEntryPick()}
    , {id: "entryteach", key: "^!+f", label: "teach the daily log fields", fn: (*) => TeachEntryFields()}
    , {id: "repeatlog", key: "$^!+r", label: "repeat the last full-entry log", fn: (*) => RepeatLastLog()}
    , {id: "endnow", key: "^!+e", label: "End Time Now in the open daily log", fn: (*) => EntryEndNow()}
    , {id: "dashboard", key: "^!+d", label: "shift dashboard", fn: (*) => ShowDashboard()}
    , {id: "cheat", key: "^!h", label: "this sheet", fn: (*) => ShowCheatSheet()}]

Lists := Map()          ; @lists from templates.txt, e.g. @tables
Lists.CaseSense := false
AppList := []
LoginList := []
PickMode := false        ; true while Pick window waits for a click
PickHwnd := 0
TeachBusy := false       ; true while the Alert Grid teach step runs
NotesWin := ""           ; the quick notes window while it's open
PadShort := ""           ; a shorthand line being run from the call pad (v3.26.0)
LastRun := ""            ; the last full-entry log that was filled in: {e, syn} (v3.28.0)
Cancelled := ""          ; the last form closed with Esc: its title, boxes and time (v3.27.0)
InErr := false
LeftOnClip := ""         ; the last log Watchlog left on the clipboard (not your own copy)
CallPadWin := ""         ; the call pad window (hidden, not closed, when you press Esc)
CallPadTarget := 0       ; the window you were in when the pad opened
CallPadLoaded := false
PadText := ""            ; what is on the call pad now (this PC only)
PadStart := ""           ; HH:mm the current call began
PadStamp := 0            ; when the pad text last changed
DashWin := ""             ; the open Shift dashboard window
PadKeys := 0             ; keys typed on the pad for this call (for the time saved tally)
PadHistory := []         ; earlier calls this shift, newest first
AutoMap := Map()         ; casino autocorrect: what you type -> what it becomes
AutoMap.CaseSense := false
AutoStamp := "-"         ; modified time of autocorrect.txt when it was last read
CurForm := ""
JustFired := 0
ReminderGui := ""
SdsTries := 0
WatchTimes := Map()
JournalNotified := false
Picker := ""            ; the template finder (Ctrl+Alt+Space) while it's open
SettingsWin := ""       ; the Settings window while it's open
FirstRun := false       ; true when this PC had no settings.ini yet
ReloadAt := 0           ; when an automatic reload was asked for
UpdateOffered := ""     ; the update already offered this run (Later = don't ask again)
Tpl := {src: "", file: "", count: 0, version: "", code: "", note: "", mine: 0, program: ""}   ; where the templates came from

TutorialWin := ""       ; the tutorial window while it's open
HomeWin := ""           ; the home window while it's open
EditorWin := ""         ; the template editor while it's open
WinMenu := ""           ; the tray's Windows sub-menu (has the Caps Lock guard tick)
if A_IsCompiled {
    ; "Watchlog.exe /selftest" only proves the exe starts (used before an update is swapped in)
    if A_Args.Length && A_Args[1] = "/selftest"
        ExitApp 0
    try DirCreate DataDir
    if A_Args.Length && A_Args[1] = "/uninstall" {
        Uninstall()
        ExitApp
    }
    if CheckInstall()
        ExitApp
    ; only one Watchlog at a time, even if an older copy or the script runs from elsewhere
    CloseOtherCopies()
    InstallBuiltIns()
}

MoveFromOldName()
OnClipboardChange(NoteCopy)

; Signs this PC has run Watchlog before (used if settings.ini goes missing)
RanBefore := FileExist(ActivityFile) != ""
Loop Reg RegKey
    RanBefore := true

TrimActivity()
TrimDayItems()
Activity("Started v" VERSION " on " A_ComputerName " (Windows user " A_UserName ") from " A_ScriptDir)
OnExit(LogExit)
OnError(LogError)
LoadSettings()
LoadTemplates()
LoadApps()
RegisterHotkeys()
CheckScale()
DailyBackup()
RegisterStamps()
ResumeSdsResign()
BreakResume()
StartWatching()
CleanJournal()
SetTimer CleanJournal, 6 * 3600000

; The Watchlog icon (Watchlog.ico next to this file; the green H without it)
if FileExist(IconFile)
    try TraySetIcon IconFile

; Click the tray icon for the home window, right-click it for the menu
; (see TRAY MENU below)
SetIconTip()
BuildTrayMenu()

; The red Caps Lock tag (see CAPS LOCK below)
BuildCapsTag()
SetTimer CheckCaps, 150

; A newer Watchlog in the team folder: offer it before anything else
CheckForUpdate()
AnnounceVersion()
; First time on this PC: the setup window (it's the Settings window)
if FirstRun
    ShowTutorial(true)


; =====================================================================
;  VERSION
;  Each load shows "Watchlog v3.0.1 running" in the bottom-right
;  corner for a few seconds. The templates file can say which version
;  everyone should be on ("# Program version: 3.0.1"). If this PC is on
;  an older one, it says so when it loads, on the tray icon and in the
;  version box. The program check code tells two PCs apart exactly: the
;  same code means exactly the same Watchlog.ahk.
; =====================================================================
OneDriveMissing() {
    return InStr(HomeDir, "OneDrive") && !ProcessExist("OneDrive.exe")
}

; True when the templates file names a newer program version than this one
OutOfDate() {
    return Tpl.program != "" && VerCompare(VERSION, Tpl.program) < 0
}

; One line on whether this PC has the version the team is on
VersionStatus() {
    if Tpl.program = ""
        return "The templates file doesn't say which version the team is on (no `"# Program version:`" line)."
    if OutOfDate()
        return "OUT OF DATE: the team is on v" Tpl.program ". This PC needs the new Watchlog.ahk."
    return "Up to date: the team is on v" Tpl.program "."
}

ProgramCode() {
    static code := ""
    if code = ""
        try code := A_IsCompiled ? CheckCode(VERSION "|" FileGetSize(A_ScriptFullPath)) : CheckCode(FileRead(A_ScriptFullPath, "UTF-8"))
    return code
}

AnnounceVersion() {
    CoordMode "ToolTip", "Screen"
    ToolTip "Watchlog v" VERSION " running" (OutOfDate() ? "  (update needed)" : Tpl.program != "" ? "  (up to date)" : ""), A_ScreenWidth - 290, A_ScreenHeight - 90, 2
    SetTimer () => ToolTip(, , , 2), -4000
    ; (when the update is waiting in the team folder, it has just been offered)
    if OutOfDate() && !UpdateWaiting() {
        Activity("Out of date: running v" VERSION ", the templates say v" Tpl.program)
        MsgBox "This PC is running Watchlog v" VERSION ", but the team is on v" Tpl.program ".`n`n"
            . "Get the new " (A_IsCompiled ? "Watchlog.exe" : "Watchlog.ahk") " from whoever looks after the tool, put it in place of this one:`n" A_ScriptFullPath (A_IsCompiled ? "" : "`n`nthen press Ctrl+Alt+R."), "Watchlog - update needed", "Icon!"
    }
}

; Tray menu > the version line at the top
ShowVersion() {
    MsgBox "Watchlog v" VERSION "  (" VERSION_DATE ")`n" COPYRIGHT "`n`n" VersionStatus()
        . "`n`nProgram check code: " ProgramCode() "`n(The same code on two PCs means exactly the same program.)"
        . "`n`nRunning from:`n" A_ScriptFullPath
        . "`n`nTemplates: " TemplateSummary()
        . "`n`nTray menu > Security and status shows what's kept where.", "Watchlog version"
}


; =====================================================================
;  MOVING FROM LOG TEMPLATES
;  Watchlog was called Log Templates before v3.0.1. On a PC that ran the
;  old one, this moves things over the first time Watchlog starts:
;    - closes Log Templates if it's still running (both at once would
;      type every log twice)
;    - %LOCALAPPDATA%\Log Templates (activity log, team copy, backups)
;      becomes %LOCALAPPDATA%\Watchlog
;    - HKCU\Software\Log Templates (last login times) moves to Watchlog
;    - a Startup shortcut to Log Templates.ahk becomes one to Watchlog
;  Saved passwords move one by one the first time each is used (see
;  CredLoad), so they're never lost even if something here fails.
;  A small Log Templates.ahk is left in the folder that only starts
;  Watchlog, so an old shortcut on another bay still works.
; =====================================================================
MoveFromOldName() {
    oldData := EnvGet("LOCALAPPDATA") "\Log Templates"
    oldKey := "HKCU\Software\Log Templates"
    moved := []
    ; The old program, if it's still running on this PC
    prev := A_DetectHiddenWindows
    DetectHiddenWindows true
    for id in WinGetList("\Log Templates.ahk ahk_class AutoHotkey") {
        try {
            pid := WinGetPID(id)
            WinClose id
            if !ProcessWaitClose(pid, 5)
                ProcessClose pid
            moved.Push("closed the old Log Templates that was still running")
        }
    }
    DetectHiddenWindows prev
    if DirExist(oldData) && !DirExist(DataDir) {
        try {
            DirMove oldData, DataDir
            moved.Push("moved " oldData " to " DataDir)
        }
    }
    hadOldKey := false
    Loop Reg oldKey
        hadOldKey := true
    if hadOldKey {
        try {
            Loop Reg oldKey
                RegWrite RegRead(), A_LoopRegType, RegKey, A_LoopRegName
            RegDeleteKey oldKey
            moved.Push("moved " oldKey " to " RegKey)
        }
    }
    Loop Files A_Startup "\*.lnk" {
        try {
            FileGetShortcut A_LoopFileFullPath, &target
            if SubStr(target, -18) = "\Log Templates.ahk" {
                FileDelete A_LoopFileFullPath
                if !FileExist(A_Startup "\Watchlog.lnk")
                    FileCreateShortcut A_ScriptFullPath, A_Startup "\Watchlog.lnk", A_ScriptDir, , "Watchlog", FileExist(IconFile) ? IconFile : ""
                moved.Push("Startup shortcut now starts Watchlog")
            }
        }
    }
    for m in moved
        Activity("Moving from Log Templates: " m)
}


; =====================================================================
;  ACTIVITY LOG  -  %LOCALAPPDATA%\Watchlog\activity.log
;  A plain record of what the tool did on this PC and when: starting,
;  where the templates came from, settings and passwords changed, and
;  each time it typed a login (the username and the program, never the
;  password). It never holds a password or the text of a log.
;  Tray menu > Activity log opens it. It trims itself past 200 KB.
; =====================================================================
Activity(what) {
    try {
        if !DirExist(DataDir)
            DirCreate DataDir
        FileAppend FormatTime(, "yyyy-MM-dd HH:mm:ss") "  " what "`n", ActivityFile, "UTF-8"
    }
}

TrimActivity() {
    try {
        if FileGetSize(ActivityFile) < 200000
            return
        text := FileRead(ActivityFile, "UTF-8")
        cut := InStr(text, "`n", , StrLen(text) // 2)
        f := FileOpen(ActivityFile, "w", "UTF-8")
        f.Write(SubStr(text, cut + 1))
        f.Close()
    }
}

OpenActivity() {
    if !FileExist(ActivityFile)
        Activity("Activity log opened")
    Run 'notepad.exe "' ActivityFile '"'
}

LogExit(reason, code) {
    if reason != "Reload"
        Activity("Closed (" reason ")")
}

; Errors still show their usual message; the log gets the line number and
; message only (never the values involved, which could be anything)
LogError(e, mode) {
    global InErr
    Activity("Error on line " e.Line ": " e.Message)
    if InErr
        return 0
    ; A short plain box instead of AutoHotkey's error window; Watchlog keeps
    ; running (v3.27.0). The line number is what to report.
    InErr := true
    try MsgBox("That didn't finish, but Watchlog is still running.`n`nIf it keeps happening, tell whoever looks after the tool:`nline " e.Line ": " e.Message, "Watchlog", "Icon! T20")
    InErr := false
    return 1
}


; =====================================================================
;  SETTINGS
; =====================================================================
LoadSettings() {
    if !FileExist(SettingsFile)
        FirstRunSetup()
    Cfg["LoginTrigger"] := Trim(IniRead(SettingsFile, "User", "LoginTrigger", ""))
    Cfg["LoginUser"] := Trim(IniRead(SettingsFile, "User", "LoginUser", ""))
    Cfg["LoginPassword"] := IniRead(SettingsFile, "User", "LoginPassword", "")
    Cfg["LaunchWork"] := Trim(IniRead(SettingsFile, "Paths", "LaunchWork", A_MyDocuments "\LaunchWork.bat"))
    ; A LaunchWork.bat that came in the program folder (a shared copy) works too
    if !FileExist(Cfg["LaunchWork"]) && FileExist(HomeDir "\LaunchWork.bat")
        Cfg["LaunchWork"] := HomeDir "\LaunchWork.bat"
    Cfg["CitrixTab"] := Trim(IniRead(SettingsFile, "Paths", "CitrixTab", "Citrix|apps.gcgaming.com"))
    Cfg["LaunchWait"] := Trim(IniRead(SettingsFile, "Paths", "LaunchWait", "20"))
    Cfg["FaceUrl"] := Trim(IniRead(SettingsFile, "Paths", "FaceUrl", "https://itrakappprod.olgnetwork.ca/iTrak/login.aspx"))
    Cfg["CitrixUrl"] := Trim(IniRead(SettingsFile, "Paths", "CitrixUrl", "https://apps.gcgaming.com/Citrix/GCGCWeb/"))
    ; The team's shared templates file (blank = templates.txt in this folder)
    Cfg["SharedTemplates"] := Trim(IniRead(SettingsFile, "Templates", "Shared", ""), " `t`"")
    ; Shift journal: full = time, name and text of every log; counts = time
    ; and name only; off = nothing saved. KeepDays: older shift files are
    ; deleted (0 = keep them all).
    Cfg["JournalSave"] := StrLower(Trim(IniRead(SettingsFile, "Journal", "Save", "full")))
    if !RegExMatch(Cfg["JournalSave"], "^(full|counts|off)$")
        Cfg["JournalSave"] := "full"
    keep := Trim(IniRead(SettingsFile, "Journal", "KeepDays", "30"))
    Cfg["KeepDays"] := IsInteger(keep) && keep >= 0 ? Integer(keep) : 30
    ; Ctrl+Alt+L puts the saved window layout back at the end (only if one was saved)
    ; the character(s) typed in front of code words instead of ; (v3.25.0):
    ; 1 to 3 symbols, no letters, digits, spaces or : or `
    pfx := Trim(IniRead(SettingsFile, "Triggers", "Prefix", ";"))
    Cfg["Prefix"] := pfx != "" && StrLen(pfx) <= 3 && !RegExMatch(pfx, "[\s:a-zA-Z0-9]") && !InStr(pfx, "``") ? pfx : ";"
    Cfg["LayoutAfterStart"] := !RegExMatch(StrLower(Trim(IniRead(SettingsFile, "Layout", "AfterStart", "yes"))), "^(no|off|0|false)$")
    ; Ctrl+Alt+L signs into the Bally programs it just opened (after asking)
    Cfg["SignInAfterStart"] := !RegExMatch(StrLower(Trim(IniRead(SettingsFile, "StartOfShift", "SignIn", "yes"))), "^(no|off|0|false)$")
    ; The plain Caps Lock key (which does nothing with the guard on) clears the Alert Grid alerts
    Cfg["CapsClearsAlerts"] := !RegExMatch(StrLower(Trim(IniRead(SettingsFile, "AlertGrid", "CapsLockClears", "yes"))), "^(no|off|0|false)$")
    ; Dark look for every Watchlog window (off unless turned on in the tray menu or Customize)
    Cfg["Dark"] := !RegExMatch(StrLower(Trim(IniRead(SettingsFile, "Look", "Dark", "no"))), "^(no|off|0|false)$")
    ; Minutes after an SDS login to sign back into SDS by itself (0 = off)
    sr := Trim(IniRead(SettingsFile, "SDS", "ResignMinutes", "62"))
    Cfg["SdsResign"] := IsInteger(sr) && sr >= 0 && sr <= 600 ? Integer(sr) : 62
    ; Call pad: Numpad + opens it (Ctrl+Alt+N always does). Key=off frees the + key.
    Cfg["PadKey"] := !RegExMatch(StrLower(Trim(IniRead(SettingsFile, "CallPad", "Key", "NumpadAdd"))), "^(off|no|0|false|none)$")
    ; Casino autocorrect in the call pad and the log forms
    Cfg["Autocorrect"] := !RegExMatch(StrLower(Trim(IniRead(SettingsFile, "CallPad", "Autocorrect", "yes"))), "^(no|off|0|false)$")
    ; Beep with the login reminder pop-up (off unless asked for in Settings)
    Cfg["ReminderBeep"] := RegExMatch(StrLower(Trim(IniRead(SettingsFile, "Reminder", "Beep", "no"))), "^(yes|on|1|true)$") ? true : false
    ; A folder of your own to take updates from, instead of the team folder
    Cfg["UpdateFolder"] := Trim(IniRead(SettingsFile, "Updates", "Folder", ""), " `t`"")
    Cfg["CloseApps"] := Trim(IniRead(SettingsFile, "EndOfShift", "Close", "outlook.exe, olk.exe, ms-teams.exe, Teams.exe, javaw.exe, CMPDesktop.exe, wfica32.exe, Spotify.exe, msedge.exe, explorer.exe"))

    ; Programs Ctrl+Alt+L opens before LaunchWork.bat: [StartOfShift] Run1 ... Run9
    ; A * in a path means "any version" (the newest one found is used).
    ; WindowN (optional) = how to spot it already open, so it isn't opened twice.
    Cfg["StartApps"] := []
    hasSection := false
    ; (a [StartOfShift] with only SignIn= in it, from Settings, still means the usual three)
    try hasSection := RegExMatch(IniRead(SettingsFile, "StartOfShift"), "im)^\s*Run\d\s*=") > 0
    if hasSection {
        Loop 9 {
            p := Trim(IniRead(SettingsFile, "StartOfShift", "Run" A_Index, ""))
            w := Trim(IniRead(SettingsFile, "StartOfShift", "Window" A_Index, ""))
            if p != ""
                Cfg["StartApps"].Push({path: p, win: w != "" ? w : DefaultStartWindow(p)})
        }
    } else {
        for p in ["C:\BallyTechnologies\AlertGridUI*\AlertGridUI\AlertGridUI.bat"
                , "C:\BallyTechnologies\SDSUI*\SDSUI\SDSUI.bat"
                , "C:\BallyTechnologies\CMPDesktop*\CMPDesktop\CMPDesktop.exe"]
            Cfg["StartApps"].Push({path: p, win: DefaultStartWindow(p)})
    }

    ; Logins: [Login1] ... [Login9], plus the older single login under [User].
    ; Any password still in settings.ini gets moved into Windows Credential
    ; Manager on this PC, then removed from the file.
    moved := 0, warnings := "", failed := ""
    if Cfg["LoginUser"] != "" && Cfg["LoginTrigger"] != "" {
        pw := MovePassword("User", "LoginPassword", Cfg["LoginUser"], Cfg["LoginPassword"], &moved, &failed)
        warnings .= AddLogin(Cfg["LoginTrigger"], Cfg["LoginUser"], pw, "")
    }
    Loop 9 {
        sec := "Login" A_Index
        trig := Trim(IniRead(SettingsFile, sec, "Trigger", ""))
        user := Trim(IniRead(SettingsFile, sec, "User", ""))
        pw := IniRead(SettingsFile, sec, "Password", "")
        win := Trim(IniRead(SettingsFile, sec, "Window", ""))
        remind := Trim(IniRead(SettingsFile, sec, "Remind", ""))
        remind := IsInteger(remind) ? Integer(remind) : 0
        if trig != "" && user != "" {
            pw := MovePassword(sec, "Password", user, pw, &moved, &failed)
            warnings .= AddLogin(trig, user, pw, win, remind)
        }
    }
    if moved
        MsgBox moved " login password(s) were moved out of settings.ini and into Windows Credential Manager on this PC.`n`n"
            . "settings.ini no longer holds them. On your other bay PCs, each login asks for its password once the first time you use it.", "Watchlog"
    if failed != ""
        MsgBox "These passwords couldn't be moved out of settings.ini, so they're still in it (logins keep working):`n`n" failed
            . "`nTake a screenshot of this and send it to Claude.", "Watchlog", "Icon!"
    if warnings != ""
        MsgBox "Login warning:`n`n" warnings "`nAdd a `; in front of the trigger, or add a Window= line so it only works in one program.", "Watchlog", "Icon!"
}

; Saves a password from settings.ini into Credential Manager and deletes it
; from the file. Returns "" when it moved, or the password if it couldn't
; (and adds the reason to failed).
MovePassword(sec, key, user, pw, &moved, &failed) {
    if pw = "" || pw = "********"
        return ""
    if !CredSave(user, pw) {
        failed .= "   " user ":  Windows wouldn't save it (error " A_LastError ")`n"
        return pw
    }
    if CredLoad(user) !== pw {
        failed .= "   " user ":  saved, but reading it back didn't match (error " A_LastError ")`n"
        return pw
    }
    try {
        IniDelete SettingsFile, sec, key
    } catch as e {
        failed .= "   " user ":  saved in Credential Manager, but couldn't delete it from settings.ini (" e.Message ")`n"
        return ""
    }
    if IniRead(SettingsFile, sec, key, "") != "" {
        failed .= "   " user ":  saved in Credential Manager, but it's still in settings.ini after deleting`n"
        return ""
    }
    moved += 1
    Activity("Password for " user " moved out of settings.ini into Credential Manager")
    return ""
}

; win = optional window (e.g. iTrak) the login is limited to.
; remind = optional minutes after using it to pop up "time to log in again".
; Returns a warning if the trigger could fire while typing normally.
AddLogin(trig, user, fallbackPw, win, remind := 0) {
    rec := {trig: trig, user: user, win: win, remind: remind, pw: fallbackPw}
    rec.timer := ShowLoginReminder.Bind(rec)
    HotIf(win != "" ? MakeWindowCheck(win) : NotInSettings)
    Hotstring(":*C:" TrigKey(trig), (*) => DoLogin(trig, user, fallbackPw, rec))
    HotIf
    LoginList.Push(rec)
    if remind && !(Cfg["SdsResign"] && (InStr(win, "SDS") || IsSdsLogin(rec)))
        ResumeReminder(rec)
    if win = "" && SubStr(trig, 1, 1) != ";"
        return "   " trig " has no `; in front, so it can fire in a chat or email and send your password.`n"
    return ""
}

MakeWindowCheck(win) {
    return (*) => LoginWindowActive(win)
}

; win can name several windows, separated by | (the login works in any of them)
LoginWindowActive(win) {
    SetTitleMatchMode 2
    if SettingsActive()
        return false
    for part in StrSplit(win, "|") {
        part := Trim(part)
        if part != "" && WinActive(part)
            return true
    }
    return false
}

; ---- "Pick window": click a program and its name is filled in for you ----
#HotIf PickMode
LButton:: {
    global PickMode, PickHwnd
    MouseGetPos(, , &h)
    PickHwnd := h
    PickMode := false
}
Esc:: {
    global PickMode
    PickMode := false
}
#HotIf

; Waits for one click on any window (the click is swallowed, so it presses
; nothing there) and returns text for the Window box, or "" if cancelled.
PickWindow() {
    global PickMode, PickHwnd
    PickHwnd := 0
    PickMode := true
    ToolTip "Click the program this login should work in.`nEsc cancels.", , , 7
    stop := A_TickCount + 30000
    while PickMode && A_TickCount < stop
        Sleep 50
    PickMode := false
    ToolTip , , , 7
    hwnd := PickHwnd
    if !hwnd
        return ""
    try {
        pid := WinGetPID("ahk_id " hwnd)
        exe := WinGetProcessName("ahk_id " hwnd)
        title := WinGetTitle("ahk_id " hwnd)
    } catch {
        MsgBox "Couldn't read that window. Try again, or type it in.", "Watchlog", "Icon!"
        return ""
    }
    if pid = DllCall("GetCurrentProcessId") {
        MsgBox "That was Watchlog itself. Press Pick window again and click the other program.", "Watchlog"
        return ""
    }
    ; Browsers, Java programs and Citrix host many different things, so they
    ; get the title as well (Citrix sessions are all wfica32.exe)
    if RegExMatch(exe, "i)^(wfica32)\.exe$")
        guess := "ahk_exe " exe
    else if RegExMatch(exe, "i)^(chrome|msedge|firefox|javaw|java)\.exe$") && title != ""
        guess := title " ahk_exe " exe
    else
        guess := "ahk_exe " exe
    ib := InputBox("This is what I found:`n`n   Program: " exe "`n   Title: " title "`n`nThe login will only type in a window matching the text below. For a web page or Java program, cut the title down to the part that never changes (like iTrak).", "Watchlog - Pick window", "w480 h260", guess)
    return ib.Result = "OK" ? Trim(ib.Value) : ""
}

; Shortcuts don't fire in the Settings window or the template editor, so
; typing ;me into a Shortcut box doesn't type a password there
SettingsActive() => (IsObject(SettingsWin) || IsObject(EditorWin)) && WinActive("ahk_pid " DllCall("GetCurrentProcessId"))
NotInSettings(*) => !SettingsActive()

; What you type for a code word: the files keep the ; in front (so they work
; the same on every PC), and the PC's own prefix is typed instead (v3.25.0)
TrigKey(t) {
    pfx := Cfg.Has("Prefix") ? Cfg["Prefix"] : ";"
    return pfx != ";" && SubStr(t, 1, 1) = ";" ? pfx SubStr(t, 2) : t
}

; Types the username, Tab, the password, Enter.
; The password comes from Windows Credential Manager on this PC. If there
; isn't one saved yet, it asks once and saves it.
DoLogin(trig, user, fallbackPw, rec) {
    ; Never type a password into the template finder's search box or Settings
    if PickerActive() || SettingsActive()
        return
    pw := CredLoad(user)
    if pw = ""
        pw := fallbackPw
    if pw = "" {
        target := WinExist("A")
        ib := InputBox("There's no password saved on this PC for " user ".`n`nType it once. It's kept in Windows Credential Manager on this PC, not in settings.ini.", "Watchlog - " trig, "Password w400 h170")
        if ib.Result != "OK" || ib.Value = ""
            return
        pw := ib.Value
        if CredSave(user, pw)
            Activity("Password saved on this PC for " user " (asked at first use)")
        else
            MsgBox "Couldn't save the password in Credential Manager, so it will ask again next time.", "Watchlog", "Icon!"
        if target {
            try WinActivate "ahk_id " target
            WinWaitActive "ahk_id " target, , 1
        }
    }
    ; Last check before typing: the right window must still be in front
    if rec.win != "" && !LoginWindowActive(rec.win) {
        Activity("Login " trig " NOT typed: " "the window it is locked to wasn't in front")
        Tip("Login not typed: the program it's for isn't in front.", 3500, true)
        return
    }
    ; A login with no program set never goes into Notepad, mail, chat, Office,
    ; Watchlog's own windows or the daily log (v3.27.0)
    if rec.win = "" && (blocked := LoginBlockedWin()) != "" {
        Activity("Login " trig " NOT typed: " blocked " was in front")
        Tip("Login not typed: " blocked " is in front. Click the program it's for first.", 4000, true)
        return
    }
    SendInput "{Text}" user
    SendInput "{Tab}"
    SendInput "{Text}" pw
    SendInput "{Enter}"
    CountSaved("login", StrLen(user) + StrLen(pw) + 2 - StrLen(trig), "Login " trig)
    pw := ""
    ; Typed into SDS while "sign back into SDS by itself" is on: no
    ; "log in again" reminder for this login at all (v3.20.0). The login is
    ; remembered as an SDS one, so the reminder stays off after a reload and
    ; even if its Window= doesn't name SDS.
    isSds := RegExMatch(WinGetTitle("A"), "i)^SDS\b")
    if isSds && Cfg["SdsResign"] {
        try RegWrite 1, "REG_DWORD", RegKey, "SdsLogin " rec.user
        try RegDelete RegKey, "LastLogin " rec.user
        SetTimer rec.timer, 0
    } else
        StartReminder(rec)
    if isSds
        StartSdsResign()
    ; The activity log notes where a password was typed (never the password)
    exe := ""
    try exe := WinGetProcessName("A")
    Activity("Login typed: " trig " (" user ") into " (exe != "" ? exe : "an unknown window"))
}


; The window that must never get a typed password, or "" (v3.27.0)
LoginBlockedWin() {
    hwnd := WinExist("A")
    if !hwnd
        return ""
    exe := "", title := ""
    try exe := StrLower(WinGetProcessName("ahk_id " hwnd))
    try title := WinGetTitle("ahk_id " hwnd)
    if WinGetPID("ahk_id " hwnd) = ProcessExist()
        return "a Watchlog window"
    if RegExMatch(exe, "^(notepad|outlook|olk|ms-teams|teams|winword|excel|onenote|slack|whatsapp|discord)\.exe$")
        return exe
    if InStr(title, "Daily Log Entry")
        return "the daily log"
    return ""
}


; =====================================================================
;  SDS SIGNS BACK IN BY ITSELF  ([SDS] ResignMinutes=62, 0 = off)
;  SDS logs you out an hour after you sign in. Typing the SDS login starts
;  a countdown; when it runs out and SDS is back on its login screen, SDS
;  comes to the front, the saved login is typed, and the window you were in
;  is put back. If SDS still says Welcome it looks again every minute (up
;  to 6 times). The time is kept on this PC, so a reload doesn't reset it.
; =====================================================================
StartSdsResign() {
    global SdsTries
    SdsTries := 0
    if !Cfg["SdsResign"]
        return
    try RegWrite A_Now, "REG_SZ", RegKey, "LastSDSLogin"
    SetTimer SdsResignDue, -Cfg["SdsResign"] * 60000
}

ResumeSdsResign() {
    global SdsTries
    SdsTries := 0
    if !Cfg["SdsResign"]
        return
    try {
        last := RegRead(RegKey, "LastSDSLogin")
        secsLeft := Cfg["SdsResign"] * 60 - DateDiff(A_Now, last, "Seconds")
    } catch {
        return
    }
    if secsLeft > 0
        SetTimer SdsResignDue, -secsLeft * 1000
    else if secsLeft > -600
        SetTimer SdsResignDue, -1000
}

; The SDS window on its login screen (not "SDS | Welcome, ..."), or 0
SdsLoginScreen() {
    SetTitleMatchMode 2
    for id in WinGetList("SDS ahk_exe javaw.exe") {
        t := SafeTitle(id)
        if RegExMatch(t, "i)^SDS\b") && !InStr(t, "Welcome")
            return id
    }
    return 0
}

; The login for the SDS window (v3.27.3). Tries the usual match (a login locked to
; the program in front); if something else grabbed the keyboard in the meantime it
; brings SDS back and tries again, then falls back to the login whose Only in
; names SDS, or the one that was last typed into SDS.
SdsLoginRec(sds) {
    loop 2 {
        r := LoginForWindow()
        if r
            return r
        try WinActivate "ahk_id " sds
        WinWaitActive "ahk_id " sds, , 2
        Sleep 300
    }
    for rec in LoginList
        if rec.win != "" && InStr(rec.win, "SDS")
            return rec
    for rec in LoginList
        if IsSdsLogin(rec)
            return rec
    return ""
}

SdsResignDue() {
    global SdsTries
    if !Cfg["SdsResign"]
        return
    ; Not while you're in Settings or the editor, or in the middle of typing
    if SettingsActive() || PickerActive() {
        SetTimer SdsResignDue, -30000
        return
    }
    sds := SdsLoginScreen()
    if !sds {
        if SDSWindow() && ++SdsTries <= 6 {
            SetTimer SdsResignDue, -60000     ; still signed in; look again in a minute
            return
        }
        Activity("SDS sign-in: " (SDSWindow() ? "SDS still said Welcome after 6 looks" : "no SDS login screen found") ", nothing typed")
        return
    }
    waited := 0
    while A_TimeIdlePhysical < 1500 && waited < 15000 {
        Sleep 300
        waited += 300
    }
    prev := WinExist("A")
    Tip("Signing back into SDS...", 4000, true)
    WinActivate "ahk_id " sds
    if !WinWaitActive("ahk_id " sds, , 3) {
        Activity("SDS sign-in: couldn't bring SDS to the front")
        return
    }
    Sleep 1000
    rec := SdsLoginRec(sds)
    if !rec {
        why := ""
        for l in LoginList
            why .= " [" l.trig " -> " (l.win != "" ? l.win : "any program") "]"
        Activity("SDS sign-in: no saved login is locked to SDS; logins are:" why)
        return
    }
    ; DoLogin checks the window it is locked to is in front: make sure SDS is
    try WinActivate "ahk_id " sds
    WinWaitActive "ahk_id " sds, , 2
    Activity("SDS sign-in: signing back in by itself")
    DoLogin(rec.trig, rec.user, rec.pw, rec)
    Sleep 3000
    if prev && prev != sds && WinExist("ahk_id " prev)
        try WinActivate "ahk_id " prev
}


; =====================================================================
;  LOGIN REMINDER  (Remind=55 under a [LoginN] in settings.ini)
;  Using that login starts the countdown. When it runs out, a small
;  window pops up on top without taking over the keyboard. The time of
;  the last login is kept on this PC, so a reload doesn't reset it.
; =====================================================================
StartReminder(rec) {
    if !rec.remind
        return
    CloseReminder()
    try RegWrite A_Now, "REG_SZ", RegKey, "LastLogin " rec.user
    SetTimer rec.timer, -rec.remind * 60000
}

; After a reload, picks the countdown back up from the last login
ResumeReminder(rec) {
    try {
        last := RegRead(RegKey, "LastLogin " rec.user)
        secsLeft := rec.remind * 60 - DateDiff(A_Now, last, "Seconds")
    } catch {
        return
    }
    if secsLeft > 0
        SetTimer rec.timer, -secsLeft * 1000
    else if secsLeft > -600              ; only just ran out (e.g. during a reload)
        SetTimer rec.timer, -1000
}

; True when this login was last typed into SDS (see DoLogin)
IsSdsLogin(rec) {
    try return RegRead(RegKey, "SdsLogin " rec.user) = 1
    return false
}

ShowLoginReminder(rec) {
    global ReminderGui
    ; SDS signs itself back in, so its "log in again" warning isn't needed
    if Cfg["SdsResign"] && (InStr(rec.win, "SDS") || IsSdsLogin(rec))
        return
    CloseReminder()
    g := WGui("+AlwaysOnTop +ToolWindow", "Login reminder")
    g.SetFont("s11", "Segoe UI")
    g.MarginX := 16, g.MarginY := 12
    g.AddText(, "Time to log in again  (" rec.remind " minutes since the last one)`n`n      " TrigKey(rec.trig) "      " rec.user)
    g.AddButton("Default w100", "OK").OnEvent("Click", (*) => CloseReminder())
    g.SetFont("s9")
    g.AddText("x+12 yp+6", "(or press Esc)")
    g.OnEvent("Close", (*) => CloseReminder())
    g.OnEvent("Escape", (*) => CloseReminder())
    ReminderGui := g
    ; Bottom-right corner, above the taskbar, without taking the keyboard
    ; from the window you're typing in
    g.Show("NoActivate Hide")
    g.GetPos(, , &w, &h)
    MonitorGetWorkArea(MonitorGetPrimary(), , , &right, &bottom)
    g.Show("NoActivate x" (right - w - 12) " y" (bottom - h - 12))
    if Cfg["ReminderBeep"]
        SoundBeep 750, 250
}

CloseReminder() {
    global ReminderGui
    if IsObject(ReminderGui) {
        try ReminderGui.Destroy()
        ReminderGui := ""
    }
}

; =====================================================================
;  WINDOWS CREDENTIAL MANAGER
;  Passwords are saved as "Watchlog: username" (Control Panel >
;  Credential Manager > Windows Credentials shows them). They stay on
;  this PC and don't sync through OneDrive. One still saved under the old
;  name ("Log Templates: username") is moved to the new name the first
;  time it's used.
; =====================================================================
CredSave(user, pw, target := "") {
    if target = ""
        target := "Watchlog: " user
    cred := Buffer(24 + A_PtrSize * 7, 0)                       ; CREDENTIALW
    NumPut("UInt", 1, cred, 4)                                  ; Type = generic
    NumPut("Ptr", StrPtr(target), cred, 8)                      ; TargetName
    NumPut("UInt", StrLen(pw) * 2, cred, 16 + A_PtrSize * 2)    ; CredentialBlobSize
    NumPut("Ptr", StrPtr(pw), cred, 16 + A_PtrSize * 3)         ; CredentialBlob
    NumPut("UInt", 2, cred, 16 + A_PtrSize * 4)                 ; Persist = this PC
    NumPut("Ptr", StrPtr(user), cred, 24 + A_PtrSize * 6)       ; UserName
    return DllCall("Advapi32.dll\CredWriteW", "Ptr", cred, "UInt", 0, "Int")
}

CredLoad(user) {
    pw := CredReadTarget("Watchlog: " user)
    if pw != ""
        return pw
    ; Saved by Log Templates: move it to the new name (the old one is only
    ; deleted once the new one is saved)
    pw := CredReadTarget("Log Templates: " user)
    if pw != "" && CredSave(user, pw) {
        DllCall("Advapi32.dll\CredDeleteW", "Str", "Log Templates: " user, "UInt", 1, "UInt", 0, "Int")
        Activity("Password for " user " moved from the old Log Templates name to Watchlog")
    }
    return pw
}

CredReadTarget(target) {
    pCred := 0
    if !DllCall("Advapi32.dll\CredReadW", "Str", target, "UInt", 1, "UInt", 0, "Ptr*", &pCred, "Int") || !pCred
        return ""
    size := NumGet(pCred, 16 + A_PtrSize * 2, "UInt")
    blob := NumGet(pCred, 16 + A_PtrSize * 3, "Ptr")
    pw := (size && blob) ? StrGet(blob, size // 2, "UTF-16") : ""
    DllCall("Advapi32.dll\CredFree", "Ptr", pCred)
    return pw
}

; Whether this PC has a password saved for a username (without reading it),
; under the new name or the old one
CredExists(user) {
    for target in ["Watchlog: " user, "Log Templates: " user] {
        pCred := 0
        if DllCall("Advapi32.dll\CredReadW", "Str", target, "UInt", 1, "UInt", 0, "Ptr*", &pCred, "Int") && pCred {
            DllCall("Advapi32.dll\CredFree", "Ptr", pCred)
            return true
        }
    }
    return false
}

; Deletes a saved password from this PC (used when a login is removed),
; under both names
CredRemove(user) {
    a := DllCall("Advapi32.dll\CredDeleteW", "Str", "Watchlog: " user, "UInt", 1, "UInt", 0, "Int")
    b := DllCall("Advapi32.dll\CredDeleteW", "Str", "Log Templates: " user, "UInt", 1, "UInt", 0, "Int")
    return a || b
}

; True if settings.ini still has a password typed into it (it shouldn't:
; they're moved into Credential Manager the moment the script sees one)
PasswordInSettings() {
    try text := FileRead(SettingsFile)
    catch
        return false
    return RegExMatch(text, "im)^\s*(Login)?Password\s*=\s*(?!\*+\s*$)\S") > 0
}

; Runs when there is no settings.ini. OneDrive can briefly hide the file
; while it syncs, or rename it settings-PCNAME.ini when two PCs save it at
; once, so it checks for both before starting fresh (a fresh file would
; have no logins in it).
FirstRunSetup() {
    global FirstRun
    while !FileExist(SettingsFile) && (OneDriveMissing() || RanBefore) {
        if MsgBox("There's no settings.ini in this folder:`n" HomeDir "`n`n"
            . (RanBefore ? "Watchlog has run on this PC before, so OneDrive may still be bringing it back.`n`n" : "")
            . (OneDriveMissing() ? "OneDrive isn't running. Start it from the Start menu and let it sync.`n`n" : "")
            . "Yes = check again`nNo = set up new settings", "Watchlog v" VERSION, "YesNo Icon! Default1") != "Yes"
            break
        Sleep 2000
    }
    if FileExist(SettingsFile)
        return

    ; A copy OneDrive renamed, like settings-BAY2.ini
    copy := "", newest := ""
    Loop Files HomeDir "\settings-*.ini" {
        if StrCompare(A_LoopFileTimeModified, newest) > 0
            copy := A_LoopFileFullPath, newest := A_LoopFileTimeModified
    }
    if copy != "" {
        SplitPath copy, &cname
        if MsgBox("There's no settings.ini, but there is " cname " (saved " FormatTime(newest, "MMM d, yyyy HH:mm") ").`n`n"
            . "OneDrive renames settings.ini like this when two PCs save it at the same time, so it's probably yours.`n`n"
            . "Use it as your settings?", "Watchlog v" VERSION, "YesNo Icon? Default1") = "Yes" {
            try {
                FileMove copy, SettingsFile
                Activity("settings.ini was missing; used " cname " (an OneDrive copy) instead")
                return
            } catch as e {
                MsgBox "Couldn't rename it (" e.Message "), so new settings will be set up.", "Watchlog", "Icon!"
            }
        }
    }

    ; The exe on a PC that ran the script version: offer to bring its settings over
    oldDir := A_MyDocuments "\AutoHotkey"
    if A_IsCompiled && StrLower(oldDir) != StrLower(HomeDir) && FileExist(oldDir "\settings.ini") {
        if MsgBox("Found settings from the script version of Watchlog:`n" oldDir "`n`n"
            . "Copy your logins and your own templates over to this one? (Saved passwords stay safe in Windows.)", "Watchlog v" VERSION, "YesNo Icon? Default1") = "Yes" {
            try {
                FileCopy oldDir "\settings.ini", SettingsFile
                if FileExist(oldDir "\my-templates.txt") && !FileExist(MyTemplatesFile)
                    FileCopy oldDir "\my-templates.txt", MyTemplatesFile
                Activity("First run of the exe: settings copied from " oldDir)
                return
            } catch as e {
                MsgBox "Couldn't copy them (" e.Message "), so new settings will be set up.", "Watchlog", "Icon!"
            }
        }
    }

    text := "
    (
; =====================================================================
;  WATCHLOG - your personal settings
;  Most of this is set in tray menu > Settings, so you shouldn't need
;  to edit this file. If you do, save it and the script reloads.
;  No passwords are kept here: they're in Windows Credential Manager.
; =====================================================================

[Templates]
; The team's shared templates file (in SharePoint, synced by OneDrive).
; Blank = templates.txt in this folder. Your own extra templates go in
; my-templates.txt in this folder.
Shared=

[Journal]
; Every log you insert is also saved in Documents\Shift Journal, one
; file per shift. Ctrl+Alt+J shows the shift summary.
; Save=full keeps the log text, Save=counts keeps only the time and
; template name, Save=off turns it off.
; KeepDays = days before old shift files are deleted (0 = keep them).
Save=full
KeepDays=30

[Paths]
LaunchWait=20
CitrixTab=Citrix|apps.gcgaming.com
; The two web pages Ctrl+Alt+L opens, in Microsoft Edge: iTrak facial rec
; (blank = not opened) and the Citrix Receiver page (opened last)
FaceUrl=https://itrakappprod.olgnetwork.ca/iTrak/login.aspx
CitrixUrl=https://apps.gcgaming.com/Citrix/GCGCWeb/

[StartOfShift]
; Programs Ctrl+Alt+L opens first (up to Run9), then it opens the Citrix page in Edge.
; A * means any version, so upgrades don't break these.
Run1=C:\BallyTechnologies\AlertGridUI*\AlertGridUI\AlertGridUI.bat
Run2=C:\BallyTechnologies\SDSUI*\SDSUI\SDSUI.bat
Run3=C:\BallyTechnologies\CMPDesktop*\CMPDesktop\CMPDesktop.exe

[EndOfShift]
; Programs Ctrl+Alt+Shift+L closes (separate with commas)
Close=outlook.exe, olk.exe, ms-teams.exe, Teams.exe, javaw.exe, CMPDesktop.exe, wfica32.exe, Spotify.exe, msedge.exe, explorer.exe

; APP HOTKEYS - Ctrl+Alt + Key switches to the app, or opens it.
; Add more as [App3], [App4] ... up to [App9].
; Taken keys: Q O I H P X R L E J K W A M N
; Built in already: T Teams, U Outlook, Y Spotify, G Edge. To change one,
; add an [AppN] with the same Name and a new Key (Key=none turns it off).
[App1]
Name=SDS
Key=S
Path=C:\BallyTechnologies\SDSUI*\SDSUI\SDSUI.bat
Window=SDS ahk_exe javaw.exe

[App2]
Name=CMP
Key=C
Path=C:\BallyTechnologies\CMPDesktop*\CMPDesktop\CMPDesktop.exe
Window=ahk_exe CMPDesktop.exe

; LOGINS are added in tray menu > Settings. They're saved below as
; [Login1] ... [Login9]: Trigger, User, and optionally Window (only
; works in that program) and Remind (minutes until a log-in-again
; reminder).
    )"
    FileAppend text "`n", SettingsFile, "UTF-16"
    FirstRun := true
    Activity("First run on this PC: new settings.ini made in " HomeDir)
}


; =====================================================================
;  TEMPLATES
;  Read from the team's shared file when one is set in Settings (on
;  SharePoint, synced by OneDrive), otherwise templates.txt in this
;  folder. Then my-templates.txt, your own extras, on top. A trigger the
;  team file already uses is skipped in my-templates.txt, so the team
;  wording always wins.
;  If the shared file can't be opened (OneDrive not running, not synced
;  yet), the last good copy saved on this PC is used and it says so.
; =====================================================================
LoadTemplates() {
    problems := ""
    ; Every trigger fires the moment it's typed, so no trigger may be the start
    ; of another one (;count would fire before you finish typing ;counttables)
    trigs := Map()
    for l in LoginList
        trigs[l.trig] := "login"
    main := ReadTemplateSource()
    if main.note != ""
        problems .= main.note "`n`n"
    mine := ""
    if FileExist(MyTemplatesFile) {
        try mine := FileRead(MyTemplatesFile, "UTF-8")
        catch
            problems .= "Couldn't open my-templates.txt, so your own templates aren't loaded.`n`n"
    }
    ; Shared lists first (team ones, then your own), so any template can use them
    ReadLists(main.text, main.label, false, &problems)
    ReadLists(mine, "my-templates.txt", true, &problems)
    Tpl.count := AddTemplates(main.text, main.src = "local" ? "local" : "team", main.label, trigs, &problems)
    Tpl.mine := AddTemplates(mine, "mine", "my-templates.txt", trigs, &problems)
    Entries := []
    ReadEntries(main.text, main.label, &problems, "main")
    ReadEntries(mine, "my-templates.txt", &problems, "mine")
    Activity("Templates: " TemplateSummary())
    if main.text = "" && main.note = ""
        problems .= "Can't find templates.txt. It needs to be in the same folder as this script:`n" HomeDir "`n`n"
    if problems != "" {
        Activity("Template problems: " StrReplace(Trim(problems, "`n"), "`n", " / "))
        MsgBox "Some templates weren't loaded:`n`n" problems, "Watchlog", "Icon!"
    }
}

; Picks the file the templates come from and reads it.
; Returns {src, file, text, label, note}: src is "team", "team-copy" (the
; last good copy, because the shared file couldn't be read) or "local".
ReadTemplateSource() {
    shared := Cfg["SharedTemplates"]
    if shared = "" {
        Tpl.src := "local", Tpl.file := TemplatesFile
        text := ""
        try text := FileRead(TemplatesFile, "UTF-8")
        catch {
            if FileExist(TemplatesFile)
                return {src: "local", file: TemplatesFile, text: "", label: "templates.txt"
                    , note: "Couldn't open templates.txt. If OneDrive isn't running, start it and press Ctrl+Alt+R."}
        }
        TemplateInfo(text)
        return {src: "local", file: TemplatesFile, text: text, label: "templates.txt", note: ""}
    }
    text := "", why := ""
    try {
        text := FileRead(shared, "UTF-8")
        if !CountTemplates(text)
            why := "has no templates in it", text := ""
    } catch {
        why := FileExist(shared) ? "couldn't be opened (OneDrive may not be running)" : "isn't there (SharePoint may not have synced to this PC)"
    }
    if text != "" {
        Tpl.src := "team", Tpl.file := shared
        TemplateInfo(text)
        SaveTeamCopy(text)
        return {src: "team", file: shared, text: text, label: "Team templates", note: ""}
    }
    ; Couldn't read it: use the last good copy, and try again every minute
    SetTimer RetryTeamFile, 60000
    if FileExist(TeamCopyFile) {
        try {
            text := FileRead(TeamCopyFile, "UTF-8")
            Tpl.src := "team-copy", Tpl.file := TeamCopyFile
            TemplateInfo(text)
            when := FormatTime(FileGetTime(TeamCopyFile, "M"), "MMM d HH:mm")
            Tpl.note := "The team templates file " why ", so the copy saved on this PC on " when " is being used."
            Activity("Team templates file " why "; using the last good copy from " when)
            TrayTip Tpl.note "`nIt switches back by itself once the file can be read.", "Watchlog: team templates", "Icon!"
            return {src: "team-copy", file: TeamCopyFile, text: text, label: "Team templates (saved copy)", note: ""}
        }
    }
    ; No copy yet either: fall back to templates.txt in this folder
    Tpl.src := "local", Tpl.file := TemplatesFile
    try text := FileRead(TemplatesFile, "UTF-8")
    TemplateInfo(text)
    Tpl.note := "The team templates file " why ", and there's no saved copy on this PC yet, so templates.txt in this folder is being used. Its wording may be older."
    return {src: "local", file: TemplatesFile, text: text, label: "templates.txt"
        , note: Tpl.note "`n`n   " shared}
}

; While the saved copy is in use: reload as soon as the shared file can be read
RetryTeamFile() {
    if IsObject(CurForm) || IsObject(SettingsWin) || IsObject(EditorWin)
        return
    try {
        if CountTemplates(FileRead(Cfg["SharedTemplates"], "UTF-8"))
            ReloadOnce()
    }
}

; The wording version (a "# Wording version: ..." line, if the file has one)
; and the check code: the same code on two PCs means exactly the same wording
TemplateInfo(text) {
    Tpl.version := RegExMatch(text, "im)^#\s*Wording version\s*:\s*(.*?)\s*$", &m) ? m[1] : ""
    Tpl.code := text != "" ? CheckCode(text) : ""
    ; "# Program version: 3.0.1" = the version everyone should be running
    Tpl.program := RegExMatch(text, "im)^#\s*Program version\s*:\s*v?(\d+(?:\.\d+)*)", &mp) ? mp[1] : ""
}

CheckCode(text) {
    text := StrReplace(text, "`r`n", "`n")
    n := StrPut(text, "UTF-8") - 1
    buf := Buffer(n + 1, 0)
    StrPut(text, buf, "UTF-8")
    crc := DllCall("ntdll\RtlComputeCrc32", "UInt", 0, "Ptr", buf, "UInt", n, "UInt")
    return Format("{:04X}-{:04X}", crc >> 16, crc & 0xFFFF)
}

; Keeps a copy of the team file on this PC, and notes when the wording changed
SaveTeamCopy(text) {
    old := ""
    try old := FileRead(TeamCopyFile, "UTF-8")
    if old == text
        return
    try {
        if !DirExist(DataDir)
            DirCreate DataDir
        f := FileOpen(TeamCopyFile, "w", "UTF-8")
        f.Write(text)
        f.Close()
    }
    if old = "" {
        Activity("Team templates first read on this PC: " Cfg["SharedTemplates"])
        return
    }
    Activity("Team templates changed: check code " CheckCode(old) " -> " Tpl.code (Tpl.version != "" ? ", wording version " Tpl.version : ""))
    TrayTip "The team's templates were updated" (Tpl.version != "" ? " (wording version " Tpl.version ")" : "") ".", "Watchlog", "Iconi"
}

; How many template lines a file has (for checking a file before using it)
CountTemplates(text) {
    n := 0
    Loop Parse text, "`n", "`r" {
        line := Trim(A_LoopField)
        if line != "" && !InStr("#@+", SubStr(line, 1, 1)) && InStr(line, "=")
            n += 1
    }
    return n
}

; One line about where the templates came from, for the status window,
; the version box and the activity log
TemplateSummary() {
    switch Tpl.src {
        case "team": s := "team file " Tpl.file
        case "team-copy": s := "the saved copy of the team file (the shared one couldn't be read)"
        default: s := "templates.txt in " HomeDir
    }
    s .= " (" Tpl.count " templates" (Tpl.version != "" ? ", wording version " Tpl.version : "") (Tpl.code != "" ? ", check code " Tpl.code : "") ")"
    if Tpl.mine
        s .= " + " Tpl.mine " of your own in my-templates.txt"
    return s
}

; Shared lists, written once and used by many blanks:
;   @tables = UT201 | FB202 | UT203     then  {Table: @tables}
ReadLists(content, label, personal, &problems) {
    Loop Parse content, "`n", "`r" {
        line := Trim(A_LoopField)
        if SubStr(line, 1, 1) != "@"
            continue
        eq := InStr(line, "=")
        lname := Trim(SubStr(line, 2, eq ? eq - 2 : StrLen(line)))
        if !eq || !RegExMatch(lname, "^[\w-]+$") {
            problems .= label " line " A_Index ": a list needs a one-word name and an = sign, like  @tables = UT201 | FB202`n"
            continue
        }
        if personal && Lists.Has(lname) {
            problems .= label " line " A_Index ": the team file already has a list called @" lname ", so the team one is used. Give yours another name.`n"
            continue
        }
        items := []
        for it in StrSplit(SubStr(line, eq + 1), "|")
            if Trim(it) != ""
                items.Push(Trim(it))
        Lists[lname] := items
    }
}

; Full-entry daily logs (v3.20.0): lines starting with +
;   +Break = Location | Topic | Reference | Synopsis [| end]
; Ctrl+Alt+F lists them; Enter on one opens a new daily log in iTrak and fills
; Location, Topic, Reference and the Synopsis, with no questions. The word
; end on the end clicks End Time's Now button too (not taught yet: ignored).
ReadEntries(content, label, &problems, src := "main") {
    Loop Parse content, "`n", "`r" {
        line := Trim(A_LoopField)
        if SubStr(line, 1, 1) != "+"
            continue
        eq := InStr(line, "=")
        name := Trim(SubStr(line, 2, eq ? eq - 2 : StrLen(line)))
        parts := eq ? StrSplit(SubStr(line, eq + 1), "|") : []
        if !eq || name = "" || parts.Length < 4 {
            problems .= label " line " A_Index ": a full-entry log looks like  +Break = Location | Topic | Reference | Synopsis`n"
            continue
        }
        dupe := false
        for e in Entries
            if StrLower(e.name) = StrLower(name)
                dupe := true
        if dupe {
            problems .= label " line " A_Index ": there are two full-entry logs called " name ", so this one was skipped.`n"
            continue
        }
        Entries.Push({name: name, loc: Trim(parts[1]), topic: Trim(parts[2]), ref: Trim(parts[3]), syn: Trim(parts[4])
            , end: parts.Length >= 5 && StrLower(Trim(parts[5])) = "end", src: src})
    }
}

; Turns each template line into a trigger. Returns how many were added.
AddTemplates(content, src, label, trigs, &problems) {
    added := 0
    Loop Parse content, "`n", "`r" {
        line := Trim(A_LoopField)
        if line = "" || SubStr(line, 1, 1) = "#" || SubStr(line, 1, 1) = "@" || SubStr(line, 1, 1) = "+"
            continue
        eq := InStr(line, "=")
        if !eq {
            problems .= label " line " A_Index ": missing the = sign`n"
            continue
        }
        left := Trim(SubStr(line, 1, eq - 1))
        text := Trim(SubStr(line, eq + 1))
        name := ""
        trig := left
        if RegExMatch(left, "^(\S+)\s*\((.*)\)$", &m) {
            trig := m[1]
            name := Trim(m[2])
        }
        if trig = "" || InStr(trig, " ") {
            problems .= label " line " A_Index ": the trigger can't have spaces in it`n"
            continue
        }
        if RegExMatch(trig, "i)^(;t|;dd|;dt)") {
            problems .= label " line " A_Index ": " trig " starts like a time/date stamp, so it would never fire`n"
            continue
        }
        clash := ""
        for other in trigs {
            if InStr(other, trig) = 1 || InStr(trig, other) = 1
                clash := other
        }
        if clash == trig {
            if trigs[clash] = "login"
                problems .= label " line " A_Index ": " trig " is also a login shortcut, so this template was skipped. Give it a different trigger.`n"
            else if src = "mine" && trigs[clash] != "mine"
                problems .= label " line " A_Index ": " trig " is already a team template, so yours was skipped. Give yours a different trigger.`n"
            else
                problems .= label " line " A_Index ": " trig " is in the file twice, so this line was skipped. Remove or rename one of them.`n"
            continue
        }
        if clash != "" {
            problems .= label " line " A_Index ": " trig " and " clash " start the same way, so the shorter one would fire before you finish typing the longer one. Rename one of them.`n"
            continue
        }
        trigs[trig] := src
        lineNo := A_Index, pos := 1
        while p := RegExMatch(text, "[:|]\s*@([\w-]+)\s*(?=[|}])", &m, pos) {
            if !Lists.Has(m[1])
                problems .= label " line " lineNo ": " trig " uses @" m[1] ", but there's no line starting with @" m[1] " =`n"
            pos := p + m.Len
        }
        text := StrReplace(text, "\n", "`n")
        ; {repeat} anywhere in a form: an "Add another" button, so several
        ; (machines, say) go into one log, one per line
        repeat := RegExMatch(text, "i)\{repeat\}") > 0
        text := RegExReplace(text, "i)\s*\{repeat\}")
        ; "wording >> Location | Topic | Reference": the code word fills a whole
        ; iTrak daily log (v3.24.0). The wording becomes the Synopsis.
        fill := InStr(text, " >> ") > 0
        if fill {
            tail := SplitTop(SubStr(text, InStr(text, " >> ", , -1) + 4))
            if tail.Length < 3 {
                problems .= label " line " lineNo ": " trig " has >> but needs three parts after it:  >> Location | Topic | Reference`n"
                fill := false
                text := SubStr(text, 1, InStr(text, " >> ", , -1) - 1)
            }
        }
        isForm := RegExMatch(text, "\{[^{}]+\}") > 0
        HotIf NotInSettings
        Hotstring(":*C:" TrigKey(trig), MakeTemplateHandler(text, name != "" ? name : trig, repeat, trig, fill))
        HotIf
        TemplateList.Push({trig: trig, name: name, text: text, form: isForm, repeat: repeat, fill: fill, src: src})
        added += 1
    }
    return added
}

MakeTemplateHandler(text, title, repeat := false, trig := "", fill := false) {
    return (*) => RunTemplate(text, title, repeat, trig, fill)
}

; Splits on | outside {boxes}
SplitTop(s) {
    parts := [], cur := "", depth := 0
    for ch in StrSplit(s) {
        if ch = "{"
            depth++
        else if ch = "}" && depth
            depth--
        if ch = "|" && !depth {
            parts.Push(cur), cur := ""
        } else
            cur .= ch
    }
    parts.Push(cur)
    return parts
}

; A finished "wording >> Location | Topic | Reference [| end]" (v3.24.0):
; fills an iTrak daily log, opening one if none is open. Returns false (so the
; wording is pasted where you are instead) when Shift is held.
TemplateFill(out, title) {
    if GetKeyState("Shift", "P")
        return false
    i := InStr(out, " >> ", , -1)
    if !i
        return false
    parts := StrSplit(SubStr(out, i + 4), "|")
    if parts.Length < 3
        return false
    ; several lines (Add another): each ends with its own  >> ..., the last one is used
    syn := Trim(RegExReplace(out, " >> [^\r\n]*", ""))
    RunEntry({name: title, loc: FillDerive(Trim(parts[1]), syn), topic: FillDerive(Trim(parts[2]), syn)
        , ref: FillDerive(Trim(parts[3]), syn), syn: syn
        , end: parts.Length >= 4 && StrLower(Trim(parts[4])) = "end", src: "code"}, true)
    return true
}

; %pit% and %slots% in the Location, Topic or Reference of a code word (v3.26.2):
; %pit% = the pit of the first table in the log (UT201 -> 2), looked up in the
; list @pit = 2=Pit 2 | 3=Pit 3; %slots% = the slots area of the first machine
; (C2102 -> C), looked up in @slots = A=Alpha Slots | B=Bravo Slots ... Both lists
; live in templates.txt, so they can be changed or added to without the program.
FillDerive(s, syn) {
    if InStr(s, "%pit%") {
        v := ""
        if Lists.Has("tables") {
            for it in Lists["tables"] {
                if RegExMatch(syn, "i)(?<![A-Za-z0-9])" it "(?![A-Za-z0-9])") && RegExMatch(it, "\d", &d) {
                    v := ListMapGet("pit", d[0])
                    break
                }
            }
        }
        if v = ""
            Tip("Couldn't tell which pit: Location left empty.", 3000, true)
        s := StrReplace(s, "%pit%", v)
    }
    if InStr(s, "%slots%") {
        v := ""
        if RegExMatch(syn, "(?<![A-Za-z0-9])([A-Za-z])\d{3,5}(?!\d)", &m)
            v := ListMapGet("slots", m[1])
        if v = ""
            Tip("Couldn't tell which slots area: Location left empty.", 3000, true)
        s := StrReplace(s, "%slots%", v)
    }
    return s
}

; In a list like  @slots = A=Alpha Slots | B=Bravo Slots , the text after key=
ListMapGet(name, key) {
    if !Lists.Has(name)
        return ""
    for it in Lists[name] {
        p := InStr(it, "=")
        if p && StrUpper(Trim(SubStr(it, 1, p - 1))) = StrUpper(key)
            return Trim(SubStr(it, p + 1))
    }
    return ""
}

; Just the wording of a finished code word line (the part before >>), for pasting
FillWording(out) {
    ; Shift is still down: let go first, or the paste becomes Ctrl+Shift+V
    held := A_TickCount + 400
    while A_TickCount < held && GetKeyState("Shift", "P")
        Sleep 10
    return Trim(RegExReplace(out, " >> [^\r\n]*", ""))
}

; trig = the shortcut typed, for the time saved tracker
RunTemplate(text, title, repeat := false, trig := "", fill := false) {
    ; Swallow a Space or Enter typed out of habit right after the trigger
    global JustFired := A_TickCount
    ; A trigger typed into the template finder: close it and run the
    ; template in the window you were typing in
    if PickerActive()
        ClosePicker(true)
    fields := ParseFields(text)
    if fields.Length = 0 {
        out := FixArticles(text)
        if fill && TemplateFill(out, title)
            return
        if fill
            out := FillWording(out)
        Paste(out)
        saved := StrLen(out) - StrLen(trig)
        Journal(title, out, saved)
        CountSaved("log", saved, title)
        return
    }
    ; "saved" boxes with a value from this shift aren't asked (v3.20.2)
    fixed := Map(), shown := []
    for f in fields {
        if f.HasOwnProp("savedVal")
            fixed[f.key] := f.savedVal
        else
            shown.Push(f)
    }
    if !fixed.Count {
        FormPaste(title, fields, vals => FillTemplate(text, fields, vals), repeat, StrLen(trig), fill)
        return
    }
    merge(vals) {
        out := [], j := 0
        for f in fields
            out.Push(fixed.Has(f.key) ? fixed[f.key] : vals[++j])
        return out
    }
    if !shown.Length {
        out := FillTemplate(text, fields, merge([]))
        if fill && TemplateFill(out, title)
            return
        if fill
            out := FillWording(out)
        Paste(out)
        saved := StrLen(out) - StrLen(trig)
        Journal(title, out, saved)
        CountSaved("log", saved, title)
        return
    }
    FormPaste(title, shown, vals => FillTemplate(text, fields, merge(vals)), repeat, StrLen(trig), fill)
}

; ---- Facial rec copies (v3.6.0) ---------------------------------------
; The facial rec page won't copy the alert # and the match % together, so
; the last copy of each is kept in memory only (never written to disk,
; forgotten after 2 minutes or once used). Only an 8-digit number or a
; percentage is kept, and only when copied in Edge, so Citrix's clipboard
; is never touched.
NoteCopy(type) {
    global CopyMemory
    if type != 1 || !WinActive("ahk_exe msedge.exe")
        return
    text := ""
    try text := Trim(A_Clipboard)
    if RegExMatch(text, "^\d{8}$")
        CopyMemory["alert"] := {text: text, at: A_TickCount}
    else if RegExMatch(text, "^\d{1,3}(\.\d+)?\s*%$")
        CopyMemory["match"] := {text: RegExReplace(text, "\s*%$"), at: A_TickCount}
}

RecentCopy(kind) {
    if CopyMemory.Has(kind) && A_TickCount - CopyMemory[kind].at < 120000
        return CopyMemory[kind].text
    return ""
}

ForgetCopy(kind) {
    if CopyMemory.Has(kind)
        CopyMemory.Delete(kind)
}

; A plain number (4 to 8 digits) from a copy. A longer copy, like a whole
; iTrak line, works if it has exactly one such number in it.
NumberFromCopy(text) {
    text := Trim(text)
    if RegExMatch(text, "^\d{4,8}$")
        return text
    if StrLen(text) > 500
        return ""
    pos := 1, found := ""
    while p := RegExMatch(text, "(?<!\d)\d{4,8}(?!\d)", &m, pos) {
        if found != ""
            return ""
        found := m[0], pos := p + m.Len
    }
    return found
}

; Which list item (a job title) appears in the copied text; the longest
; match wins ("Security Supervisor" over "Supervisor"). 0 = none.
TitleFromCopy(items, text) {
    if StrLen(text) > 2000
        return 0
    best := 0, bestLen := 0
    for i, it in items {
        if StrLen(it) > bestLen && RegExMatch(text, "i)(?<![\w])" RegExReplace(it, "[\\.*?+\[\](){}|^$]", "\$0") "(?![\w])") {
            best := i, bestLen := StrLen(it)
        }
    }
    return best
}

; Finds every {blank} in the text and turns it into a form box (once per name)
ParseFields(text) {
    fields := [], seen := Map()
    ; Last-used values for "last" and "next" boxes, read once for the whole
    ; form. They're kept on this PC (not in settings.ini, which OneDrive
    ; syncs); before v3.3 they were in settings.ini, so that's the fallback.
    last := Map()
    last.CaseSense := false
    if InStr(text, "last") || InStr(text, "next") || InStr(text, "alertcopy") || InStr(text, "saved") {
        section := ""
        try section := IniRead(LastUsedFile, "LastUsed")
        if section = ""
            try section := IniRead(SettingsFile, "LastUsed")
        for line in StrSplit(section, "`n", "`r") {
            if eq := InStr(line, "=")
                last[SubStr(line, 1, eq - 1)] := SubStr(line, eq + 1)
        }
    }
    pos := 1
    while p := RegExMatch(text, "\{([^{}]+)\}", &m, pos) {
        f := ParseField(m[1], last)
        if !seen.Has(f.key) {
            seen[f.key] := true
            fields.Push(f)
        }
        pos := p + m.Len
    }
    return fields
}

IsTimeStamp(v) => RegExMatch(v, "^\d{14}$")

ParseField(spec, last := Map()) {
    c := InStr(spec, ":")
    key := Trim(c ? SubStr(spec, 1, c - 1) : spec)
    f := {key: key, label: key, ph: "XX"}
    if !c
        return f
    items := [], pick := false, hint := ""
    for opt in StrSplit(SubStr(spec, c + 1), "|") {
        opt := Trim(opt)
        low := StrLower(opt)
        if opt = "" {
            continue
        } else if low = "now" {
            f.kind := "time", f.def := FormatTime(, "HH:mm"), f.ph := "XX:XX"
        } else if RegExMatch(low, "^now\s*\+\s*(\d+)$", &n) {
            f.kind := "time", f.def := FormatTime(DateAdd(A_Now, Integer(n[1]), "Minutes"), "HH:mm"), f.ph := "XX:XX"
        } else if low = "time" {
            f.kind := "time", f.ph := "XX:XX", hint := "  (e.g. 2130)"
        } else if low = "thousands" {
            ; with money: 3.3 means 3,300 (a decimal point = thousands)
            f.thousands := true, hint := "  (e.g. 3.3 = 3,300)"
        } else if low = "money" {
            f.kind := "money", f.ph := "XX,XXX", hint := "  (e.g. 10000)"
        } else if low = "percent" {
            f.kind := "percent", f.ph := "XX%", hint := "  (e.g. 67)"
        } else if low = "clip" {
            f.def := NumberFromCopy(CopiedText())
            hint := "  (copy it first to auto-fill)"
        } else if low = "alertcopy" {
            ; facial rec alert #: the 8-digit number copied in the last two
            ; minutes, and the last one logged on this PC (alerts count up)
            f.remember := true, f.alertCopy := true
            lastA := last.Has(key) ? last[key] : ""
            copied := RecentCopy("alert")
            if copied != "" {
                f.def := copied
                if lastA != "" && copied = lastA
                    hint := "  (SAME as the last one logged: " lastA ")"
                else if lastA != "" && copied < lastA
                    hint := "  (LOWER than the last one logged: " lastA ")"
                else
                    hint := "  (copied)"
            } else {
                hint := lastA != "" ? "  (last logged: " lastA "; copy the new one first)" : "  (copy it first to auto-fill)"
            }
        } else if low = "matchcopy" {
            ; facial rec match %: the percentage copied in the last two minutes
            f.kind := "percent", f.ph := "XX%", f.matchCopy := true
            copied := RecentCopy("match")
            f.def := copied
            hint := copied != "" ? "  (copied)" : "  (copy it first to auto-fill, e.g. 65)"
        } else if low = "fromcopy" {
            f.fromCopy := true

        } else if low = "last" {
            f.remember := true
            f.def := last.Has(key) ? last[key] : ""
        } else if low = "saved" {
            ; like last, but when a value was entered in the last 14 hours
            ; (the bay at the start of shift) it is used without asking (v3.20.2)
            f.remember := true
            f.def := last.Has(key) ? last[key] : ""
            if f.def != "" && last.Has(key ".at") && IsTimeStamp(last[key ".at"]) && DateDiff(A_Now, last[key ".at"], "Hours") < 14
                f.savedVal := f.def
        } else if low = "next" {
            f.remember := true, f.nextStep := true
        } else if low = "pick" {
            pick := true
        } else if low = "several" {
            f.several := true           ; Add another adds to this box, on the same line (v3.19.3)
        } else if low = "caps" {
            f.caps := true
        } else if low = "tidy" {
            f.tidy := true              ; bvs -> BVs, bvs divert -> BVs/Divert
        } else if low = "upper" {
            f.upper := true             ; all capitals: rn -> RN
        } else if SubStr(opt, 1, 1) = "@" && Lists.Has(SubStr(opt, 2)) {
            for it in Lists[SubStr(opt, 2)]
                items.Push(it)
        } else if RegExMatch(opt, "i)^if\s+(.+?)\s*=\s*(.*)$", &cm) {
            ; "if ATM=100000": fill this box with 100000 while another
            ; box in the form starts with ATM
            if !f.HasOwnProp("conds")
                f.conds := []
            f.conds.Push({when: cm[1], val: cm[2]})
        } else if SubStr(low, 1, 6) = "blank=" {
            f.ph := SubStr(opt, 7)
        } else if SubStr(low, 1, 7) = "prefix=" {
            f.prefix := SubStr(opt, 8)
        } else if SubStr(low, 1, 7) = "suffix=" {
            f.suffix := SubStr(opt, 8)       ; added after what you type, only if you type something
        } else if SubStr(low, 1, 13) = "numberprefix=" {
            ; added only in front of a number: 12345 -> #12345, RN stays RN
            f.numPrefix := SubStr(opt, 14)
        } else {
            items.Push(opt)
        }
    }
    if items.Length {
        f.items := items
        if pick
            f.kind := "list"
        else
            hint := "  (pick or type)"
        ; "fromcopy": open the list on the job title found in what was copied
        if f.HasOwnProp("fromCopy") {
            at := TitleFromCopy(items, CopiedText())
            if at {
                f.choose := at
                hint := "  (from the copied text)"
            }
        }
        ; "next" opens the list on the item after the one used last time
        if f.HasOwnProp("nextStep") {
            lastVal := last.Has(key) ? last[key] : ""
            f.choose := 1
            for i, it in items {
                if it = lastVal
                    f.choose := Mod(i, items.Length) + 1
            }
        }
    }
    f.label := key hint
    return f
}

FillTemplate(text, fields, vals) {
    byKey := Map()
    for i, f in fields
        byKey[f.key] := vals[i]
    out := "", pos := 1
    while p := RegExMatch(text, "\{([^{}]+)\}", &m, pos) {
        c := InStr(m[1], ":")
        key := Trim(c ? SubStr(m[1], 1, c - 1) : m[1])
        out .= SubStr(text, pos, p - pos)
        if byKey[key] = "" && SubStr(out, -1) = " "      ; empty box: don't leave a double space
            out := SubStr(out, 1, -1)
        out .= byKey[key]
        pos := p + m.Len
    }
    out .= SubStr(text, pos)
    return FixArticles(out)
}

; ["BJ205", "BJ206", "RO204"] -> "BJ205, BJ206 and RO204"
JoinList(items) {
    out := ""
    for i, it in items
        out .= (i = 1 ? "" : i = items.Length ? " and " : ", ") it
    return out
}

; Empties a form box (a pick-only list ends with nothing picked)
ClearBox(c) {
    if c.Type = "DDL"
        c.Choose(0)
    else
        c.Text := ""
}

; "a/an employee" -> "an employee", "a/an guest" -> "a guest"
FixArticles(s) {
    pos := 1
    while p := RegExMatch(s, "a/an (\S)", &m, pos) {
        art := InStr("aeiouAEIOU", m[1]) ? "an" : "a"
        s := SubStr(s, 1, p - 1) . art . SubStr(s, p + 4)
        pos := p + StrLen(art)
    }
    return s
}


; =====================================================================
;  HELPERS
; =====================================================================

; A short note by the mouse (or mid-screen) that clears itself after ms.
; ms = 0 leaves it up until Tip("") clears it. A new note restarts the
; clock, so a quick second note isn't wiped early by the first one's timer.
Tip(msg, ms := 2000, center := false) {
    if msg = "" {
        ToolTip()
        return
    }
    if center {
        CoordMode "ToolTip", "Screen"
        ToolTip msg, A_ScreenWidth // 2 - StrLen(msg) * 3, A_ScreenHeight // 2
    } else {
        ToolTip msg
    }
    SetTimer ClearTip, ms ? -ms : 0
}
ClearTip() => ToolTip()

; Puts the keyboard back in the window you were typing in, with a short
; pause so a paste lands there (Citrix needs a moment longer)
ReturnTo(hwnd) {
    try WinActivate "ahk_id " hwnd
    ok := WinWaitActive("ahk_id " hwnd, , 2)
    Sleep WinActive("ahk_exe wfica32.exe") ? 400 : 50
    return ok != 0
}

; The log couldn't be pasted (the window it was started in isn't in front):
; it stays on the clipboard instead of going into whatever has the keyboard
KeepOnClip(text) {
    global LeftOnClip
    A_Clipboard := StrReplace(StrReplace(text, "`r`n", "`n"), "`n", "`r`n")
    LeftOnClip := text
    SoundBeep 750, 120
    Tip("The window you were in isn't in front, so nothing was pasted.`nThe log is on the clipboard: click where it goes and press Ctrl+V.", 7000, true)
    Activity("Form log not pasted: the window it was started in wasn't in front (the log is on the clipboard)")
}

; What you copied, for the clip and fromcopy boxes. A log Watchlog itself
; left on the clipboard doesn't count: the next form would otherwise pick a
; number or a job title out of the last log (v3.14.2).
CopiedText() {
    text := ""
    try text := A_Clipboard
    if LeftOnClip != "" && Trim(StrReplace(text, "`r`n", "`n")) == Trim(StrReplace(LeftOnClip, "`r`n", "`n"))
        return ""
    return text
}

; Fast paste: backs up your clipboard, pastes the text, then restores it
; keep = true leaves the text on the clipboard afterwards (used by forms, so
; if the paste doesn't land you can still press Ctrl+V yourself).
Paste(text, keep := false) {
    global LeftOnClip
    ; Windows apps want a CR+LF pair for a new line - a bare LF gets ignored
    text := StrReplace(StrReplace(text, "`r`n", "`n"), "`n", "`r`n")
    ; Pasting into Citrix (iTrak): the log stays on the clipboard and the old
    ; clipboard isn't saved or put back. Reading a clipboard that came from
    ; iTrak (like a copied employee number) makes Citrix fetch it back from
    ; the session, and swapping it again right after a paste can leave
    ; Citrix's clipboard stuck, so nothing pastes into iTrak at all.
    citrix := WinActive("ahk_exe wfica32.exe")
    if citrix
        keep := true
    saved := keep ? "" : ClipboardAll()
    ; Set it in one go (no emptying first), so Citrix sees a single change
    A_Clipboard := text
    if keep
        LeftOnClip := text
    ; Citrix copies the clipboard across to the session on its own
    ; schedule: give it a moment before pasting
    if citrix
        Sleep 300
    SendInput "^v"
    if keep
        return
    Sleep 150
    A_Clipboard := saved
}

; Fill-in form: shows boxes, then pastes the finished log where you were typing.
; Tab / Shift+Tab between boxes, Enter to insert, Esc to cancel.
; Any box left blank keeps its placeholder so you can fill it in later.
SetForm(v) {
    global CurForm := v
}

FormPaste(title, fields, build, repeat := false, trigLen := 0, fill := false) {
    global Cancelled
    target := WinExist("A")
    g := WGui("+AlwaysOnTop +ToolWindow", title)
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 14, g.MarginY := 12
    ctrls := [], starts := [], labs := []
    for f in fields {
        labs.Push(g.AddText(A_Index > 1 ? "y+10" : "", f.label))
        kind := f.HasOwnProp("kind") ? f.kind : ""
        n := f.HasOwnProp("choose") ? f.choose : 1
        ; Lists open showing up to 12 choices at once
        rows := f.HasOwnProp("items") ? " r" Min(f.items.Length, 12) : ""
        if kind = "list"
            c := g.AddDropDownList("w420 Choose" n rows, f.items)
        else if f.HasOwnProp("items")
            c := g.AddComboBox("w420 Choose" n rows, f.items)
        else
            c := g.AddEdit("w420", f.HasOwnProp("def") ? f.def : "")
        ctrls.Push(c)
        starts.Push({text: c.Text, choose: n})
    }
    ; "several" boxes (v3.19.3): Add another adds to this box's list on the
    ; same line ("BJ205, BJ206 and RO204 Opened.") instead of a new line.
    ; They start empty, so a box left empty at the end is skipped.
    multi := Map()
    for i, f in fields {
        if !f.HasOwnProp("several")
            continue
        multi[i] := []
        ClearBox(ctrls[i])
        starts[i].text := "", starts[i].choose := 0
    }
    if multi.Count
        repeat := true
    ; Boxes the call pad can fill (machine, table, amount, alert #)
    hints := PadHints()
    padUsed := 0, padRows := [], padMarks := Map()
    if hints.Count {
        res := PadFill(fields, ctrls, labs, hints, padMarks)
        padUsed := res.n, padRows := res.rows
    }
    ; the same form closed with Esc in the last 10 minutes: what was typed comes back (v3.27.0)
    restored := ""
    if !padUsed && IsObject(Cancelled) && Cancelled.title = title && A_TickCount - Cancelled.at < 600000 && Cancelled.vals.Length = ctrls.Length {
        restored := ""
        for i, c in ctrls {
            t := Cancelled.vals[i]
            if fields[i].HasOwnProp("items") && fields[i].HasOwnProp("kind") && fields[i].kind = "list" {
                for j, it in fields[i].items
                    if it = t
                        c.Choose(j)
            } else
                c.Text := t
            restored .= t Chr(1)
        }
        Cancelled := ""
        g.Title := title "  (what you typed before is back)"
    }
    LoadAutocorrect()
    for c in ctrls
        if c.Type = "Edit" || c.Type = "ComboBox"
            c.OnEvent("Change", AutoFixEdit)
    done := []          ; finished entries so far, when "Add another" is used
    typed := 0          ; keystrokes typed into the form, for the time saved tracker
    autoVals := Map()   ; boxes filled in by an "if" option, and with what
    ; How the log will come out, updated as you type
    g.SetFont("s9")
    g.AddText("y+14 c707070", "How it will look:")
    preview := g.AddEdit("w420 r5 ReadOnly -TabStop VScroll BackgroundF1F5F5")
    lastPreview := ""
    g.SetFont("s10")
    prevLen := Map()
    for i, c in ctrls {
        if fields[i].HasOwnProp("items") && !(fields[i].HasOwnProp("kind") && fields[i].kind = "list")
            c.OnEvent("Change", Complete.Bind(i))
        c.OnEvent("Change", Changed)
    }
    Changed()
    if fill
        g.AddText("xm y+8 w420 c666666", "Enter fills the iTrak daily log. Shift+Enter pastes just the wording here.")
    ; Buttons along the bottom-right; Insert is the one Enter presses
    if repeat
        g.AddButton("xm+132 y+12 w180", "Add another (Ctrl+Enter)").OnEvent("Click", AddAnother)
    else
        g.AddButton("xm+212 y+12 w100", "Cancel").OnEvent("Click", Cancel)
    g.AddButton("x+8 yp w100 Default", "Insert").OnEvent("Click", Submit)
    g.OnEvent("Escape", Cancel)
    g.OnEvent("Close", Cancel)
    SetForm({hwnd: g.Hwnd, ctrls: ctrls, submit: Submit, more: repeat ? AddAnother : ""})
    g.Show()
    WinActivate "ahk_id " g.Hwnd
    WinWaitActive "ahk_id " g.Hwnd, , 1
    ; Start on the first box you'd actually fill in: an empty one or a list
    ; to pick from (skips boxes already filled with a time or copied number)
    first := ctrls[1]
    for i, c in ctrls {
        if c.Text = "" || fields[i].HasOwnProp("items") {
            first := c
            break
        }
    }
    first.Focus()
    ; Several machine fills jotted on the pad: one set of boxes for each
    if padRows.Length {
        for i, row in padRows {
            PadSetRow(fields, ctrls, labs, row, padMarks)
            if i < padRows.Length
                AddAnother()
        }
        padUsed := padRows.Length
        Changed()
    }
    ; a shorthand line that had everything: make the log without waiting for Enter (v3.26.0)
    if padUsed && hints.Has("go") && hints["go"] && (!hints.Has("expect") || padUsed >= hints["expect"])
        Submit()

    Cancel(*) {
        global Cancelled
        ; kept for 10 minutes so reopening the same log puts it back; not when it
        ; is only what was put back last time (a second Esc clears it)
        if !Untouched() {
            vals := [], snapTxt := ""
            for c in ctrls {
                vals.Push(c.Text)
                snapTxt .= c.Text Chr(1)
            }
            if snapTxt != restored
                Cancelled := {title: title, vals: vals, at: A_TickCount}
        }
        SetForm("")
        g.Destroy()
    }

    Changed(*) {
        AutoFill()
        ShowPreview()
    }

    ; "if" options: fill a box when another box starts with the given text,
    ; unless you've typed something of your own in it
    AutoFill() {
        for i, f in fields {
            if !f.HasOwnProp("conds")
                continue
            want := ""
            for cond in f.conds {
                for j, c2 in ctrls {
                    if j != i && InStr(Trim(c2.Text), cond.when) = 1 {
                        want := cond.val
                        break
                    }
                }
                if want != ""
                    break
            }
            c := ctrls[i]
            had := autoVals.Has(i) ? autoVals[i] : ""
            if c.Text = "" || c.Text = had {
                if c.Text != want
                    c.Value := want
                autoVals[i] := want
            }
        }
    }

    ; Pick-or-type lists: typing the start of an item fills in the rest
    ; (selected, so the next key replaces it and Backspace removes it).
    ; Only when text was added, so deleting never fights you.
    Complete(i, *) {
        c := ctrls[i]
        txt := c.Text
        was := prevLen.Has(i) ? prevLen[i] : 0
        prevLen[i] := StrLen(txt)
        if StrLen(txt) <= was || txt = ""
            return
        for it in fields[i].items {
            if StrLen(it) > StrLen(txt) && SubStr(it, 1, StrLen(txt)) = txt {
                prevLen[i] := StrLen(it)
                c.Text := it
                ; CB_SETEDITSEL: select the part that was filled in
                SendMessage(0x142, 0, StrLen(txt) | (StrLen(it) << 16), c.Hwnd)
                return
            }
        }
    }

    ShowPreview() {
        out := ""
        if multi.Count {
            out := build(Joined(Collect(false)))
        } else {
            for entry in done
                out .= entry "`r`n"
            out .= build(Collect(false))
        }
        out := StrReplace(StrReplace(out, "`r`n", "`n"), "`n", "`r`n")
        ; Only redraw when it changed (saves flicker while typing)
        if out != lastPreview
            preview.Value := lastPreview := out
    }

    ; The boxes as they'll go into the log (placeholders, time/money fixes, caps)
    ; save = false for the preview: nothing is remembered for next time
    Collect(save := true) {
        vals := []
        for i, c in ctrls {
            f := fields[i]
            kind := f.HasOwnProp("kind") ? f.kind : ""
            v := Trim(c.Text)
            ; Just a number typed in a list box: the list item ending in it
            ; (202 -> FB202 when FB202 is in the list)
            if RegExMatch(v, "^\d+$") && f.HasOwnProp("items") {
                hits := []
                for it in f.items
                    if RegExMatch(it, "^\D*" v "$")
                        hits.Push(it)
                if hits.Length = 1
                    v := hits[1]
            }
            if v = "" {
                v := f.ph
            } else {
                if kind = "time"
                    v := FixTime(v)
                else if kind = "money" {
                    if f.HasOwnProp("thousands") && RegExMatch(StrReplace(v, "$"), "^\d*\.\d+$")
                        v := Format("{:d}", Round(StrReplace(v, "$") * 1000))
                    v := FixMoney(v)
                }
                else if kind = "percent"
                    v := RTrim(v, "%") "%"
                ; caps: capitals in machine numbers (b1410 -> B1410). Only words
                ; with a digit in them change, so "nrt2 and nrt4" -> "NRT2 and NRT4"
                if f.HasOwnProp("caps") {
                    ; in a machine or NRT box, a lone n or a before a single
                    ; digit: n3 -> NRT3, a1 -> ATM1 (not in Location boxes)
                    if RegExMatch(f.key, "i)machine|nrt|atm") {
                        v := RegExReplace(v, "i)(?<![A-Za-z0-9])n(?=\d(?!\d))", "NRT")
                        v := RegExReplace(v, "i)(?<![A-Za-z0-9])a(?=\d(?!\d))", "ATM")
                    }
                    v := RegExReplace(v, "(\w*\d\w*)", "$U1")
                }
                if f.HasOwnProp("tidy")
                    v := PadNote(v)
                if f.HasOwnProp("prefix")
                    v := f.prefix v
                if f.HasOwnProp("suffix")
                    v := v f.suffix
                if f.HasOwnProp("upper")
                    v := StrUpper(v)
                if f.HasOwnProp("numPrefix") && RegExMatch(v, "^\d")
                    v := f.numPrefix v
            }
            if save && f.HasOwnProp("remember") && v != f.ph {
                try {
                    if !DirExist(DataDir)
                        DirCreate DataDir
                    IniWrite v, LastUsedFile, "LastUsed", f.key
                    IniWrite A_Now, LastUsedFile, "LastUsed", f.key ".at"
                }
            }
            if save && f.HasOwnProp("alertCopy")
                ForgetCopy("alert")
            if save && f.HasOwnProp("matchCopy")
                ForgetCopy("match")
            vals.Push(v)
        }
        return vals
    }

    ; True when nothing was typed: every plain box is empty or as it started
    ; (lists don't count, since they always have something picked)
    Untouched() {
        for i, c in ctrls {
            if fields[i].HasOwnProp("items")
                continue
            if Trim(c.Text) != "" && c.Text != starts[i].text
                return false
        }
        return true
    }

    ; Roughly what was typed for this set of boxes: what's in each box you
    ; changed (a pick from a list counts as 1), plus a Tab or Enter per box
    TypedNow() {
        n := 0
        for i, c in ctrls {
            ; a box the call pad filled costs nothing here: its keys are counted from the pad
            if padMarks.Has(i)
                continue
            v := Trim(c.Text)
            n += 1
            ; a box left blank keeps its placeholder (XXXXX), which saves nothing
            if v = "" {
                n += StrLen(fields[i].ph)
                continue
            }
            if v = starts[i].text || (autoVals.Has(i) && v = autoVals[i])
                continue
            n += fields[i].HasOwnProp("items") && HasVal(fields[i].items, v) ? 1 : StrLen(v)
        }
        return n
    }

    ; The "several" boxes as one list each: what was added so far plus
    ; what's in the box now ("BJ205, BJ206 and RO204")
    Joined(vals) {
        for i, list in multi {
            all := list.Clone()
            if Trim(ctrls[i].Text) != "" && !HasVal(all, vals[i])
                all.Push(vals[i])
            vals[i] := all.Length ? JoinList(all) : fields[i].ph
        }
        return vals
    }

    AddAnother(*) {
        if multi.Count {
            vals := Collect(false)
            most := 0, box := ""
            for i, list in multi {
                if box = ""
                    box := ctrls[i]
                v := Trim(ctrls[i].Text)
                if v != "" {
                    typed += StrLen(v) + 1
                    if !HasVal(list, vals[i])
                        list.Push(vals[i])
                    ClearBox(ctrls[i])
                }
                most := Max(most, list.Length)
            }
            Changed()
            if most
                g.Title := title "  (" most " added)"
            box.Focus()
            return
        }
        if Untouched() {
            first.Focus()
            return
        }
        typed += TypedNow()
        done.Push(build(Collect()))
        ; Clear the boxes for the next one
        for i, c in ctrls {
            if fields[i].HasOwnProp("items")
                c.Choose(starts[i].choose)
            else
                c.Value := starts[i].text
        }
        autoVals.Clear()
        Changed()
        g.Title := title "  (" done.Length " added)"
        first.Focus()
    }

    Submit(*) {
        out := ""
        if multi.Count {
            ; "several" boxes: one log, the list on one line
            typed += TypedNow()
            out := build(Joined(Collect()))
        } else {
            ; With "Add another", a last set of boxes left empty is skipped
            if !(done.Length && Untouched()) {
                typed += TypedNow()
                done.Push(build(Collect()))
            }
            for entry in done
                out .= (A_Index > 1 ? "`n" : "") entry
        }
        SetForm("")
        g.Destroy()
        if fill {
            if TemplateFill(out, title)
                return
            out := FillWording(out)
        }
        ; what was typed on the call pad for this call, plus the + key and Ctrl+Enter
        if padUsed
            typed += PadKeys + 2
        saved := StrLen(out) - trigLen - typed
        CountSaved("log", saved, title)
        ; Give the window you were typing in a moment to take the keyboard
        ; back (Citrix needs longer) - otherwise the paste can get lost
        back := ReturnTo(target)
        if target && !back {
            KeepOnClip(out)
        } else
            Paste(out, true)
        Journal(title, out, saved)
        if padUsed
            CallPadUsed()
    }
}

; Moves to the next (dir = 1) or previous (dir = -1) box in the open form
FormMove(dir) {
    ctrls := CurForm.ctrls
    focused := ControlGetFocus("ahk_id " CurForm.hwnd)
    idx := 0
    for i, c in ctrls {
        if c.Hwnd = focused || DllCall("IsChild", "Ptr", c.Hwnd, "Ptr", focused)
            idx := i
    }
    idx += dir
    if idx < 1
        idx := ctrls.Length
    else if idx > ctrls.Length
        idx := 1
    ctrls[idx].Focus()
}

; Templates fire as soon as the trigger is typed. A Space or Enter pressed
; out of habit in the next half second is ignored, so it can't add a stray
; space or submit a form before you've filled it in.
#HotIf A_TickCount - JustFired < 500
Space:: return
Enter:: return
NumpadEnter:: return
#HotIf

; Esc closes the login reminder from any window while it's showing
#HotIf IsObject(ReminderGui)
Esc:: CloseReminder()
#HotIf

; Tab / Shift+Tab / Enter only do this while a form is the active window
#HotIf IsObject(CurForm) && WinActive("ahk_id " CurForm.hwnd)
Tab:: FormMove(1)
+Tab:: FormMove(-1)
Enter:: CurForm.submit()
NumpadEnter:: CurForm.submit()
+Enter:: CurForm.submit()
+NumpadEnter:: CurForm.submit()
^Enter:: FormMore()
^NumpadEnter:: FormMore()
#HotIf

; Ctrl+Enter in a form that has "Add another"
FormMore() {
    if IsObject(CurForm.more)
        CurForm.more()
}

; 2130 -> 21:30, 930 -> 09:30, 21:30 stays 21:30
FixTime(s) {
    s := Trim(s)
    if RegExMatch(s, "^\d{3,4}$") {
        if StrLen(s) = 3
            s := "0" s
        s := SubStr(s, 1, 2) ":" SubStr(s, 3)
    }
    return s
}

; 10000 -> 10,000
FixMoney(s) {
    s := StrReplace(StrReplace(Trim(s), "$"), ",")
    if RegExMatch(s, "^\d+(\.\d+)?$") {
        parts := StrSplit(s, ".")
        s := RegExReplace(parts[1], "\G\d+?(?=(\d{3})+$)", "$0,")
            . (parts.Length > 1 ? "." parts[2] : "")
    }
    return s
}


; =====================================================================
;  AUTO-RELOAD  -  checks every 2 seconds whether templates.txt,
;  my-templates.txt, settings.ini or the team's shared file was saved,
;  and reloads if so (so a supervisor's change to the team file reaches
;  every PC as soon as OneDrive syncs it). Waits while a form or window
;  is open, and while settings.ini is missing (OneDrive can briefly
;  remove a file while it syncs - reloading then would start with no
;  settings). Any other file that goes missing is skipped until it's back.
; =====================================================================
StartWatching() {
    files := [TemplatesFile, MyTemplatesFile, SettingsFile]
    if Cfg["SharedTemplates"] != ""
        files.Push(Cfg["SharedTemplates"])
    if TeamProgramFile() != ""
        files.Push(TeamProgramFile())
    for f in files
        WatchTimes[f] := FileTimeOf(f)
    SetTimer CheckForEdits, 2000
}

FileTimeOf(f) {
    try return FileGetTime(f, "M")
    return ""
}

; The script writes to settings.ini itself (e.g. the last bay used), so it
; updates its note of the time instead of reloading over its own change.
NoteOwnWrite() {
    WatchTimes[SettingsFile] := FileTimeOf(SettingsFile)
}

; Same, for every watched file: a Customize screen already applied what it
; saved, so Watchlog doesn't need to reload over it (v3.21.0)
NoteOwnWrites() {
    for f in WatchTimes
        WatchTimes[f] := FileTimeOf(f)
}

CheckForEdits() {
    if IsObject(CurForm) || IsObject(SettingsWin) || IsObject(Picker) || IsObject(EditorWin)
        return
    ; settings.ini missing for a moment: wait for it to come back, since
    ; reloading without it would start over with no settings
    if !FileExist(SettingsFile)
        return
    for f, before in WatchTimes {
        now := FileTimeOf(f)
        ; Another file gone missing is probably mid-sync, so it's ignored -
        ; except my-templates.txt, which was deleted on purpose
        if now = "" && f != MyTemplatesFile
            continue
        if now != before {
            ReloadOnce()
            return
        }
    }
}

; Reloads once. If the new copy is slow to start, the 2-second check could
; ask again before it has closed this one, and two new copies then fight
; over it ("Could not close the previous instance").
ReloadOnce() {
    global ReloadAt
    if ReloadAt && A_TickCount - ReloadAt < 20000
        return
    ReloadAt := A_TickCount
    Reload
}


; =====================================================================
;  QUICK NOTES
;  Ctrl+Alt+Q = add a note
;  Ctrl+Alt+O = open all notes
; =====================================================================
; (set up by RegisterHotkeys, see HotkeyDefs)

QuickNote() {
    ib := InputBox("Type your note. Start with a tag like #todo, #incident or #idea:", "Quick Note", "w450 h120")
    if ib.Result != "OK" || Trim(ib.Value) = ""
        return
    note := Trim(ib.Value)
    if SaveNote(NotesFile, note) {
        Tip("Note saved", 1000)
        RefreshNotes()
        SetTitleMatchMode 2
        if WinExist("Quick Notes ahk_exe Notepad.exe")
            MsgBox "Quick Notes.md is open in Notepad. Your note IS saved, but that Notepad window still shows the old text.`n`nClose it and choose Don't save (saving it would write over your new note). Ctrl+Alt+O shows your notes without this problem.", "Quick Note", "Icon! 4096"
        return
    }
    ; Quick Notes.md is in OneDrive. If OneDrive isn't running, Windows can't
    ; open it, so the note goes in a file on this PC instead.
    backup := DataDir "\Quick Notes (this PC).md"
    if SaveNote(backup, note) {
        MsgBox "OneDrive isn't running, so Quick Notes.md couldn't be opened.`n`nYour note was saved on this PC instead:`n" backup, "Quick Note", "Icon!"
    } else {
        A_Clipboard := note
        MsgBox "Couldn't save the note anywhere, so it's on the clipboard. Paste it somewhere safe.", "Quick Note", "Icon!"
    }
}

; Adds a note under today's date. Returns false if the file can't be used.
SaveNote(file, note) {
    try {
        SplitPath file, , &dir
        if !DirExist(dir)
            DirCreate dir
        header := "## " FormatTime(, "yyyy-MM-dd (ddd)")
        existing := FileExist(file) ? FileRead(file) : ""
        entry := ""
        if !InStr(existing, header)
            entry .= (existing = "" ? "" : "`n") header "`n"
        entry .= "- " FormatTime(, "HH:mm") "  " note "`n"
        FileAppend entry, file, "UTF-8"
        return true
    }
    return false
}

; (set up by RegisterHotkeys, see HotkeyDefs)

; Ctrl+Alt+O: a window that reads the notes file fresh every time, so it
; can't show an old copy the way a Notepad tab left open does. Notes saved
; on this PC while OneDrive was off are moved into Quick Notes.md first.
ShowNotes() {
    global NotesWin
    MergeNotesBackup()
    if IsObject(NotesWin) {
        RefreshNotes()
        NotesWin.Show()
        return
    }
    g := WGui("+Resize", "Quick notes  -  v" VERSION)
    g.SetFont("s10", "Consolas")
    g.AddEdit("vText w560 r20 ReadOnly -WantReturn")
    g.SetFont("s10", "Segoe UI")
    g.AddButton("vNp w140 Default", "Open in Notepad").OnEvent("Click", OpenNp)
    g.AddButton("vCl x+4 w112", "Close").OnEvent("Click", CloseIt)
    g.OnEvent("Escape", CloseIt)
    g.OnEvent("Close", CloseIt)
    g.OnEvent("Size", (gui, mm, w, h) => mm = -1 ? 0 : (gui["Text"].Move(, , w - 20, h - 62), gui["Np"].Move(, h - 40), gui["Cl"].Move(, h - 40)))
    NotesWin := g
    RefreshNotes()
    g.Show()

    OpenNp(*) {
        CloseIt()
        Run 'notepad.exe "' NotesFile '"'
    }
    CloseIt(*) {
        global NotesWin
        NotesWin := ""
        g.Destroy()
    }
}

; Reloads the text in the notes window (if it's open) and shows the end
RefreshNotes() {
    if !IsObject(NotesWin)
        return
    text := ""
    try text := FileRead(NotesFile, "UTF-8")
    catch
        text := "(No notes yet. Ctrl+Alt+Q adds one.)"
    NotesWin["Text"].Value := StrReplace(StrReplace(text, "`r`n", "`n"), "`n", "`r`n")
    SendMessage 0x115, 7, 0, NotesWin["Text"].Hwnd   ; WM_VSCROLL, SB_BOTTOM
}

; Moves notes saved to the this-PC backup file into Quick Notes.md
MergeNotesBackup() {
    backup := DataDir "\Quick Notes (this PC).md"
    if !FileExist(backup)
        return
    try {
        text := FileRead(backup, "UTF-8")
        if Trim(text, " `r`n") != ""
            FileAppend "`n" Trim(text, "`r`n") "`n", NotesFile, "UTF-8"
        FileDelete backup
        Activity("Quick notes: moved the notes saved on this PC into Quick Notes.md")
    }
}


; =====================================================================
;  CALL PAD  (v3.12.0)
;  Numpad +  (or Ctrl+Alt+N) = a small pad to jot a phone call into, with
;  one hand. It opens with the cursor in the box and stamps the time of
;  your first key. Esc hides it (the text stays), Ctrl+Enter makes a log
;  from it: the log forms then open with the machine, table, amount and
;  alert # already filled in from what you jotted ("from your call pad").
;  Nothing is guessed: if you jotted two different machines, the box stays
;  empty. The text is kept on this PC only (never in settings.ini or the
;  shared folder) and is wiped by New call and at end of shift.
;  Casino autocorrect (autocorrect.txt) fixes slang and acronyms as you
;  type, in the pad and in the log form boxes. Ctrl+Z undoes a fix.
;  [CallPad] Key=off frees the + key; Autocorrect=no turns the fixes off.
; =====================================================================
#HotIf CallPadKeyOn()
NumpadAdd:: ShowCallPad()
#HotIf
; (set up by RegisterHotkeys, see HotkeyDefs)

#HotIf CallPadActive()
^Enter:: CallPadMakeLog()
^NumpadEnter:: CallPadMakeLog()
#HotIf

; The + key only opens the pad while you're in some other program, so it
; still types a + in Watchlog's own boxes. Shift+ or Ctrl+ with it types a +.
CallPadKeyOn() => Cfg.Has("PadKey") && Cfg["PadKey"] && !WinActive("ahk_pid " DllCall("GetCurrentProcessId"))
CallPadActive() => IsObject(CallPadWin) && WinActive("ahk_id " CallPadWin.Hwnd)

ShowCallPad() {
    global CallPadWin, CallPadTarget
    if !WinActive("ahk_pid " DllCall("GetCurrentProcessId"))
        CallPadTarget := WinExist("A")
    if IsObject(CallPadWin) {
        if WinActive("ahk_id " CallPadWin.Hwnd) {
            CallPadHide()
            return
        }
        LoadAutocorrect()
        CallPadWin.Show()
        WinActivate "ahk_id " CallPadWin.Hwnd
        CallPadWin["Pad"].Focus()
        return
    }
    LoadCallPad()
    LoadAutocorrect()
    g := WGui("+AlwaysOnTop +ToolWindow", "Call pad  -  v" VERSION)
    g.MarginX := 12, g.MarginY := 10
    g.SetFont("s10 c606060", "Segoe UI")
    g.AddText("vStamp w290", "")
    g.AddButton("vEarlier x+6 yp-5 w184", "Earlier calls this shift").OnEvent("Click", Earlier)
    g.SetFont("s12 c000000", "Segoe UI")
    ed := g.AddEdit("vPad xm w480 r10 Multi WantReturn", PadText)
    g.SetFont("s10", "Segoe UI")
    g.AddButton("vLog xm w150", "Make a log (Ctrl+Enter)").OnEvent("Click", (*) => CallPadMakeLog())
    g.AddButton("x+6 yp w80", "Copy all").OnEvent("Click", CopyAll)
    g.AddButton("x+6 yp w130", "Paste into window").OnEvent("Click", PasteInto)
    g.AddButton("x+6 yp w100", "New call").OnEvent("Click", NewCall)
    g.SetFont("s9 c707070")
    g.AddText("xm w480", "Esc hides the pad and keeps the text. The + key brings it back.")
    ed.OnEvent("Change", PadChanged)
    g.OnEvent("Escape", (*) => CallPadHide())
    g.OnEvent("Close", (*) => (CallPadHide(), true))
    CallPadWin := g
    ShowStamp()
    g.Show()
    WinActivate "ahk_id " g.Hwnd
    ed.Focus()
    ; cursor at the end of what is already there
    SendMessage 0xB1, StrLen(ed.Value), StrLen(ed.Value), ed.Hwnd

    PadChanged(*) {
        global PadText, PadStart, PadStamp, PadKeys
        AutoFixEdit(ed)
        PadKeys += Abs(StrLen(ed.Value) - StrLen(PadText))
        PadText := ed.Value
        PadStamp := A_TickCount
        if PadStart = "" && Trim(PadText) != ""
            PadStart := FormatTime(, "HH:mm")
        ShowStamp()
        SetTimer SaveCallPad, -700
    }
    ShowStamp() {
        g["Stamp"].Text := PadStart != "" ? "Call started " PadStart : "Type while you talk. The time is stamped at your first key."
    }
    CopyAll(*) {
        if Trim(PadText) = "" {
            Tip("Nothing on the pad yet")
            return
        }
        A_Clipboard := PadText
        Tip("Copied. Paste it with Ctrl+V.")
    }
    PasteInto(*) {
        if Trim(PadText) = ""
            return
        CallPadHide()
        Paste(PadText)
    }
    NewCall(*) {
        global PadText, PadStart, PadKeys
        PadPush()
        PadText := "", PadStart := "", PadKeys := 0
        ed.Value := ""
        ShowStamp()
        SaveCallPad()
        ed.Focus()
    }
    Earlier(*) {
        m := Menu()
        if !PadHistory.Length {
            m.Add("(no earlier calls this shift)", (*) => 0)
            m.Disable("1&")
        }
        for i, h in PadHistory {
            first := StrReplace(StrReplace(SubStr(Trim(h.text), 1, 40), "`r"), "`n", " ")
            m.Add(h.start "  " first, LoadOld.Bind(i))
        }
        m.Show()
    }
    LoadOld(i, *) {
        global PadText, PadStart, PadStamp, PadKeys
        h := PadHistory.RemoveAt(i)
        PadPush()
        PadText := h.text, PadStart := h.start, PadKeys := h.keys, PadStamp := A_TickCount
        ed.Value := PadText
        ShowStamp()
        SaveCallPad()
        ed.Focus()
    }
}

; Puts the current call on the list of earlier calls (if there is one)
PadPush() {
    global PadHistory
    if Trim(PadText) = ""
        return
    PadHistory.InsertAt(1, {start: PadStart != "" ? PadStart : "--:--", text: PadText, keys: PadKeys})
    while PadHistory.Length > 8
        PadHistory.Pop()
}

CallPadHide() {
    if !IsObject(CallPadWin)
        return
    CallPadWin.Hide()
    if CallPadTarget
        ReturnTo(CallPadTarget)
}

; Ctrl+Enter / "Make a log": the call goes on the clipboard and the pad hides.
; Then type any log trigger: its form reads the saved call and fills its
; boxes. When that log is inserted the call moves to Earlier calls and the
; next Numpad + gives a fresh pad.
CallPadMakeLog() {
    if Trim(PadText) = "" {
        Tip("Nothing on the pad yet")
        return
    }
    A_Clipboard := PadText
    if IsObject(CallPadWin)
        CallPadWin.Hide()
    if CallPadTarget
        ReturnTo(CallPadTarget)
    ; a code word first on the pad (fill 205 5.5) runs that log now (v3.26.0)
    global PadShort
    sc := PadShortcut(PadText)
    if IsObject(sc) {
        for t in TemplateList
            if t.trig = sc.trig {
                PadShort := sc
                RunTemplate(t.text, t.name != "" ? t.name : t.trig, t.repeat, t.trig, t.fill)
                PadShort := ""
                return
            }
    }
    Tip("Call saved. Now type the trigger of the log (like `;jack) and it fills in the boxes.", 3500)
}

; A log that used the call has been inserted: the call goes to the earlier
; calls and the pad is empty for the next one
CallPadUsed() {
    global PadText, PadStart, PadKeys
    PadPush()
    PadText := "", PadStart := "", PadKeys := 0
    if IsObject(CallPadWin) {
        try CallPadWin["Pad"].Value := ""
        try CallPadWin["Stamp"].Text := "Type while you talk. The time is stamped at your first key."
    }
    SaveCallPad()
}

; The pad text is saved a moment after you stop typing, so a reload or a
; crash can't lose a call. Files are on this PC only.
SaveCallPad() {
    try {
        if !DirExist(DataDir)
            DirCreate DataDir
        if Trim(PadText) = "" {
            try FileDelete CallPadFile
        } else {
            f := FileOpen(CallPadFile, "w", "UTF-8")
            f.Write(PadStart "|" PadKeys "`n" PadText)
            f.Close()
        }
        if !PadHistory.Length {
            try FileDelete CallHistFile
        } else {
            out := ""
            for h in PadHistory
                out .= "@@@@ " h.start "|" h.keys "`n" StrReplace(h.text, "@@@@", "@@@") "`n"
            f := FileOpen(CallHistFile, "w", "UTF-8")
            f.Write(out)
            f.Close()
        }
    }
}

; Reads the saved pad once. Files older than 14 hours are from an earlier
; shift and are thrown away.
LoadCallPad() {
    global CallPadLoaded, PadText, PadStart, PadStamp, PadHistory, PadKeys
    if CallPadLoaded
        return
    CallPadLoaded := true
    for file in [CallPadFile, CallHistFile] {
        if FileExist(file) && DateDiff(A_Now, FileGetTime(file, "M"), "Hours") >= 14
            try FileDelete file
    }
    try {
        if FileExist(CallPadFile) {
            t := FileRead(CallPadFile, "UTF-8")
            nl := InStr(t, "`n")
            head := StrSplit(nl ? SubStr(t, 1, nl - 1) : "", "|")
            PadStart := head.Length ? head[1] : ""
            PadKeys := head.Length > 1 && IsInteger(head[2]) ? Integer(head[2]) : 0
            PadText := nl ? SubStr(t, nl + 1) : t
            ; keep the call's real age (forms only use a call jotted in the last 90 minutes)
            PadStamp := A_TickCount - DateDiff(A_Now, FileGetTime(CallPadFile, "M"), "Seconds") * 1000
        }
    }
    try {
        if FileExist(CallHistFile) {
            PadHistory := []
            for chunk in StrSplit(FileRead(CallHistFile, "UTF-8"), "@@@@ ") {
                if Trim(chunk) = ""
                    continue
                nl := InStr(chunk, "`n")
                head := StrSplit(SubStr(chunk, 1, nl - 1), "|")
                PadHistory.Push({start: head[1], keys: head.Length > 1 && IsInteger(head[2]) ? Integer(head[2]) : 0, text: RTrim(SubStr(chunk, nl + 1), "`r`n")})
            }
        }
    }
}

; End of shift: the pad and the earlier calls are wiped
CallPadEndShift() {
    global PadText, PadStart, PadHistory, PadKeys
    PadText := "", PadStart := "", PadHistory := [], PadKeys := 0
    try FileDelete CallPadFile
    try FileDelete CallHistFile
    if IsObject(CallPadWin) {
        try CallPadWin["Pad"].Value := ""
        try CallPadWin["Stamp"].Text := "Type while you talk. The time is stamped at your first key."
    }
}

; ---- Reading the pad for the log forms ------------------------------
; Looks for a machine (B1410, NRT2, ATM3), a table from the @tables list,
; a dollar amount ($4,000 or 4k) and an 8-digit alert #. A value is only
; used when the pad holds exactly one of that kind. Expires after 90
; minutes without typing on the pad.
PadHints() {
    if IsObject(PadShort) && IsObject(PadShort.hints)
        return PadShort.hints
    hints := Map()
    if Trim(PadText) = "" || A_TickCount - PadStamp > 5400000
        return hints
    text := PadText
    found := Map()
    pos := 1
    while p := RegExMatch(text, "i)(?<![A-Za-z0-9])((?:[A-Za-z]\d{3,5})|(?:NRT|ATM)\d)(?![A-Za-z0-9])", &m, pos) {
        found[StrUpper(m[1])] := true
        pos := p + m.Len
    }
    if found.Count = 1
        for k in found
            hints["machine"] := k
    found := Map()
    if Lists.Has("tables") {
        for it in Lists["tables"]
            if RegExMatch(text, "i)(?<![A-Za-z0-9])" it "(?![A-Za-z0-9])")
                found[it] := true
    }
    if found.Count = 1
        for k in found
            hints["table"] := k
    found := Map()
    pos := 1
    while p := RegExMatch(text, "(?<![\w.])\$\s?(\d[\d,]*(?:\.\d+)?)(k?)(?![\w])", &m, pos) {
        found[PadMoney(m[1], m[2])] := true
        pos := p + m.Len
    }
    pos := 1
    while p := RegExMatch(text, "i)(?<![\w.$,])(\d[\d,]*(?:\.\d+)?)\s?(k)(?![\w])", &m, pos) {
        found[PadMoney(m[1], m[2])] := true
        pos := p + m.Len
    }
    if found.Count = 1
        for k in found
            hints["money"] := k
    found := Map()
    pos := 1
    while p := RegExMatch(text, "(?<!\d)\d{8}(?!\d)", &m, pos) {
        found[m[0]] := true
        pos := p + m.Len
    }
    if found.Count = 1
        for k in found
            hints["alert"] := k
    shorthand := PadParse(text)
    if shorthand.fills.Length
        hints["fills"] := shorthand.fills
    if IsObject(shorthand.jack)
        hints["jack"] := shorthand.jack
    return hints
}

; Shorthand lines on the pad, one per line:
;   n3 190800 bvs         a machine fill: NRT3, 190,800, note (BVs)
;   a1 100000             ATM1, 100,000   (NRT1-4, ATM1-5)
;   c2102 11421.11 win 3 cash   a jackpot: machine, amount, window #
; Returns the fills (a list) and the jackpot (only when there is exactly one).
PadParse(text) {
    fills := [], jacks := []
    for line in StrSplit(text, "`n", "`r") {
        line := Trim(line)
        if line = ""
            continue
        if RegExMatch(line, "i)^(n|nrt|a|atm)\s*(\d)\s+\$?(\d[\d,]*(?:\.\d+)?)(k?)(?![\w.])\s*(.*)$", &m) {
            nrt := SubStr(StrLower(m[1]), 1, 1) = "n"
            if m[2] >= 1 && m[2] <= (nrt ? 4 : 5)
                fills.Push({machine: (nrt ? "NRT" : "ATM") m[2], amount: PadMoney(m[3], m[4]), note: PadNote(m[5])})
        } else if RegExMatch(line, "i)^([A-Za-z]\d{3,5})\s+\$?(\d[\d,]*(?:\.\d+)?)(k?)\s+w(?:in(?:dow)?)?\.?\s*#?(\d+)\b", &m) {
            jacks.Push({machine: StrUpper(m[1]), amount: PadMoney(m[2], m[3]), window: m[4]})
        }
    }
    return {fills: fills, jack: jacks.Length = 1 ? jacks[1] : ""}
}

; A shorthand line on the pad that starts with a code word (v3.26.0):
;   fill 205 5.5          table fill (5.5 = $5,500; 5k = $5,000; 500 = $500)
;   open 201 202 203      tables opened      201 auto   tables auto-closed
;   jack c2102 11421.11 w3 cash [2130]      bv c2102 4471 full      account 123456
; Any other template's code word first (cards ry301) just opens that form
; with the pad filled in. Returns "" when the first line isn't one.
; hints.go = the line had everything, so the log is made without the form.
PadShortcut(text) {
    line := ""
    for l in StrSplit(text, "`n", "`r") {
        l := Trim(l)
        if l != "" {
            line := l
            break
        }
    }
    if line = ""
        return ""
    words := StrSplit(RegExReplace(line, "\s+", " "), " ")
    code := StrLower(words[1])
    rest := []
    known := Map("fill", 1, "open", 1, "auto", 1, "jack", 1, "bv", 1, "account", 1, "mfill", 1)
    padText := text
    if known.Has(code) {
        loop words.Length - 1
            rest.Push(words[A_Index + 1])
        if code = "mfill"
            padText := RegExReplace(text, "i)^\s*mfill\s*", "")
    } else if words.Length > 1 && StrLower(words[words.Length]) = "auto" {
        code := "auto"
        loop words.Length - 1
            rest.Push(words[A_Index])
    } else if (sh := PadParse(text)).fills.Length {
        ; the older shorthand with no code word: n3 190800 bvs  = machine fill
        code := "mfill"
    } else if IsObject(sh.jack) {
        ; c2102 11421.11 win 3 cash  = jackpot
        code := "jack"
        for w in words
            rest.Push(w)
    } else {
        for t in TemplateList
            if t.trig = ";" code
                return {trig: t.trig, hints: ""}
        return ""
    }
    trig := ";" code
    hints := Map("go", false)
    if code = "fill" {
        rows := [], ok := rest.Length >= 2 && Mod(rest.Length, 2) = 0
        loop rest.Length // 2 {
            t := PadTable(rest[2 * A_Index - 1]), a := PadAmount(rest[2 * A_Index], true)
            if t = "" || a = ""
                ok := false
            else
                rows.Push({table: t, amount: a})
        }
        hints["rows"] := rows, hints["go"] := ok && rows.Length > 0
    } else if code = "open" || code = "auto" {
        rows := [], ok := rest.Length > 0
        for w in rest {
            t := PadTable(w)
            if t = ""
                ok := false
            else
                rows.Push({table: t})
        }
        hints["rows"] := rows, hints["go"] := ok && rows.Length > 0
    } else if code = "jack" {
        machine := "", amount := "", window := "", time := "", afterWin := false
        k := 1
        while k <= rest.Length {
            w := rest[k]
            if machine = "" && RegExMatch(w, "^[A-Za-z]\d{3,5}$") {
                machine := StrUpper(w)
            } else if window = "" && RegExMatch(w, "i)^w(?:in(?:dow)?)?\.?#?(\d*)$", &m) {
                if m[1] != ""
                    window := m[1]
                else if k < rest.Length && RegExMatch(rest[k + 1], "^#?(\d+)$", &m2)
                    window := m2[1], k += 1
                afterWin := true
            } else if afterWin && time = "" && RegExMatch(w, "^(\d{4}|\d{1,2}:\d\d)$") {
                time := w
            } else if amount = "" && RegExMatch(w, "^\$?[\d,]+(?:\.\d+)?k?$") {
                amount := PadAmount(w)
            }
            k += 1
        }
        if machine != "" && amount != "" && window != "" {
            hints["jack"] := {machine: machine, amount: amount, window: window}
            hints["machine"] := machine
            if time != ""
                hints["time"] := time
            hints["expect"] := 3 + (time != "" ? 1 : 0)
            hints["go"] := true
        }
    } else if code = "bv" {
        machine := "", asset := "", reason := ""
        for w in rest {
            if machine = "" && RegExMatch(w, "^[A-Za-z]\d{3,5}$")
                machine := StrUpper(w)
            else if asset = "" && RegExMatch(w, "^\d{3,}$")
                asset := w
            else if reason = "" && RegExMatch(w, "i)^f")
                reason := "Full"
            else if reason = "" && RegExMatch(w, "i)^d")
                reason := "Defective"
        }
        if machine != ""
            hints["machine"] := machine
        if asset != ""
            hints["asset"] := asset
        if reason != ""
            hints["reason"] := reason
        hints["expect"] := 3
        hints["go"] := machine != "" && asset != "" && reason != ""
    } else if code = "mfill" {
        fills := PadParse(padText).fills
        if fills.Length
            hints["fills"] := fills, hints["go"] := true
    } else if code = "account" {
        if rest.Length && RegExMatch(rest[1], "^\d{3,}$") {
            hints["account"] := rest[1]
            hints["expect"] := 1
            hints["go"] := true
        }
    }
    return {trig: trig, hints: hints}
}

; "5.5" -> 5500, "5k" -> 5000, "11421.11" -> 11421.11. small = a plain number
; under 100 counts as thousands too (table fills: 5.5 is $5,500)
PadAmount(tok, small := false) {
    t := StrReplace(StrReplace(tok, "$"), ",")
    if !RegExMatch(t, "i)^(\d+(?:\.\d+)?)(k?)$", &m)
        return ""
    v := m[1] + 0
    if m[2] != "" || (small && v < 100)
        v *= 1000
    return v = Floor(v) ? String(Integer(v)) : Format("{:.2f}", v)
}

; A table typed as 205, bj205 or BJ205 -> the table in the @tables list ("" if none or two match)
PadTable(tok) {
    if !Lists.Has("tables")
        return ""
    hit := ""
    for it in Lists["tables"] {
        if StrLower(it) = StrLower(tok)
            return it
        if RegExMatch(tok, "^\d+$") && RegExMatch(it, "^\D*" tok "$") {
            if hit != ""
                return ""
            hit := it
        }
    }
    return hit
}

; The words after an amount on a fill line, as the note in brackets
PadNote(words) {
    r := StrLower(Trim(RegExReplace(words, "[()]")))
    if r = ""
        return ""
    if InStr(r, "div") || r = "bvd"
        return "BVs/Divert"
    if r = "bv" || r = "bvs"
        return "BVs"
    return Trim(RegExReplace(words, "[()]"))
}

PadMoney(num, k) {
    v := StrReplace(num, ",") + 0
    if k != ""
        v *= 1000
    return v = Floor(v) ? String(Integer(v)) : Format("{:.2f}", v)
}

; Fills the form boxes the pad has an answer for and marks them. Returns
; how many boxes it filled, and for a machine fill form the rows to enter
; (FormPaste adds each one with "Add another").
PadFill(fields, ctrls, labs, hints, marks) {
    n := 0
    hasBuyIn := false, hasWindow := false
    for f in fields {
        if f.key = "Buy-in"
            hasBuyIn := true
        else if RegExMatch(StrLower(f.key), "^window")
            hasWindow := true
    }
    ; a machine fill form (;mfill): a Machine list holding the fill machines
    fills := hints.Has("fills") ? hints["fills"] : []
    if fills.Length {
        for f in fields
            if StrLower(f.key) = "machine" && f.HasOwnProp("items") && HasVal(f.items, fills[1].machine)
                return {n: 0, rows: fills}
    }
    ; a table fill / opening / auto-close from a shorthand line: one row per table
    rows := hints.Has("rows") ? hints["rows"] : []
    if rows.Length {
        for f in fields
            if RegExMatch(StrLower(f.key), "^table")
                return {n: 0, rows: rows}
    }
    jack := hints.Has("jack") && hasWindow ? hints["jack"] : ""
    for i, f in fields {
        kind := f.HasOwnProp("kind") ? f.kind : ""
        if kind = "time" && hints.Has("time") {
            ctrls[i].Value := hints["time"]
            labs[i].Text := f.label "  (from your call pad)"
            marks[i] := true
            n += 1
            continue
        }
        if f.HasOwnProp("alertCopy") || f.HasOwnProp("matchCopy") || kind = "time"
            continue
        k := StrLower(f.key)
        val := ""
        if InStr(k, "machine")
            val := IsObject(jack) ? jack.machine : hints.Get("machine", "")
        else if RegExMatch(k, "^table")
            val := hints.Get("table", "")
        else if (k = "amount" && !hasBuyIn) || k = "tito value"
            val := IsObject(jack) ? jack.amount : hints.Get("money", "")
        else if RegExMatch(k, "^alert #")
            val := hints.Get("alert", "")
        else if RegExMatch(k, "^asset #")
            val := hints.Get("asset", "")
        else if k = "reason"
            val := hints.Get("reason", "")
        else if RegExMatch(k, "^account #")
            val := hints.Get("account", "")
        else if RegExMatch(k, "^window") && IsObject(jack)
            val := jack.window
        if val = ""
            continue
        if PadPut(f, ctrls[i], val) {
            labs[i].Text := f.label "  (from your call pad)"
            marks[i] := true
            n += 1
        }
    }
    return {n: n, rows: []}
}

; Puts a value in one box. A list you must pick from only takes an item it has.
PadPut(f, c, val) {
    kind := f.HasOwnProp("kind") ? f.kind : ""
    if kind = "list" {
        hit := 0
        for j, it in f.items
            if StrLower(it) = StrLower(val)
                hit := j
        if !hit
            return false
        c.Choose(hit)
    } else if f.HasOwnProp("items") {
        c.Text := val
    } else {
        if Trim(c.Text) != ""
            return false
        c.Value := val
    }
    return true
}

; One shorthand fill row (machine, amount, note) into a machine fill form
PadSetRow(fields, ctrls, labs, row, marks) {
    for i, f in fields {
        k := StrLower(f.key)
        val := ""
        if k = "machine" && row.HasOwnProp("machine")
            val := row.machine
        else if RegExMatch(k, "^table") && row.HasOwnProp("table")
            val := row.table
        else if k = "amount" && row.HasOwnProp("amount")
            val := row.amount
        else if k = "note" && row.HasOwnProp("note")
            val := row.note
        if val = ""
            continue
        c := ctrls[i]
        if f.HasOwnProp("items") {
            if PadPut(f, c, val) {
                labs[i].Text := f.label "  (from your call pad)"
                marks[i] := true
            }
        } else {
            c.Value := val
            labs[i].Text := f.label "  (from your call pad)"
            marks[i] := true
        }
    }
}

; ---- Casino autocorrect ---------------------------------------------
; autocorrect.txt (in the Watchlog folder, made from the built-in list
; the first time you choose Advanced > Edit the autocorrect list). One
; fix per line:  what you type = what it becomes. Lines starting with # are
; notes. A fix happens when you finish a word with a space, Enter or
; punctuation, never in the middle of a word.
LoadAutocorrect() {
    global AutoMap, AutoStamp
    stamp := ""
    try stamp := FileGetTime(AutoFile, "M")
    if stamp = AutoStamp
        return
    AutoStamp := stamp
    AutoMap := Map()
    AutoMap.CaseSense := false
    if !Cfg["Autocorrect"]
        return
    text := AutoDefault()
    if stamp != ""
        try text := FileRead(AutoFile, "UTF-8")
    for line in StrSplit(text, "`n", "`r") {
        line := Trim(line)
        if line = "" || SubStr(line, 1, 1) = "#"
            continue
        eq := InStr(line, "=")
        if !eq
            continue
        wrong := Trim(SubStr(line, 1, eq - 1))
        right := Trim(SubStr(line, eq + 1))
        if wrong != "" && right != "" && !InStr(wrong, " ")
            AutoMap[wrong] := right
    }
}

; Call from an Edit's Change event: if the word just finished is in the
; list, swap it. Uses the Edit's own undo, so Ctrl+Z puts the old word back.
AutoFixEdit(ctrl, *) {
    static busy := false
    if busy
        return
    ; picks up a saved change to autocorrect.txt (checked at most once a second)
    static checked := 0
    if A_TickCount - checked > 1000 {
        checked := A_TickCount
        LoadAutocorrect()
    }
    if !AutoMap.Count
        return
    ; a combo box keeps its typing in a child Edit
    hw := ctrl.Hwnd
    if ctrl.Type = "ComboBox" {
        hw := DllCall("FindWindowEx", "Ptr", hw, "Ptr", 0, "Str", "Edit", "Ptr", 0, "Ptr")
        if !hw
            return
    }
    sel := Buffer(8, 0)
    SendMessage 0xB0, sel.Ptr, sel.Ptr + 4, hw        ; EM_GETSEL
    caret := NumGet(sel, 4, "UInt")
    if caret < 2
        return
    ; The Edit counts a line break as 2 characters (CR+LF); work on a copy
    ; with single-character breaks and convert the position
    text := StrReplace(ctrl.Text, "`r`n", "`n")
    pos := caret
    Loop 5 {
        part := SubStr(text, 1, pos)
        np := caret - (StrLen(part) - StrLen(StrReplace(part, "`n")))
        if np = pos
            break
        pos := np
    }
    ch := SubStr(text, pos, 1)
    if ch = "" || !InStr(" `t`n.,;:!?)", ch)
        return
    wordEnd := pos - 1
    if wordEnd < 1 || !RegExMatch(SubStr(text, 1, wordEnd), "([\p{L}\d'-]+)$", &m)
        return
    word := m[1]
    if AutoMap.Has(word) {
        rep := AutoMap[word]
    } else if RegExMatch(word, "i)^(.{2,})s$", &pl) && AutoMap.Has(pl[1]) {
        rep := AutoMap[pl[1]] "s"       ; titos -> TITOs, handpays -> hand pays
    } else
        return
    if rep == word
        return
    ; a capital at the start of the typed word carries over to a lower-case fix
    if RegExMatch(word, "^\p{Lu}") && RegExMatch(rep, "^\p{Ll}")
        rep := StrUpper(SubStr(rep, 1, 1)) SubStr(rep, 2)
    start := wordEnd - StrLen(word)
    before := SubStr(text, 1, start)
    start += StrLen(before) - StrLen(StrReplace(before, "`n"))
    busy := true
    try {
        SendMessage 0xB1, start, start + StrLen(word), hw             ; EM_SETSEL
        SendMessage 0xC2, 1, StrPtr(rep), hw                          ; EM_REPLACESEL (can undo)
        after := caret + StrLen(rep) - StrLen(word)
        SendMessage 0xB1, after, after, hw
    }
    busy := false
}

EditAutocorrect() {
    if !FileExist(AutoFile) {
        try FileAppend AutoDefault(), AutoFile, "UTF-8"
    }
    EditFile(AutoFile)
}

; The built-in list: acronyms from the SOP glossary (fixed to capitals) and
; a few words that should be two words. Choosing Advanced > Edit the
; autocorrect list saves a copy to edit; that copy is then the whole list.
AutoDefault() {
    return "
(
# Watchlog casino autocorrect. One fix per line:  what you type = what it becomes
# A fix happens when you finish the word with a space, Enter or punctuation.
# Ctrl+Z puts the old word back. Put # in front of a line to switch it off.
# Save the file and it is used the next time you open the call pad or a form.

# Acronyms
abm = ABM
agco = AGCO
ajm = AJM
apc = APC
ccom = CCOM
cvt = CVT
cfe = CFE
cpu = CPU
xvu = XVU
ctr = CTR
eprom = EPROM
gms = GMS
gbhc = GBHC
ioc = IOC
olg = OLG
ptm = PTM
pmgr = PMGR
romsig = ROMSIG
tito = TITO
meal = MEAL
ram = RAM
wan = WAN
gm = GM

# Words that should be two words
handpay = hand pay
cashbox = cash box
softcount = soft count
mainbank = Main Bank
shortpay = short pay
)"
}


; =====================================================================
;  SHIFT JOURNAL
;  Every log you insert is also saved, with the time, in
;  Documents\Shift Journal\<date the shift started>.txt
;  A shift ends with Ctrl+Alt+Shift+L, or after 6 hours with no logs.
;  Ctrl+Alt+J = this shift's summary (copy it into your End of Shift log)
;  [Journal] Save= in settings.ini: full, counts or off
;  [Journal] KeepDays= : shift files older than this are deleted
;  (default 30, 0 = keep them all). Tray > Settings sets both.
; =====================================================================
JournalDir() => A_MyDocuments "\Shift Journal"
JournalBackupDir() => DataDir "\Shift Journal (this PC)"

Journal(title, text, keys := "") {
    global JournalNotified
    mode := Cfg["JournalSave"]
    if mode = "off"
        return
    ; [k112] = the keystrokes this log saved, so deleting or renaming it in
    ; the journal window can take exactly that off the counts (v3.17.0)
    entry := FormatTime(, "HH:mm") "  " title (keys != "" ? "  [k" keys "]" : "") "`n"
    if mode != "counts" {
        body := StrReplace(StrReplace(Trim(text, " `r`n"), "`r`n", "`n"), "`n", "`n       ")
        entry .= "       " body "`n`n"
    }
    if JournalWrite(JournalDir(), entry)
        return
    ; The journal is in OneDrive. If OneDrive isn't running, it goes in a
    ; folder on this PC instead (and says so once).
    if JournalWrite(JournalBackupDir(), entry) && !JournalNotified {
        JournalNotified := true
        TrayTip "OneDrive isn't running, so the shift journal is being saved on this PC:`n" JournalBackupDir(), "Shift journal", "Iconi"
    }
}

; Adds an entry to this shift's file, starting a new shift if needed.
; Returns false if the folder can't be used.
JournalWrite(dir, entry) {
    if IsObject(TutorialWin)
        return
    try {
        if !DirExist(dir)
            DirCreate dir
        latest := JournalLatest(dir)
        file := latest.file
        if !latest.open {
            file := dir "\" FormatTime(, "yyyy-MM-dd") ".txt"
            entry := (FileExist(file) ? "`n" : "") "=== Shift started " FormatTime(, "ddd MMM d, yyyy  HH:mm")
                . "  (" A_ComputerName ") ===`n`n" entry
        }
        FileAppend entry, file, "UTF-8"
        return true
    }
    return false
}

; The latest journal file in a folder (today's, or from the last couple of
; days for a shift that started earlier), and whether its shift is still
; going: not ended with Ctrl+Alt+Shift+L, and a log in the last 6 hours
JournalLatest(dir) {
    file := ""
    Loop 3 {
        f := dir "\" FormatTime(DateAdd(A_Now, 1 - A_Index, "Days"), "yyyy-MM-dd") ".txt"
        if FileExist(f) {
            file := f
            break
        }
    }
    if file = ""
        return {file: "", open: false}
    open := DateDiff(A_Now, FileGetTime(file, "M"), "Hours") < 6
    if open {
        text := FileRead(file, "UTF-8")
        open := LastPos(text, "=== Shift started") > LastPos(text, "=== Shift ended")
    }
    return {file: file, open: open}
}

; The most recently used journal (OneDrive, or this PC's backup folder)
JournalFind() {
    best := {file: "", open: false, error: ""}, bestTime := 0
    for dir in [JournalDir(), JournalBackupDir()] {
        try {
            latest := JournalLatest(dir)
            if latest.file = ""
                continue
            t := FileGetTime(latest.file, "M")
            if t > bestTime {
                best := {file: latest.file, open: latest.open, error: ""}
                bestTime := t
            }
        } catch as err {
            if best.file = ""
                best.error := dir ":`n" err.Message
        }
    }
    return best
}

; Deletes shift files older than KeepDays. Only files named like
; 2026-10-16.txt in the two journal folders are ever touched, and never
; one from the last two days (a night shift's file is still in use).
CleanJournal() {
    days := Cfg["KeepDays"]
    if days <= 0
        return
    removed := 0
    for dir in [JournalDir(), JournalBackupDir()] {
        Loop Files dir "\*.txt" {
            if !RegExMatch(A_LoopFileName, "^(\d{4})-(\d\d)-(\d\d)\.txt$", &d)
                continue
            try {
                if DateDiff(A_Now, d[1] d[2] d[3], "Days") > Max(days, 2) {
                    FileDelete A_LoopFileFullPath
                    removed += 1
                }
            }
        }
    }
    if removed
        Activity("Shift journal: deleted " removed " shift file(s) older than " days " days")
}

; How many shift files there are and the oldest one's date, for the status window
JournalFiles() {
    n := 0, oldest := ""
    for dir in [JournalDir(), JournalBackupDir()] {
        Loop Files dir "\*.txt" {
            if !RegExMatch(A_LoopFileName, "^\d{4}-\d\d-\d\d(?=\.txt$)", &d)
                continue
            n += 1
            if oldest = "" || StrCompare(d[0], oldest) < 0
                oldest := d[0]
        }
    }
    return {count: n, oldest: oldest}
}

; Called by end of shift: the next log starts a new shift
JournalEnd() {
    try IniWrite 1, SavedFile, "Shift", "Ended"
    CallPadEndShift()
    latest := JournalFind()
    if latest.open
        try FileAppend "=== Shift ended " FormatTime(, "HH:mm") " ===`n`n", latest.file, "UTF-8"
}

; Where the last copy of needle starts in text (0 if it isn't there)
LastPos(text, needle) {
    pos := 0, p := 0
    while p := InStr(text, needle, , p + 1)
        pos := p
    return pos
}

; Counts the logs in the last shift of a journal file
JournalStats(file, text := "") {
    if text = ""
        text := FileRead(file, "UTF-8")
    p := LastPos(text, "=== Shift started")
    if p > 0
        text := SubStr(text, p)
    st := {started: "", ended: "", first: "", last: "", total: 0, list: "", summary: ""}
    if RegExMatch(text, "=== Shift started (.+?)  \(", &m)
        st.started := m[1]
    if RegExMatch(text, "=== Shift ended (\d\d:\d\d)", &m)
        st.ended := m[1]
    names := [], counts := Map()
    Loop Parse text, "`n", "`r" {
        ; a log's first line: the time at the very start, two spaces, its name
        if !RegExMatch(A_LoopField, "^(\d\d:\d\d) +(\S.*)$", &e)
            continue
        name := Trim(RegExReplace(Trim(e[2]), "\s*\[k-?\d+\]$"))
        if !counts.Has(name) {
            counts[name] := 0
            names.Push(name)
        }
        counts[name] += 1
        st.total += 1
        if st.first = ""
            st.first := e[1]
        st.last := e[1]
    }
    ; most-used first (the list is short, so pick the biggest each time)
    parts := ""
    while names.Length {
        top := 1
        for i, nm in names {
            if counts[nm] > counts[names[top]]
                top := i
        }
        nm := names.RemoveAt(top)
        n := counts[nm]
        st.list .= Format("{:4}", n) "  " nm "`r`n"
        parts .= (parts = "" ? "" : ", ") n " " nm
    }
    st.summary := "Shift summary (" st.first " - " (st.ended != "" ? st.ended : st.last) "): " st.total " logs. " parts "."
    return st
}

; (set up by RegisterHotkeys, see HotkeyDefs)

ShowJournal() {
    if Cfg["JournalSave"] = "off" {
        MsgBox "The shift journal is turned off. Tray menu > Settings turns it back on.", "Shift journal"
        return
    }
    latest := JournalFind()
    if latest.file = "" {
        if latest.error != ""
            MsgBox "Couldn't open the shift journal folder.`n`n" latest.error
                . "`n`nTake a screenshot of this and send it to Claude.", "Shift journal", "Icon!"
        else {
            seen := ""
            Loop Files JournalDir() "\*.*"
                seen .= (A_Index <= 5 ? "   " A_LoopFileName "`n" : "")
            MsgBox "No logs saved yet.`n`nEvery log you insert is saved in:`n" JournalDir()
                . (seen != "" ? "`n`nFiles in that folder:`n" seen "`nIf a log is in there, take a screenshot of this and send it to Claude." : ""), "Shift journal"
        }
        return
    }
    try st := JournalStats(latest.file)
    catch as err {
        MsgBox "Couldn't read the shift journal:`n" latest.file "`n`n" err.Message
            . "`n`nTake a screenshot of this and send it to Claude.", "Shift journal", "Icon!"
        return
    }
    if !st.total {
        MsgBox "This shift's journal has no log lines in it yet:`n" latest.file
            . "`n`nEach log starts with a line like  22:15  Audit  and Ctrl+Alt+J counts those."
            . " If the file was open in Notepad while logs came in, saving Notepad can write over them.", "Shift journal", "Icon!"
        return
    }
    file := latest.file
    raw := FileRead(file, "UTF-8")
    sp := LastPos(raw, "=== Shift started")
    shiftText := sp > 0 ? SubStr(raw, sp) : raw      ; this shift's part of the file, as saved
    dirty := false
    sv := SavedShift()
    summary := ""
    g := WGui("+AlwaysOnTop", "Shift journal  -  v" VERSION)
    g.BackColor := "F4F7F7"
    g.MarginX := 16, g.MarginY := 12
    g.SetFont("s15 bold c0F766E", "Segoe UI")
    g.AddText("w640", "Shift journal")
    g.SetFont("s10 norm c1F2933", "Segoe UI")
    headT := g.AddText("w640 y+2", "")
    g.SetFont("s9 bold c0F766E")
    g.AddText("w640 y+10", "WHAT YOU LOGGED")
    g.SetFont("s10 norm c1F2933", "Consolas")
    counts := g.AddEdit("w640 r5 ReadOnly -WantReturn -TabStop VScroll BackgroundWhite")
    g.SetFont("s9 bold c0F766E", "Segoe UI")
    g.AddText("w640 y+10", "EVERY LOG THIS SHIFT   (edit anything, then Save changes: removed logs come off the counts. [k12] = keystrokes that log saved, leave it on its line)")
    g.SetFont("s10 norm c1F2933", "Consolas")
    ed := g.AddEdit("w640 r16 Multi WantReturn VScroll BackgroundWhite")
    g.SetFont("s10 norm c1F2933", "Segoe UI")
    saveB := g.AddButton("xm y+12 w120 Default Disabled", "Save changes")
    revB := g.AddButton("x+6 w100 Disabled", "Undo edits")
    g.AddButton("x+6 w112", "Copy summary").OnEvent("Click", CopySummary)
    g.AddButton("x+6 w112", "Copy shift text").OnEvent("Click", CopyText)
    g.AddButton("x+6 w110", "Time saved").OnEvent("Click", (*) => (CloseIt(), ShowTimeSaved()))
    g.AddButton("x+6 w80", "Close").OnEvent("Click", (*) => CloseIt())
    saveB.OnEvent("Click", Save)
    revB.OnEvent("Click", Undo)
    ed.OnEvent("Change", (*) => MarkDirty(true))
    g.OnEvent("Escape", (*) => CloseIt())
    g.OnEvent("Close", (*) => CloseIt())
    Fill()
    g.Show()
    ; cursor at the end (newest logs), nothing selected so a stray key can't replace everything
    ed.Focus()
    n := StrLen(ed.Value)
    SendMessage 0xB1, n, n, ed.Hwnd
    SendMessage 0xB7, 0, 0, ed.Hwnd

    ; Fills the window from the saved shift text
    Fill() {
        sv := SavedShift()
        st := JournalStats(file)
        h := "Shift started " st.started "`n" st.total " logs, " st.first " to " st.last
            . (st.ended != "" ? "   (ended " st.ended ")" : latest.open ? "   (still going)" : "")
        if sv.keys > 0
            h .= "`nTime saved this shift: " SavedTime(sv.keys) " (" Commas(sv.keys) " keystrokes)"
        headT.Text := h
        counts.Value := st.list
        ed.Value := StrReplace(shiftText, "`n", "`r`n")
        summary := st.summary
        MarkDirty(false)
    }
    MarkDirty(on) {
        dirty := on
        saveB.Enabled := on
        revB.Enabled := on
    }
    Undo(*) {
        ed.Value := StrReplace(shiftText, "`n", "`r`n")
        MarkDirty(false)
    }
    CopySummary(*) {
        if dirty
            summary := JournalSummaryOf(StrReplace(ed.Value, "`r`n", "`n"))
        A_Clipboard := summary
        Tip("Summary copied. Paste it with Ctrl+V.")
    }
    CopyText(*) {
        A_Clipboard := ed.Value
        Tip("Shift text copied.")
    }
    ; Writes the edited text back. A log that came in while this window was
    ; open is kept (it is added after your text); if the file changed in any
    ; other way nothing is written.
    Save(*) {
        edited := StrReplace(ed.Value, "`r`n", "`n")
        try {
            cur := FileRead(file, "UTF-8")
            cp := LastPos(cur, "=== Shift started")
            curPrefix := cp > 0 ? SubStr(cur, 1, cp - 1) : ""
            curShift := cp > 0 ? SubStr(cur, cp) : cur
            tail := ""
            if curShift == shiftText {
            } else if SubStr(curShift, 1, StrLen(shiftText)) == shiftText {
                tail := SubStr(curShift, StrLen(shiftText) + 1)
            } else {
                MsgBox "The journal file changed while this window was open (OneDrive or another program wrote to it), so your edits were not saved.`n`nUse Copy shift text to keep what you typed, close this window and open the journal again.", "Shift journal", "Icon!"
                return
            }
            if edited != "" && SubStr(edited, -1) != "`n"
                edited .= "`n"
            f := FileOpen(file, "w", "UTF-8")
            f.Write(curPrefix edited tail)
            f.Close()
            took := JournalApplyEdit(shiftText, edited, RegExMatch(file, "(\d{4}-\d\d-\d\d)\.txt$", &fd) ? fd[1] : FormatTime(, "yyyy-MM-dd"))
            shiftText := edited tail
        } catch as err {
            MsgBox "Couldn't save the journal:`n" file "`n`n" err.Message, "Shift journal", "Icon!"
            return
        }
        Activity("Shift journal edited and saved" (took.removed || took.added ? " (" took.removed " logs taken off the counts, " took.added " put on)" : ""))
        Fill()
        Tip("Journal saved" (took.removed || took.added ? ": " took.removed " taken off, " took.added " added to the counts" : ""))
    }
    CloseIt() {
        if dirty {
            r := MsgBox("Save your edits to the shift journal first?", "Shift journal", "YesNoCancel Icon?")
            if r = "Cancel"
                return
            if r = "Yes" {
                Save()
                if dirty
                    return
            }
        }
        g.Destroy()
    }
}

; The logs in some journal text: [{head, name, keys, tagged}] in order
JournalLogs(text) {
    logs := []
    p := LastPos(text, "=== Shift started")
    if p > 0
        text := SubStr(text, p)
    Loop Parse text, "`n", "`r" {
        if !RegExMatch(A_LoopField, "^(\d\d:\d\d) +(\S.*)$", &e)
            continue
        name := Trim(e[2]), keys := 0, tagged := false
        if RegExMatch(name, "\s*\[k(-?\d+)\]$", &k) {
            keys := Integer(k[1]), tagged := true
            name := Trim(SubStr(name, 1, k.Pos - 1))
        }
        logs.Push({head: A_LoopField, name: name, keys: keys, tagged: tagged})
    }
    return logs
}

; Logs in `a` that have no match left in `b` (matched by their whole first line)
LogsMissingFrom(a, b) {
    left := Map()
    for l in b
        left[l.head] := (left.Has(l.head) ? left[l.head] : 0) + 1
    miss := []
    for l in a {
        if left.Has(l.head) && left[l.head] > 0
            left[l.head] -= 1
        else
            miss.Push(l)
    }
    return miss
}

; What a log saved: its [k] tag, or (an older journal) the average for its type
LogKeys(l, day) {
    if l.tagged
        return l.keys
    it := ItemRow(IniRead(SavedFile, "DayItems", day "|" l.name, ""))
    if it.n < 1
        it := ItemRow(IniRead(SavedFile, "ShiftItems", l.name, ""))
    return it.n > 0 ? Round(it.keys / it.n) : 0
}

; The edit made in the journal window goes through to every count: Shift count,
; this shift, Time saved (day, week, month, since the start) and the dashboard.
; A log taken out comes off with its own keystrokes; one added by hand goes on
; with whatever its [k] tag says (none = 0). Returns {removed, added}.
JournalApplyEdit(oldText, newText, day) {
    oldL := JournalLogs(oldText), newL := JournalLogs(newText)
    gone := LogsMissingFrom(oldL, newL), came := LogsMissingFrom(newL, oldL)
    for l in gone
        AdjustCount(l.name, -1, -LogKeys(l, day), day)
    for l in came
        AdjustCount(l.name, 1, l.tagged ? l.keys : 0, day)
    return {removed: gone.Length, added: came.Length}
}

; Adds dn logs and dkeys keystrokes (either can be negative, never below 0)
; to the item in every tally
AdjustCount(name, dn, dkeys, day) {
    name := Trim(StrReplace(StrReplace(StrReplace(name, "=", "-"), "`n", " "), "`r"))
    try {
        inShift := CountBump("ShiftItems", name, dn, dkeys)
        CountBump("DayItems", day "|" name, dn, dkeys)
        d := SavedRow(IniRead(SavedFile, "Days", day, ""))
        d.log := Max(0, d.log + dn), d.keys := Max(0, d.keys + dkeys)
        IniWrite d.log "," d.login "," d.stamp "," d.keys, SavedFile, "Days", day
        ; this shift's totals only when this shift's item tally had the log
        ; (or, for an added log, while the shift is still going)
        if dn < 0 ? inShift : !IniRead(SavedFile, "Shift", "Ended", 0) {
            sh := SavedRow(IniRead(SavedFile, "Shift", "Counts", ""))
            sh.log := Max(0, sh.log + dn), sh.keys := Max(0, sh.keys + dkeys)
            IniWrite sh.log "," sh.login "," sh.stamp "," sh.keys, SavedFile, "Shift", "Counts"
        }
    }
}

; One "times,keystrokes" line: add dn / dkeys (clamped at 0, deleted at 0 times).
; Returns whether the line had anything in it before.
CountBump(section, key, dn, dkeys) {
    it := ItemRow(IniRead(SavedFile, section, key, ""))
    n := Max(0, it.n + dn), k := Max(0, it.keys + dkeys)
    if n = 0 {
        try IniDelete SavedFile, section, key
    } else {
        IniWrite n "," k, SavedFile, section, key
    }
    return it.n > 0
}

; The summary line for some journal text (Copy summary, for edited text)
JournalSummaryOf(text) => JournalStats("", text).summary


; =====================================================================
;  ALERT GRID - clear all   Ctrl+Alt+A
;  Does what you do by hand: Ctrl+A on the alert list, right-click,
;  "Acknowledge as received", Submit, OK. Works from any window: it brings
;  Alert Grid to the front, then puts you back where you were. It never
;  types a password (the Acknowledge box already has your login filled in).
;  It clears EVERYTHING in the list, so look at the list first.
;  Ctrl+Alt+Shift+A teaches it where to click, once per PC: you clear
;  alerts by hand and press F8 over five spots. Only numbers are kept
;  (%LOCALAPPDATA%\Watchlog\alertgrid.ini), positions inside each window.
;  v3.18.0: Alert Grid can be anywhere and any size. Spots in Alert Grid
;  are measured from the inside of the window (not its frame), the
;  clear-acknowledged button follows the edge it was nearest when the
;  window is resized, the menu line can be picked with the arrow keys
;  when the menu opens upward near the bottom of the screen, and one PC's
;  teach can be shared through the team folder (alertgrid.ini beside the
;  team templates file, one section per screen scaling) for PCs that
;  haven't been taught. A PC's own teach always wins.
; =====================================================================
; (set up by RegisterHotkeys, see HotkeyDefs)
; (set up by RegisterHotkeys, see HotkeyDefs)

AlertGridWin() {
    SetTitleMatchMode "RegEx"
    return WinExist("^Alert Grid \( ahk_exe javaw.exe")
}

; alertgrid.ini in the team folder (beside the team templates file), or ""
AlertTeamFile() {
    if Cfg["SharedTemplates"] = ""
        return ""
    SplitPath Cfg["SharedTemplates"], , &dir
    return dir = "" ? "" : dir "\alertgrid.ini"
}

; The team file's section for this PC's screen scaling (96 = 100%)
AlertTeamSection() => "Clicks-" A_ScreenDPI

; Where the taught clicks come from: "here" (this PC's own teach), "team"
; (the team copy for this screen scaling) or "" (not taught)
AlertTaught() {
    global AlertFile
    if FileExist(AlertFile) && IniRead(AlertFile, "Clicks", "RowX", "") != ""
        return "here"
    f := AlertTeamFile()
    try {
        if f != "" && FileExist(f) && IniRead(f, AlertTeamSection(), "RowX", "") != ""
            return "team"
    }
    return ""
}

; The taught clicks as a Map, or "" when there are none. An alertgrid.ini
; taught before v3.18.0 measured the Alert Grid spots from the window's
; outer corner: with Alert Grid open (grid) it's turned into
; inside-the-window numbers once and saved back. Until then (Alert Grid
; minimised) the old numbers are used the old way.
AlertLoad(grid := 0) {
    global AlertFile, ALERT_KEYS
    src := AlertTaught()
    if src = ""
        return ""
    f := src = "here" ? AlertFile : AlertTeamFile()
    sec := src = "here" ? "Clicks" : AlertTeamSection()
    c := Map("Src", src)
    try {
        for k in ALERT_KEYS
            c[k] := Trim(IniRead(f, sec, k, ""))
    } catch
        return ""
    ; the menu line set on this PC (Settings) wins over the team copy's
    if src = "team" && FileExist(AlertFile) {
        own := Trim(IniRead(AlertFile, "Clicks", "MenuLine", ""))
        if own != ""
            c["MenuLine"] := own
    }
    for k in ["RowX", "RowY", "MenuDX", "MenuDY", "SubmitX", "SubmitY"]
        if !IsInteger(c[k])
            return ""
    if c["Basis"] != "client" && src = "here" && grid && WinGetMinMax("ahk_id " grid) != -1 {
        WinGetPos &wx, &wy, , , "ahk_id " grid
        WinGetClientPos &cx, &cy, &cw, &ch, "ahk_id " grid
        ox := cx - wx, oy := cy - wy
        c["RowX"] := Integer(c["RowX"]) - ox, c["RowY"] := Integer(c["RowY"]) - oy
        if IsInteger(c["ClearX"]) && IsInteger(c["ClearY"])
            c["ClearX"] := Integer(c["ClearX"]) - ox, c["ClearY"] := Integer(c["ClearY"]) - oy
        c["GridW"] := cw, c["GridH"] := ch, c["Basis"] := "client"
        try {
            for k in ["RowX", "RowY", "ClearX", "ClearY", "GridW", "GridH", "Basis"]
                if c[k] != ""
                    IniWrite c[k], AlertFile, "Clicks", k
            Activity("Alert Grid: taught clicks changed to inside-the-window numbers (v3.18.0)")
        }
    }
    return c
}

; Where a taught Alert Grid spot (keys kx, ky) is on the screen now, in &x
; and &y. With inside-the-window numbers, a spot taught in the right half
; of Alert Grid keeps its distance from the right edge when the window is
; resized, and one in the bottom half from the bottom edge. topLeft keeps
; it measured from the top-left corner whatever (the alert rows: wider
; columns can leave blank space on the right that isn't a row).
; False when the spot falls outside the window as it is now.
AlertSpot(c, grid, kx, ky, topLeft, &x, &y) {
    tx := Integer(c[kx]), ty := Integer(c[ky])
    if c["Basis"] != "client" {
        WinGetPos &wx, &wy, &ww, &wh, "ahk_id " grid
        x := wx + tx, y := wy + ty
        return tx >= 0 && ty >= 0 && tx < ww && ty < wh
    }
    WinGetClientPos &cx, &cy, &cw, &ch, "ahk_id " grid
    w0 := IsInteger(c["GridW"]) ? Integer(c["GridW"]) : cw
    h0 := IsInteger(c["GridH"]) ? Integer(c["GridH"]) : ch
    if !topLeft && tx > w0 // 2
        tx := cw - (w0 - tx)
    if !topLeft && ty > h0 // 2
        ty := ch - (h0 - ty)
    x := cx + tx, y := cy + ty
    return tx >= 0 && ty >= 0 && tx < cw && ty < ch
}

; True when (x, y) is on one of the screens
AlertOnScreen(x, y) {
    loop MonitorGetCount() {
        MonitorGet A_Index, &l, &t, &r, &b
        if x >= l && x < r && y >= t && y < b
            return true
    }
    return false
}

; True when a right-click at (x, y) is likely to open its menu upward:
; Java does that when the menu doesn't fit between the spot and the bottom
; of the screen (above the taskbar). dy is how far down the taught menu
; line was; the 60 px is room for the lines below it.
AlertMenuFlips(x, y, dy) {
    loop MonitorGetCount() {
        MonitorGetWorkArea A_Index, &l, &t, &r, &b
        if x >= l && x < r && y >= t && y < b
            return y + dy + 60 > b
    }
    return false
}

; Picks line n of the open right-click menu with the arrow keys (the first
; Down lands on the top line), then Enter
AlertMenuKeys(n) {
    loop n {
        SendEvent "{Down}"
        Sleep 25
    }
    SendEvent "{Enter}"
}

; The menu line of "Acknowledge as received" set on this PC ("" = not set)
AlertMenuLine() {
    global AlertFile
    return FileExist(AlertFile) ? Trim(IniRead(AlertFile, "Clicks", "MenuLine", "")) : ""
}

; Waits for F8 or Ctrl+Alt+Shift+A (true), or Ctrl+Alt+Esc / 3 minutes (false).
; It reads the keys itself instead of using hotkeys, so it works whatever
; window is in front (a hotkey can't see keys typed into some Java windows).
TeachWait(msg) {
    Tip(msg, 0, true)
    KeyWait "F8"
    KeyWait "a"
    stop := A_TickCount + 180000
    ok := false, cancelled := false
    while A_TickCount < stop {
        if GetKeyState("F8", "P")
            || (GetKeyState("a", "P") && GetKeyState("Ctrl", "P") && GetKeyState("Alt", "P") && GetKeyState("Shift", "P")) {
            ok := true
            break
        }
        if GetKeyState("Esc", "P") && GetKeyState("Ctrl", "P") && GetKeyState("Alt", "P") {
            cancelled := true
            break
        }
        Sleep 30
    }
    Tip("")
    KeyWait "F8", "T2"
    KeyWait "a", "T2"
    if !ok {
        Tip(cancelled ? "Teach Alert Grid cancelled. Nothing saved." : "Teach Alert Grid timed out. Nothing saved.", 3000, true)
        Activity("Alert Grid teach: " (cancelled ? "cancelled" : "timed out"))
    } else
        Activity("Alert Grid teach: captured a spot")
    return ok
}

TeachAlerts() {
    global TeachBusy
    if TeachBusy
        return
    TeachBusy := true
    try TeachRun()
    catch as err
        MsgBox "Teach Alert Grid stopped: " err.Message, "Teach Alert Grid", "Icon!"
    TeachBusy := false
}

TeachRun() {
    global AlertFile
    if !AlertGridWin() {
        MsgBox "Open Alert Grid first, with at least one alert in the list.", "Teach Alert Grid", "Icon!"
        return
    }
    if MsgBox("This takes about a minute and you do it once on each PC (or once for the whole team, if you share it afterwards).`n`nYou will clear the alerts by hand, and at six points hover the mouse over the right spot and press F8, or Ctrl+Alt+Shift+A if F8 needs the Fn key (Ctrl+Alt+Esc cancels).`n`nAlert Grid needs at least one alert in the list. Start?", "Teach Alert Grid", "YesNo Icon?") != "Yes"
        return
    CoordMode "Mouse", "Screen"
    SetTitleMatchMode "RegEx"
    if !TeachWait("1 of 6`nHover over the TOP alert row in Alert Grid and press F8 (or Ctrl+Alt+Shift+A)   (Ctrl+Alt+Esc cancels)")
        return
    MouseGetPos &sx, &sy, &hwnd
    grid := AlertGridWin()
    if !grid {
        MsgBox "Alert Grid isn't open any more. Nothing saved.", "Teach Alert Grid", "Icon!"
        return
    }
    ; inside the window, so the frame (maximised or not) doesn't matter (v3.18.0)
    WinGetClientPos &gx, &gy, &gw, &gh, "ahk_id " grid
    rowx := sx - gx, rowy := sy - gy
    if !TeachWait("2 of 6`nNow press Ctrl+A, right-click the row, hover over 'Acknowledge as received' and press F8 (or Ctrl+Alt+Shift+A)   (do NOT click it yet)")
        return
    MouseGetPos &mx, &my
    dx := mx - sx, dy := my - sy
    if !TeachWait("3 of 6`nClick 'Acknowledge as received'. When the Acknowledge box shows, hover over Submit and press F8 (or Ctrl+Alt+Shift+A)   (do NOT click it yet)")
        return
    MouseGetPos &bx, &by
    dlg := WinExist("^Acknowledge$ ahk_exe javaw.exe")
    if !dlg {
        MsgBox "The Acknowledge box wasn't open. Nothing saved. Try again.", "Teach Alert Grid", "Icon!"
        return
    }
    WinGetPos &ax, &ay, , , "ahk_id " dlg
    try {
        IniWrite rowx, AlertFile, "Clicks", "RowX"
        IniWrite rowy, AlertFile, "Clicks", "RowY"
        IniWrite dx, AlertFile, "Clicks", "MenuDX"
        IniWrite dy, AlertFile, "Clicks", "MenuDY"
        IniWrite bx - ax, AlertFile, "Clicks", "SubmitX"
        IniWrite by - ay, AlertFile, "Clicks", "SubmitY"
        IniWrite gw, AlertFile, "Clicks", "GridW"
        IniWrite gh, AlertFile, "Clicks", "GridH"
        IniWrite "client", AlertFile, "Clicks", "Basis"
        IniWrite A_ScreenDPI, AlertFile, "Clicks", "DPI"
        ; an older teach's OK and clear button spots don't belong with these
        for k in ["OkX", "OkY", "ClearX", "ClearY", "NoMoreX", "NoMoreY", "NoMoreBox"]
            try IniDelete AlertFile, "Clicks", k
    } catch {
        MsgBox "Couldn't save the clicks to " AlertFile, "Teach Alert Grid", "Icon!"
        return
    }
    Activity("Alert Grid: clicks taught (row " rowx "," rowy "  menu " dx "," dy "  submit " bx - ax "," by - ay "  window " gw "x" gh ")")
    if !TeachWait("4 of 6`nNow click Submit. When the 'Acknowledgement Successful' box shows, hover over its OK button and press F8 (or Ctrl+Alt+Shift+A)   (do NOT click it yet)")
        return
    MouseGetPos &kx, &ky
    ok := WinExist("^Alert Grid$ ahk_exe javaw.exe")
    if !ok {
        MsgBox "The 'Acknowledgement Successful' box wasn't open. The first three clicks are saved, and Enter will be used for OK.`n`nClick OK now.", "Teach Alert Grid", "Icon!"
        return
    }
    WinGetPos &ox, &oy, , , "ahk_id " ok
    try {
        IniWrite kx - ox, AlertFile, "Clicks", "OkX"
        IniWrite ky - oy, AlertFile, "Clicks", "OkY"
    }
    Activity("Alert Grid: OK button taught (" kx - ox "," ky - oy ")")
    if !TeachWait("5 of 6`nClick OK. Then hover over the little button that clears the acknowledged alerts and press F8 (or Ctrl+Alt+Shift+A)   (do NOT click it yet)")
        return
    MouseGetPos &cx, &cy
    grid := AlertGridWin()
    if !grid {
        MsgBox "Alert Grid isn't open any more. The first four clicks are saved.", "Teach Alert Grid", "Icon!"
        return
    }
    WinGetClientPos &gx, &gy, &gw, &gh, "ahk_id " grid
    try {
        IniWrite cx - gx, AlertFile, "Clicks", "ClearX"
        IniWrite cy - gy, AlertFile, "Clicks", "ClearY"
        IniWrite gw, AlertFile, "Clicks", "GridW"
        IniWrite gh, AlertFile, "Clicks", "GridH"
    }
    Activity("Alert Grid: clear-acknowledged button taught (" cx - gx "," cy - gy ")")
    ; step 6 (v3.19.2): the box that says there are no more alerts
    if !TeachWait("6 of 6`nNow click that button. When the box about there being no more alerts shows, hover over its button and press F8 (or Ctrl+Alt+Shift+A)   (do NOT click it yet; Ctrl+Alt+Esc skips this step)")
        return AlertTeachDone()
    MouseGetPos &nx, &ny, &nwin
    nt := nwin ? WinGetTitle("ahk_id " nwin) : ""
    try {
        if SubStr(nt, 1, 12) = "Alert Grid (" {
            ; the button is inside Alert Grid itself
            grid := AlertGridWin()
            WinGetClientPos &gx, &gy, &gw, &gh, "ahk_id " grid
            IniWrite nx - gx, AlertFile, "Clicks", "NoMoreX"
            IniWrite ny - gy, AlertFile, "Clicks", "NoMoreY"
            try IniDelete AlertFile, "Clicks", "NoMoreBox"
            Activity("Alert Grid: no-more-alerts button taught inside the window (" nx - gx "," ny - gy ")")
        } else if nt != "" {
            WinGetPos &wx, &wy, , , "ahk_id " nwin
            IniWrite nx - wx, AlertFile, "Clicks", "NoMoreX"
            IniWrite ny - wy, AlertFile, "Clicks", "NoMoreY"
            IniWrite nt, AlertFile, "Clicks", "NoMoreBox"
            Activity("Alert Grid: no-more-alerts box taught (" nt ", button " nx - wx "," ny - wy ")")
        } else
            MsgBox "That box wasn't open. This step isn't saved.", "Teach Alert Grid", "Icon!"
    }
    AlertTeachDone()
}

AlertTeachDone() {
    MsgBox "Saved. Now click that button yourself to finish.", "Teach Alert Grid"
    AskMenuLine()
    MsgBox "All done. From now on Ctrl+Alt+A does all of it, wherever Alert Grid is and whatever its size.`n`nSo teammates' PCs don't have to be taught: tray > Alert Grid > Share my setup with the team.", "Teach Alert Grid"
}

; The last teach question: which line of the right-click menu
; "Acknowledge as received" is (used with the arrow keys when the menu
; opens upward). Blank = not used.
AskMenuLine() {
    global AlertFile
    r := InputBox("Last question. In Alert Grid's right-click menu, which line is 'Acknowledge as received'? Count from the top (1 = the top line).`n`nIt's used with the arrow keys when Alert Grid is near the bottom of the screen and the menu opens upward. Leave it blank if you're not sure.", "Teach Alert Grid", "w440 h210", AlertMenuLine())
    if r.Result != "OK"
        return
    n := Trim(r.Value)
    if n = "" {
        try IniDelete AlertFile, "Clicks", "MenuLine"
        return
    }
    if !IsInteger(n) || n < 1 || n > 20 {
        MsgBox "That isn't a line number, so the arrow keys won't be used. You can type it later in Settings > Alert Grid.", "Teach Alert Grid", "Icon!"
        return
    }
    try IniWrite Integer(n), AlertFile, "Clicks", "MenuLine"
    Activity("Alert Grid: menu line set to " Integer(n))
}

; Puts this PC's taught clicks in alertgrid.ini in the team folder, under
; this PC's screen scaling, so PCs that haven't been taught use them.
; Numbers only. A PC's own teach always wins over the team copy.
ShareAlertSetup() {
    global AlertFile, ALERT_KEYS
    f := AlertTeamFile()
    if f = "" {
        MsgBox "There's no team folder set up (the team templates file in Settings), so there's nowhere to share it.", "Share Alert Grid setup", "Icon!"
        return
    }
    if AlertTaught() != "here" {
        MsgBox "Alert Grid isn't taught on this PC, so there's nothing of this PC's to share. Teach it first (Ctrl+Alt+Shift+A).", "Share Alert Grid setup", "Icon!"
        return
    }
    c := AlertLoad(AlertGridWin())
    if !c || c["Basis"] != "client" {
        MsgBox "Open Alert Grid first (not minimised): this PC's numbers were taught by an older version and it needs the window once to update them. Then try again.", "Share Alert Grid setup", "Icon!"
        return
    }
    sec := AlertTeamSection()
    scale := Round(A_ScreenDPI / 96 * 100)
    if MsgBox("Share this PC's Alert Grid clicks with the team?`n`nThey go in " f " for screens at " scale "% scaling. PCs that haven't been taught use them; a PC that has been taught keeps its own.`n`nOnly click positions are saved (numbers): no names, logins or passwords.", "Share Alert Grid setup", "YesNo Icon?") != "Yes"
        return
    try {
        for k in ALERT_KEYS {
            if c[k] != ""
                IniWrite c[k], f, sec, k
            else
                try IniDelete f, sec, k
        }
    } catch as e {
        MsgBox "Couldn't write to the team folder:`n" e.Message "`n`nIf OneDrive is syncing, try again in a moment.", "Share Alert Grid setup", "Icon!"
        return
    }
    Activity("Alert Grid: shared this PC's clicks with the team (" scale "% scaling)")
    MsgBox "Shared. PCs that haven't been taught now clear alerts with these clicks (once OneDrive has synced the team folder).`n`nA PC with different screen scaling still needs its own teach, and can share it the same way.", "Share Alert Grid setup"
}

ClearAlerts() {
    global AlertFile
    if AlertTaught() = "" {
        MsgBox "Alert Grid clicks haven't been taught on this PC yet (and the team folder has none for this screen).`n`nPress Ctrl+Alt+Shift+A once and follow the steps.", "Clear alerts", "Icon!"
        return
    }
    grid := AlertGridWin()
    if !grid {
        Tip("Alert Grid isn't open.", 2000, true)
        return
    }
    c := AlertLoad(grid)
    if !c {
        MsgBox "The taught Alert Grid clicks can't be read. Teach them again (Ctrl+Alt+Shift+A).", "Clear alerts", "Icon!"
        return
    }
    dx := Integer(c["MenuDX"]), dy := Integer(c["MenuDY"])
    subx := Integer(c["SubmitX"]), suby := Integer(c["SubmitY"])
    okx := c["OkX"], oky := c["OkY"]
    line := IsInteger(c["MenuLine"]) && c["MenuLine"] > 0 ? Integer(c["MenuLine"]) : 0
    ; wait for Ctrl/Alt/Shift/Caps Lock to come up first: while they're held,
    ; Alert Grid can see Ctrl+Alt+A (or nothing) instead of Ctrl+A (v3.17.1)
    ; (all together, at most 250 ms in all, so a held key can't slow it down)
    ; (Caps Lock isn't waited for: it can't turn Ctrl+A into something else)
    held := A_TickCount + 250
    while A_TickCount < held && (GetKeyState("Ctrl", "P") || GetKeyState("Alt", "P") || GetKeyState("Shift", "P"))
        Sleep 5
    prev := WinExist("A")
    CoordMode "Mouse", "Screen"
    CoordMode "Pixel", "Screen"
    MouseGetPos &ox, &oy
    wasMin := WinGetMinMax("ahk_id " grid) = -1
    if wasMin
        WinRestore "ahk_id " grid
    WinActivate "ahk_id " grid
    if !WinWaitActive("ahk_id " grid, , 2) {
        Tip("Couldn't bring Alert Grid to the front.", 2500, true)
        return
    }
    if wasMin && c["Basis"] != "client"
        c := AlertLoad(grid)    ; it was minimised: now old numbers can be changed over
    ; where the top alert row is now, wherever Alert Grid is and whatever its size
    if !AlertSpot(c, grid, "RowX", "RowY", true, &px, &py) {
        Tip("Alert Grid is too small for the taught spot. Make it bigger, or teach the clicks again.", 3500, true)
        Activity("Alert Grid: not cleared (window smaller than the taught row spot)")
        AlertBack(prev, grid)
        return
    }
    if !AlertOnScreen(px, py) {
        Tip("Alert Grid's alert list is off the screen. Drag Alert Grid back onto the screen.", 3500, true)
        Activity("Alert Grid: not cleared (alert list off the screen)")
        AlertBack(prev, grid)
        return
    }
    WinGetClientPos , &cy0, , &ch0, "ahk_id " grid
    bottom := cy0 + ch0
    ; near the bottom of the screen Java opens the menu upward, so the taught
    ; menu spot would miss: use the arrow keys there (when the line is known)
    useKeys := line && AlertMenuFlips(px, py, dy)
    keysUsed := false
    ackedFirst := false
    done := false
    checked := false
    ; A new alert arriving while this runs re-draws the list and drops the
    ; selection, so everything here is fast, and if the Acknowledge box or
    ; the "Successful" box doesn't turn up it starts again (up to 3 tries).
    ; [AlertGrid] Pause= in settings.ini is the wait between clicks in ms
    ; (default 40; raise it if a click lands before the menu is up).
    gap := Integer(IniRead(SettingsFile, "AlertGrid", "Pause", "40"))
    ; [AlertGrid] SelectWait= (ms) is the most it waits for Ctrl+A to show
    ; before the right-click (v3.17.1: it now watches the list turn blue
    ; instead of just waiting, and presses Ctrl+A again if it didn't take.
    ; One alert never changes colour, so 300 ms is all that case costs: v3.17.2)
    selWait := Integer(IniRead(SettingsFile, "AlertGrid", "SelectWait", "120"))
    SetMouseDelay 0
    SetKeyDelay 0
    attempts := 0
    lostFront := false
    while !done && attempts < 3 {
        attempts += 1
        try {
            ; a pop-up that took the front: stop before clicking anything (v3.27.0)
            if !GridFront(grid) {
                lostFront := true
                break
            }
            Click px, py
            Sleep gap
            ; the rows under the clicked one, before and after Ctrl+A: when
            ; there's more than one alert they turn blue, so a change means
            ; the whole list is selected. No change = one alert, or Ctrl+A
            ; was missed, so it presses Ctrl+A again halfway through the wait.
            before := AlertColumn(px, py, bottom)
            AlertSelectAll()
            ; a lone alert is already blue from the click, so nothing can change:
            ; when the column under the row is one plain colour, wait only a moment (v3.17.3)
            lone := AlertIsPlain(before)
            stop := A_TickCount + (lone ? Min(selWait, 40) : selWait), again := lone ? 0 : A_TickCount + selWait // 2
            checked := false
            while A_TickCount < stop {
                Sleep 3
                if AlertColumn(px, py, bottom) != before {
                    checked := true
                    break
                }
                if again && A_TickCount >= again {
                    AlertSelectAll()
                    again := 0
                }
            }
            if !GridFront(grid) {
                lostFront := true
                break
            }
            Click px, py, "Right"
            Sleep gap * 2
            if useKeys {
                AlertMenuKeys(line)
                keysUsed := true
            } else
                Click px + dx, py + dy
            dlg := WinWait("^Acknowledge$ ahk_exe javaw.exe", , 1.5)
            if !dlg {
                Send "{Escape}"
                ; Alert Grid only lets you right-click unacknowledged alerts: with
                ; acknowledged ones in the selection the menu doesn't open. Clear
                ; the acknowledged ones first (once), then go again (v3.24.1)
                if !ackedFirst && IsInteger(c["ClearX"]) && IsInteger(c["ClearY"]) {
                    ackedFirst := true
                    if WinExist("ahk_id " grid) {
                        WinActivate "ahk_id " grid
                        WinWaitActive "ahk_id " grid, , 2
                    }
                    cleared := AlertClearAcked(c, grid, gap, false)
                    Activity("Alert Grid: the right-click menu didn't open, so the acknowledged alerts were cleared first" (cleared ? "" : " (the clear button spot was outside the window)"))
                    if cleared {
                        attempts -= 1       ; this try doesn't count against the three
                        continue
                    }
                }
                ; the menu spot missed (menu somewhere else): try the arrow keys next time
                if line && !useKeys
                    useKeys := true
                if attempts = 3
                    Tip("Nothing to clear (or the menu didn't open).", 2500, true)
                continue
            }
            WinGetPos &ax, &ay, , , "ahk_id " dlg
            Click ax + subx, ay + suby
            ok := WinWait("^Alert Grid$ ahk_exe javaw.exe", , 3)
            if !ok {
                ; the box is still open (Submit didn't take): close it and go again
                if WinExist("ahk_id " dlg) {
                    WinActivate "ahk_id " dlg
                    Send "{Escape}"
                    WinWaitClose "ahk_id " dlg, , 1
                }
                if attempts = 3
                    Tip("The 'Acknowledgement Successful' box didn't show. Check Alert Grid.", 3500, true)
                continue
            }
            WinActivate "ahk_id " ok
            if IsInteger(okx) && IsInteger(oky) {
                WinGetPos &kx, &ky, , , "ahk_id " ok
                Click kx + Integer(okx), ky + Integer(oky)
            } else
                Send "{Enter}"
            WinWaitClose "ahk_id " ok, , 2
            done := true
            ; the little button that clears the acknowledged alerts (the ones just
            ; acknowledged), then the "no more alerts" step. Always: also after the
            ; acknowledged ones were cleared first, below (v3.26.1)
            AlertClearAcked(c, grid, gap)
        }
    }
    if lostFront {
        Tip("Alert Grid lost the front, so the clear was stopped. Press it again.", 3500, true)
        Activity("Alert Grid: stopped, a window took the front before a click")
    }
    ; only acknowledged alerts were there: they were cleared first, so finish with
    ; the "no more alerts" step
    if !done && ackedFirst {
        AlertClearAcked(c, grid, gap)
        done := true
    }
    if done {
        Tip("Alerts cleared", 1000)
        Activity("Alert Grid: cleared all alerts" (keysUsed ? " (picked the menu line with the arrow keys)" : "")
            . (c["Src"] = "team" ? " (team setup)" : "")
            . (checked ? "" : " (list didn't change colour after Ctrl+A: only one alert, or Ctrl+A missed)"))
        CountSaved("", 3, "Alert Grid clear")   ; keystrokes only: a clear isn't a log, a login or a stamp
    } else {
        Activity("Alert Grid: clear all didn't finish" (line ? "" : " (no menu line set for the arrow keys: Settings > Alert Grid)"))
    }
    MouseMove ox, oy, 0
    AlertBack(prev, grid)
}

; Clears the acknowledged alerts: the little button (it follows the edge it was
; nearest when Alert Grid has been resized), then the "no more alerts" box or
; button. Returns true when the clear button was clicked.
AlertClearAcked(c, grid, gap, noMore := true) {
    clicked := false
    ; the little button that clears the acknowledged alerts (it follows
    ; the edge it was nearest when Alert Grid has been resized)
    if IsInteger(c["ClearX"]) && IsInteger(c["ClearY"]) && WinExist("ahk_id " grid) {
        WinActivate "ahk_id " grid
        WinWaitActive "ahk_id " grid, , 2
        if AlertSpot(c, grid, "ClearX", "ClearY", false, &bx, &by) {
            Click bx, by
            clicked := true
            Sleep gap
        } else
            Activity("Alert Grid: the clear-acknowledged button spot is outside the window now (skipped it)")
    }
    ; the box (or button) that says there are no more alerts (v3.19.2).
    ; Only if it was taught; an older teach skips it.
    if noMore && IsInteger(c["NoMoreX"]) && IsInteger(c["NoMoreY"]) {
        if c["NoMoreBox"] != "" {
            SetTitleMatchMode 3
            nb := WinWait(c["NoMoreBox"] " ahk_exe javaw.exe", , 2)
            SetTitleMatchMode "RegEx"
            if nb {
                WinActivate "ahk_id " nb
                WinGetPos &nbx, &nby, , , "ahk_id " nb
                Click nbx + Integer(c["NoMoreX"]), nby + Integer(c["NoMoreY"])
                WinWaitClose "ahk_id " nb, , 1
            }
        } else if WinExist("ahk_id " grid) && AlertSpot(c, grid, "NoMoreX", "NoMoreY", false, &nmx, &nmy) {
            ; the box needs a moment to come up after the clear button (v3.27.3)
            Sleep Max(gap * 4, 250)
            Click nmx, nmy
            Sleep gap
        }
    }

    return clicked
}

; The Windows display scale is different from when the iTrak or Alert Grid
; clicks were taught: they would land in the wrong place (v3.27.0)
CheckScale() {
    msgs := ""
    for pair in [[ITrakFile, "iTrak"], [AlertFile, "Alert Grid"]] {
        d := ""
        try d := IniRead(pair[1], "Clicks", "DPI", "")
        if IsInteger(d) && d != A_ScreenDPI
            msgs .= pair[2] " was taught at " Round(d / 96 * 100) "% scaling, the screen is at " Round(A_ScreenDPI / 96 * 100) "% now.`n"
    }
    if msgs = ""
        return
    Activity("Display scale changed since the clicks were taught: " StrReplace(RTrim(msgs, "`n"), "`n", " "))
    TrayTip msgs "Teach them again if a click lands in the wrong place.", "Watchlog: display scale", "Icon!"
}

; Alert Grid in front (it gets one second to come back)
GridFront(grid) {
    if WinActive("ahk_id " grid)
        return true
    ; the "no more alerts" box closing right after the last click can hold the
    ; front for a moment: try again for up to 2 seconds before giving up (v3.27.3)
    loop 4 {
        try WinActivate "ahk_id " grid
        if WinWaitActive("ahk_id " grid, , 0.5)
            return true
    }
    return false
}

; Puts back the window that was in front before a clear
AlertBack(prev, grid) {
    if prev && prev != grid && WinExist("ahk_id " prev)
        try WinActivate "ahk_id " prev
}

; Ctrl+A held down long enough for Java to see it (a fast SendInput burst
; can slip past Alert Grid)
AlertSelectAll() {
    SendEvent "{Ctrl down}"
    Sleep 5
    SendEvent "{a down}"
    Sleep 10
    SendEvent "{a up}"
    Sleep 5
    SendEvent "{Ctrl up}"
}

; True when every sampled colour in AlertColumn's string is the same
AlertIsPlain(col) {
    first := ""
    loop parse col, "," {
        if A_LoopField = ""
            continue
        if first = ""
            first := A_LoopField
        else if A_LoopField != first
            return false
    }
    return true
}

; The screen colours down a line from just under the clicked row to the
; bottom of the window (5 points down the list, so 5 reads: it has
; to stay quick when alerts arrive many a second), as one string
AlertColumn(x, y, bottom) {
    s := ""
    for off in [12, 24, 40, 80, 140] {
        if y + off < bottom - 8
            try s .= PixelGetColor(x, y + off) ","
    }
    return s
}

; =====================================================================
;  ITRAK - new daily log   Ctrl+Alt+D
;  iTrak has no keyboard shortcut for it, so Watchlog does the mouse
;  click(s) for you: it brings iTrak (the Citrix window) to the front,
;  moves to the spot you taught and clicks. Ctrl+Alt+Shift+I teaches it
;  the spot once per PC: you hover over the "new daily log" button and
;  press F8 (and over the menu line after it, if it takes two clicks).
;  Only numbers are kept (%LOCALAPPDATA%\Watchlog\itrak.ini), measured
;  from the inside of the iTrak window, so the window can be anywhere. A
;  spot taught near the right or bottom edge follows that edge if the
;  window is resized. Tray > iTrak > Share my setup with the team puts the
;  numbers in itrak.ini in the team folder (per screen scaling) for PCs
;  that haven't been taught. A PC's own teach always wins.
; =====================================================================
; (set up by RegisterHotkeys, see HotkeyDefs)
; (set up by RegisterHotkeys, see HotkeyDefs)

; iTrak is a Citrix window (wfica32.exe) titled like
; "iTrak - [Daily Log] - \\Remote". [ITrak] Window= in settings.ini changes
; what it looks for (part of the title, then "ahk_exe ...")
ITrakWin() {
    SetTitleMatchMode 2
    spec := Trim(IniRead(SettingsFile, "ITrak", "Window", "iTrak ahk_exe wfica32.exe"))
    return WinExist(spec)
}

; itrak.ini in the team folder (beside the team templates file), or ""
ITrakTeamFile() {
    if Cfg["SharedTemplates"] = ""
        return ""
    SplitPath Cfg["SharedTemplates"], , &dir
    return dir = "" ? "" : dir "\itrak.ini"
}

ITrakTeamSection() => "Clicks-" A_ScreenDPI

; "here" (this PC's own teach), "team" (the team copy for this screen
; scaling) or "" (not taught)
ITrakTaught() {
    global ITrakFile
    try {
        if FileExist(ITrakFile) && IniRead(ITrakFile, "Clicks", "X1", "") != ""
            return "here"
        f := ITrakTeamFile()
        if f != "" && FileExist(f) && IniRead(f, ITrakTeamSection(), "X1", "") != ""
            return "team"
    }
    return ""
}

; The taught spots as a Map (X1 Y1 X2 Y2 W H Clicks), or "" when none
ITrakLoad() {
    global ITrakFile
    src := ITrakTaught()
    if src = ""
        return ""
    f := src = "here" ? ITrakFile : ITrakTeamFile()
    sec := src = "here" ? "Clicks" : ITrakTeamSection()
    c := Map("Src", src)
    try {
        for k in ["X1", "Y1", "X2", "Y2", "W", "H", "Clicks"]
            c[k] := Trim(IniRead(f, sec, k, ""))
    } catch
        return ""
    for k in ["X1", "Y1", "W", "H"]
        if !IsInteger(c[k])
            return ""
    c["Clicks"] := c["Clicks"] = "2" && IsInteger(c["X2"]) && IsInteger(c["Y2"]) ? 2 : 1
    return c
}

; Where a spot taught inside the iTrak window (tx, ty, window w0 x h0 then)
; is on the screen now. A spot in the right half keeps its distance from the
; right edge when the window is resized, one in the bottom half from the
; bottom edge. False when it falls outside the window as it is now.
ITrakSpot(hwnd, tx, ty, w0, h0, &x, &y) {
    WinGetClientPos &cx, &cy, &cw, &ch, "ahk_id " hwnd
    if tx > w0 // 2
        tx := cw - (w0 - tx)
    if ty > h0 // 2
        ty := ch - (h0 - ty)
    x := cx + tx, y := cy + ty
    return tx >= 0 && ty >= 0 && tx < cw && ty < ch
}

ITrakNewLog(count := true) {
    c := ITrakLoad()
    if !c {
        MsgBox "iTrak's new daily log click hasn't been taught on this PC yet (and the team folder has none for this screen).`n`nPress Ctrl+Alt+Shift+I once and follow the steps.", "New iTrak daily log", "Icon!"
        return false
    }
    win := ITrakWin()
    if !win {
        Tip("iTrak isn't open.", 2000, true)
        return false
    }
    ; let go of Ctrl/Alt first so the click isn't a Ctrl+Alt+click (at most 250 ms)
    held := A_TickCount + 250
    while A_TickCount < held && (GetKeyState("Ctrl", "P") || GetKeyState("Alt", "P") || GetKeyState("Shift", "P"))
        Sleep 10
    CoordMode "Mouse", "Screen"
    MouseGetPos &ox, &oy
    wasActive := WinActive("ahk_id " win)
    if WinGetMinMax("ahk_id " win) = -1
        WinRestore "ahk_id " win
    WinActivate "ahk_id " win
    if !WinWaitActive("ahk_id " win, , 2) || !WinActive("ahk_id " win) {
        Tip("Couldn't bring iTrak to the front.", 2500, true)
        return false
    }
    if !wasActive
        Sleep 300    ; Citrix needs a moment to take the keyboard and mouse
    pause := Integer(IniRead(SettingsFile, "ITrak", "Pause", "300"))
    w0 := Integer(c["W"]), h0 := Integer(c["H"])
    WinGetClientPos , , &cw, &ch, "ahk_id " win
    if StrLower(Trim(IniRead(SettingsFile, "ITrak", "RefuseIfResized", "no"))) ~= "^(yes|on|1|true)$" && (Abs(cw - w0) > 2 || Abs(ch - h0) > 2) {
        Tip("The iTrak window isn't the size it was when taught (" cw "x" ch " now, " w0 "x" h0 " then). Put it back, or teach again.", 4000, true)
        Activity("iTrak new daily log: not clicked (window " cw "x" ch ", taught at " w0 "x" h0 ")")
        return false
    }
    n := c["Clicks"]
    loop n {
        k := A_Index
        if !ITrakSpot(win, Integer(c["X" k]), Integer(c["Y" k]), w0, h0, &x, &y) || !AlertOnScreen(x, y) {
            Tip("The iTrak window is too small for the taught spot (or off the screen). Make it bigger, or teach again.", 4000, true)
            Activity("iTrak new daily log: not clicked (spot " k " outside the window)")
            MouseMove ox, oy, 0
            return false
        }
        if !WinActive("ahk_id " win) {
            Tip("iTrak lost the front. Nothing more was clicked.", 3000, true)
            Activity("iTrak new daily log: stopped before click " k " (iTrak lost the front)")
            return false
        }
        if k > 1
            Sleep pause
        MouseMove x, y, 0
        Sleep 60
        Click
    }
    Sleep 60
    MouseMove ox, oy, 0
    if count
        Tip("New daily log", 1000)
    Activity("iTrak: new daily log clicked (" n " click" (n = 1 ? "" : "s") ", window " cw "x" ch ")" (c["Src"] = "team" ? " (team setup)" : ""))
    if count
        CountSaved("", 2, "iTrak new daily log")
    return true
}

; =====================================================================
;  FULL-ENTRY DAILY LOGS  -  Ctrl+Alt+F picks one, Ctrl+Alt+Shift+F teaches  (v3.20.0)
;  For logs that never change (Break, Table Drop, Card Destruction...):
;  +Break = Surveillance | Duty | NA | Break    in templates.txt
;  Ctrl+Alt+F shows the list; type the first letters, Enter. Watchlog
;  clicks New daily log (taught with Ctrl+Alt+Shift+I), waits for the new
;  "Daily Log Entry" window to open, then clicks each
;  field it was taught (Ctrl+Alt+Shift+F: open a daily log, hover over
;  Location, Topic, Reference and Synopsis, F8 on each) and types the
;  wording: the drop-downs are typed in full and accepted with Enter, the
;  Reference is typed, the Synopsis is pasted. End Time is left alone and
;  nothing is saved: you click Now and Save yourself. Spots are numbers
;  measured from inside that Daily Log Entry window, so it can open anywhere.
; =====================================================================
; (set up by RegisterHotkeys, see HotkeyDefs)
; (set up by RegisterHotkeys, see HotkeyDefs)

EntryFields := ["Location", "Topic", "Reference", "Synopsis"]

; The daily log form opens as its OWN Citrix window, titled like
; "Daily Log Entry - N/A - \\Remote" (not "iTrak"), so the field spots are
; measured from it and not from the main iTrak window (v3.20.1).
; [ITrak] EntryWindow= changes what it looks for.
EntryWin() {
    SetTitleMatchMode 2
    spec := Trim(IniRead(SettingsFile, "ITrak", "EntryWindow", "Daily Log Entry ahk_exe wfica32.exe"))
    return WinExist(spec)
}

; Every open daily log form's window id, as a Map
EntryWins() {
    SetTitleMatchMode 2
    m := Map()
    spec := Trim(IniRead(SettingsFile, "ITrak", "EntryWindow", "Daily Log Entry ahk_exe wfica32.exe"))
    for h in WinGetList(spec)
        m[h] := true
    return m
}

; The taught field spots as a Map (LocX LocY ... W H), or "" when none
EntryLoad() {
    global ITrakFile, EntryFields
    c := Map()
    try {
        for k in EntryFields
            for ax in ["X", "Y"]
                c[k ax] := Trim(IniRead(ITrakFile, "Fields", k ax, ""))
        c["W"] := Trim(IniRead(ITrakFile, "Fields", "W", ""))
        c["H"] := Trim(IniRead(ITrakFile, "Fields", "H", ""))
    } catch
        return ""
    for k, v in c
        if !IsInteger(v)
            return ""
    ; End Time's Now button (v3.20.2): optional, only for logs that end with | end
    try {
        ex := Trim(IniRead(ITrakFile, "Fields", "EndNowX", "")), ey := Trim(IniRead(ITrakFile, "Fields", "EndNowY", ""))
        if IsInteger(ex) && IsInteger(ey)
            c["EndNowX"] := ex, c["EndNowY"] := ey
    }
    return c
}

EntryPickWin := ""

#HotIf IsObject(EntryPickWin) && WinActive("ahk_id " EntryPickWin.gui.Hwnd)
Down:: EntryPickMove(1)
Up:: EntryPickMove(-1)
#HotIf

ShowEntryPick() {
    global EntryPickWin
    if IsObject(EntryPickWin) {
        try WinActivate "ahk_id " EntryPickWin.gui.Hwnd
        return
    }
    if !Entries.Length {
        MsgBox "There are no full-entry logs yet.`n`nAdd lines to templates.txt like:`n+Break = Surveillance | Duty | NA | Break`n(Location | Topic | Reference | Synopsis), then press Ctrl+Alt+R.", "Full-entry logs", "Icon!"
        return
    }
    target := WinExist("A")
    g := WGui("+AlwaysOnTop +ToolWindow", "Full-entry daily log")
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 14, g.MarginY := 12
    g.AddText(, "Type the first letters, then Enter. It opens a new daily log in iTrak and fills it in.")
    ed := g.AddEdit("w380")
    lb := g.AddListBox("w380 r" Min(Max(Entries.Length, 3), 10))
    g.AddButton("Default w100", "Run").OnEvent("Click", Run)
    g.AddButton("x+8 yp w100", "Cancel").OnEvent("Click", Cancel)
    shown := []
    EntryPickWin := {gui: g, lb: lb}
    ed.OnEvent("Change", Refill)
    g.OnEvent("Escape", Cancel)
    g.OnEvent("Close", Cancel)
    Refill()
    g.Show()

    Refill(*) {
        typed := StrLower(Trim(ed.Text))
        shown := []
        for e in Entries
            if typed = "" || InStr(StrLower(e.name), typed) = 1
                shown.Push(e)
        for e in Entries
            if typed != "" && InStr(StrLower(e.name), typed) > 1
                shown.Push(e)
        lb.Delete()
        names := []
        for e in shown
            names.Push(e.name)
        if names.Length {
            lb.Add(names)
            lb.Choose(1)
        }
    }
    Cancel(*) {
        global EntryPickWin
        EntryPickWin := ""
        g.Destroy()
    }
    Run(*) {
        global EntryPickWin
        i := lb.Value
        if !i || i > shown.Length
            return
        e := shown[i]
        EntryPickWin := ""
        g.Destroy()
        try WinActivate "ahk_id " target
        RunEntry(e)
    }
}

EntryPickMove(d) {
    lb := EntryPickWin.lb
    n := SendMessage(0x18B, 0, 0, lb.Hwnd)      ; LB_GETCOUNT
    if n < 1
        return
    i := lb.Value + d
    lb.Choose(Max(1, Min(n, i)))
}

; The bay entered at the start of this shift (last 14 hours), or "" when none
SavedBay() {
    try {
        v := Trim(IniRead(LastUsedFile, "LastUsed", "Bay", ""))
        at := IniRead(LastUsedFile, "LastUsed", "Bay.at", "")
        if v != "" && IsTimeStamp(at) && DateDiff(A_Now, at, "Hours") < 14
            return v
    }
    return ""
}

; Fills a new daily log. Keys counted as saved: 5 for each drop-down (a
; few letters, Enter, the click), the full length of the Reference and
; the Synopsis plus a click each, and the 2 for the new-log click.
RunEntry(e, useOpen := false) {
    global EntryFields, LastRun
    f := EntryLoad()
    if !f {
        MsgBox "The daily log fields haven't been taught on this PC yet.`n`nOpen a new daily log in iTrak, then press Ctrl+Alt+Shift+F and follow the steps.", "Full-entry daily log", "Icon!"
        return
    }
    syn := e.syn
    ; {Bay?}: always asks which bay (start of shift), offering the last one,
    ; and keeps the answer for the rest of the shift (v3.20.3)
    if InStr(syn, "{Bay?}") {
        last := ""
        try last := Trim(IniRead(LastUsedFile, "LastUsed", "Bay", ""))
        ib := InputBox("Which bay are you on?`n`nKept for the rest of the shift.", "Watchlog - " e.name, "w320 h160", last)
        if ib.Result != "OK" || Trim(ib.Value) = ""
            return
        bay := Trim(ib.Value)
        try {
            if !DirExist(DataDir)
                DirCreate DataDir
            IniWrite bay, LastUsedFile, "LastUsed", "Bay"
            IniWrite A_Now, LastUsedFile, "LastUsed", "Bay.at"
        }
        syn := StrReplace(syn, "{Bay?}", bay)
    }
    if InStr(syn, "{Bay}") {
        bay := SavedBay()
        if bay = "" {
            ib := InputBox("Which bay are you on? (Start of shift keeps it for the rest of the shift.)", "Watchlog - " e.name, "w320 h140")
            if ib.Result != "OK" || Trim(ib.Value) = ""
                return
            bay := Trim(ib.Value)
            try {
                if !DirExist(DataDir)
                    DirCreate DataDir
                IniWrite bay, LastUsedFile, "LastUsed", "Bay"
                IniWrite A_Now, LastUsedFile, "LastUsed", "Bay.at"
            }
        }
        syn := StrReplace(syn, "{Bay}", bay)
    }
    ; a code word (useOpen) fills the daily log that is already open (the one in
    ; front if there are several), and opens a new one only when none is (v3.24.0)
    win := 0
    if useOpen {
        ents := EntryWins()
        act := WinExist("A")
        if ents.Has(act)
            win := act
        else
            for h in ents {
                win := h
                break
            }
    }
    if !win {
        before := EntryWins()
        if !ITrakNewLog(false)
            return
        ; wait (at most EntryWait ms) for the NEW Daily Log Entry window
        wait := Integer(IniRead(SettingsFile, "ITrak", "EntryWait", "8000"))
        deadline := A_TickCount + wait
        while !win && A_TickCount < deadline {
            for h in EntryWins()
                if !before.Has(h)
                    win := h
            if !win
                Sleep 100
        }
        if !win {
            Tip("The new daily log window didn't open. Nothing was filled in.", 4000, true)
            Activity("Full-entry log " e.name ": no new Daily Log Entry window appeared within " wait " ms")
            return
        }
        Sleep Integer(IniRead(SettingsFile, "ITrak", "EntrySettle", "600"))      ; let it finish drawing
    }
    try WinActivate "ahk_id " win
    if !WinWaitActive("ahk_id " win, , 3) {
        Tip("Couldn't bring the daily log to the front. Nothing was filled in.", 4000, true)
        Activity("Full-entry log " e.name ": couldn't activate the Daily Log Entry window")
        return
    }
    w0 := Integer(f["W"]), h0 := Integer(f["H"])
    CoordMode "Mouse", "Screen"
    MouseGetPos &ox, &oy
    vals := Map("Location", e.loc, "Topic", e.topic, "Reference", e.ref, "Synopsis", syn)
    LastRun := {e: e, syn: syn}
    pause := Integer(IniRead(SettingsFile, "ITrak", "Pause", "300"))
    keys := 2
    for k in EntryFields {
        if vals[k] = ""
            continue
        if !ITrakSpot(win, Integer(f[k "X"]), Integer(f[k "Y"]), w0, h0, &x, &y) || !AlertOnScreen(x, y) {
            Tip("The iTrak window is too small for the " k " spot (or off the screen). Stopped.", 4000, true)
            Activity("Full-entry log " e.name ": stopped before " k " (spot outside the window)")
            return
        }
        if !WinActive("ahk_id " win) {
            Tip("iTrak lost the front. Stopped before " k ".", 3000, true)
            Activity("Full-entry log " e.name ": stopped before " k " (iTrak lost the front)")
            return
        }
        MouseMove x, y, 0
        Sleep 60
        Click
        Sleep pause
        if k = "Synopsis" {
            Paste(vals[k], true)
            keys += StrLen(vals[k]) + 1
        } else if k = "Reference" {
            EntryType vals[k]
            keys += StrLen(vals[k]) + 1
        } else {
            EntryType vals[k]
            Sleep 250           ; let the list narrow down to the one option
            SendInput "{Enter}"
            keys += 5
        }
        Sleep 120
    }
    ; End Time's Now button, for logs that end with | end (the log is complete)
    if e.end {
        if !f.Has("EndNowX") {
            Tip("End Time's Now button isn't taught yet: press Ctrl+Alt+Shift+F to teach it.", 5000, true)
            Activity("Full-entry log " e.name ": End Time Now not clicked (not taught; run Ctrl+Alt+Shift+F again)")
        } else if ITrakSpot(win, Integer(f["EndNowX"]), Integer(f["EndNowY"]), w0, h0, &x, &y) && AlertOnScreen(x, y) && WinActive("ahk_id " win) {
            Sleep 300
            MouseMove x, y, 0
            Sleep 60
            Click
            keys += 1
            Sleep 120
        } else
            Activity("Full-entry log " e.name ": End Time Now not clicked (spot outside the window or window lost the front)")
    }
    MouseMove ox, oy, 0
    if IsBreakLog(e)
        BreakBegin(win)
    Tip("Filled in: " e.name, 1500)
    Activity("Full-entry log " e.name ": filled in (" keys " keystrokes counted as saved)")
    CountSaved("log", keys, "Full log: " e.name)
    Journal("Full log: " e.name, "Location: " e.loc "`n" "Topic: " e.topic "`n" "Reference: " e.ref "`n" "Synopsis: " syn, keys)
}

; Types text key by key (what Citrix handles best), a little slower than normal
EntryType(text) {
    SetKeyDelay 20, 10
    SendEvent "{Text}" text
}

TeachEntryFields() {
    global TeachBusy
    if TeachBusy
        return
    TeachBusy := true
    try TeachEntryFieldsRun()
    catch as err
        MsgBox "Teach daily log fields stopped: " err.Message, "Teach daily log fields", "Icon!"
    TeachBusy := false
}

TeachEntryFieldsRun() {
    global ITrakFile, EntryFields
    win := EntryWin()
    if !win {
        MsgBox "Open a new daily log in iTrak first, so the empty Daily Log Entry form is showing (its window title starts with Daily Log Entry), then run this again.", "Teach daily log fields", "Icon!"
        return
    }
    if MsgBox("Leave the empty Daily Log Entry form showing.`n`nFor each of Location, Topic, Reference and Synopsis, hover the mouse over that box and press F8, or Ctrl+Alt+Shift+A if F8 needs the Fn key (Ctrl+Alt+Esc cancels). Nothing is clicked for you while teaching. The fifth spot is End Time's Now button.`n`nStart?", "Teach daily log fields", "YesNo Icon?") != "Yes"
        return
    SetTitleMatchMode 2
    pts := Map()
    for i, k in EntryFields {
        if !TeachWait(i " of 5`nHover over the " k " box on the daily log and press F8 (or Ctrl+Alt+Shift+A)   (do NOT click it)   (Ctrl+Alt+Esc cancels)")
            return
        win := EntryWin()
        if !win || !ITrakPoint(win, &x, &y) {
            MsgBox "That spot isn't inside the Daily Log Entry window. Nothing saved. Try again.", "Teach daily log fields", "Icon!"
            return
        }
        pts[k] := [x, y]
    }
    if !TeachWait("5 of 5`nHover over End Time's  Now  button and press F8 (or Ctrl+Alt+Shift+A)   (do NOT click it)   (Ctrl+Alt+Esc cancels)")
        return
    win := EntryWin()
    if !win || !ITrakPoint(win, &x, &y) {
        MsgBox "That spot isn't inside the Daily Log Entry window. Nothing saved. Try again.", "Teach daily log fields", "Icon!"
        return
    }
    pts["EndNow"] := [x, y]
    WinGetClientPos , , &cw, &ch, "ahk_id " win
    try {
        for k in EntryFields {
            IniWrite pts[k][1], ITrakFile, "Fields", k "X"
            IniWrite pts[k][2], ITrakFile, "Fields", k "Y"
        }
        IniWrite pts["EndNow"][1], ITrakFile, "Fields", "EndNowX"
        IniWrite pts["EndNow"][2], ITrakFile, "Fields", "EndNowY"
        IniWrite cw, ITrakFile, "Fields", "W"
        IniWrite ch, ITrakFile, "Fields", "H"
    } catch {
        MsgBox "Couldn't save the spots to " ITrakFile, "Teach daily log fields", "Icon!"
        return
    }
    Activity("iTrak: daily log fields taught (window " cw "x" ch ")")
    MsgBox "Saved. Ctrl+Alt+F now fills in a full-entry log (add them to templates.txt as lines like  +Break = Surveillance | Duty | NA | Break ).`n`nThe form can open anywhere, but keep it the same size.", "Teach daily log fields"
}

TeachITrak() {
    global TeachBusy
    if TeachBusy
        return
    TeachBusy := true
    try TeachITrakRun()
    catch as err
        MsgBox "Teach iTrak stopped: " err.Message, "Teach iTrak", "Icon!"
    TeachBusy := false
}

; Where the mouse is now, inside the iTrak window: sets &x &y, false when
; it isn't over that window
ITrakPoint(win, &x, &y) {
    CoordMode "Mouse", "Screen"
    MouseGetPos &mx, &my
    WinGetClientPos &cx, &cy, &cw, &ch, "ahk_id " win
    x := mx - cx, y := my - cy
    return x >= 0 && y >= 0 && x < cw && y < ch
}

TeachITrakRun() {
    global ITrakFile
    win := ITrakWin()
    if !win {
        MsgBox "Open iTrak first (the Daily Log window).", "Teach iTrak", "Icon!"
        return
    }
    two := MsgBox("Does opening a new daily log in iTrak take TWO clicks (a button, then a line in a menu that opens)?`n`nYes = two clicks`nNo = one click", "Teach iTrak", "YesNo Icon?") = "Yes"
    if MsgBox("This takes about a minute and you do it once on each PC (or once for the whole team, if you share it afterwards).`n`nAt " (two ? "two points" : "one point") " you hover the mouse over the right spot in iTrak and press F8, or Ctrl+Alt+Shift+A if F8 needs the Fn key (Ctrl+Alt+Esc cancels). Nothing is clicked for you while teaching.`n`nStart?", "Teach iTrak", "YesNo Icon?") != "Yes"
        return
    SetTitleMatchMode 2
    if !TeachWait("1 of " (two ? 2 : 1) "`nHover over the button that opens a new daily log in iTrak and press F8 (or Ctrl+Alt+Shift+A)   (do NOT click it yet)   (Ctrl+Alt+Esc cancels)")
        return
    win := ITrakWin()
    if !win || !ITrakPoint(win, &x1, &y1) {
        MsgBox "That spot isn't inside the iTrak window. Nothing saved. Try again.", "Teach iTrak", "Icon!"
        return
    }
    x2 := "", y2 := ""
    if two {
        if !TeachWait("2 of 2`nNow click that button, and when the menu is open hover over the line that starts the new daily log and press F8 (or Ctrl+Alt+Shift+A)   (do NOT click it yet)")
            return
        win := ITrakWin()
        if !win || !ITrakPoint(win, &x2, &y2) {
            MsgBox "That spot isn't inside the iTrak window. Nothing saved. Try again.", "Teach iTrak", "Icon!"
            return
        }
    }
    WinGetClientPos , , &cw, &ch, "ahk_id " win
    try {
        try FileDelete ITrakFile
        IniWrite x1, ITrakFile, "Clicks", "X1"
        IniWrite y1, ITrakFile, "Clicks", "Y1"
        if two {
            IniWrite x2, ITrakFile, "Clicks", "X2"
            IniWrite y2, ITrakFile, "Clicks", "Y2"
        }
        IniWrite two ? 2 : 1, ITrakFile, "Clicks", "Clicks"
        IniWrite cw, ITrakFile, "Clicks", "W"
        IniWrite ch, ITrakFile, "Clicks", "H"
        IniWrite A_ScreenDPI, ITrakFile, "Clicks", "DPI"
    } catch {
        MsgBox "Couldn't save the click to " ITrakFile, "Teach iTrak", "Icon!"
        return
    }
    Activity("iTrak: new daily log taught (" x1 "," y1 (two ? "  then " x2 "," y2 : "") "  window " cw "x" ch ")")
    MsgBox "Saved. Now click " (two ? "that line" : "the button") " yourself to finish.`n`nFrom now on Ctrl+Alt+D opens a new daily log, wherever iTrak is. To share it with the team's other PCs: tray > iTrak > Share my setup with the team.", "Teach iTrak"
}

; Puts this PC's taught iTrak click in itrak.ini in the team folder, under
; this PC's screen scaling, so PCs that haven't been taught use it.
; Numbers only. A PC's own teach always wins over the team copy.
ShareITrakSetup() {
    global ITrakFile
    f := ITrakTeamFile()
    if f = "" {
        MsgBox "There's no team folder set up (the team templates file in Settings), so there's nowhere to share it.", "Share iTrak setup", "Icon!"
        return
    }
    if ITrakTaught() != "here" {
        MsgBox "iTrak isn't taught on this PC, so there's nothing of this PC's to share. Teach it first (Ctrl+Alt+Shift+I).", "Share iTrak setup", "Icon!"
        return
    }
    c := ITrakLoad()
    if !c
        return
    scale := Round(A_ScreenDPI / 96 * 100)
    if MsgBox("Share this PC's iTrak click with the team?`n`nIt goes in " f " for screens at " scale "% scaling. PCs that haven't been taught use it; a PC that has been taught keeps its own.`n`nOnly click positions are saved (numbers).", "Share iTrak setup", "YesNo Icon?") != "Yes"
        return
    sec := ITrakTeamSection()
    try {
        for k in ["X1", "Y1", "X2", "Y2", "W", "H", "Clicks"] {
            if c[k] != ""
                IniWrite c[k], f, sec, k
            else
                try IniDelete f, sec, k
        }
    } catch as e {
        MsgBox "Couldn't write to the team folder:`n" e.Message "`n`nIf OneDrive is syncing, try again in a moment.", "Share iTrak setup", "Icon!"
        return
    }
    Activity("iTrak: shared this PC's click with the team (" scale "% scaling)")
    MsgBox "Shared. PCs that haven't been taught now use this click (once OneDrive has synced the team folder).`n`nThe iTrak window should be about the same size on those PCs (maximised is best).", "Share iTrak setup"
}

; =====================================================================
;  BREAK TIME TRACKER (v3.29.0)
;  The ;break daily log (any full-entry log named Break) starts the clock;
;  the break ends when that Daily Log Entry window closes (Save & Close).
;  The minutes add up for the shift against [Break] Minutes= in
;  settings.ini (default 60). Kept in last used.ini [Break] so a reload
;  doesn't lose it; cleared by Start of shift or after 14 hours.
; =====================================================================
IsBreakLog(e) => RegExMatch(e.name, "i)^break\b")

BreakAllowed() {
    m := IniRead(SettingsFile, "Break", "Minutes", "60")
    return IsNumber(m) && m > 0 ? m * 60 : 3600
}

; Seconds of break used this shift (the open one counted up to now)
BreakUsedSecs() {
    BreakCheckStale()
    used := 0, openAt := ""
    try used := Integer(IniRead(LastUsedFile, "Break", "Used", "0"))
    try openAt := IniRead(LastUsedFile, "Break", "OpenSince", "")
    if openAt != ""
        used += DateDiff(A_Now, openAt, "Seconds")
    return used
}

BreakLeftSecs() => BreakAllowed() - BreakUsedSecs()

; "Break left: 42 min (18 of 60 used)" or "On break 12 min, 30 min left"
BreakText() {
    left := BreakLeftSecs()
    openAt := ""
    try openAt := IniRead(LastUsedFile, "Break", "OpenSince", "")
    mins := (left >= 0 ? left : -left) // 60
    tail := left >= 0 ? mins " min left" : "over by " mins " min"
    if openAt != ""
        return "On break " DateDiff(A_Now, openAt, "Seconds") // 60 " min, " tail
    return "Break: " tail " (" BreakUsedSecs() // 60 " of " BreakAllowed() // 60 " used)"
}

; Clears a tally from an earlier shift (14 hours after the first break)
BreakCheckStale() {
    since := ""
    try since := IniRead(LastUsedFile, "Break", "Since", "")
    if since != "" && DateDiff(A_Now, since, "Hours") >= 14
        BreakReset()
}

BreakReset() {
    try IniDelete LastUsedFile, "Break"
    SetTimer BreakWatch, 0
    SetIconTip()
}

BreakBegin(win) {
    BreakCheckStale()
    try {
        if !DirExist(DataDir)
            DirCreate DataDir
        if IniRead(LastUsedFile, "Break", "Since", "") = ""
            IniWrite A_Now, LastUsedFile, "Break", "Since"
        ; a break log already open is ended first (it can't be counted twice)
        if IniRead(LastUsedFile, "Break", "OpenSince", "") != ""
            BreakEnd()
        IniWrite A_Now, LastUsedFile, "Break", "OpenSince"
        IniWrite win, LastUsedFile, "Break", "Win"
    }
    Activity("Break started (" BreakText() ")")
    SetTimer BreakWatch, 2000
    SetIconTip()
}

; After a reload: keep watching a break log that is still open
BreakResume() {
    openAt := ""
    try openAt := IniRead(LastUsedFile, "Break", "OpenSince", "")
    if openAt != ""
        SetTimer BreakWatch, 2000
    SetIconTip()
}

BreakWatch() {
    win := 0, openAt := ""
    try win := Integer(IniRead(LastUsedFile, "Break", "Win", "0"))
    try openAt := IniRead(LastUsedFile, "Break", "OpenSince", "")
    if openAt = "" {
        SetTimer BreakWatch, 0
        return
    }
    if !win || !WinExist("ahk_id " win)
        BreakEnd()
    else
        SetIconTip()
}

BreakEnd() {
    openAt := "", used := 0
    try openAt := IniRead(LastUsedFile, "Break", "OpenSince", "")
    if openAt = ""
        return
    secs := DateDiff(A_Now, openAt, "Seconds")
    try used := Integer(IniRead(LastUsedFile, "Break", "Used", "0"))
    try {
        IniWrite used + secs, LastUsedFile, "Break", "Used"
        IniDelete LastUsedFile, "Break", "OpenSince"
        IniDelete LastUsedFile, "Break", "Win"
    }
    SetTimer BreakWatch, 0
    Activity("Break ended after " secs // 60 " min (" BreakText() ")")
    Tip("Break " secs // 60 " min. " BreakText(), 4000)
    SetIconTip()
}

; The tray icon's hover text: version, and break time once a break was taken
SetIconTip() {
    iconTxt := "Watchlog v" VERSION "  (" VERSION_DATE ")" (OutOfDate() ? "  - UPDATE NEEDED" : "")
    since := ""
    try since := IniRead(LastUsedFile, "Break", "Since", "")
    if since != ""
        iconTxt .= "`n" BreakText()
    A_IconTip := iconTxt
}

; Clicks End Time's Now button in the Daily Log Entry in front (or the
; break log, or the only one open)
EntryEndNow() {
    f := EntryLoad()
    if !f || !f.Has("EndNowX") {
        Tip("End Time's Now button isn't taught yet: press " HK("entryteach") " to teach it.", 4000, true)
        return
    }
    ents := EntryWins()
    win := 0
    if ents.Has(WinExist("A"))
        win := WinExist("A")
    else {
        bw := 0
        try bw := Integer(IniRead(LastUsedFile, "Break", "Win", "0"))
        if bw && ents.Has(bw)
            win := bw
        else if ents.Count = 1
            for h in ents
                win := h
    }
    if !win {
        Tip("Click the daily log first, then press " HK("endnow") " again.", 3000, true)
        return
    }
    WinActivate "ahk_id " win
    if !WinWaitActive("ahk_id " win, , 2)
        return
    CoordMode "Mouse", "Screen"
    MouseGetPos &ox, &oy
    if ITrakSpot(win, Integer(f["EndNowX"]), Integer(f["EndNowY"]), Integer(f["W"]), Integer(f["H"]), &x, &y) && AlertOnScreen(x, y) {
        MouseMove x, y, 0
        Sleep 60
        Click
        MouseMove ox, oy, 0
        Activity("End Time Now clicked by " HK("endnow"))
    } else
        Tip("The End Time Now spot is outside the daily log window.", 3000, true)
}

; =====================================================================
;  SAFEGUARDS: repeat the last log, backups, going back (v3.28.0)
; =====================================================================
; Does the last full-entry log again (a new daily log with the same boxes)
RepeatLastLog() {
    if !IsObject(LastRun) {
        Tip("No log to repeat yet: make one with a code word, the call pad or " HK("entrypick") " first.", 3500, true)
        return
    }
    ne := {}
    for k, v in LastRun.e.OwnProps()
        ne.%k% := v
    ne.syn := LastRun.syn
    Activity("Repeat last log: " ne.name)
    RunEntry(ne)
}

; The files a backup holds: the ones in the Watchlog folder and the numbers
; taught on this PC (no passwords: those live in Windows' Credential Manager)
BackupSources() {
    list := []
    for n in ["templates.txt", "my-templates.txt", "settings.ini", "autocorrect.txt"]
        if FileExist(HomeDir "\" n)
            list.Push([HomeDir "\" n, "home - " n])
    if DirExist(DataDir)
        loop files DataDir "\*.ini"
            list.Push([A_LoopFileFullPath, "data - " A_LoopFileName])
    return list
}

; Copies them into DataDir\Backups\<folder>. Returns the number copied.
BackupInto(folder) {
    n := 0
    try {
        DirCreate DataDir "\Backups\" folder
        for it in BackupSources() {
            try {
                FileCopy it[1], DataDir "\Backups\" folder "\" it[2], true
                n += 1
            }
        }
    }
    return n
}

; Once a day (the first start of the day): keeps the last 14 backup folders
DailyBackup() {
    today := FormatTime(, "yyyy-MM-dd")
    if DirExist(DataDir "\Backups\" today)
        return
    n := BackupInto(today)
    Activity("Backup of " n " settings and template files made (" today ")")
    names := []
    loop files DataDir "\Backups\*", "D"
        names.Push(A_LoopFileName)
    if names.Length > 14 {
        names := SortNames(names)
        loop names.Length - 14
            try DirDelete DataDir "\Backups\" names[A_Index], true
    }
}

; Names in order, oldest first (the folder names start with the date)
SortNames(names) {
    txt := ""
    for nm in names
        txt .= nm "`n"
    return StrSplit(Sort(RTrim(txt, "`n")), "`n")
}

BackupNow() {
    n := BackupInto(FormatTime(, "yyyy-MM-dd HHmmss") " (made by hand)")
    Activity("Backup made by hand: " n " files")
    MsgBox "Backed up " n " files (your templates, settings, autocorrect list and the taught clicks).`n`nPasswords are not in it: Windows keeps those.", "Watchlog backup", "Iconi"
}

ShowRestore() {
    names := []
    if DirExist(DataDir "\Backups")
        loop files DataDir "\Backups\*", "D"
            names.Push(A_LoopFileName)
    if !names.Length {
        MsgBox "There are no backups yet. One is made the first time Watchlog starts each day.", "Watchlog restore", "Iconi"
        return
    }
    names := SortNames(names)
    g := Gui("+AlwaysOnTop", "Restore from a backup")
    g.SetFont("s10")
    g.AddText("w420", "Pick a backup. Your templates, settings, autocorrect list and taught clicks go back to how they were then. What you have now is backed up first, so this can be undone.")
    lb := g.AddListBox("w420 r10")
    shown := []
    loop names.Length {
        nm := names[names.Length - A_Index + 1]
        shown.Push(nm)
        lb.Add([nm])
    }
    lb.Choose(1)
    g.AddButton("w120 Default", "Restore").OnEvent("Click", Go)
    g.AddButton("x+10 w120", "Cancel").OnEvent("Click", (*) => g.Destroy())
    g.OnEvent("Escape", (*) => g.Destroy())
    g.Show()
    Go(*) {
        if !lb.Value
            return
        pick := shown[lb.Value]
        g.Destroy()
        if MsgBox("Restore the backup " pick "?`n`nWatchlog reloads afterwards.", "Watchlog restore", "YesNo Icon? Default2") != "Yes"
            return
        BackupInto(FormatTime(, "yyyy-MM-dd HHmmss") " (before restore)")
        n := 0
        loop files DataDir "\Backups\" pick "\*" {
            if SubStr(A_LoopFileName, 1, 7) = "home - "
                dest := HomeDir "\" SubStr(A_LoopFileName, 8)
            else if SubStr(A_LoopFileName, 1, 7) = "data - "
                dest := DataDir "\" SubStr(A_LoopFileName, 8)
            else
                continue
            try {
                FileCopy A_LoopFileFullPath, dest, true
                n += 1
            }
        }
        Activity("Restored " n " files from the backup " pick)
        MsgBox "Restored " n " files. Watchlog reloads now.", "Watchlog restore", "Iconi T4"
        Reload
    }
}

; The newer version that was skipped when going back (not offered again)
SkippedVersion() {
    try return IniRead(LastUsedFile, "Updates", "Skip", "")
    return ""
}

ClearSkippedVersion() {
    try IniDelete LastUsedFile, "Updates", "Skip"
    BuildTrayMenu()
    Tip("The newer version will be offered again.", 2500, true)
}

; Puts back the copy Watchlog kept when it last updated
GoBackVersion() {
    ext := A_IsCompiled ? "exe" : "ahk"
    best := "", bestV := ""
    loop files DataDir "\Watchlog v* (backup)." ext {
        if RegExMatch(A_LoopFileName, "^Watchlog v([\d.]+) \(backup\)", &m) && VerCompare(m[1], VERSION) < 0
            && (bestV = "" || VerCompare(m[1], bestV) > 0)
            best := A_LoopFileFullPath, bestV := m[1]
    }
    if best = "" {
        MsgBox "There is no earlier version kept on this PC. Watchlog keeps the old one each time it updates.", "Watchlog", "Iconi"
        return
    }
    if MsgBox("Go back from v" VERSION " to v" bestV "?`n`nWatchlog restarts on the older version, and v" VERSION " won't be offered again until you choose 'Offer the skipped update again' (tray > Advanced).", "Watchlog", "YesNo Icon? Default2") != "Yes"
        return
    keep := DataDir "\Watchlog v" VERSION " (backup)." ext
    try {
        try IniWrite VERSION, LastUsedFile, "Updates", "Skip"
        if A_IsCompiled {
            try FileDelete keep
            FileMove A_ScriptFullPath, keep, 1
            try FileCopy best, A_ScriptFullPath, 1
            catch as err {
                try FileMove keep, A_ScriptFullPath, 1
                throw err
            }
        } else {
            FileCopy A_ScriptFullPath, keep, true
            FileCopy best, A_ScriptFullPath, true
        }
    } catch as err {
        try IniDelete LastUsedFile, "Updates", "Skip"
        Activity("Going back to v" bestV " failed: " err.Message)
        MsgBox "Couldn't go back: " err.Message, "Watchlog", "Icon!"
        return
    }
    Activity("Went back from v" VERSION " to v" bestV)
    if A_IsCompiled {
        Run '"' A_ScriptFullPath '"'
        ExitApp
    }
    Reload
}

; =====================================================================
;  UPDATES FROM THE TEAM FOLDER
;  Whoever looks after the tool puts the new Watchlog.ahk (and
;  Watchlog.ico) in the same SharePoint folder as the team templates.
;  When that copy is a newer version, each PC asks to update: it checks
;  the new file loads, keeps the old one as a backup in
;  %LOCALAPPDATA%\Watchlog, copies the new one over this one and reloads.
;  It only ever updates from that one folder.
; =====================================================================
; Watchlog.ahk next to the team templates file, or "" when there's no team
; file (or this copy is the one in the team folder)
TeamProgramFile() {
    dir := Cfg["UpdateFolder"]
    if dir = "" {
        if Cfg["SharedTemplates"] = ""
            return ""
        SplitPath Cfg["SharedTemplates"], , &dir
    }
    f := dir (A_IsCompiled ? "\Watchlog.exe" : "\Watchlog.ahk")
    return StrLower(f) = StrLower(A_ScriptFullPath) ? "" : f
}

; The version of the team folder's Watchlog.ahk, or "" if there isn't one
TeamProgramVersion() => ProgramVersionOf(TeamProgramFile())

; The version of a Watchlog.exe or Watchlog.ahk ("" if there isn't one)
ProgramVersionOf(f) {
    if f = "" || !FileExist(f)
        return ""
    if A_IsCompiled {
        try return RegExMatch(FileGetVersion(f), "^\d+\.\d+\.\d+", &v) ? v[0] : ""
        return ""
    }
    try text := FileRead(f, "UTF-8")
    catch
        return ""
    return RegExMatch(text, 'm)^VERSION := "([\d.]+)"', &m) ? m[1] : ""
}

; True when the team folder has a newer Watchlog than this one
UpdateWaiting() {
    v := TeamProgramVersion()
    return v != "" && v != SkippedVersion() && VerCompare(v, VERSION) > 0
}

CheckForUpdate() {
    global UpdateOffered
    if !UpdateWaiting()
        return false
    v := TeamProgramVersion()
    if UpdateOffered = v
        return false
    UpdateOffered := v
    if MsgBox("Watchlog v" v " is in the team folder. This PC has v" VERSION ".`n`n"
        . "Update now? It takes a few seconds. The old version is kept as a backup.", "Watchlog update", "YesNo Iconi Default1") != "Yes" {
        Activity("Update to v" v " offered, Later chosen")
        return true
    }
    UpdateFrom(TeamProgramFile(), v)
    return true
}

UpdateFrom(f, v) {
    if A_IsCompiled {
        UpdateExeFrom(f, v)
        return
    }
    ; Make sure the new file loads before swapping it in
    tmp := A_Temp "\Watchlog update check.ahk"
    ok := false
    try {
        FileCopy f, tmp, true
        ok := RunWait('"' A_AhkPath '" /Validate /ErrorStdOut "' tmp '"', , "Hide") = 0
    }
    try FileDelete tmp
    if !ok {
        Activity("Update to v" v " stopped: the team folder's Watchlog.ahk didn't load")
        MsgBox "The new Watchlog.ahk in the team folder didn't load, so this PC stays on v" VERSION ".`n`nTell whoever looks after the tool.", "Watchlog update", "Icon!"
        return
    }
    backup := DataDir "\Watchlog v" VERSION " (backup).ahk"
    try {
        if !DirExist(DataDir)
            DirCreate DataDir
        FileCopy A_ScriptFullPath, backup, true
        FileCopy f, A_ScriptFullPath, true
    } catch as err {
        try FileCopy backup, A_ScriptFullPath, true
        Activity("Update to v" v " failed: " err.Message)
        MsgBox "Couldn't update: " err.Message "`n`nThis PC stays on v" VERSION ".", "Watchlog update", "Icon!"
        return
    }
    SplitPath f, , &dir
    if FileExist(dir "\Watchlog.ico")
        try FileCopy dir "\Watchlog.ico", IconFile, true
    Activity("Updated from v" VERSION " to v" v " from " f " (old copy kept: " backup ")")
    Reload
}


; =====================================================================
;  TIME SAVED  (tray > Time saved, or the button in Ctrl+Alt+J)
;  Every log, login and stamp adds the keystrokes it saved: the length
;  of what went in minus what you typed (the shortcut, what you put in
;  the boxes, one Tab or Enter per box). Time is worked out at 40 words
;  a minute (200 keystrokes). Kept per day in time saved.ini in
;  %LOCALAPPDATA%\Watchlog: numbers only, never log text or passwords.
;  A shift starts with the first count after End of shift or after 6
;  hours with nothing counted.
; =====================================================================
CountSaved(kind, keys, name := "") {
    if IsObject(TutorialWin)
        return
    try {
        day := FormatTime(, "yyyy-MM-dd")
        d := SavedRow(IniRead(SavedFile, "Days", day, ""))
        if kind != ""
            d.%kind% += 1
        d.keys += keys
        IniWrite d.log "," d.login "," d.stamp "," d.keys, SavedFile, "Days", day
        if IniRead(SavedFile, "Info", "First", "") = ""
            IniWrite day, SavedFile, "Info", "First"
        ; this shift
        last := IniRead(SavedFile, "Shift", "Last", "")
        sh := SavedRow(IniRead(SavedFile, "Shift", "Counts", ""))
        if last = "" || IniRead(SavedFile, "Shift", "Ended", 0) || DateDiff(A_Now, last, "Hours") >= 6 {
            sh := SavedRow("")
            IniWrite A_Now, SavedFile, "Shift", "Start"
            IniWrite 0, SavedFile, "Shift", "Ended"
            try IniDelete SavedFile, "ShiftItems"
        }
        if name != "" {
            ; the shift count: how many times, and keystrokes saved, per item
            name := Trim(StrReplace(StrReplace(StrReplace(name, "=", "-"), "`n", " "), "`r"))
            it := ItemRow(IniRead(SavedFile, "ShiftItems", name, ""))
            IniWrite (it.n + 1) "," (it.keys + keys), SavedFile, "ShiftItems", name
            di := ItemRow(IniRead(SavedFile, "DayItems", day "|" name, ""))
            IniWrite (di.n + 1) "," (di.keys + keys), SavedFile, "DayItems", day "|" name
        }
        if kind != ""
            sh.%kind% += 1
        sh.keys += keys
        IniWrite sh.log "," sh.login "," sh.stamp "," sh.keys, SavedFile, "Shift", "Counts"
        IniWrite A_Now, SavedFile, "Shift", "Last"
    }
}

; "times,keystrokes" -> an object
ItemRow(str) {
    p := StrSplit(str, ",")
    num(i) => p.Length >= i && IsInteger(p[i]) ? Integer(p[i]) : 0
    return {n: num(1), keys: num(2)}
}

; "logs,logins,stamps,keystrokes" -> an object
SavedRow(str) {
    p := StrSplit(str, ",")
    num(i) => p.Length >= i && IsInteger(p[i]) ? Integer(p[i]) : 0
    return {log: num(1), login: num(2), stamp: num(3), keys: num(4)}
}

; This shift's counts (all zero when the last shift has ended)
SavedShift() {
    try {
        last := IniRead(SavedFile, "Shift", "Last", "")
        if last != "" && !IniRead(SavedFile, "Shift", "Ended", 0) && DateDiff(A_Now, last, "Hours") < 6
            return SavedRow(IniRead(SavedFile, "Shift", "Counts", ""))
    }
    return SavedRow("")
}

; Adds up the days from `from` (yyyy-MM-dd, "" = since the start) to today
SavedSince(from) {
    t := SavedRow(""), t.days := 0
    try section := IniRead(SavedFile, "Days")
    catch
        return t
    for line in StrSplit(section, "`n", "`r") {
        if !(eq := InStr(line, "="))
            continue
        if from != "" && StrCompare(SubStr(line, 1, eq - 1), from) < 0
            continue
        d := SavedRow(SubStr(line, eq + 1))
        t.log += d.log, t.login += d.login, t.stamp += d.stamp, t.keys += d.keys, t.days += 1
    }
    return t
}

; Keystrokes -> "about 12 minutes" / "about 3.5 hours", at 200 a minute
SavedTime(keys) {
    mins := keys / 200
    if mins < 1
        return "under a minute"
    if mins < 60
        return "about " Round(mins) " minute" (Round(mins) = 1 ? "" : "s")
    return "about " Round(mins / 60, 1) " hours"
}

Commas(n) => RegExReplace(Format("{:d}", n), "\G\d+?(?=(\d{3})+$)", "$0,")

HasVal(arr, v) {
    for it in arr
        if it = v
            return true
    return false
}

; =====================================================================
;  SHIFT COUNT  (tray > Shift count, or the button in Time saved)
;  Counts exactly what got done this shift, item by item: each template
;  by name, each login, each time stamp, each Alert Grid clear, each
;  app switch. Numbers only (never the log text), kept in time saved.ini.
;  It starts by itself with the first thing you do and starts again after
;  End of shift (or 6 hours of nothing); "Start a new count" restarts it.
; =====================================================================
ShowShiftCount() {
    items := []
    try section := IniRead(SavedFile, "ShiftItems")
    catch
        section := ""
    for line in StrSplit(section, "`n", "`r") {
        if !(eq := InStr(line, "="))
            continue
        it := ItemRow(SubStr(line, eq + 1))
        it.name := SubStr(line, 1, eq - 1)
        items.Push(it)
    }
    ; most used first (simple insertion sort, the list is short)
    Loop items.Length - 1 {
        i := A_Index + 1
        cur := items[i], j := i - 1
        while j >= 1 && items[j].n < cur.n {
            items[j + 1] := items[j]
            j -= 1
        }
        items[j + 1] := cur
    }
    live := items.Length > 0
    sh := SavedShift()
    start := last := ""
    try start := IniRead(SavedFile, "Shift", "Start", "")
    try last := IniRead(SavedFile, "Shift", "Last", "")
    total := 0, keysTotal := 0
    for it in items
        total += it.n, keysTotal += it.keys
    span := live && start != "" && last != "" ? "from " FormatTime(start, "HH:mm") " to " FormatTime(last, "HH:mm") : "nothing counted yet"
    g := WGui("+AlwaysOnTop", "Shift count  -  v" VERSION)
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 14, g.MarginY := 12
    g.AddText("w520", "Everything Watchlog did this shift, counted exactly (" span "). Numbers only: no log text.")
    lv := g.AddListView("w520 r14 -Multi NoSortHdr", ["What", "Times", "Keystrokes saved"])
    report := "Watchlog shift count on " A_ComputerName " (" span ")`r`n"
    for it in items {
        lv.Add(, it.name, it.n, Commas(it.keys))
        report .= it.name ": " it.n " (" Commas(it.keys) " keystrokes saved)`r`n"
    }
    lv.ModifyCol(1, 260), lv.ModifyCol(2, 70), lv.ModifyCol(3, 130)
    sum := total " things done, " Commas(keysTotal) " keystrokes saved, " SavedTime(keysTotal) " at 40 words a minute"
    report .= "TOTAL: " sum "`r`n"
    g.AddText("xm w480", "Total: " sum)
    g.AddButton("xm y+12 w120", "Start a new count").OnEvent("Click", NewCount)
    g.AddButton("x+8 yp w100", "Copy report").OnEvent("Click", CopyIt)
    g.AddButton("x+8 yp w100", "Dashboard").OnEvent("Click", (*) => (g.Destroy(), ShowDashboard()))
    g.AddButton("x+8 yp w80 Default", "Close").OnEvent("Click", (*) => g.Destroy())
    g.OnEvent("Escape", (*) => g.Destroy())
    g.Show()

    CopyIt(*) {
        A_Clipboard := report
        g.Destroy()
        Tip("Report copied. Paste it with Ctrl+V.")
    }
    NewCount(*) {
        if MsgBox("Throw away this count and start again from zero?`n`n(The Time saved totals are not touched.)", "Shift count", "YesNo Icon? Default2") != "Yes"
            return
        try IniDelete SavedFile, "ShiftItems"
        try IniWrite 1, SavedFile, "Shift", "Ended"
        Activity("Shift count restarted by hand")
        g.Destroy()
        Tip("Shift count started again from zero")
    }
}

ShowTimeSaved() {
    first := ""
    try first := IniRead(SavedFile, "Info", "First", "")
    rows := [["This shift", SavedShift()]
        , ["Today", SavedSince(FormatTime(, "yyyy-MM-dd"))]
        , ["Last 7 days", SavedSince(FormatTime(DateAdd(A_Now, -6, "Days"), "yyyy-MM-dd"))]
        , ["Last 30 days", SavedSince(FormatTime(DateAdd(A_Now, -29, "Days"), "yyyy-MM-dd"))]
        , ["Since " (first != "" ? FormatTime(StrReplace(first, "-") "000000", "MMM d, yyyy") : "the start"), SavedSince("")]]
    g := WGui("+AlwaysOnTop", "Time saved  -  v" VERSION)
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 14, g.MarginY := 12
    g.AddText("w560", "Keystrokes Watchlog saved you: what went in, minus what you typed. Time is worked out at 40 words a minute.")
    lv := g.AddListView("w560 r5 -Multi NoSortHdr", ["", "Logs", "Logins", "Stamps", "Keystrokes saved", "Time saved"])
    report := "Watchlog time saved on " A_ComputerName " (keystrokes saved, at 40 words a minute)`r`n"
    for r in rows {
        t := r[2]
        lv.Add(, r[1], t.log, t.login, t.stamp, Commas(t.keys), SavedTime(t.keys))
        report .= r[1] ": " t.log " logs, " t.login " logins, " Commas(t.keys) " keystrokes, " SavedTime(t.keys)
            . (A_Index = rows.Length ? " (" t.days " days used)" : "") "`r`n"
    }
    lv.ModifyCol(1, 130), lv.ModifyCol(2, 50), lv.ModifyCol(3, 55), lv.ModifyCol(4, 60), lv.ModifyCol(5, 120), lv.ModifyCol(6, 120)
    g.AddButton("xm+142 y+12 w110", "Shift count").OnEvent("Click", (*) => (g.Destroy(), ShowShiftCount()))
    g.AddButton("x+8 yp w110", "Dashboard").OnEvent("Click", (*) => (g.Destroy(), ShowDashboard()))
    g.AddButton("x+8 yp w100", "Copy report").OnEvent("Click", CopyIt)
    g.AddButton("x+8 yp w100 Default", "Close").OnEvent("Click", (*) => g.Destroy())
    g.OnEvent("Escape", (*) => g.Destroy())
    g.Show()

    CopyIt(*) {
        A_Clipboard := report
        g.Destroy()
        Tip("Report copied. Paste it with Ctrl+V.")
    }
}



; =====================================================================
;  SHIFT DASHBOARD  (tray > Shift dashboard, Ctrl+Alt+Shift+D, or the
;  button in Shift count / Time saved)
;  Three tabs: this shift (tiles + logs by type), the last 7 days and the
;  last 30 days. This shift can be copied as text or saved as a one-page
;  sheet in Shift Reports (next to settings.ini) to print or hand over.
;  Numbers only: log type names and counts, never log text, employee
;  numbers, patron names, machine or alert numbers. Kept on this PC in
;  time saved.ini ([DayItems], one line per day and log type; 400 days).
;  "Alert clears" counts each Clear all (Ctrl+Alt+A / Caps Lock), not
;  each alert.
; =====================================================================
; (set up by RegisterHotkeys, see HotkeyDefs)

; log / alert / other (logins, stamps and app switches aren't logs)
ItemKind(name) {
    if name = "Alert Grid clear"
        return "alert"
    if RegExMatch(name, "^(Login |Stamp |Switch to |iTrak new )")
        return "other"
    return "log"
}

; Drops [DayItems] lines older than 400 days (once, when Watchlog starts)
TrimDayItems() {
    try {
        section := IniRead(SavedFile, "DayItems")
        cutoff := FormatTime(DateAdd(A_Now, -400, "Days"), "yyyy-MM-dd")
        for line in StrSplit(section, "`n", "`r") {
            bar := InStr(line, "|"), eq := InStr(line, "=")
            if bar && eq && bar < eq && StrCompare(SubStr(line, 1, bar - 1), cutoff) < 0
                IniDelete SavedFile, "DayItems", SubStr(line, 1, eq - 1)
        }
    }
}

; This shift's items, most used first: [{name, n, keys}]
ShiftItemList() {
    items := []
    try section := IniRead(SavedFile, "ShiftItems")
    catch
        return items
    for line in StrSplit(section, "`n", "`r") {
        if !(eq := InStr(line, "="))
            continue
        it := ItemRow(SubStr(line, eq + 1))
        it.name := SubStr(line, 1, eq - 1)
        items.Push(it)
    }
    return SortByCount(items)
}

; Biggest .n first (insertion sort, the lists are short)
SortByCount(items) {
    Loop items.Length - 1 {
        i := A_Index + 1
        cur := items[i], j := i - 1
        while j >= 1 && items[j].n < cur.n {
            items[j + 1] := items[j]
            j -= 1
        }
        items[j + 1] := cur
    }
    return items
}

; Logs and alert clears from [DayItems] for days from..to (yyyy-MM-dd):
; {logs, alerts, days: Map(day -> {logs, alerts}), types: sorted [{name, n}]}
DashRange(from, to) {
    r := {logs: 0, alerts: 0, days: Map(), types: []}
    try section := IniRead(SavedFile, "DayItems")
    catch
        return r
    tally := Map()
    for line in StrSplit(section, "`n", "`r") {
        bar := InStr(line, "|"), eq := InStr(line, "=")
        if !bar || !eq || bar > eq
            continue
        day := SubStr(line, 1, bar - 1)
        if StrCompare(day, from) < 0 || StrCompare(day, to) > 0
            continue
        name := SubStr(line, bar + 1, eq - bar - 1)
        kind := ItemKind(name)
        if kind = "other"
            continue
        n := ItemRow(SubStr(line, eq + 1)).n
        if !r.days.Has(day)
            r.days[day] := {logs: 0, alerts: 0}
        if kind = "alert" {
            r.days[day].alerts += n, r.alerts += n
        } else {
            r.days[day].logs += n, r.logs += n
            tally[name] := (tally.Has(name) ? tally[name] : 0) + n
        }
    }
    for name, n in tally
        r.types.Push({name: name, n: n})
    SortByCount(r.types)
    return r
}

; Rows for the last `count` days, newest first: [{day, label, logs, alerts, keys}]
DashDays(count) {
    rng := DashRange(FormatTime(DateAdd(A_Now, -(count - 1), "Days"), "yyyy-MM-dd"), FormatTime(, "yyyy-MM-dd"))
    rows := []
    Loop count {
        t := DateAdd(A_Now, -(A_Index - 1), "Days")
        day := FormatTime(t, "yyyy-MM-dd")
        d := SavedRow(IniRead(SavedFile, "Days", day, ""))
        al := rng.days.Has(day) ? rng.days[day].alerts : 0
        rows.Push({day: day, label: FormatTime(t, "ddd MMM d"), logs: d.log, alerts: al, keys: d.keys})
    }
    return {rows: rows, range: rng}
}

Bar(n, top, width := 22) => top > 0 && n > 0 ? RegExReplace(Format("{:" Max(1, Ceil(n / top * width)) "}", ""), " ", "█") : ""

HtmlSafe(s) => StrReplace(StrReplace(StrReplace(s, "&", "&amp;"), "<", "&lt;"), ">", "&gt;")

; What the This shift tab shows: {logs, alerts, keys, span, items(log types)}
ShiftFacts() {
    f := {logs: 0, alerts: 0, keys: 0, span: "nothing counted yet", types: []}
    sh := SavedShift()
    f.logs := sh.log, f.keys := sh.keys
    start := last := ""
    try start := IniRead(SavedFile, "Shift", "Start", "")
    try last := IniRead(SavedFile, "Shift", "Last", "")
    for it in ShiftItemList() {
        kind := ItemKind(it.name)
        if kind = "alert"
            f.alerts += it.n
        else if kind = "log"
            f.types.Push(it)
    }
    if start != "" && last != "" && (f.logs || f.alerts || f.keys) {
        mins := DateDiff(last, start, "Minutes")
        f.span := FormatTime(start, "HH:mm") " to " FormatTime(last, "HH:mm") " (" Format("{}h {:02}m", mins // 60, Mod(mins, 60)) ")"
    }
    return f
}

DashSummaryText(f, withTime) {
    s := "Shift summary, " A_ComputerName ", " FormatTime(, "yyyy-MM-dd") " (" f.span ")`r`n"
    s .= f.logs " logs, " f.alerts " Alert Grid clears" (withTime ? ", " SavedTime(f.keys) " of typing saved" : "") "`r`n"
    for it in f.types
        s .= "  " Format("{:4}", it.n) "  " it.name "`r`n"
    return s
}

DashSheetHtml(f, withTime) {
    top := f.types.Length ? f.types[1].n : 0
    h := "<!doctype html><html><head><meta charset='utf-8'><title>Shift summary " FormatTime(, "yyyy-MM-dd") "</title><style>"
        . "body{font-family:Segoe UI,Arial,sans-serif;margin:32px;color:#222;max-width:720px}"
        . "h1{color:#0E746E;margin:0 0 4px}.sub{color:#666;margin-bottom:20px}"
        . ".tiles{display:flex;gap:14px;margin-bottom:22px}.tile{flex:1;border:1px solid #cfd8d7;border-radius:8px;padding:12px;text-align:center}"
        . ".tile b{display:block;font-size:28px;color:#0E746E}.tile span{color:#666;font-size:13px}"
        . "table{border-collapse:collapse;width:100%}td{padding:5px 8px;border-bottom:1px solid #e3e8e8}"
        . ".n{width:50px;text-align:right}.bar{background:#0E746E;height:12px;border-radius:3px}"
        . "</style></head><body><h1>Shift summary</h1><div class='sub'>" HtmlSafe(A_ComputerName) " &middot; "
        . FormatTime(, "dddd, MMMM d, yyyy") " &middot; " HtmlSafe(f.span) "</div><div class='tiles'>"
        . "<div class='tile'><b>" f.logs "</b><span>logs</span></div>"
        . "<div class='tile'><b>" f.alerts "</b><span>Alert Grid clears</span></div>"
    if withTime
        h .= "<div class='tile'><b>" StrReplace(StrReplace(SavedTime(f.keys), "about ", ""), "under a minute", "&lt;1 min") "</b><span>typing saved</span></div>"
    h .= "</div><table>"
    for it in f.types
        h .= "<tr><td>" HtmlSafe(it.name) "</td><td class='n'>" it.n "</td><td style='width:45%'><div class='bar' style='width:" Round(it.n / top * 100) "%'></div></td></tr>"
    return h "</table></body></html>"
}

ShowDashboard(tab := 1) {
    global DashWin
    if IsObject(DashWin)
        try DashWin.Destroy()
    f := ShiftFacts()
    wk := DashDays(7), mo := DashDays(30)
    prevRng := DashRange(FormatTime(DateAdd(A_Now, -59, "Days"), "yyyy-MM-dd"), FormatTime(DateAdd(A_Now, -30, "Days"), "yyyy-MM-dd"))
    g := DashWin := WGui("+AlwaysOnTop", "Shift dashboard  -  v" VERSION)
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 14, g.MarginY := 12
    tb := g.AddTab3("w600 h430", ["This shift", "Week", "Month"])

    tb.UseTab(1)
    y := Tiles(g, [[f.logs, "logs"], [f.alerts, "alert clears"], [StrReplace(SavedTime(f.keys), "about ", ""), "typing saved"], [f.span = "nothing counted yet" ? "-" : RegExReplace(f.span, ".* \((.*)\)$", "$1"), "shift length"]])
    g.AddText("xm+12 y" y " w560 BackgroundTrans", BreakText())
    y += 24
    g.AddText("xm+12 y" y " w560 BackgroundTrans", "Logs by type (" f.span ")")
    lv := g.AddListView("xm+12 y+6 w570 r11 -Multi NoSortHdr", ["Log type", "Times", ""])
    top := f.types.Length ? f.types[1].n : 0
    for it in f.types
        lv.Add(, it.name, it.n, Bar(it.n, top))
    lv.ModifyCol(1, 250), lv.ModifyCol(2, 55), lv.ModifyCol(3, 240)

    for pair in [[2, wk, 7, "Last 7 days"], [3, mo, 30, "Last 30 days"]] {
        tb.UseTab(pair[1])
        d := pair[2]
        logs := alerts := keys := used := best := 0
        bestDay := ""
        for r in d.rows {
            logs += r.logs, alerts += r.alerts, keys += r.keys
            if r.logs || r.alerts
                used += 1
            if r.logs > best
                best := r.logs, bestDay := r.label
        }
        avg := used ? Round(logs / used) : 0
        y := Tiles(g, [[logs, "logs"], [alerts, "alert clears"], [SavedTime(keys) = "under a minute" ? "<1 min" : StrReplace(SavedTime(keys), "about ", ""), "typing saved"], [used ? avg : "-", "logs per day worked"]])
        if pair[1] = 3 {
            prevLogs := 0
            for day, v in prevRng.days
                prevLogs += v.logs
            note := "Busiest day: " (bestDay != "" ? bestDay " (" best " logs)" : "none yet")
            note .= prevRng.logs || prevLogs ? "     Previous 30 days: " prevLogs " logs (counted by log type)" : ""
            g.AddText("xm+12 y" y " w570 BackgroundTrans", note)
        }
        dl := g.AddListView("xm+12 " (pair[1] = 3 ? "y+6" : "y" y) " w570 r" (pair[1] = 2 ? 7 : 6) " -Multi NoSortHdr", ["Day", "Logs", "Alert clears", "Typing saved", ""])
        mx := 0
        for r in d.rows
            mx := Max(mx, r.logs)
        for r in d.rows
            dl.Add(, r.label, r.logs, r.alerts, r.keys ? SavedTime(r.keys) : "", Bar(r.logs, mx, 16))
        dl.ModifyCol(1, 110), dl.ModifyCol(2, 55), dl.ModifyCol(3, 90), dl.ModifyCol(4, 110), dl.ModifyCol(5, 170)
        tl := g.AddListView("xm+12 y+8 w570 r" (pair[1] = 2 ? 5 : 4) " -Multi NoSortHdr", ["Top log types (" pair[4] ")", "Times"])
        for it in d.range.types {
            if A_Index > 20
                break
            tl.Add(, it.name, it.n)
        }
        tl.ModifyCol(1, 400), tl.ModifyCol(2, 70)
    }
    tb.UseTab()
    tb.Value := tab
    timeCB := g.AddCheckbox("xm Checked", "Include time saved in the copy and the sheet")
    g.AddButton("xm y+8 w130", "Copy summary").OnEvent("Click", CopyIt)
    g.AddButton("x+8 yp w130", "Save as a sheet").OnEvent("Click", SaveIt)
    g.AddButton("x+8 yp w120", "Shift count").OnEvent("Click", (*) => (g.Destroy(), ShowShiftCount()))
    g.AddButton("x+8 yp w100 Default", "Close").OnEvent("Click", (*) => g.Destroy())
    g.OnEvent("Escape", (*) => g.Destroy())
    g.Show()

    CopyIt(*) {
        A_Clipboard := DashSummaryText(f, timeCB.Value)
        Tip("Shift summary copied. Paste it with Ctrl+V.")
    }
    SaveIt(*) {
        dir := HomeDir "\Shift Reports"
        file := dir "\Shift summary " FormatTime(, "yyyy-MM-dd HHmm") ".html"
        try {
            DirCreate dir
            FileAppend DashSheetHtml(f, timeCB.Value), file, "UTF-8"
        } catch as e {
            MsgBox "Couldn't save the sheet.`n`n" e.Message, "Shift dashboard", "Icon!"
            return
        }
        Activity("Shift dashboard: sheet saved")
        Run file
    }
}

; A row of big numbers with a small label under each
Tiles(g, tiles) {
    ctrls := []
    for i, t in tiles {
        g.SetFont("s20 bold c0E746E", "Segoe UI")
        c := g.AddText(i = 1 ? "xm+12 y+14 w135 Center BackgroundTrans" : "x+4 yp w135 Center BackgroundTrans", t[1])
        ctrls.Push(c)
    }
    for i, t in tiles {
        ctrls[i].GetPos(&x, &y, &w, &h)
        g.SetFont("s9 norm c606060", "Segoe UI")
        g.AddText("x" x " y" y + h " w135 Center BackgroundTrans", t[2])
        bottom := y + h + 22
    }
    g.SetFont("s10 norm c000000", "Segoe UI")
    return bottom
}


; =====================================================================
;  TIME & DATE STAMPS
;  ;t  = @21:42      ;dd = 2026-10-13      ;dt = 2026-10-13 @21:42
;  (not in the template finder's search box, so ;t can be searched for,
;  and not in Settings)
; =====================================================================
StampsOK(*) => !PickerActive() && !SettingsActive()

; Registered here (not as fixed hotstrings) so the prefix can be changed
RegisterStamps() {
    HotIf StampsOK
    Hotstring(":*:" TrigKey(";t"), StampTime)
    Hotstring(":*:" TrigKey(";dd"), StampDate)
    Hotstring(":*:" TrigKey(";dt"), StampDateTime)
    HotIf
}

StampTime(*) {
    SendInput "{Text}@" FormatTime(, "HH:mm")
    CountSaved("stamp", 6 - 2, "Stamp `;t")
}

StampDate(*) {
    SendInput "{Text}" FormatTime(, "yyyy-MM-dd")
    CountSaved("stamp", 10 - 3, "Stamp `;dd")
}

StampDateTime(*) {
    SendInput "{Text}" FormatTime(, "yyyy-MM-dd") " @" FormatTime(, "HH:mm")
    CountSaved("stamp", 17 - 3, "Stamp `;dt")
}


; =====================================================================
;  APP SWITCHING  (apps are set up in settings.ini)
;  Ctrl+Alt+I = show the current window's title and program name
; =====================================================================
LoadApps() {
    taken := "QOIHPXRLEJKWAMN"
    problems := "", named := ""
    Loop 9 {
        sec := "App" A_Index
        name := Trim(IniRead(SettingsFile, sec, "Name", ""))
        if name = ""
            continue
        named .= "|" name "|"
        key := Trim(IniRead(SettingsFile, sec, "Key", ""))
        path := Trim(IniRead(SettingsFile, sec, "Path", ""))
        win := Trim(IniRead(SettingsFile, sec, "Window", ""))
        if key = "" || key = "none"          ; Key=none turns an app off
            continue
        if StrLen(key) != 1 || InStr(taken, key) {
            problems .= name ": Key must be one letter that isn't taken (" key ")`n"
            continue
        }
        Hotkey "^!" StrLower(key), MakeSwitchHandler(name, win, path)
        AppList.Push({name: name, key: StrUpper(key)})
        taken .= key
    }

    ; Built-in app hotkeys. An [AppN] section with the same Name replaces
    ; one (to change its letter), or turns it off with Key=none.
    for a in [{name: "Teams",   key: "T", win: "ahk_exe ms-teams.exe", path: "msteams:"}
            , {name: "Outlook", key: "U", win: "ahk_exe olk.exe",      path: "shell:AppsFolder\Microsoft.OutlookForWindows_8wekyb3d8bbwe!Microsoft.OutlookforWindows"}
            , {name: "Spotify", key: "Y", win: "ahk_exe Spotify.exe",  path: "spotify:"}
            , {name: "Edge",    key: "G", win: "ahk_exe msedge.exe",   path: "msedge.exe"}] {
        if InStr(named, "|" a.name "|") || InStr(taken, a.key)
            continue
        Hotkey "^!" StrLower(a.key), MakeSwitchHandler(a.name, a.win, a.path)
        AppList.Push({name: a.name, key: a.key})
        taken .= a.key
    }

    if problems != ""
        MsgBox "Some apps in settings.ini were skipped:`n`n" problems, "Watchlog", "Icon!"
}

IsBallyPath(path) => InStr(path, "SDSUI") || InStr(path, "CMPDesktop") || InStr(path, "AlertGridUI")

; The saved login that belongs to the program in front: one locked to
; its window (Window= in settings.ini, e.g. ;prd for SDS, CMP, Alert Grid)
LoginForWindow() {
    for rec in LoginList
        if rec.win != "" && SubStr(rec.trig, 1, 1) = ";" && LoginWindowActive(rec.win)
            return rec
    return ""
}

; After a Bally program comes to the front: asks, and types its login on a yes.
; Closes itself after 6 seconds (counts as no).
OfferLogin(name) {
    rec := LoginForWindow()
    if !rec
        return
    r := MsgBox("Log in to " name " as " rec.user "?`n`nEnter = yes, Esc = no. Only say yes on the login screen.", "Watchlog", "YesNo Icon? T6")
    if r = "Yes"
        DoLogin(rec.trig, rec.user, rec.pw, rec)
}

MakeSwitchHandler(name, win, path) {
    return (*) => SwitchTo(name, win, path)
}

; Switches to the app, minimizes it if it's already in front, or opens it
SwitchTo(name, match, runTarget := "") {
    SetTitleMatchMode 2
    CountSaved("", 0, "Switch to " name)
    if match != "" && WinExist(match) {
        if WinActive(match)
            WinMinimize
        else {
            WinActivate
            if IsBallyPath(runTarget) && WinWaitActive(match, , 2)
                OfferLogin(name)
        }
        return
    }
    if runTarget = ""
        return
    ; Links like msteams: or shell:AppsFolder\... open apps from the Microsoft
    ; Store (Teams, new Outlook). They aren't files, so there's nothing to check.
    if RegExMatch(runTarget, "i)^[a-z][a-z0-9+.-]+:(?!\\)") {
        try Run runTarget
        catch
            MsgBox "Couldn't open " name " with:`n" runTarget "`n`nCheck its Path in settings.ini", "Watchlog", "Icon!"
        return
    }
    path := ResolvePath(runTarget)
    if InStr(runTarget, "\") && (path = "" || !FileExist(path)) {
        MsgBox name " wasn't found here:`n" runTarget "`n`nCheck its Path in settings.ini", "Watchlog", "Icon!"
        return
    }
    SplitPath path, , &dir
    Run path, dir
    ; A Bally program just opened: once its window is up, offer to log in
    if IsBallyPath(runTarget) {
        w := match != "" ? match : DefaultStartWindow(path)
        if w != "" && WinWait(w, , 30) {
            Sleep 2000
            WinActivate "ahk_id " WinExist(w)
            if WinWaitActive(w, , 3)
                OfferLogin(name)
        }
    }
}

; The window each Bally app shows, so Ctrl+Alt+L can skip it if it's already open
DefaultStartWindow(path) {
    if InStr(path, "AlertGridUI")
        return "Alert Grid ahk_exe javaw.exe"
    if InStr(path, "SDSUI")
        return "SDS ahk_exe javaw.exe"
    if InStr(path, "CMPDesktop")
        return "ahk_exe CMPDesktop.exe"
    return ""
}

; Turns a path with * in it into a real one, picking the newest version:
; C:\BallyTechnologies\CMPDesktop*\CMPDesktop\CMPDesktop.exe
;   -> C:\BallyTechnologies\CMPDesktop15_14_2\CMPDesktop\CMPDesktop.exe
; Returns "" if nothing matches. Paths without * come back unchanged.
ResolvePath(path) {
    if !RegExMatch(path, "[*?]")
        return path
    parts := StrSplit(path, "\")
    return ResolveParts(parts[1], parts, 2)
}

ResolveParts(base, parts, i) {
    if i > parts.Length
        return FileExist(base) ? base : ""
    part := parts[i]
    if !RegExMatch(part, "[*?]")
        return ResolveParts(base "\" part, parts, i + 1)
    found := []
    Loop Files base "\" part, (i = parts.Length ? "FD" : "D")
        found.Push(A_LoopFileName)
    ; newest version first (15_14_2 is newer than 15_9)
    if found.Length > 1 {
        Loop found.Length - 1 {
            Loop found.Length - A_Index {
                j := A_Index
                if VerCompare(VersionOf(found[j]), VersionOf(found[j + 1])) < 0 {
                    tmp := found[j], found[j] := found[j + 1], found[j + 1] := tmp
                }
            }
        }
    }
    for name in found {
        r := ResolveParts(base "\" name, parts, i + 1)
        if r != ""
            return r
    }
    return ""
}

; "CMPDesktop15_14_2" -> "15.14.2"
VersionOf(name) {
    v := "", pos := 1
    while pos := RegExMatch(name, "\d+", &m, pos) {
        v .= (v = "" ? "" : ".") m[0]
        pos += m.Len
    }
    return v = "" ? "0" : v
}

; (set up by RegisterHotkeys, see HotkeyDefs)
WindowInfo() {
    title := WinGetTitle("A")
    exe := WinGetProcessName("A")
    A_Clipboard := "Title: " title "  |  Program: " exe
    Tip("Title: " title "`nProgram: " exe "`n(Copied to clipboard)", 5000)
}


; True if Edge has a window open
; (it can run in the background with no window, which doesn't count)
BrowserOpen() {
    for id in WinGetList("ahk_class Chrome_WidgetWin_1 ahk_exe msedge.exe")
        if SafeTitle(id) != ""
            return true
    return false
}

; =====================================================================
;  START OF SHIFT  -  Ctrl+Alt+L
;  Opens the programs in [StartOfShift] (any version) first, waits for
;  their windows, then opens the Citrix Receiver page in Edge (the only web
;  page it opens, so there is no tab to hunt for).
;  If Edge is already open, it asks before opening the page again.
; =====================================================================
; (set up by RegisterHotkeys, see HotkeyDefs)

StartOfShift() {
    BreakReset()
    sites := true
    if BrowserOpen()
        sites := MsgBox("Edge is already open, so the Citrix page is probably open too.`n`n"
            . "Open it again?", "Start of shift", "YesNo Icon? Default2") = "Yes"
    CoordMode "ToolTip", "Screen"
    began := A_TickCount
    secs := IsNumber(Cfg["LaunchWait"]) ? Max(Cfg["LaunchWait"], 20) : 20   ; the apps get at least 20 s
    Tip("Opening work apps...", 0, true)
    missing := ""

    SetTitleMatchMode 2
    started := []       ; how to spot each app it opened
    startedApps := []   ; the same apps, with their paths
    for app in Cfg["StartApps"] {
        target := app.path
        if app.win != "" && WinExist(app.win)    ; already open - don't open a second one
            continue
        p := ResolvePath(target)
        if InStr(target, "\") && (p = "" || !FileExist(p)) {
            missing .= "   " target "`n"
            continue
        }
        SplitPath p, , &dir
        ; a one-second gap between apps so the Java apps don't choke
        if started.Length
            Sleep 500
        try Run p, dir
        catch {
            missing .= "   " target "`n"
            continue
        }
        started.Push(app.win)
        startedApps.Push(app)
    }

    ; Wait until the apps it opened have their windows up, so they don't
    ; pop up over Edge afterwards. LaunchWait = the most it waits (seconds
    ; from pressing Ctrl+Alt+L); anything slower than that is left to finish.
    deadline := began + secs * 1000
    for w in started {
        if w = ""
            continue
        while !WinExist(w) && A_TickCount < deadline
            Sleep 200
    }
    Sleep 800           ; let the apps finish drawing
    if Cfg["SignInAfterStart"]
        SignInStarted(startedApps)
    Tip("Opening Citrix page...", 0, true)
    ; The Citrix page opens last, so it is the thing left on screen
    if sites {
        if Cfg["CitrixUrl"] = ""
            missing .= "   CitrixUrl in settings.ini is empty`n"
        else {
            ; one command, facial rec first and Citrix last, so Edge ends on the Citrix tab
            try Run 'msedge.exe ' (Cfg["FaceUrl"] != "" ? '"' Cfg["FaceUrl"] '" ' : "") '"' Cfg["CitrixUrl"] '"'
            catch
                missing .= "   Microsoft Edge (msedge.exe)`n"
        }
    }

    Tip("")
    if sites
        EdgeToFront(true)
    if Cfg["LayoutAfterStart"]
        RestoreLayout(true)
    if sites
        EdgeToFront(false)
    if missing != ""
        MsgBox "These weren't found, so they didn't open:`n`n" missing "`nCheck [StartOfShift] in settings.ini", "Watchlog", "Icon!"
}


; Start of shift: the Bally programs this run just opened are on their
; login screens, so (after one question) each is brought to the front and
; its saved login is typed. Programs that were already open are left alone.
SignInStarted(apps) {
    list := [], names := ""
    for app in apps {
        w := app.win != "" ? app.win : DefaultStartWindow(app.path)
        if w = "" || !IsBallyPath(app.path)
            continue
        n := InStr(app.path, "SDSUI") ? "SDS" : InStr(app.path, "CMPDesktop") ? "CMP" : "Alert Grid"
        list.Push({win: w, name: n})
        names .= (names != "" ? ", " : "") n
    }
    if !list.Length
        return
    Tip("")
    if MsgBox("Sign in to " names " now with your saved logins?`n`nEach program comes to the front and its login is typed.", "Start of shift", "YesNo Icon? T20") != "Yes" {
        Activity("Start of shift: sign-in skipped")
        return
    }
    SetTitleMatchMode 2
    for item in list {
        if !WinWait(item.win, , 10) {
            Activity("Start of shift sign-in: " item.name " window not found")
            continue
        }
        WinActivate "ahk_id " WinExist(item.win)
        if !WinWaitActive(item.win, , 3) {
            Activity("Start of shift sign-in: couldn't bring " item.name " to the front")
            continue
        }
        Sleep 1500
        rec := LoginForWindow()
        if !rec {
            Activity("Start of shift sign-in: no saved login is locked to " item.name)
            continue
        }
        DoLogin(rec.trig, rec.user, rec.pw, rec)
        Sleep 3000
    }
}

; Tray: pick a folder of your own for Watchlog.exe updates (settings.ini [Updates] Folder=)
ChooseUpdateFolder() {
    start := Cfg["UpdateFolder"] != "" ? Cfg["UpdateFolder"] : A_MyDocuments
    dir := DirSelect("*" start, 3, "Pick the folder where you put new Watchlog builds (leave it empty and press Cancel to keep things as they are)")
    if dir = "" {
        if Cfg["UpdateFolder"] != "" && MsgBox("Stop using your own update folder (" Cfg["UpdateFolder"] ") and go back to the team folder?", "Watchlog", "YesNo Icon?") = "Yes" {
            IniWrite "", SettingsFile, "Updates", "Folder"
            Activity("Update folder cleared (back to the team folder)")
            Reload
        }
        return
    }
    IniWrite dir, SettingsFile, "Updates", "Folder"
    Activity("Update folder set to " dir)
    MsgBox "Done. Watchlog will now offer updates from:`n" dir "`n`nPut Watchlog.exe in that folder.", "Watchlog"
    Reload
}


; Brings the Edge window with the Citrix page to the front. wait = true
; when the page was just opened: Edge gets up to 15 seconds to show it. No
; tabs are searched; a window counts when its title has CitrixTab
; (settings.ini, default "Citrix|apps.gcgaming.com") in it, and a page still
; loading is named after its address, which has apps.gcgaming.com in it.
EdgeToFront(wait) {
    want := Cfg["CitrixTab"] "|apps.gcgaming.com"
    stopAt := A_TickCount + (wait ? 15000 : 0)
    Loop {
        for id in EdgeWindows() {
            if TabHas(SafeTitle(id), want) {
                try WinActivate "ahk_id " id
                Activity("Citrix page: Edge window brought to the front (" SafeTitle(id) ")")
                return
            }
        }
        if A_TickCount >= stopAt {
            if wait
                Activity("Citrix page: no Edge window with the page appeared")
            if wait && (ids := EdgeWindows()).Length
                try WinActivate "ahk_id " ids[1]
            return
        }
        Sleep 500
    }
}

; A window's title, or "" if the window closed while Edge was opening
; or closing tabs
SafeTitle(id) {
    try return WinGetTitle("ahk_id " id)
    return ""
}

; Every Edge window that has a title (Edge also keeps hidden windows with
; no title in the background), front-most first
EdgeWindows() {
    list := []
    for id in WinGetList("ahk_class Chrome_WidgetWin_1 ahk_exe msedge.exe")
        if SafeTitle(id) != ""
            list.Push(id)
    return list
}

; True when the title has any of the "|"-separated words in it
TabHas(title, words) {
    for w in StrSplit(words, "|")
        if w != "" && InStr(title, w)
            return true
    return false
}


; =====================================================================
;  END OF SHIFT  -  Ctrl+Alt+Shift+L
;  Asks first, then closes every work app listed in settings.ini
;  ([EndOfShift] Close=...). Apps get a normal close, so anything
;  that needs saving can still ask you.
; =====================================================================
; (set up by RegisterHotkeys, see HotkeyDefs)

EndOfShift() {
    apps := Cfg["CloseApps"]
    answer := MsgBox("Log out of SDS and close all work apps?`n`nThis closes: " apps
        . "`n`nDid you enter your End of Shift log first? (Ctrl+Alt+J has your shift summary.)", "End of Shift", "YesNo Icon? Default2")
    if answer != "Yes"
        return
    ; SDS has to be logged out properly before it's closed, or the account
    ; gets locked out
    if !LogOutSDS() {
        if MsgBox("Watchlog couldn't log you out of SDS by itself.`n`n"
            . "Log out of SDS now (the lock button next to the red X, then Yes), then press OK to close everything.`n`n"
            . "Cancel stops here and closes nothing.", "End of Shift", "OKCancel Icon! Default1") != "OK"
            return
    }
    JournalEnd()
    for exe in StrSplit(apps, ",") {
        exe := Trim(exe)
        if exe = ""
            continue
        for hwnd in WinGetList(CloseTarget(exe)) {
            try WinClose("ahk_id " hwnd)
        }
    }
    CoordMode "ToolTip", "Screen"
    ToolTip "Closing work apps...", A_ScreenWidth // 2 - 70, A_ScreenHeight // 2
    Sleep 5000
    ToolTip()

    ; Anything still showing a window gets offered a force close
    left := [], names := ""
    for exe in StrSplit(apps, ",") {
        exe := Trim(exe)
        if exe != "" && WinExist(CloseTarget(exe)) {
            left.Push(exe)
            names .= "   " SubStr(WinGetTitle(CloseTarget(exe)), 1, 50) "  (" exe ")`n"
        }
    }
    if left.Length {
        answer := MsgBox("These didn't close (check for an `"Are you sure?`" popup):`n`n" names
            . "`nForce them closed? Anything unsaved in them will be lost.", "End of Shift", "YesNo Icon! Default2")
        if answer = "Yes" {
            for exe in left {
                if exe = "explorer.exe" {          ; never kill Explorer - it runs the taskbar
                    for hwnd in WinGetList(CloseTarget(exe))
                        try WinClose("ahk_id " hwnd)
                    continue
                }
                Loop 10 {
                    if !ProcessExist(exe)
                        break
                    ProcessClose exe
                    Sleep 100
                }
            }
        }
    }
    Tip("Done. Have a good one!", 2500, true)
}


; Ctrl+Alt+K: log out of SDS properly (same as end of shift does), leaving
; SDS open at its login screen
; (set up by RegisterHotkeys, see HotkeyDefs)

SDSLogout() {
    if !SDSWindow() {
        Tip("SDS isn't logged in on this PC.")
        return
    }
    if LogOutSDS()
        Tip("Logged out of SDS.", 2500, true)
    else
        MsgBox "Watchlog couldn't log you out of SDS by itself.`n`nLog out by hand: the lock button next to the red X, then Yes.", "Log out of SDS", "Icon!"
}

; Logs out of SDS the way you would by hand: the lock button on its
; toolbar (4th of 5, next to the red X), then Yes on "User ... will be
; logged out of SDS application". True when SDS is logged out or wasn't
; logged in; false when it couldn't do it or couldn't tell, so nothing
; gets closed until you've logged out yourself.
LogOutSDS() {
    sds := SDSWindow()
    if !sds
        return true
    lock := SDSLockButton(sds)
    if !lock
        return false
    if WinGetMinMax("ahk_id " sds) = -1
        WinRestore "ahk_id " sds
    WinActivate "ahk_id " sds
    WinWaitActive "ahk_id " sds, , 2
    ; Click the lock without moving the mouse; if the "logged out" question
    ; doesn't come up, try once more with a real click
    try ControlClick lock.ctrl, "ahk_id " sds, , , , "NA x" lock.x " y" lock.y
    dlg := SDSLogoutQuestion(2000)
    if !dlg {
        try {
            ControlGetPos &cx, &cy, , , lock.ctrl
            WinActivate "ahk_id " sds
            CoordMode "Mouse", "Client"
            Click cx + lock.x, cy + lock.y
        }
        dlg := SDSLogoutQuestion(3000)
    }
    if !dlg {
        Activity("End of shift: SDS logout question didn't appear")
        return false
    }
    ; Yes is the first button
    yes := ""
    try yes := ControlGetText("Button1", "ahk_id " dlg)
    if !InStr(yes, "Yes")
        return false
    ControlClick "Button1", "ahk_id " dlg, , , , "NA"
    ; Logged out once the question has gone and SDS no longer says Welcome
    Loop 100 {
        Sleep 100
        if !WinExist("ahk_id " dlg) && !SDSWindow() {
            Activity("End of shift: logged out of SDS")
            return true
        }
    }
    Activity("End of shift: SDS still looked logged in after Yes")
    return false
}

; The logged-in SDS window ("SDS | Welcome, Jakob @ Belleville"), or 0
SDSWindow() {
    for id in WinGetList("ahk_exe javaw.exe") {
        try {
            if RegExMatch(WinGetTitle(id), "i)^SDS\b.*Welcome")
                return id
        }
    }
    return 0
}

; Where the lock button is on SDS's toolbar: the 4th of its 5 buttons.
; Anything else (a different toolbar) gives 0, so it never clicks a guess.
SDSLockButton(sds) {
    found := ""
    for ctrl in WinGetControlsHwnd("ahk_id " sds) {
        if WinGetClass("ahk_id " ctrl) != "ToolbarWindow32"
            continue
        n := SendMessage(0x418, 0, 0, ctrl)          ; TB_BUTTONCOUNT
        found .= n " "
        if n != 5
            continue
        size := SendMessage(0x43A, 0, 0, ctrl)       ; TB_GETBUTTONSIZE
        w := size & 0xFFFF, h := (size >> 16) & 0xFFFF
        return {ctrl: ctrl, x: w * 3 + w // 2, y: h // 2}
    }
    Activity("End of shift: SDS lock button not found (toolbar buttons: " (found = "" ? "no toolbar" : Trim(found)) ")")
    return 0
}

; Waits up to ms for SDS's "will be logged out" question; its window, or 0
SDSLogoutQuestion(ms) {
    stopAt := A_TickCount + ms
    Loop {
        for id in WinGetList("ahk_class #32770 ahk_exe javaw.exe") {
            try {
                if InStr(WinGetText(id), "logged out")
                    return id
            }
        }
        if A_TickCount >= stopAt
            return 0
        Sleep 100
    }
}

; Which windows to close for a program name. explorer.exe also runs the
; taskbar and desktop, so for it only File Explorer windows are touched.
CloseTarget(exe) {
    if exe = "explorer.exe"
        return "ahk_class CabinetWClass ahk_exe explorer.exe"
    return "ahk_exe " exe
}


; =====================================================================
;  EDIT TEMPLATES  -  Ctrl+Alt+E   (save it and the script reloads)
;  (v3.10.0: Ctrl+Alt+E opens the template editor instead, see TEMPLATE
;  EDITOR. These Notepad ones are under tray menu > Advanced.)
; =====================================================================
; Tray menu > Advanced > Edit my templates in Notepad (makes the file the first time)
EditMine() {
    if MakeMineFile()
        EditFile(MyTemplatesFile)
}

EditFile(path) {
    if !FileExist(path) {
        MsgBox "Can't find:`n" path, "Watchlog", "Icon!"
        return
    }
    Run 'notepad.exe "' path '"'
    ; Windows 11 Notepad can open it as a tab in a window that's behind
    ; everything else, so find that window and bring it to the front
    SplitPath path, &fname
    SetTitleMatchMode 2
    if WinWait(fname " ahk_exe Notepad.exe", , 3)
        WinActivate
}


; =====================================================================
;  TEMPLATE FINDER  -  Ctrl+Alt+Space   (also tray menu > Find a template)
;  Type part of a name, a trigger, or any word from the wording, and the
;  matching templates show up with a preview. Enter runs the one picked
;  in the window you were typing in. Up/Down choose, Esc closes.
; =====================================================================
; (set up by RegisterHotkeys, see HotkeyDefs)

PickerActive() => IsObject(Picker) && WinActive("ahk_id " Picker.hwnd)

ShowPicker() {
    global Picker
    if IsObject(Picker) {
        ; Pressed again: close it (or bring it back if it's behind)
        if WinActive("ahk_id " Picker.hwnd)
            ClosePicker(true)
        else
            WinActivate "ahk_id " Picker.hwnd
        return
    }
    ; A form is already open: finish that one first
    if IsObject(CurForm) {
        try WinActivate "ahk_id " CurForm.hwnd
        return
    }
    if !TemplateList.Length {
        MsgBox "No templates are loaded. Check templates.txt (Ctrl+Alt+E).", "Find a template", "Icon!"
        return
    }
    target := WinExist("A")
    found := {rows: []}         ; template numbers in the order they're listed

    g := WGui("+AlwaysOnTop", "Find a template  -  v" VERSION)
    g.SetFont("s10", "Segoe UI")
    g.AddText("w560", "Type part of a name, a shortcut, or any word from the log:")
    box := g.AddEdit("w560")
    lv := g.AddListView("w560 r12 -Multi NoSortHdr", ["Shortcut", "Template", "Type"])
    lv.ModifyCol(1, 110), lv.ModifyCol(2, 316), lv.ModifyCol(3, 110)
    g.AddText("w560", "What it writes:")
    prev := g.AddEdit("w560 r5 ReadOnly -TabStop")
    tip := g.AddText("w560 r2", "")
    g.AddButton("w120 Default", "Insert").OnEvent("Click", Go)
    g.AddButton("x+6 w120", "Close").OnEvent("Click", (*) => ClosePicker(true))
    g.AddText("x+14 yp+5", "Up/Down = choose    Enter = insert    Esc = close")
    box.OnEvent("Change", Filter)
    lv.OnEvent("ItemSelect", Preview)
    lv.OnEvent("DoubleClick", (ctl, row) => row ? Go() : 0)
    g.OnEvent("Escape", (*) => ClosePicker(true))
    g.OnEvent("Close", (*) => ClosePicker(true))
    Picker := {hwnd: g.Hwnd, gui: g, box: box, lv: lv, target: target, go: Go, preview: Preview}
    Filter()
    g.Show()
    WinActivate "ahk_id " g.Hwnd
    box.Focus()

    ; Lists the templates that match what's typed, best match first
    Filter(*) {
        found.rows := FindTemplates(box.Value)
        lv.Opt("-Redraw")
        lv.Delete()
        for i in found.rows {
            t := TemplateList[i]
            lv.Add(, TrigKey(t.trig), t.name != "" ? t.name : t.trig, (t.repeat ? "Form, several" : t.form ? "Form" : "Instant") (t.src = "mine" ? " (mine)" : ""))
        }
        lv.Opt("+Redraw")
        if found.rows.Length
            lv.Modify(1, "Select Focus Vis")
        Preview()
    }

    ; The wording of the picked template, with its blanks in [brackets]
    Preview(*) {
        row := lv.GetNext()
        if !row {
            prev.Value := 'Nothing matches "' Trim(box.Value) '". Try one word, like jackpot or medical.'
            tip.Text := ""
            return
        }
        t := TemplateList[found.rows[row]]
        prev.Value := RegExReplace(t.text, "\{([^{}:]+)(:[^{}]*)?\}", "[$1]")
        tip.Text := "Next time you can type  " TrigKey(t.trig) "  anywhere instead of opening this. "
            . (t.repeat ? "It opens a form, and Ctrl+Enter adds another." : t.form ? "It opens a form to fill in." : "It goes in straight away.")
            . (t.src = "mine" ? " (One of yours, from my-templates.txt.)" : "")
    }

    Go(*) {
        row := lv.GetNext()
        if !row {
            box.Focus()
            return
        }
        t := TemplateList[found.rows[row]]
        ClosePicker(true)
        RunTemplate(t.text, t.name != "" ? t.name : t.trig, t.repeat, t.trig, t.fill)
    }
}

; Closes the finder. back = true puts you back in the window you were
; typing in (Citrix needs a moment longer to take the keyboard back).
ClosePicker(back := false) {
    global Picker
    if !IsObject(Picker)
        return
    p := Picker
    Picker := ""
    p.gui.Destroy()
    if back && p.target {
        ReturnTo(p.target)
    }
}

; Every word typed has to be in the shortcut, the name or the wording.
; Shortcut matches come first, then name matches, then wording matches.
; With nothing typed, every template shows, in templates.txt order.
FindTemplates(query) {
    words := []
    for w in StrSplit(RegExReplace(StrLower(query), "[^a-z0-9#]+", " "), " ")
        if w != ""
            words.Push(w)
    sorted := []
    for i, t in TemplateList {
        trig := RegExReplace(StrLower(t.trig), "[^a-z0-9#]+")
        name := " " RegExReplace(StrLower(t.name), "[^a-z0-9#]+", " ")
        body := " " RegExReplace(StrLower(t.text), "[^a-z0-9#]+", " ")
        score := 0
        for w in words {
            s := WordScore(w, trig, name, body)
            if !s {
                score := -1
                break
            }
            score += s
        }
        if score < 0
            continue
        ; Higher scores go first; equal scores keep their templates.txt order
        pos := sorted.Length + 1
        while pos > 1 && sorted[pos - 1].score < score
            pos--
        sorted.InsertAt(pos, {i: i, score: score})
    }
    rows := []
    for m in sorted
        rows.Push(m.i)
    return rows
}

WordScore(w, trig, name, body) {
    if trig = w
        return 100
    if InStr(trig, w) = 1
        return 60
    if InStr(name, " " w)
        return 40
    if InStr(trig, w) || InStr(name, w)
        return 20
    if InStr(body, " " w)
        return 10
    if InStr(body, w)
        return 5
    return 0
}

; Moves the highlight in the finder's list (works while typing in the box)
PickerMove(n) {
    lv := Picker.lv
    count := lv.GetCount()
    if !count
        return
    row := Max(1, Min(count, lv.GetNext() + n))
    lv.Modify(0, "-Select")
    lv.Modify(row, "Select Focus Vis")
    Picker.preview()
}

#HotIf PickerActive()
Up:: PickerMove(-1)
Down:: PickerMove(1)
PgUp:: PickerMove(-10)
PgDn:: PickerMove(10)
Enter:: Picker.go()
NumpadEnter:: Picker.go()
#HotIf


; =====================================================================
;  SETTINGS  -  tray menu > Settings  (it's also the first-run setup)
;  Tabs: logins, where the templates come from, start and end of shift,
;  Alert Grid, updates, the shift journal, the Caps Lock guard and
;  starting with Windows, without editing settings.ini. Nothing changes until
;  Save. Passwords typed here go straight into Windows Credential Manager
;  on this PC, and removing a login deletes its saved password too.
; =====================================================================
SetSettingsWin(v) {
    global SettingsWin := v
}

; startTab: 1 Logins, 2 Templates, 3 Start / end of shift, 4 Alert Grid,
; 5 Updates, 6 General   (v3.10.0: tabs, and the settings that used to be
; only in settings.ini are here as boxes and ticks)
ShowSettings(welcome := false, startTab := 1) {
    if IsObject(SettingsWin) {
        try WinActivate "ahk_id " SettingsWin.Hwnd
        return
    }
    if IsObject(CurForm) {
        MsgBox "Finish or close the form that's open first.", "Watchlog"
        return
    }
    ClosePicker()
    ; Working copies: nothing changes until Save
    st := {logins: CopyLogins(), shared: Cfg["SharedTemplates"], upd: Cfg["UpdateFolder"]}
    keepDays := [7, 14, 30, 60, 90, 365, 0]
    keepNames := ["7 days", "14 days", "30 days", "60 days", "90 days", "1 year", "Never"]
    if !IndexOf(keepDays, Cfg["KeepDays"])
        keepDays.InsertAt(1, Cfg["KeepDays"]), keepNames.InsertAt(1, Cfg["KeepDays"] " days")
    modes := ["full", "counts", "off"]
    clickGap := IniRead(SettingsFile, "AlertGrid", "Pause", "40")
    W := 640

    g := WGui("+AlwaysOnTop", (welcome ? "Welcome to Watchlog" : "Watchlog settings") "  -  v" VERSION)
    SetSettingsWin(g)
    g.BackColor := "FFFFFF"     ; the same white as the tab pages
    g.SetFont("s10", "Segoe UI")
    if welcome {
        g.SetFont("s12 bold")
        g.AddText("w" W, "Welcome! Two quick things and you're set.")
        g.SetFont("s10 norm")
        g.AddText("w" W, "1.   Add the logins you'd like typed for you (or skip this).`n"
            . "2.   If your team keeps its templates on SharePoint, pick that file on the Templates tab.`n"
            . "Then press Save. You can change any of this later: click the teal icon near the clock > Settings.")
    }
    tabs := g.AddTab2("xm w" (W + 36) " h400 Choose" startTab, ["Logins", "Templates", "Start / end of shift", "Alert Grid", "Updates", "General"])

    ; ---- Logins
    tabs.UseTab(1)
    g.AddText("Section w" W, "Type a login's shortcut and it types the username, Tab, the password and Enter. Passwords are kept in Windows Credential Manager on this PC only, never in a file.")
    lv := g.AddListView("xs w" W " r7 -Multi NoSortHdr", ["Shortcut", "Username", "Only in", "Reminder", "Password on this PC"])
    lv.ModifyCol(1, 95), lv.ModifyCol(2, 165), lv.ModifyCol(3, 120), lv.ModifyCol(4, 80), lv.ModifyCol(5, 176)
    g.AddButton("xs w120", "Add...").OnEvent("Click", (*) => LoginBox(0))
    g.AddButton("x+6 w120", "Edit...").OnEvent("Click", (*) => LoginBox(Picked()))
    g.AddButton("x+6 w160", "Change password...").OnEvent("Click", (*) => LoginBox(Picked(), true))
    g.AddButton("x+6 w120", "Remove").OnEvent("Click", RemoveLogin)
    lv.OnEvent("DoubleClick", (ctl, row) => row ? LoginBox(row) : 0)
    sdsCB := g.AddCheckbox("xs y+16" (Cfg["SdsResign"] ? " Checked" : ""), "Sign back into SDS by itself this many minutes after I sign in (replaces its reminder):")
    sdsE := g.AddEdit("xs+18 y+4 w60 Number", Cfg["SdsResign"] ? Cfg["SdsResign"] : 62)
    g.AddText("x+6 yp+3", "minutes (SDS logs out after an hour, so 62)")
    beepCB := g.AddCheckbox("xs y+12" (Cfg["ReminderBeep"] ? " Checked" : ""), "Beep when a log-in-again reminder pops up")

    ; ---- Templates
    tabs.UseTab(2)
    g.AddText("Section w" W, "The team's shared templates file (in SharePoint, synced by OneDrive). Leave it blank to use templates.txt in the Watchlog folder.")
    pathBox := g.AddEdit("xs w420 r1 ReadOnly", st.shared)
    g.AddButton("x+6 w100", "Browse...").OnEvent("Click", Browse)
    g.AddButton("x+6 w100", "Clear").OnEvent("Click", ClearShared)
    info := g.AddText("xs w" W " r2", "")
    g.AddText("xs y+18 w" W, "To change the wording of a template, add one, or change a list like @tables, use the template editor. Your own extra templates (my-templates.txt, just for you) are in there too.")
    g.AddButton("xs w240", "Open the template editor").OnEvent("Click", (*) => (Close(), ShowEditor()))

    ; ---- Start / end of shift
    tabs.UseTab(3)
    g.AddText("Section w" W, "Start of shift (Ctrl+Alt+L) opens your work programs (Alert Grid, SDS, CMP), waits for them, then opens iTrak facial rec and the Citrix page in Edge (Citrix last, so you can start iTrak).")
    signCB := g.AddCheckbox("xs y+10" (Cfg["SignInAfterStart"] ? " Checked" : ""), "Then sign in to the Bally programs it opened with my saved logins (asks first)")
    layCB := g.AddCheckbox("xs" (Cfg["LayoutAfterStart"] ? " Checked" : ""), "Then put my windows back where I saved them (Ctrl+Alt+Shift+S saves)")
    g.AddText("xs y+12", "Wait for the programs for up to")
    waitE := g.AddEdit("x+6 yp-3 w60 Number", Cfg["LaunchWait"])
    g.AddText("x+6 yp+3", "seconds (20 or more)")
    g.AddText("xs y+12 w" W, "The page Ctrl+Alt+L opens in Edge (Citrix Receiver):")
    urlE := g.AddEdit("xs w526 r1", Cfg["CitrixUrl"])
    g.AddText("xs y+10 w" W, "The iTrak facial rec page Ctrl+Alt+L opens first (blank = don't open it):")
    faceE := g.AddEdit("xs w526 r1", Cfg["FaceUrl"])
    g.AddText("xs y+14 w" W, "End of shift (Ctrl+Alt+Shift+L) logs out of SDS, then closes these programs (separate them with commas):")
    closeE := g.AddEdit("xs w" W " r3", Cfg["CloseApps"])

    ; ---- Alert Grid
    tabs.UseTab(4)
    taught := AlertTaught()
    g.AddText("Section w" W, "Ctrl+Alt+A acknowledges every alert in Alert Grid in one go (it never types your password), wherever Alert Grid is and whatever its size. A PC has to be shown where to click once, or it can use a setup shared from another PC.")
    g.SetFont("s10 c" (taught != "" ? "2E7D32" : "B86E00"))
    g.AddText("xs y+12 w" W, taught = "here" ? "●  The clicks are taught on this PC."
        : taught = "team" ? "●  Using the team's shared setup (taught on another PC)." : "●  The clicks aren't taught on this PC yet.")
    g.SetFont("s10 c000000")
    g.AddButton("xs y+8 w240", taught = "here" ? "Teach the clicks again..." : "Teach the clicks now...").OnEvent("Click", TeachNow)
    g.AddButton("x+8 w240", "Share my setup with the team...").OnEvent("Click", (*) => ShareAlertSetup())
    capsClearCB := g.AddCheckbox("xs y+16" (Cfg["CapsClearsAlerts"] ? " Checked" : ""), "Plain Caps Lock clears the alerts too (needs the Caps Lock guard on, General tab)")
    g.AddText("xs y+14", "Wait between clicks:")
    pauseE := g.AddEdit("x+6 yp-3 w60 Number", clickGap)
    g.AddText("x+6 yp+3", "milliseconds (40 is normal; raise it if a clear misses a step)")
    g.AddText("xs y+14", "'Acknowledge as received' is menu line:")
    lineE := g.AddEdit("x+6 yp-3 w40 Number", AlertMenuLine())
    g.AddText("x+6 yp+3", "(1 = top; for the arrow keys when the menu opens upward)")
    g.SetFont("s10 bold")
    g.AddText("xs y+22", "iTrak: new daily log (Ctrl+Alt+D)")
    g.SetFont("s10 norm")
    itTaught := ITrakTaught()
    g.SetFont("s10 c" (itTaught != "" ? "2E7D32" : "B86E00"))
    g.AddText("xs y+6 w" W, itTaught = "here" ? "●  The click is taught on this PC." : itTaught = "team" ? "●  Using the team's shared setup." : "●  The click isn't taught on this PC yet.")
    g.SetFont("s10 c000000")
    g.AddButton("xs y+6 w240", itTaught = "here" ? "Teach the iTrak click again..." : "Teach the iTrak click...").OnEvent("Click", TeachITrakNow)
    g.AddButton("x+8 w240", "Share it with the team...").OnEvent("Click", (*) => ShareITrakSetup())

    ; ---- Updates
    tabs.UseTab(5)
    g.AddText("Section w" W, "When a newer Watchlog is put in the team folder (the folder the team templates file is in), every PC offers to update. You can pick a folder of your own instead, for trying a new version before the team gets it.")
    g.AddText("xs y+12 w" W, "My own update folder (blank = the team folder):")
    updE := g.AddEdit("xs w420 r1 ReadOnly", st.upd)
    g.AddButton("x+6 w100", "Browse...").OnEvent("Click", BrowseUpd)
    g.AddButton("x+6 w100", "Clear").OnEvent("Click", (*) => (st.upd := "", updE.Value := "", ShowUpd()))
    updInfo := g.AddText("xs y+10 w" W " r3 c505050", "")

    ; ---- General
    tabs.UseTab(6)
    g.SetFont("s10 bold")
    g.AddText("Section", "Shift journal")
    g.SetFont("s10 norm")
    modeDD := g.AddDropDownList("xs w330 Choose" Max(1, IndexOf(modes, Cfg["JournalSave"]))
        , ["Save each log's time, name and text", "Save only the time and template name", "Don't keep a shift journal"])
    g.AddText("x+14 yp+4", "Delete shift files after")
    keepDD := g.AddDropDownList("x+6 yp-4 w100 Choose" IndexOf(keepDays, Cfg["KeepDays"]), keepNames)
    g.SetFont("s10 bold")
    g.AddText("xs y+18", "This PC")
    g.SetFont("s10 norm")
    capsCB := g.AddCheckbox("xs y+6" (CapsGuard ? " Checked" : ""), "Caps Lock guard: plain Caps Lock can't turn it on by accident (Shift+Caps Lock does), red tag while it's on")
    startCB := g.AddCheckbox("xs y+6" (StartupShortcuts().Length ? " Checked" : ""), "Start Watchlog when I sign in to Windows")
    g.AddText("xs y+14", "Type this in front of code words and logins:")
    prefE := g.AddEdit("x+8 yp-3 w60 Limit3", Cfg["Prefix"])
    g.AddText("x+8 yp+3 w330", "(a `; by default, 1 to 3 symbols, no letters or digits)")
    g.AddText("xs y+4 w" W, "The templates and shared files keep the `; in them: this PC just types your prefix instead. Press Ctrl+Alt+H after saving to see your shortcuts.")
    tabs.UseTab()

    tabs.GetPos(&tx, &ty, &tw, &th)
    g.AddButton("x" tx " y" (ty + th + 12) " w120 Default", "Save").OnEvent("Click", Save)
    g.AddButton("x+6 w120", "Cancel").OnEvent("Click", Close)
    if welcome
        g.AddText("x+14 yp+4 w380", "Then: type a shortcut like `;jack in iTrak, or click the teal icon by the clock.")
    g.OnEvent("Escape", Close)
    g.OnEvent("Close", Close)
    Refresh()
    ShowInfo()
    ShowUpd()
    g.Show()
    WinActivate "ahk_id " g.Hwnd

    Refresh(sel := 0) {
        lv.Delete()
        for x in st.logins
            lv.Add(, TrigKey(x.trig), x.user, x.win != "" ? x.win : "(any program)", x.remind ? x.remind " min" : ""
                , x.pw != "" ? "new one, saved on Save" : CredExists(x.user) ? "saved" : "not yet (asks once)")
        if sel
            lv.Modify(sel, "Select Focus Vis")
    }

    ShowInfo() {
        if st.shared = "" {
            cnt := 0
            try cnt := CountTemplates(FileRead(TemplatesFile, "UTF-8"))
            info.Text := "Using templates.txt in the Watchlog folder (" cnt " templates)."
            return
        }
        try {
            body := FileRead(st.shared, "UTF-8")
            ver := RegExMatch(body, "im)^#\s*Wording version\s*:\s*(.*?)\s*$", &mv) ? mv[1] : ""
            info.Text := "Found it: " CountTemplates(body) " templates" (ver != "" ? ", wording version " ver : "")
                . ". A copy is kept on this PC in case SharePoint can't be reached."
        } catch {
            info.Text := "Can't open that file right now (is OneDrive running and synced?). The last good copy on this PC is used until it can be."
        }
    }

    ; Where updates would come from with what's picked now, and what's there
    ShowUpd() {
        dir := st.upd
        if dir = "" && st.shared != ""
            SplitPath st.shared, , &dir
        if dir = "" {
            updInfo.Text := "There's no team folder (no team templates file is picked), so updates are only offered from a folder of your own."
            return
        }
        f := dir (A_IsCompiled ? "\Watchlog.exe" : "\Watchlog.ahk")
        v := ProgramVersionOf(f)
        updInfo.Text := "Looking in: " dir "`n"
            . (v = "" ? "No Watchlog there right now." : "Watchlog v" v " is there" (VerCompare(v, VERSION) > 0 ? ", newer than this one (v" VERSION "): it's offered when Watchlog next starts." : ", the same as or older than this one (v" VERSION ")."))
    }

    ; The login picked in the list (-1 if none)
    Picked() {
        g.Opt("+OwnDialogs")
        row := lv.GetNext()
        if !row && st.logins.Length = 1
            row := 1
        if !row {
            MsgBox st.logins.Length ? "Pick a login in the list first." : "There are no logins yet. Press Add to make one.", "Watchlog"
            return -1
        }
        return row
    }

    ; Add (row 0) or edit a login. pwOnly starts on the password box.
    LoginBox(row, pwOnly := false) {
        if row < 0
            return
        if row = 0 && st.logins.Length >= 9 {
            g.Opt("+OwnDialogs")
            MsgBox "There's room for 9 logins.", "Watchlog"
            return
        }
        cur := row ? st.logins[row] : {trig: ";", user: "", win: "", remind: 0, pw: ""}
        d := WGui("+AlwaysOnTop +Owner" g.Hwnd, row ? "Login " cur.trig : "Add a login")
        d.SetFont("s10", "Segoe UI")
        d.AddText("w420", "Shortcut you'll type. Start it with `; so it never fires while you're typing normally:")
        tb := d.AddEdit("w420", cur.trig)
        d.AddText("w420", "Username:")
        ub := d.AddEdit("w420", cur.user)
        d.AddText("w420", row ? "New password (leave it blank to keep the one saved on this PC):" : "Password (or leave it blank and it asks the first time you use it):")
        pb := d.AddEdit("w420 Password")
        d.AddText("w420", "Only works in these windows (use | between several). Pick window fills it in for you:")
        wb := d.AddEdit("w420", cur.win)
        d.AddButton("xm w140", "Pick window...").OnEvent("Click", PickIt)
        d.AddText("w420", "Optional: remind me to log in again after this many minutes:")
        rb := d.AddEdit("w80 Number", cur.remind ? cur.remind : "")
        d.AddButton("xm y+14 w120 Default", "OK").OnEvent("Click", OK)
        d.AddButton("x+6 w120", "Cancel").OnEvent("Click", Done)
        d.OnEvent("Escape", Done)
        d.OnEvent("Close", Done)
        g.Opt("+Disabled")
        d.Show()
        if pwOnly {
            pb.Focus()
        } else {
            tb.Focus()
            SendMessage 0xB1, StrLen(cur.trig), StrLen(cur.trig), tb      ; cursor at the end
        }

        PickIt(*) {
            d.Opt("+OwnDialogs")
            got := PickWindow()
            if got = ""
                return
            have := Trim(wb.Value)
            wb.Value := have != "" ? have " | " got : got
        }

        Done(*) {
            g.Opt("-Disabled")
            d.Destroy()
            try WinActivate "ahk_id " g.Hwnd
        }

        OK(*) {
            d.Opt("+OwnDialogs")
            nt := Trim(tb.Value), nu := Trim(ub.Value), nw := Trim(wb.Value), nr := Trim(rb.Value)
            err := LoginProblem(nt, nu, nw, nr, st.logins, row)
            if err != "" {
                MsgBox err, "Watchlog", "Icon!"
                return
            }
            ; A typed password waits for Save (a new one typed earlier is kept
            ; if the username didn't change)
            npw := pb.Value != "" ? pb.Value : (row && cur.user = nu) ? cur.pw : ""
            rec := {trig: nt, user: nu, win: nw, remind: nr = "" ? 0 : Integer(nr), pw: npw}
            if row
                st.logins[row] := rec
            else
                st.logins.Push(rec)
            Done()
            Refresh(row ? row : st.logins.Length)
        }
    }

    RemoveLogin(*) {
        row := Picked()
        if row < 1
            return
        x := st.logins[row]
        if MsgBox("Remove the login " x.trig " (" x.user ")?`n`nWhen you press Save, its password is deleted from this PC too.", "Watchlog", "YesNo Icon? Default2") != "Yes"
            return
        st.logins.RemoveAt(row)
        Refresh()
    }

    Browse(*) {
        g.Opt("+OwnDialogs")
        startAt := st.shared != "" ? st.shared : EnvGet("USERPROFILE")
        chosen := FileSelect(3, startAt, "Pick the team's templates file (in the synced SharePoint folder)", "Text files (*.txt)")
        if chosen = ""
            return
        if chosen = TemplatesFile {
            ClearShared()
            return
        }
        try body := FileRead(chosen, "UTF-8")
        catch as e {
            MsgBox "Couldn't open that file:`n" e.Message, "Watchlog", "Icon!"
            return
        }
        if !CountTemplates(body) {
            MsgBox "That file doesn't have any templates in it. Pick the team's templates file.", "Watchlog", "Icon!"
            return
        }
        st.shared := chosen
        pathBox.Value := chosen
        ShowInfo()
        ShowUpd()
    }

    ClearShared(*) {
        st.shared := ""
        pathBox.Value := ""
        ShowInfo()
        ShowUpd()
    }

    BrowseUpd(*) {
        g.Opt("+OwnDialogs")
        dir := DirSelect("*" (st.upd != "" ? st.upd : A_MyDocuments), 3, "Pick the folder where you put new Watchlog builds")
        if dir = ""
            return
        st.upd := dir
        updE.Value := dir
        ShowUpd()
    }

    TeachNow(*) {
        Close()
        SetTimer TeachAlerts, -300
    }

    TeachITrakNow(*) {
        Close()
        SetTimer TeachITrak, -300
    }

    Save(*) {
        g.Opt("+OwnDialogs")
        wait := Trim(waitE.Value), gap := Trim(pauseE.Value)
        if !IsInteger(wait) || wait < 1 || wait > 600 {
            tabs.Choose(3)
            MsgBox "Type how many seconds to wait for the programs, like 20.", "Watchlog", "Icon!"
            return
        }
        if !IsInteger(gap) || gap > 2000 {
            tabs.Choose(4)
            MsgBox "Type the wait between Alert Grid clicks in milliseconds, like 40 (2000 at most).", "Watchlog", "Icon!"
            return
        }
        menuLine := Trim(lineE.Value)
        if menuLine != "" && (!IsInteger(menuLine) || menuLine < 1 || menuLine > 20) {
            tabs.Choose(4)
            MsgBox "Type which line of Alert Grid's right-click menu 'Acknowledge as received' is, like 2 (1 = top), or leave it blank.", "Watchlog", "Icon!"
            return
        }
        newPfx := Trim(prefE.Value)
        if newPfx = ""
            newPfx := ";"
        if StrLen(newPfx) > 3 || RegExMatch(newPfx, "[\s:a-zA-Z0-9]") || InStr(newPfx, "``") {
            tabs.Choose(6)
            MsgBox "The prefix must be 1 to 3 symbols, like `; or . or // (no letters, digits, spaces or colons).", "Watchlog", "Icon!"
            return
        }
        failed := ""
        ; New passwords go into Credential Manager first
        for x in st.logins {
            if x.pw = ""
                continue
            if CredSave(x.user, x.pw)
                Activity("Password saved on this PC for " x.user " (Settings)")
            else
                failed .= "   " x.user "`n"
            x.pw := ""
        }
        ; A removed login's password is deleted from this PC
        RemovePasswords(st.logins)
        yn(v) => v ? "yes" : "no"
        try {
            WriteLogins(st.logins)
            IniWrite st.shared, SettingsFile, "Templates", "Shared"
            IniWrite modes[modeDD.Value], SettingsFile, "Journal", "Save"
            IniWrite keepDays[keepDD.Value], SettingsFile, "Journal", "KeepDays"
            IniWrite yn(beepCB.Value), SettingsFile, "Reminder", "Beep"
            sdsMin := sdsCB.Value ? Max(1, Min(600, Integer(sdsE.Value != "" ? sdsE.Value : 62))) : 0
            if sdsMin != Cfg["SdsResign"]
                IniWrite sdsMin, SettingsFile, "SDS", "ResignMinutes"
            ; The rest only when changed, so settings.ini stays short
            if signCB.Value != Cfg["SignInAfterStart"]
                IniWrite yn(signCB.Value), SettingsFile, "StartOfShift", "SignIn"
            if layCB.Value != Cfg["LayoutAfterStart"]
                IniWrite yn(layCB.Value), SettingsFile, "Layout", "AfterStart"
            if wait != Cfg["LaunchWait"]
                IniWrite wait, SettingsFile, "Paths", "LaunchWait"
            if Trim(faceE.Value) != Cfg["FaceUrl"]
                IniWrite Trim(faceE.Value), SettingsFile, "Paths", "FaceUrl"
            if Trim(urlE.Value) != Cfg["CitrixUrl"]
                IniWrite Trim(urlE.Value), SettingsFile, "Paths", "CitrixUrl"
            apps := Trim(RegExReplace(closeE.Value, "\s*[\r\n]+\s*", ", "), " ,")
            if apps != Cfg["CloseApps"]
                IniWrite apps, SettingsFile, "EndOfShift", "Close"
            if capsClearCB.Value != Cfg["CapsClearsAlerts"]
                IniWrite yn(capsClearCB.Value), SettingsFile, "AlertGrid", "CapsLockClears"
            if gap != clickGap
                IniWrite gap, SettingsFile, "AlertGrid", "Pause"
            if menuLine != AlertMenuLine() {
                if menuLine = "" {
                    try IniDelete AlertFile, "Clicks", "MenuLine"
                } else
                    IniWrite Integer(menuLine), AlertFile, "Clicks", "MenuLine"
            }
            if st.upd != Cfg["UpdateFolder"]
                IniWrite st.upd, SettingsFile, "Updates", "Folder"
            if newPfx != Cfg["Prefix"] {
                if newPfx = ";" {
                    try IniDelete SettingsFile, "Triggers", "Prefix"
                } else
                    IniWrite newPfx, SettingsFile, "Triggers", "Prefix"
            }
        } catch as e {
            MsgBox "Couldn't save settings.ini:`n" e.Message "`n`nIf OneDrive is syncing, press Save again in a moment.", "Watchlog", "Icon!"
            return
        }
        if capsCB.Value != CapsGuard {
            try DirCreate DataDir
            try IniWrite capsCB.Value ? "1" : "0", LastUsedFile, "Caps", "Guard"
        }
        SetStartup(startCB.Value)
        names := ""
        for x in st.logins
            names .= (names = "" ? "" : ", ") x.trig " " x.user
        Activity("Settings saved: logins " (names = "" ? "none" : names)
            . "; team templates " (st.shared = "" ? "none (templates.txt in this folder)" : st.shared)
            . "; journal " modes[modeDD.Value] ", kept " (keepDays[keepDD.Value] ? keepDays[keepDD.Value] " days" : "forever")
            . "; start with Windows " (startCB.Value ? "on" : "off")
            . "; sign in at start " yn(signCB.Value) ", windows back " yn(layCB.Value) ", wait " wait " s"
            . "; Caps Lock clears alerts " yn(capsClearCB.Value) ", click gap " gap " ms; Caps Lock guard " (capsCB.Value ? "on" : "off")
            . "; update folder " (st.upd = "" ? "team folder" : st.upd)
            . "; code word prefix " newPfx)
        if failed != ""
            MsgBox "These passwords couldn't be saved in Credential Manager, so each one is asked for the first time you use it:`n`n" failed, "Watchlog", "Icon!"
        SetSettingsWin("")
        g.Destroy()
        Tip("Settings saved")
        Sleep 700
        ReloadOnce()
    }

    Close(*) {
        SetSettingsWin("")
        g.Destroy()
    }
}

CopyLogins() {
    list := []
    for l in LoginList
        list.Push({trig: l.trig, user: l.user, win: l.win, remind: l.remind, pw: ""})
    return list
}

IndexOf(arr, val) {
    for i, v in arr
        if v = val
            return i
    return 0
}

; What's wrong with a login typed into Settings ("" if nothing)
LoginProblem(trig, user, win, remind, logins, row) {
    if trig = "" || trig = ";"
        return "Type the shortcut, like `;me"
    if InStr(trig, " ")
        return "The shortcut can't have spaces in it."
    if SubStr(trig, 1, 1) != ";" && win = ""
        return "Start the shortcut with `; (like `;me). Without it, it could fire in a chat or an email and type your password there.`n`n(Or fill in the window box, so it only works in that one program.)"
    if RegExMatch(trig, "i)^(;t|;dd|;dt)")
        return trig " starts like a time/date stamp (;t `;dd `;dt), so it would never fire. Pick another shortcut."
    for i, l in logins {
        if i != row && (InStr(l.trig, trig) = 1 || InStr(trig, l.trig) = 1)
            return trig " and the login " l.trig " start the same way, so the shorter one would fire before you finish typing the longer one. Pick another shortcut."
    }
    for t in TemplateList {
        if InStr(t.trig, trig) = 1 || InStr(trig, t.trig) = 1
            return trig " and the template " t.trig " start the same way, so the shorter one would fire before you finish typing the longer one. Pick another shortcut."
    }
    if user = ""
        return "Type the username."
    if InStr(user, " ")
        return "The username can't have spaces in it."
    if remind != "" && remind != "0" && Integer(remind) > 600
        return "The reminder is in minutes, up to 600 (like 55)."
    return ""
}

; Writes the logins as [Login1] ... [Login9] (no passwords), and removes
; the older single login under [User]
WriteLogins(logins) {
    for key in ["LoginTrigger", "LoginUser", "LoginPassword"]
        try IniDelete SettingsFile, "User", key
    Loop 9 {
        sec := "Login" A_Index
        if A_Index > logins.Length {
            try IniDelete SettingsFile, sec
            continue
        }
        l := logins[A_Index]
        IniWrite l.trig, SettingsFile, sec, "Trigger"
        IniWrite l.user, SettingsFile, sec, "User"
        IniSetOrDelete(sec, "Window", l.win)
        IniSetOrDelete(sec, "Remind", l.remind ? l.remind : "")
        try IniDelete SettingsFile, sec, "Password"
    }
}

IniSetOrDelete(sec, key, val) {
    if val != ""
        IniWrite val, SettingsFile, sec, key
    else
        try IniDelete SettingsFile, sec, key
}

; Deletes the saved password of every login that's gone (unless another
; login still uses the same username)
RemovePasswords(newLogins) {
    keep := Map()
    keep.CaseSense := false
    for x in newLogins
        keep[x.user] := true
    for l in LoginList {
        if keep.Has(l.user)
            continue
        keep[l.user] := true
        if CredExists(l.user) && CredRemove(l.user)
            Activity("Password deleted from this PC for " l.user " (login removed)")
    }
}


; =====================================================================
;  START WITH WINDOWS  (Settings > Windows)
;  A shortcut in your Startup folder (shell:startup) opens the script
;  when you sign in to Windows.
; =====================================================================
StartupShortcuts() {
    found := []
    Loop Files A_Startup "\*.lnk" {
        try {
            FileGetShortcut A_LoopFileFullPath, &target, , &args
            if InStr(target, A_ScriptName) || InStr(args, A_ScriptName)
                found.Push(A_LoopFileFullPath)
        }
    }
    return found
}

SetStartup(on) {
    have := StartupShortcuts()
    if on && !have.Length {
        try {
            FileCreateShortcut A_ScriptFullPath, A_Startup "\Watchlog.lnk", A_ScriptDir, , "Watchlog", FileExist(IconFile) ? IconFile : ""
            Activity("Start with Windows turned on")
        } catch as e {
            MsgBox "Couldn't add it to the Startup folder:`n" e.Message, "Watchlog", "Icon!"
        }
    } else if !on && have.Length {
        for f in have
            try FileDelete f
        Activity("Start with Windows turned off")
    }
}


; =====================================================================
;  SECURITY AND STATUS  -  tray menu > Security and status
;  Everything the tool keeps, where it is and what it never keeps,
;  checked live on this PC. Copy report puts it on the clipboard, to
;  send to IT or a supervisor. It never shows a password.
; =====================================================================
ShowSecurity() {
    report := SecurityReport()
    teal := "0F766E", ink := "1F2933", muted := "6B7280"
    g := WGui("+AlwaysOnTop", "Security and status  -  v" VERSION)
    g.BackColor := "F4F7F7"
    g.MarginX := 18, g.MarginY := 14
    g.SetFont("s18 bold c" teal, "Segoe UI")
    g.AddText("w800", "Security and status")
    g.SetFont("s10 norm c" muted, "Segoe UI")
    g.AddText("w800 y+0", "What Watchlog keeps on this PC, where it is, and what it never keeps. Checked just now.")
    ; Traffic lights: green = fine, amber = look at it, red = fix it
    good := "15803D", warn := "B45309", bad := "B91C1C"
    lights := []
    pw := PasswordInSettings()
    lights.Push(pw ? [bad, "A password is typed into settings.ini. Press Ctrl+Alt+R and it is moved out."]
        : [good, "No passwords in settings.ini. Saved passwords live in Windows Credential Manager only."])
    lights.Push([InStr(VersionStatus(), "OUT OF DATE") ? bad : good, "Version v" VERSION ", check code " ProgramCode() ". " VersionStatus()])
    od := !InStr(HomeDir, "OneDrive") ? "The Watchlog folder is not in OneDrive."
        : ProcessExist("OneDrive.exe") ? "OneDrive is running, so this PC gets changes as they sync." : "OneDrive is NOT running, so this PC may have older files."
    lights.Push([InStr(od, "NOT") ? warn : good, od])
    lights.Push([good, "Makes no internet connections and sends nothing anywhere itself."])
    conflicts := ""
    Loop Files HomeDir "\settings-*.ini"
        conflicts .= (conflicts = "" ? "" : ", ") A_LoopFileName
    if conflicts != ""
        lights.Push([warn, "OneDrive made copies of settings.ini: " conflicts ". Compare them, then delete them."])
    g.SetFont("s10 norm c" ink, "Segoe UI")
    for l in lights {
        g.SetFont("s12 bold c" l[1], "Segoe UI")
        g.AddText("x18 y+8 w22", Chr(0x25CF))
        g.SetFont("s10 norm c" ink, "Segoe UI")
        g.AddText("x42 yp+2 w776", l[2])
    }
    ; One tab for each part of the report
    secs := SecuritySections(report)
    names := []
    for sc in secs
        names.Push(sc.tab)
    g.SetFont("s10 norm c" ink, "Segoe UI")
    tabs := g.AddTab3("x18 y+14 w800 h330", names)
    for sc in secs {
        tabs.UseTab(A_Index)
        g.SetFont("s10 norm c" ink, "Consolas")
        g.AddEdit("x30 y+10 w776 h286 ReadOnly -WantReturn -TabStop VScroll BackgroundWhite", sc.body)
    }
    tabs.UseTab()
    g.SetFont("s10 norm c" ink, "Segoe UI")
    g.AddButton("x18 y+14 w150 Default", "Copy full report").OnEvent("Click", CopyIt)
    g.AddButton("x+6 w150", "Open activity log").OnEvent("Click", (*) => OpenActivity())
    g.AddButton("x+6 w150", "Settings...").OnEvent("Click", OpenSettings)
    g.AddButton("x+6 w150", "Close").OnEvent("Click", (*) => g.Destroy())
    g.OnEvent("Escape", (*) => g.Destroy())
    g.Show()

    CopyIt(*) {
        A_Clipboard := report
        Tip("Report copied. Paste it with Ctrl+V.")
    }

    OpenSettings(*) {
        g.Destroy()
        ShowSettings()
    }
}

; Splits the report into tabs: [{tab, body}]. A heading is a line of capital
; letters after a blank line; the first block (before any heading) is Overview.
SecuritySections(report) {
    secs := [{tab: "Overview", body: ""}]
    blank := false          ; the very first line (WATCHLOG v...) is not a heading
    for line in StrSplit(report, "`n", "`r") {
        if blank && RegExMatch(line, "^([A-Z][A-Z ]{3,}[A-Z])(\s|$)", &m) {
            tab := Map("PASSWORDS", "Passwords", "TEMPLATES", "Templates", "SHIFT JOURNAL", "Journal"
                , "EVERYTHING ELSE IT KEEPS", "Kept on this PC", "WHAT IT NEVER DOES", "Never", "TO CHECK", "To check")
            secs.Push({tab: tab.Has(m[1]) ? tab[m[1]] : m[1], body: line "`r`n"})
        } else if line = "" {
            secs[secs.Length].body .= "`r`n"
        } else if RegExMatch(line, "^Start with Windows") {
            secs[1].body .= line "`r`n"
        } else {
            secs[secs.Length].body .= line "`r`n"
        }
        blank := line = ""
    }
    return secs
}

SecurityReport() {
    nl := "`r`n"
    r := "WATCHLOG v" VERSION " (" VERSION_DATE ")  -  security and status" nl
    r .= COPYRIGHT " Used by permission only (tray menu > About Watchlog)." nl
    r .= "Checked " FormatTime(, "yyyy-MM-dd HH:mm") " on " A_ComputerName ", Windows user " A_UserName nl
    r .= "Program:   " A_ScriptFullPath nl
    r .= "Version:   v" VERSION ", program check code " ProgramCode() ". " VersionStatus() nl
    r .= "OneDrive:  " (!InStr(HomeDir, "OneDrive") ? "the Watchlog folder isn't in OneDrive"
        : ProcessExist("OneDrive.exe") ? "running, so this PC gets changes as they sync" : "NOT running, so this PC may have older files") nl

    r .= nl "PASSWORDS" nl
    r .= "  Kept in Windows Credential Manager on this PC only, saved as `"Watchlog: <username>`"." nl
    r .= "  Never written to a file, never synced, never in the shift journal or the activity log." nl
    r .= "  Each PC asks once. Removing a login in Settings deletes its password from this PC." nl
    if LoginList.Length {
        for l in LoginList
            r .= "    " Format("{:-10}", l.trig) " " Format("{:-22}", l.user)
                . (CredExists(l.user) ? "saved on this PC" : "not saved yet (asks the first time)")
                . (l.win != "" ? ", only works in " l.win : ", works in ANY program (no window set)") nl
    } else {
        r .= "    No logins set up." nl
    }
    r .= "  settings.ini: " (PasswordInSettings() ? "HAS A PASSWORD TYPED IN IT. Press Ctrl+Alt+R and it's moved out." : "no passwords in it (checked just now)") nl

    r .= nl "TEMPLATES  (wording only)" nl
    switch Tpl.src {
        case "team": r .= "  Team file:  " Tpl.file nl
        case "team-copy": r .= "  The saved copy of the team file (the shared one couldn't be read):" nl "              " TeamCopyFile nl
        default: r .= "  templates.txt in the program folder" nl
    }
    r .= "  " Tpl.count " templates" (Tpl.version != "" ? ", wording version " Tpl.version : "") ", check code " Tpl.code nl
    r .= "  (Two PCs with the same check code have exactly the same wording.)" nl
    if Tpl.note != ""
        r .= "  Note: " Tpl.note nl
    r .= "  Your own: " (Tpl.mine ? Tpl.mine " in my-templates.txt" : "none (my-templates.txt)") nl
    if Cfg["SharedTemplates"] != ""
        r .= "  Copy kept for when SharePoint can't be reached:  " TeamCopyFile nl

    jf := JournalFiles()
    r .= nl "SHIFT JOURNAL  (a copy of each log you insert, for your shift summary)" nl
    r .= "  Saves:   " (Cfg["JournalSave"] = "off" ? "nothing (turned off)"
        : Cfg["JournalSave"] = "counts" ? "the time and template name only, no log text" : "the time, template name and full log text") nl
    r .= "  Folder:  " JournalDir() nl
    r .= "  Kept:    " (Cfg["KeepDays"] ? Cfg["KeepDays"] " days, then deleted automatically" : "until you delete them (no limit set)") nl
    r .= "  Now:     " jf.count " shift file(s)" (jf.oldest != "" ? ", oldest " jf.oldest : "") nl

    r .= nl "EVERYTHING ELSE IT KEEPS" nl
    r .= "  settings.ini    login shortcuts and usernames, app paths and journal options. No passwords." nl
    r .= "  Last used       " LastUsedFile nl
    r .= "                  the last value typed in boxes that remember one (like the bay), this PC only" nl
    r .= "  Quick notes     " NotesFile nl
    r .= "                  only what you type with Ctrl+Alt+Q, kept until you delete it" nl
    r .= "  Window layout   " LayoutFile nl
    r .= "                  where your windows were (program name, position, size), numbers only, this PC only" nl
    r .= "  Time saved      " SavedFile nl
    r .= "                  counts only (logs, logins, keystrokes saved per day), never log text" nl
    r .= "  Activity log    " ActivityFile nl
    r .= "                  what the tool did and when, this PC only, never passwords or log text" nl
    r .= "  Registry        the time of the last login per username, for the log-in-again reminder" nl
    r .= "                  (" RegKey ")" nl

    r .= nl "WHAT IT NEVER DOES" nl
    r .= "  It makes no internet connections and sends nothing anywhere itself. Files reach other PCs" nl
    r .= "  only through your own OneDrive and SharePoint sync, under your Microsoft 365 permissions." nl
    r .= "  (Ctrl+Alt+L opens your work websites in the browser, the same as clicking their links.)" nl
    r .= "  It doesn't keep what you type: it only watches for its own shortcuts. Nothing is saved" nl
    r .= "  except the logs you insert (journal), your notes, and the activity log above." nl
    r .= "  It types a password only when you type that login's shortcut, never in the template" nl
    r .= "  finder or the Settings window." nl

    conflicts := ""
    Loop Files HomeDir "\settings-*.ini"
        conflicts .= (conflicts = "" ? "" : ", ") A_LoopFileName
    if conflicts != ""
        r .= nl "TO CHECK" nl "  OneDrive made copies of settings.ini: " conflicts ". Compare them with settings.ini, then delete them." nl
    r .= nl "Start with Windows: " (StartupShortcuts().Length ? "on" : "off") nl
    return r
}


; =====================================================================
;  MAKE A COPY TO SHARE  -  tray menu > Make a copy to share
;  Copies only what a new operator needs into a new folder: the program,
;  the templates, the guides, an example settings file and LaunchWork.
;  Never your settings.ini, my-templates.txt, shift journal, quick notes,
;  activity log or passwords.
; =====================================================================
MakeShareCopy() {
    dest := DirSelect("*" A_MyDocuments, 3, "Pick where to put the copy (a SharePoint or Teams folder, for example). A folder called Watchlog v" VERSION " is made inside it.")
    if dest = ""
        return
    out := RTrim(dest, "\") "\Watchlog v" VERSION
    if DirExist(out) && MsgBox("There's already a copy here:`n" out "`n`nReplace the files in it?", "Make a copy to share", "YesNo Icon? Default2") != "Yes"
        return
    res := CopyForSharing(out)
    if res.error != "" {
        MsgBox "Couldn't make the folder:`n" out "`n`n" res.error, "Make a copy to share", "Icon!"
        return
    }
    msg := "Copied to:`n" out "`n`n" res.copied (res.notCopied != "" ? "`nNot copied:`n" res.notCopied : "")
        . "`nLeft out on purpose (they're yours):`n"
        . "   settings.ini  (your logins and settings)`n"
        . "   my-templates.txt  (your own templates)`n"
        . "   your shift journal, quick notes and activity log`n"
        . "   your passwords  (they're in Credential Manager and can't be copied)`n"
        . (res.warn != "" ? "`nThat folder already had these in it, from someone running Watchlog from there. Delete them before you share it:`n" res.warn : "")
        . "`nA new operator copies the folder to their own PC and opens QUICK START.txt first.`n`nOpen the folder now?"
    if MsgBox(msg, "Make a copy to share", "YesNo Iconi") = "Yes"
        Run out
}

; Copies the safe files into the folder out. Returns {copied, notCopied, warn, error}.
CopyForSharing(out) {
    res := {copied: "", notCopied: "", warn: "", error: ""}
    ; The team's wording when it's in use, so a new operator starts with the same templates
    tplFrom := Tpl.src != "local" && FileExist(Tpl.file) ? Tpl.file : TemplatesFile
    files := [[A_ScriptFullPath, A_IsCompiled ? "Watchlog.exe" : "Watchlog.ahk"], [tplFrom, "templates.txt"]
        , [HomeDir "\QUICK START.txt", "QUICK START.txt"], [HomeDir "\README.txt", "README.txt"]
        , [HomeDir "\LICENCE.txt", "LICENCE.txt"], [Cfg["LaunchWork"], "LaunchWork.bat"]]
    if !A_IsCompiled
        files.Push([A_ScriptDir "\settings.example.ini", "settings.example.ini"], [IconFile, "Watchlog.ico"])
    try DirCreate out
    catch as e {
        res.error := e.Message
        return res
    }
    for f in files {
        if !FileExist(f[1]) {
            res.notCopied .= "   " f[2] "  (not found)`n"
            continue
        }
        try {
            FileCopy f[1], out "\" f[2], 1
            res.copied .= "   " f[2] "`n"
        } catch as e {
            res.notCopied .= "   " f[2] "  (" e.Message ")`n"
        }
    }
    for name in ["settings.ini", "my-templates.txt"]
        if FileExist(out "\" name)
            res.warn .= "   " name "`n"
    Activity("Made a copy to share in " out ": " StrReplace(Trim(res.copied, " `n"), "`n   ", ", "))
    return res
}


; =====================================================================
;  CHEAT SHEET  -  Ctrl+Alt+H   (built from templates.txt and settings.ini)
; =====================================================================
; (set up by RegisterHotkeys, see HotkeyDefs)

ShowCheatSheet() {
    teal := "0F766E", ink := "1F2933", muted := "6B7280"
    g := WGui("+AlwaysOnTop", "Shortcut Cheat Sheet  -  v" VERSION)
    g.BackColor := "F4F7F7"
    g.MarginX := 20, g.MarginY := 14
    colW := 340, gap := 26
    ; Three columns of sections. Each row is a shortcut and what it does.
    forms := [], quick := [], apps := []
    for t in TemplateList {
        row := [TrigKey(t.trig), t.name (t.repeat ? "  (adds more)" : "") (t.src = "mine" ? "  (mine)" : "")]
        if t.form
            forms.Push(row)
        else
            quick.Push(row)
    }
    for l in LoginList
        quick.Push([TrigKey(l.trig), "Login: " l.user (l.win != "" ? "  (only in " l.win ")" : "")])
    for a in AppList
        apps.Push([a.key, a.name])
    stamps := [[TrigKey(";t"), "time"], [TrigKey(";dd"), "date"], [TrigKey(";dt"), "date and time"]]
    keys := []
    for d in HotkeyDefs
        keys.Push([HKShort(d.id), d.label])
    keys.Push(["Shift+Caps", "turn Caps Lock on"], ["P or X", "pause / resume"], ["R", "reload"])

    g.SetFont("s20 bold c" teal, "Segoe UI")
    g.AddText("x20 y10 w700", "Watchlog shortcuts")
    g.SetFont("s10 norm c" muted, "Segoe UI")
    g.AddText("x20 y+0 w900", "Can't remember one?  Ctrl+Alt+Space finds a template by name or any word.   Forms: Tab = next box, Enter = insert, Esc = cancel.")
    top := 78
    x1 := 20, x2 := x1 + colW + gap, x3 := x2 + colW + gap
    y1 := Section(x1, top, "FORMS", forms, 92)
    y2 := Section(x2, top, "QUICK TEMPLATES AND LOGINS", quick, 92)
    y2 := Section(x2, y2 + 14, "STAMPS", stamps, 92)
    y3 := Section(x3, top, "HOTKEYS   (Ctrl+Alt + the key unless shown in full)", keys, 92)
    y3 := Section(x3, y3 + 14, "APPS   (Ctrl+Alt + the key)", apps, 92)
    bottom := Max(y1, y2, y3) + 14
    g.SetFont("s9 norm c" muted, "Segoe UI")
    foot := "Click the teal Watchlog icon by the clock (or Ctrl+Alt+M) for the home window; right-click it for the menu.`n"
        . "v" VERSION " (" VERSION_DATE ")   Templates: " (Tpl.src = "local" ? "templates.txt in this folder" : "the team file")
        . (Tpl.version != "" ? ", wording " Tpl.version : "") (Tpl.mine ? ", plus " Tpl.mine " of yours" : "")
        . "   Settings: " HomeDir "`n" COPYRIGHT
    g.AddText("x20 y" bottom " w" (colW * 3 + gap * 2), foot)
    g.SetFont("s10 norm c" ink, "Segoe UI")
    g.AddButton("x20 y" (bottom + 62) " Default w90", "OK").OnEvent("Click", (*) => g.Destroy())
    g.OnEvent("Escape", (*) => g.Destroy())
    g.Show()

    ; One titled block of rows at (x, y); returns the y just below it
    Section(x, y, title, rows, keyW) {
        if !rows.Length
            return y
        g.SetFont("s9 bold c" teal, "Segoe UI")
        g.AddText("x" x " y" y " w" colW, title)
        g.AddText("x" x " y" (y + 20) " w" colW " h1 Background" teal)
        y += 28
        for r in rows {
            g.SetFont("s10 bold c" teal, "Consolas")
            g.AddText("x" x " y" y " w" keyW " h20 +0x4000", r[1])
            g.SetFont("s10 norm c" ink, "Segoe UI")
            g.AddText("x" (x + keyW + 4) " y" y " w" (colW - keyW - 4) " h20 +0x4000", r[2])
            y += 22
        }
        return y
    }
}


; =====================================================================
;  SCRIPT CONTROLS (these keep working even while paused)
;  Ctrl+Alt+P  or  Ctrl+Alt+X = pause / resume all shortcuts
;  Ctrl+Alt+R = reload (after editing templates.txt or settings.ini)
; =====================================================================
#SuspendExempt
^!p::
^!x:: TogglePause()

TogglePause() {
    Suspend -1
    SoundBeep A_IsSuspended ? 400 : 900, 150
    Tip(A_IsSuspended ? "Shortcuts PAUSED" : "Shortcuts ON", 1500, true)
}

^!r:: Reload
#SuspendExempt False


; =====================================================================
;  WINDOW LAYOUT  -  Ctrl+Alt+Shift+S saves, Ctrl+Alt+W puts back
;  Arrange your windows how you like them, press Ctrl+Alt+Shift+S, and
;  Ctrl+Alt+W moves them back any time. Ctrl+Alt+L also puts them back
;  by itself at the end of the start of shift (settings.ini [Layout]
;  AfterStart=no turns that off). What's kept: the program name, the
;  position and the size of each window, as numbers, on this PC only
;  (each bay's screens are different, so it isn't synced). No titles,
;  no contents. Windows are matched by program, in the order they sit
;  on screen, so two Edge windows go back to the first and second
;  spots saved. Watchlog's own windows and minimised windows are left alone.
;  v3.19.3: SDS and Alert Grid are both javaw.exe (Java), so front-to-back
;  order alone let them swap spots (the start of shift sign-in brings SDS
;  to the front). Each Java window is now also saved as AlertGrid, SDS or
;  Java (from the start of its title; the title itself isn't saved) and
;  matched on that. Layouts saved before v3.19.3 still work the old way
;  and ask to be saved again.
; =====================================================================
#HotIf
; (set up by RegisterHotkeys, see HotkeyDefs)
; (set up by RegisterHotkeys, see HotkeyDefs)

LayoutSkip(hwnd) {
    if !WinExist("ahk_id " hwnd)
        return true
    if WinGetTitle("ahk_id " hwnd) = ""
        return true
    cls := WinGetClass("ahk_id " hwnd)
    if cls = "Progman" || cls = "WorkerW" || cls = "Shell_TrayWnd" || cls = "Shell_SecondaryTrayWnd"
        return true
    if WinGetExStyle("ahk_id " hwnd) & 0x80      ; tool windows
        return true
    if WinGetPID("ahk_id " hwnd) = ProcessExist()    ; Watchlog's own windows
        return true
    return false
}

; Which Bally app a Java window is, so SDS and Alert Grid can't swap
; spots (both are javaw.exe). "" for every other program.
LayoutKind(hwnd, exe) {
    if exe != "javaw.exe"
        return ""
    t := WinGetTitle("ahk_id " hwnd)
    if RegExMatch(t, "i)^Alert Grid\b")
        return "AlertGrid"
    if RegExMatch(t, "i)^SDS\b")
        return "SDS"
    return "Java"
}

SaveLayout() {
    try DirCreate DataDir
    try FileDelete LayoutFile
    seen := Map()
    n := 0
    for hwnd in WinGetList() {
        try {
            if LayoutSkip(hwnd)
                continue
            exe := WinGetProcessName("ahk_id " hwnd)
            if RegExMatch(exe, "i)^AutoHotkey")
                continue
            mm := WinGetMinMax("ahk_id " hwnd)
            if mm = -1
                continue                         ; minimised: leave alone
            WinGetPos &x, &y, &w, &h, "ahk_id " hwnd
            kind := LayoutKind(hwnd, exe)
        } catch
            continue
        key := exe "|" kind
        seen[key] := seen.Has(key) ? seen[key] + 1 : 1
        n += 1
        sec := "W" n
        try {
            IniWrite exe, LayoutFile, sec, "exe"
            IniWrite kind, LayoutFile, sec, "kind"
            IniWrite seen[key], LayoutFile, sec, "nth"
            IniWrite x, LayoutFile, sec, "x"
            IniWrite y, LayoutFile, sec, "y"
            IniWrite w, LayoutFile, sec, "w"
            IniWrite h, LayoutFile, sec, "h"
            IniWrite mm, LayoutFile, sec, "max"
        } catch {
            Tip("Couldn't save the layout (" LayoutFile ").", 4000, true)
            Activity("Window layout: couldn't write " LayoutFile)
            return
        }
    }
    try IniWrite n, LayoutFile, "Layout", "count"
    try IniWrite 2, LayoutFile, "Layout", "format"
    Activity("Window layout saved: " n " windows")
    Tip("Saved where " n " windows are.", 2500, true)
}

; auto = true when Ctrl+Alt+L does it: says nothing if no layout was saved,
; and leaves the window you were in at the front
RestoreLayout(auto := false) {
    if !FileExist(LayoutFile) {
        if !auto
            MsgBox "No layout saved yet.`n`nArrange your windows, then press Ctrl+Alt+Shift+S.", "Watchlog"
        return
    }
    prev := WinExist("A")
    count := Integer(IniRead(LayoutFile, "Layout", "count", "0"))
    ; Saved before v3.19.3: Java windows (SDS, Alert Grid) were saved by
    ; program only, so they're matched the old way until it's saved again
    old := IniRead(LayoutFile, "Layout", "format", "1") != "2"
    byKey := Map()
    oldJava := false
    for hwnd in WinGetList() {
        try {
            if LayoutSkip(hwnd)
                continue
            exe := WinGetProcessName("ahk_id " hwnd)
            key := exe "|" (old ? "" : LayoutKind(hwnd, exe))
        } catch
            continue
        if old && exe = "javaw.exe"
            oldJava := true
        if !byKey.Has(key)
            byKey[key] := []
        byKey[key].Push(hwnd)
    }
    moved := 0
    loop count {
        sec := "W" A_Index
        exe := IniRead(LayoutFile, sec, "exe", "")
        key := exe "|" (old ? "" : IniRead(LayoutFile, sec, "kind", ""))
        nth := Integer(IniRead(LayoutFile, sec, "nth", "1"))
        if exe = "" || !byKey.Has(key) || byKey[key].Length < nth
            continue
        hwnd := byKey[key][nth]
        x := Integer(IniRead(LayoutFile, sec, "x", "0"))
        y := Integer(IniRead(LayoutFile, sec, "y", "0"))
        w := Integer(IniRead(LayoutFile, sec, "w", "800"))
        h := Integer(IniRead(LayoutFile, sec, "h", "600"))
        mx := Integer(IniRead(LayoutFile, sec, "max", "0"))
        try {
            mm := WinGetMinMax("ahk_id " hwnd)
            if auto && mm = -1
                continue                         ; minimised: leave it
            if mm != 0
                WinRestore "ahk_id " hwnd
            WinMove x, y, w, h, "ahk_id " hwnd
            if mx = 1
                WinMaximize "ahk_id " hwnd
            moved += 1
        }
    }
    if auto && prev && WinExist("ahk_id " prev)
        try WinActivate "ahk_id " prev
    Activity("Window layout put back: " moved " of " count " windows" (auto ? " (after start of shift)" : "") (old ? " (layout saved before v3.19.3)" : ""))
    ; once per old layout file: SDS and Alert Grid could still swap
    if oldJava && IniRead(LayoutFile, "Layout", "asked", "0") != "1" {
        try IniWrite 1, LayoutFile, "Layout", "asked"
        MsgBox "Watchlog now tells SDS and Alert Grid apart when it puts your windows back, but your layout was saved before that.`n`n"
            . "Put SDS and Alert Grid where they belong, then press Ctrl+Alt+Shift+S to save your layout again. You only need to do this once.", "Watchlog", "Iconi"
    } else if !auto
        Tip("Put " moved " windows back.", 2500, true)
}


; =====================================================================
;  CAPS LOCK GUARD  (tray menu > Windows, the home window or Settings > General turn it off)
;  Plain Caps Lock can't turn Caps Lock ON by accident: Shift+Caps Lock
;  does. Plain Caps Lock still turns it OFF. While it's on, a red
;  "CAPS LOCK ON" tag sits at the top right of the screen. No sounds.
;  Ctrl+Alt+P (pause) switches the guard off with everything else.
; =====================================================================
#HotIf CapsGuard
$CapsLock:: {
    if GetKeyState("CapsLock", "T")
        SetCapsLockState "Off"
    else if Cfg["CapsClearsAlerts"] && AlertTaught() != "" && AlertGridWin()
        ClearAlerts()    ; Caps Lock was doing nothing, so it clears the Alert Grid alerts
    else
        Tip("Hold Shift and press Caps Lock to turn it on", 1500)
}
$+CapsLock:: SetCapsLockState "On"
#HotIf

BuildCapsTag() {
    global CapsGui
    CapsGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "Caps Lock")
    CapsGui.BackColor := "C00000"
    CapsGui.SetFont("s14 bold cWhite", "Segoe UI")
    CapsGui.Add("Text", "x12 y6", "CAPS LOCK ON")
}

CheckCaps() {
    global CapsWasOn
    on := CapsGuard && GetKeyState("CapsLock", "T")
    if on && !CapsWasOn
        CapsGui.Show("NoActivate x" (A_ScreenWidth - 220) " y8 w200 h40")
    else if !on && CapsWasOn
        CapsGui.Hide()
    CapsWasOn := on
}

ToggleCapsGuard(*) {
    global CapsGuard
    CapsGuard := !CapsGuard
    try WinMenu.ToggleCheck(CAPS_MENU)
    try DirCreate DataDir
    try IniWrite CapsGuard ? "1" : "0", LastUsedFile, "Caps", "Guard"
    Activity("Caps Lock guard " (CapsGuard ? "on" : "off"))
    Tip("Caps Lock guard " (CapsGuard ? "ON" : "OFF"), 1500, true)
}


; =====================================================================
;  THE EXE: INSTALLING ON THIS PC  (v3.5.0)
;  Watchlog.exe copies itself to %LOCALAPPDATA%\Programs\Watchlog (no
;  administrator rights), adds a Start menu entry and the Start with
;  Windows shortcut, and registers itself under Settings > Apps so it
;  can be removed like any program. Running a newer Watchlog.exe later
;  offers to update the installed copy. Settings, templates and the
;  journal stay where they are (Documents), so uninstalling never
;  deletes anyone's work.
; =====================================================================
#HotIf
IsInstalledCopy() {
    return A_IsCompiled && StrLower(A_ScriptFullPath) = StrLower(INSTALL_EXE)
}

StartupLink() => A_Startup "\Watchlog.lnk"
MenuLink() => A_Programs "\Watchlog.lnk"

; Returns true when this copy installed itself or handed over to the
; installed one, and should exit
CheckInstall() {
    if IsInstalledCopy()
        return false
    if FileExist(INSTALL_EXE) {
        have := RegRead(UNINSTALL_KEY, "DisplayVersion", "")
        if have = "" || VerCompare(VERSION, have) > 0 {
            if MsgBox("Watchlog " (have != "" ? "v" have " " : "") "is installed on this PC. Update it to v" VERSION "?", "Watchlog setup", "YesNo Iconi Default1") = "Yes"
                return InstallSelf(false)
        }
        try Run '"' INSTALL_EXE '"'
        return true
    }
    askedFile := DataDir "\install.ini"
    if IniRead(askedFile, "Install", "Asked", "") = VERSION
        return false
    try IniWrite VERSION, askedFile, "Install", "Asked"
    if MsgBox("Install Watchlog on this PC?`n`n"
        . "It adds Watchlog to the Start menu, starts it when Windows starts, and can be removed in Settings > Apps. It doesn't need administrator rights.`n`n"
        . "Your settings and templates go in:`n" HomeDir "`n`n"
        . "No = just run it from where it is this time.", "Watchlog setup", "YesNo Iconi Default1") = "Yes"
        return InstallSelf(true)
    return false
}

InstallSelf(fresh) {
    CloseOtherCopies()
    try DirCreate INSTALL_DIR
    copied := false
    Loop 10 {
        try {
            FileCopy A_ScriptFullPath, INSTALL_EXE, 1
            copied := true
            break
        }
        Sleep 300
    }
    if !copied {
        MsgBox "Watchlog couldn't install itself to:`n" INSTALL_EXE "`n`nIt will keep running from where it is.", "Watchlog setup", "Icon!"
        return false
    }
    try {
        RegWrite "Watchlog", "REG_SZ", UNINSTALL_KEY, "DisplayName"
        RegWrite VERSION, "REG_SZ", UNINSTALL_KEY, "DisplayVersion"
        RegWrite INSTALL_EXE, "REG_SZ", UNINSTALL_KEY, "DisplayIcon"
        RegWrite INSTALL_DIR, "REG_SZ", UNINSTALL_KEY, "InstallLocation"
        RegWrite '"' INSTALL_EXE '" /uninstall', "REG_SZ", UNINSTALL_KEY, "UninstallString"
        RegWrite 1, "REG_DWORD", UNINSTALL_KEY, "NoModify"
        RegWrite 1, "REG_DWORD", UNINSTALL_KEY, "NoRepair"
        RegWrite Integer(FileGetSize(INSTALL_EXE) / 1024), "REG_DWORD", UNINSTALL_KEY, "EstimatedSize"
    }
    SetShortcut(StartupLink(), fresh || FileExist(StartupLink()) != "")
    SetShortcut(MenuLink(), true)
    ; (a fresh install writes no log line yet: the activity log existing would make the new copy think Watchlog ran here before)
    if !fresh
        Activity("Updated the installed copy to v" VERSION " in " INSTALL_DIR)
    try Run '"' INSTALL_EXE '"'
    return true
}

; Closes any other running Watchlog (an older exe being replaced, or the
; script version this exe takes over from)
CloseOtherCopies() {
    hidden := A_DetectHiddenWindows
    DetectHiddenWindows true
    me := ProcessExist()
    for hwnd in WinGetList("ahk_class AutoHotkey") {
        try {
            pid := WinGetPID("ahk_id " hwnd)
            if pid = me
                continue
            if StrLower(WinGetProcessName("ahk_id " hwnd)) = "watchlog.exe" || InStr(WinGetTitle("ahk_id " hwnd), "\Watchlog.ahk") {
                ProcessClose pid
                ProcessWaitClose pid, 3
            }
        }
    }
    DetectHiddenWindows hidden
}

Uninstall() {
    if MsgBox("Remove Watchlog from this PC?`n`nYour settings, templates and shift journal stay in:`n" HomeDir, "Watchlog uninstall", "YesNo Icon? Default2") != "Yes"
        return false
    if MsgBox("Also delete the passwords Watchlog saved on this PC (in Windows Credential Manager)?`n`n"
        . "Yes = delete them`nNo = keep them, in case you install Watchlog again", "Watchlog uninstall", "YesNo Icon? Default2") = "Yes" {
        Loop 9 {
            u := Trim(IniRead(SettingsFile, "Login" A_Index, "User", ""))
            if u != ""
                try CredRemove(u)
        }
    }
    CloseOtherCopies()
    SetShortcut(StartupLink(), false)
    SetShortcut(MenuLink(), false)
    try RegDeleteKey UNINSTALL_KEY
    MsgBox "Watchlog has been removed from this PC.", "Watchlog uninstall", "Iconi"
    if IsInstalledCopy()
        ; run from Temp: Windows won't delete a folder something is working in
        Run A_ComSpec ' /c ping -n 3 127.0.0.1 >nul & rmdir /s /q "' INSTALL_DIR '"', A_Temp, "Hide"
    else if DirExist(INSTALL_DIR)
        try DirDelete INSTALL_DIR, true
    return true
}

SetShortcut(lnk, want) {
    try {
        if !want {
            if FileExist(lnk)
                FileDelete lnk
            return
        }
        FileCreateShortcut INSTALL_EXE, lnk, INSTALL_DIR, , "Watchlog - log templates"
    } catch as err {
        MsgBox "Watchlog couldn't update the shortcut:`n" lnk "`n`n" err.Message, "Watchlog", "Icon!"
    }
}

; Puts the files built into the exe in the Watchlog folder: templates.txt
; and LaunchWork.bat only when they're missing (they may have been edited),
; the guides every time (so they match the version)
InstallBuiltIns() {
    try DirCreate HomeDir
    try {
        if !FileExist(TemplatesFile)
            FileInstall "templates.txt", TemplatesFile, 0
        if !FileExist(HomeDir "\LaunchWork.bat")
            FileInstall "LaunchWork.bat", HomeDir "\LaunchWork.bat", 0
        FileInstall "README.txt", HomeDir "\README.txt", 1
        FileInstall "QUICK START.txt", HomeDir "\QUICK START.txt", 1
        FileInstall "LICENCE.txt", HomeDir "\LICENCE.txt", 1
    } catch as e {
        Activity("Couldn't put the built-in files in " HomeDir ": " e.Message)
    }
}

; An exe in the team folder (next to the team templates) replaces this one.
; A running exe can be renamed but not overwritten, so this one is moved
; aside as the backup, the new one is copied into its place, and started.
UpdateExeFrom(f, v) {
    tmp := A_Temp "\Watchlog update check.exe"
    ok := false
    try {
        FileCopy f, tmp, true
        ok := RunWait('"' tmp '" /selftest', , "Hide") = 0
    }
    try FileDelete tmp
    if !ok {
        Activity("Update to v" v " stopped: the team folder's Watchlog.exe didn't start")
        MsgBox "The new Watchlog.exe in the team folder didn't start, so this PC stays on v" VERSION ".`n`nTell whoever looks after the tool.", "Watchlog update", "Icon!"
        return
    }
    backup := DataDir "\Watchlog v" VERSION " (backup).exe"
    moved := false
    try {
        if !DirExist(DataDir)
            DirCreate DataDir
        try FileDelete backup
        FileMove A_ScriptFullPath, backup, 1
        moved := true
        FileCopy f, A_ScriptFullPath, 1
    } catch as err {
        if moved
            try FileMove backup, A_ScriptFullPath, 1
        Activity("Update to v" v " failed: " err.Message)
        MsgBox "Couldn't update: " err.Message "`n`nThis PC stays on v" VERSION ".", "Watchlog update", "Icon!"
        return
    }
    if IsInstalledCopy()
        try RegWrite v, "REG_SZ", UNINSTALL_KEY, "DisplayVersion"
    Activity("Updated from v" VERSION " to v" v " from " f " (old copy kept: " backup ")")
    Run '"' A_ScriptFullPath '"'
    ExitApp
}


; =====================================================================
;  TUTORIAL  (first run on a new PC, and tray > Tutorial)
;  A short guided tour with two practice boxes. Nothing typed here goes
;  in the shift journal or the time saved numbers.
; =====================================================================
; Tray menu / home window > About Watchlog: version, owner and the licence
LicenceText() {
    return "WATCHLOG LICENCE`r`n`r`n"
        . COPYRIGHT "`r`n`r`n"
        . "Watchlog (the program and its guides) is not free or open software.`r`n`r`n"
        . "1. You may use Watchlog only with the copyright holder's permission.`r`n`r`n"
        . "2. You may not copy, share, sell, change, decompile, take apart or redistribute Watchlog, in whole or in part, or make anything from it, without the copyright holder's written permission.`r`n`r`n"
        . "3. Permission can be withdrawn at any time. When it is, stop using Watchlog and delete your copies.`r`n`r`n"
        . "4. Watchlog is provided `"as is`", without any warranty. The copyright holder is not liable for any loss or damage from using it. Always check an entry before you save it.`r`n`r`n"
        . "Your own settings, logins and log entries are not part of Watchlog and aren't covered by this licence."
}

ShowAbout() {
    g := WGui(, "About Watchlog")
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 20, g.MarginY := 16
    g.SetFont("s15 bold")
    g.AddText("w520", "Watchlog v" VERSION)
    g.SetFont("s10 norm")
    g.AddText("w520 y+2", VERSION_DATE "`n" COPYRIGHT)
    g.AddEdit("w520 r14 y+12 ReadOnly Multi -WantReturn", LicenceText())
    b := g.AddButton("xm y+14 w100 Default", "Close")
    b.OnEvent("Click", (*) => g.Destroy())
    g.OnEvent("Escape", (*) => g.Destroy())
    g.Show()
    b.Focus()
}

ShowTutorial(first := false) {
    global TutorialWin
    if IsObject(TutorialWin) {
        try WinActivate "ahk_id " TutorialWin.Hwnd
        return
    }
    steps := [
        {head: "Welcome to Watchlog"
            , body: "Watchlog types your standard log entries for you.`n`nYou type a short code that starts with a semicolon, like `;interior, and the whole entry appears. Codes that need details open a small form first.`n`nThis takes about two minutes. Nothing you do here is saved to your shift journal."
            , practice: false, logins: false, start: false, check: "", done: ""}
        , {head: "Your logins"
            , body: "Watchlog can also type your usernames and passwords. Each login has its own code, like `;me, and can be locked to the program it belongs to, so it never types a password anywhere else.`n`nPasswords are kept in Windows Credential Manager on this PC, never in a file.`n`nAdd your logins now, or skip this and do it later: click the teal icon by the clock > Settings."
            , practice: false, logins: true, start: false, check: "", done: ""}
        , {head: "Try a quick entry"
            , body: "Click in the box below and type:   `;interior`n`nThe whole line appears the moment you finish typing the code. There's no Enter to press."
            , practice: true, logins: false, start: false, check: "interior door check", done: "That's a quick entry. Most codes work like that."}
        , {head: "Try a form"
            , body: "Some entries need details. Click in the box and type:   `;evict`n`nA form opens. Tab moves between the boxes, Enter inserts the entry, Esc cancels. The preview at the bottom shows how it will look."
            , practice: true, logins: false, start: false, check: "Trespass", done: "That's a form. The log is ready to paste into iTrak."}
        , {head: "Finding a code"
            , body: "Can't remember a code? Press Ctrl+Alt+Space, type any word (like jackpot or audit) and pick the template from the list. Enter inserts it.`n`nTry it in the box below.`n`nCtrl+Alt+H shows every code on one page."
            , practice: true, logins: false, start: false, check: "", done: ""}
        , {head: "Handy keys, and you're set"
            , body: "Ctrl+Alt+M   the Watchlog home window: everything as buttons`nCtrl+Alt+Space   find a template`nCtrl+Alt+H   cheat sheet of every code`nCtrl+Alt+L   start of shift (opens your work programs)`nCtrl+Alt+J   this shift's journal`n`nOr just click the teal Watchlog icon by the clock: it opens the home window. Right-click it for the menu."
            , practice: false, logins: false, start: true, check: "", done: ""}
    ]
    st := {i: 1}
    g := WGui(, "Watchlog tutorial")
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 20, g.MarginY := 16
    g.SetFont("s15 bold")
    hd := g.AddText("w560 h34", "")
    g.SetFont("s10 norm")
    bd := g.AddText("w560 h150 y+6", "")
    pr := g.AddEdit("w560 r6 Multi y+4")
    stt := g.AddText("w560 h24 y+6 cGreen", "")
    sw := g.AddCheckbox("w560 y+8", "Start Watchlog when Windows starts")
    sw.Value := StartupShortcuts().Length ? 1 : 0
    bBack := g.AddButton("xm y+14 w90", "Back")
    bNext := g.AddButton("x+8 w110 Default", "Next")
    bAdd := g.AddButton("x+8 w150", "Add logins...")
    bClose := g.AddButton("x+8 w120", "Close")
    g.SetFont("s8 c707070")
    g.AddText("xm y+12 w560", COPYRIGHT " Used by permission only: tray menu > About Watchlog has the licence.")
    g.SetFont("s10 c000000")
    bBack.OnEvent("Click", (*) => Go(-1))
    bNext.OnEvent("Click", (*) => Go(1))
    bAdd.OnEvent("Click", (*) => ShowSettings())
    bClose.OnEvent("Click", Done)
    g.OnEvent("Close", Done)
    g.OnEvent("Escape", Done)
    pr.OnEvent("Change", Check)
    TutorialWin := g
    Render()
    g.Show()

    Render() {
        s := steps[st.i]
        hd.Text := s.head
        bd.Text := s.body
        stt.Text := ""
        pr.Visible := s.practice
        sw.Visible := s.start
        bAdd.Visible := s.logins
        bBack.Enabled := st.i > 1
        bNext.Text := st.i = steps.Length ? "Finish" : "Next"
        g.Title := "Watchlog tutorial  (" st.i " of " steps.Length ")"
        if s.practice {
            pr.Value := ""
            pr.Focus()
        } else
            bNext.Focus()
    }

    Check(*) {
        s := steps[st.i]
        if s.check != "" && InStr(pr.Value, s.check)
            stt.Text := "✓  " s.done
    }

    Go(d) {
        if d > 0 && st.i = steps.Length {
            Done()
            return
        }
        if st.i + d < 1
            return
        st.i += d
        Render()
    }

    Done(*) {
        global TutorialWin
        if sw.Visible
            SetStartup(sw.Value)
        TutorialWin := ""
        try g.Destroy()
        if first
            Activity("Tutorial finished on this PC")
    }
}


; =====================================================================
;  ICONS  (v3.10.0)
;  The small pictures on the tray menu and on the home window's buttons
;  are drawn from Windows' own icon font (Segoe Fluent Icons on Windows
;  11, Segoe MDL2 Assets on Windows 10), so there are no icon files to
;  ship. On a PC with neither font the menus just have no pictures.
; =====================================================================
IconFont() {
    static font := ""
    if font = ""
        font := FileExist(A_WinDir "\Fonts\SegoeIcons.ttf") ? "Segoe Fluent Icons"
            : FileExist(A_WinDir "\Fonts\segmdl2.ttf") ? "Segoe MDL2 Assets" : "-"
    return font = "-" ? "" : font
}

; An icon of one picture from the icon font, in a colour (0xRRGGBB), size
; pixels square. 0 when the font isn't there. Each one is made once.
GlyphIcon(code, color := 0x0E746E, size := 16) {
    static made := Map()
    key := code "|" color "|" size
    if made.Has(key)
        return made[key]
    made[key] := 0
    font := IconFont()
    if font = ""
        return 0
    hdc := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
    bi := Buffer(40, 0)
    NumPut("UInt", 40, "Int", size, "Int", -size, "UShort", 1, "UShort", 32, bi)
    bits := 0
    hbm := DllCall("CreateDIBSection", "Ptr", hdc, "Ptr", bi, "UInt", 0, "Ptr*", &bits, "Ptr", 0, "UInt", 0, "Ptr")
    if !hbm || !bits {
        DllCall("DeleteDC", "Ptr", hdc)
        return 0
    }
    oldBm := DllCall("SelectObject", "Ptr", hdc, "Ptr", hbm, "Ptr")
    hf := DllCall("CreateFontW", "Int", -Round(size * 0.9), "Int", 0, "Int", 0, "Int", 0, "Int", 400
        , "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 1, "UInt", 0, "UInt", 0, "UInt", 4, "UInt", 0, "Str", font, "Ptr")
    oldF := DllCall("SelectObject", "Ptr", hdc, "Ptr", hf, "Ptr")
    DllCall("SetTextColor", "Ptr", hdc, "UInt", 0xFFFFFF)
    DllCall("SetBkMode", "Ptr", hdc, "Int", 1)
    rc := Buffer(16, 0)
    NumPut("Int", size, "Int", size, rc, 8)
    ; centred, one line, & is not special
    DllCall("DrawTextW", "Ptr", hdc, "Str", Chr(code), "Int", -1, "Ptr", rc, "UInt", 0x825)
    DllCall("GdiFlush")
    ; White on black becomes the colour, with the brightness as how solid it is
    rgb := color & 0xFFFFFF
    Loop size * size {
        off := (A_Index - 1) * 4
        p := NumGet(bits, off, "UInt")
        a := Max(p & 0xFF, (p >> 8) & 0xFF, (p >> 16) & 0xFF)
        NumPut("UInt", a ? (a << 24) | rgb : 0, bits, off)
    }
    DllCall("SelectObject", "Ptr", hdc, "Ptr", oldF)
    DllCall("DeleteObject", "Ptr", hf)
    DllCall("SelectObject", "Ptr", hdc, "Ptr", oldBm)
    DllCall("DeleteDC", "Ptr", hdc)
    maskBits := Buffer(((size + 15) // 16) * 2 * size, 0)
    mask := DllCall("CreateBitmap", "Int", size, "Int", size, "UInt", 1, "UInt", 1, "Ptr", maskBits, "Ptr")
    ii := Buffer(A_PtrSize = 8 ? 32 : 20, 0)                  ; ICONINFO
    NumPut("Int", 1, ii, 0)
    mo := A_PtrSize = 8 ? 16 : 12
    NumPut("Ptr", mask, ii, mo)
    NumPut("Ptr", hbm, ii, mo + A_PtrSize)
    h := DllCall("CreateIconIndirect", "Ptr", ii, "Ptr")
    DllCall("DeleteObject", "Ptr", mask)
    DllCall("DeleteObject", "Ptr", hbm)
    made[key] := h
    return h
}

; Adds a menu item with a picture from the icon font
MenuItem(m, name, fn, glyph := 0) {
    m.Add(name, fn)
    if glyph && (h := GlyphIcon(glyph, 0x0E746E, DllCall("GetSystemMetrics", "Int", 49)))
        try m.SetIcon(name, "HICON:*" h)
}

; A big button with a picture on the left and one or two lines of text
IconButton(g, opt, text, glyph, color, fn) {
    b := g.AddButton(opt " +0x2000 +0x100", text)       ; several lines, left-aligned
    color := Integer("0x" LookText(Format("{:06X}", color)))
    if glyph && (h := GlyphIcon(glyph, color, 24))
        SendMessage 0xF7, 1, h, b                       ; BM_SETIMAGE
    b.OnEvent("Click", fn)
    return b
}


; =====================================================================
;  TRAY MENU  (v3.10.0)
;  Click the teal icon by the clock = the Watchlog home window.
;  Right-click = this menu: everyday things on top, the rest in small
;  sub-menus (Alert Grid, Windows, Advanced). AutoHotkey's own items
;  (Window Spy, Edit Script...) are gone; Reload and Pause are under
;  Advanced.
; =====================================================================
BuildTrayMenu() {
    global WinMenu
    tm := A_TrayMenu
    tm.Delete()
    MenuItem(tm, "Watchlog v" VERSION "  (" VERSION_DATE ")" (OutOfDate() ? "  - update needed" : ""), (*) => ShowVersion(), 0xE946)
    tm.Add()
    MenuItem(tm, HOME_MENU, (*) => ShowHome(), 0xE80F)
    MenuItem(tm, "Find a template  (" HK("find") ")", (*) => ShowPicker(), 0xE721)
    MenuItem(tm, "Cheat sheet  (" HK("cheat") ")", (*) => ShowCheatSheet(), 0xE8FD)
    MenuItem(tm, "Shift journal  (" HK("journal") ")", (*) => ShowJournal(), 0xE8F1)
    MenuItem(tm, "Call pad  (Numpad +)", (*) => ShowCallPad(), 0xE717)
    MenuItem(tm, "Quick notes  (" HK("notes") ")", (*) => ShowNotes(), 0xE70B)
    MenuItem(tm, "Time saved", (*) => ShowTimeSaved(), 0xE916)
    MenuItem(tm, "Shift count", (*) => ShowShiftCount(), 0xE9D2)
    MenuItem(tm, "Shift dashboard  (" HK("dashboard") ")", (*) => ShowDashboard(), 0xE9D9)
    tm.Add()
    MenuItem(tm, "Start of shift  (" HK("start") ")", (*) => StartOfShift(), 0xE768)
    MenuItem(tm, "End of shift  (close apps)", (*) => EndOfShift(), 0xE7E8)

    ag := Menu()
    MenuItem(ag, "Clear all alerts  (" HK("alertclear") ")", (*) => ClearAlerts(), 0xE894)
    MenuItem(ag, "Teach the clicks  (" HK("alertteach") ")", (*) => TeachAlerts(), 0xE7C9)
    MenuItem(ag, "Share my setup with the team", (*) => ShareAlertSetup(), 0xE72D)
    MenuItem(tm, "Alert Grid", ag, 0xEA8F)

    itm := Menu()
    MenuItem(itm, "New daily log  (" HK("itraknew") ")", (*) => ITrakNewLog(), 0xE710)
    MenuItem(itm, "Teach the click  (" HK("itrakteach") ")", (*) => TeachITrak(), 0xE7C9)
    MenuItem(itm, "Full-entry log  (" HK("entrypick") ")", (*) => ShowEntryPick(), 0xE8F1)
    MenuItem(itm, "Teach the daily log fields  (" HK("entryteach") ")", (*) => TeachEntryFields(), 0xE7C9)
    MenuItem(itm, "Share my setup with the team", (*) => ShareITrakSetup(), 0xE72D)
    MenuItem(tm, "iTrak", itm, 0xE8F1)

    WinMenu := Menu()
    MenuItem(WinMenu, "Save window layout  (" HK("savelayout") ")", (*) => SaveLayout(), 0xE74E)
    MenuItem(WinMenu, "Put windows back  (" HK("restorelayout") ")", (*) => RestoreLayout(), 0xE7C4)
    WinMenu.Add(CAPS_MENU, (*) => ToggleCapsGuard())
    if CapsGuard
        WinMenu.Check(CAPS_MENU)
    MenuItem(tm, "Windows", WinMenu, 0xE7F4)
    tm.Add()

    MenuItem(tm, "Template editor  (" HK("editor") ")", (*) => ShowEditor(), 0xE70F)
    MenuItem(tm, "Customize Watchlog...", (*) => ShowCustomize(), 0xE713)
    tm.Add("Dark look", (*) => SetDarkLook(!Cfg["Dark"]))
    if Cfg["Dark"]
        tm.Check("Dark look")
    MenuItem(tm, "Settings", (*) => ShowSettings(), 0xE713)
    MenuItem(tm, "Tutorial", (*) => ShowTutorial(), 0xE7BE)
    MenuItem(tm, "About Watchlog", (*) => ShowAbout(), 0xE946)

    more := Menu()
    MenuItem(more, "Security and status", (*) => ShowSecurity(), 0xE72E)
    MenuItem(more, "Activity log", (*) => OpenActivity(), 0xE81C)
    MenuItem(more, "Make a copy to share", (*) => MakeShareCopy(), 0xE8C8)
    more.Add()
    MenuItem(more, (Cfg["SharedTemplates"] != "" ? "Edit team templates" : "Edit templates") " in Notepad", (*) => EditFile(Cfg["SharedTemplates"] != "" ? Cfg["SharedTemplates"] : TemplatesFile), 0xE8A5)
    MenuItem(more, "Edit my templates in Notepad", (*) => EditMine(), 0xE8A5)
    MenuItem(more, "Edit settings file", (*) => EditFile(SettingsFile), 0xE8A5)
    MenuItem(more, "Edit the autocorrect list", (*) => EditAutocorrect(), 0xE8A5)
    MenuItem(more, "Open Watchlog folder", (*) => Run(HomeDir), 0xE8B7)
    MenuItem(more, "Choose my own update folder", (*) => ChooseUpdateFolder(), 0xE896)
    more.Add()
    MenuItem(more, "Back up my settings and templates now", (*) => BackupNow(), 0xE74E)
    MenuItem(more, "Restore from a backup...", (*) => ShowRestore(), 0xE777)
    MenuItem(more, "Go back to the previous version...", (*) => GoBackVersion(), 0xE72B)
    if SkippedVersion() != ""
        MenuItem(more, "Offer the skipped update again (v" SkippedVersion() ")", (*) => ClearSkippedVersion(), 0xE896)
    more.Add()
    MenuItem(more, "Pause all shortcuts  (Ctrl+Alt+P)", (*) => TogglePause(), 0xE769)
    MenuItem(more, "Reload Watchlog  (Ctrl+Alt+R)", (*) => Reload(), 0xE72C)
    MenuItem(tm, "Advanced", more, 0xE712)
    tm.Add()
    MenuItem(tm, "Exit Watchlog", (*) => ExitApp(), 0xE711)

    ; One click on the tray icon opens the home window
    tm.Default := HOME_MENU
    tm.ClickCount := 1
}


; =====================================================================
;  CUSTOMIZE WATCHLOG  (v3.21.0)  -  tray menu > Customize Watchlog,
;  or the Customize button on the home window
;  Screens for the things that used to mean editing a file: the full-entry
;  daily logs, the shortcut keys, the programs Ctrl+Alt+L opens and
;  Ctrl+Alt+Shift+L closes, the shared lists, the autocorrect words and
;  the waits behind Alert Grid and iTrak. Each saves when you press Save.
; =====================================================================
CustomWin := ""

ShowCustomize() {
    global CustomWin
    if IsObject(CustomWin) {
        try WinActivate "ahk_id " CustomWin.Hwnd
        return
    }
    g := WGui("+AlwaysOnTop", "Customize Watchlog  -  v" VERSION)
    CustomWin := g
    g.BackColor := "FFFFFF"
    g.MarginX := 20, g.MarginY := 16
    g.SetFont("s16 bold c0E746E", "Segoe UI")
    g.AddText(, "Customize Watchlog")
    g.SetFont("s10 norm c606060")
    g.AddText("w560", "Change how Watchlog works from these screens, with no files to edit. Each one opens in its own window and applies when you save.")
    g.SetFont("s10 norm c000000")
    items := [["Full-entry daily logs", "Add, change or remove the logs Ctrl+Alt+F fills in.", () => ShowEntryEditor()]
        , ["Shortcut keys", "Pick different keys for Watchlog's shortcuts.", () => ShowHotkeyEditor()]
        , ["Start and end of shift", "Which programs open first, and which close at the end.", () => ShowShiftEditor()]
        , ["Shared lists", "Tables, machines and the other pick lists.", () => ShowEditor(2)]
        , ["Autocorrect words", "Acronyms and words fixed as you type.", () => ShowAutoEditor()]
        , ["Speed and timing", "The waits behind Alert Grid and iTrak, if one ever misses a step.", () => ShowTimingEditor()]
        , ["Logins and reminders", "Logins, the SDS sign-in and the log-in-again reminder.", () => ShowSettings(false, 1)]
        , ["Caps Lock, journal, updates", "The Caps Lock guard, the shift journal and update folder.", () => ShowSettings(false, 6)]]
    for it in items {
        g.AddButton("xm y+10 w220 h36", it[1]).OnEvent("Click", Open.Bind(it[3]))
        g.AddText("x+14 yp+8 w330", it[2])
    }
    darkCB := g.AddCheckbox("xm y+22" (Cfg["Dark"] ? " Checked" : ""), "Dark look  (also in the tray menu; applies to windows opened from now on)")
    darkCB.OnEvent("Click", SetDark)
    g.AddButton("xm y+14 w120 Default", "Close").OnEvent("Click", Close)
    g.OnEvent("Escape", Close)
    g.OnEvent("Close", Close)
    g.Show()

    SetDark(*) {
        SetDarkLook(darkCB.Value ? true : false)
    }
    Open(fn, *) {
        Close()
        fn()
    }
    Close(*) {
        global CustomWin
        CustomWin := ""
        g.Destroy()
    }
}

; ---- Shortcut keys -----------------------------------------------------
; Every Ctrl+Alt shortcut that can be changed, with its standard key. A
; key picked in Customize is kept in settings.ini [Hotkeys] id=key. The
; pause and reload keys, the app keys (Ctrl+Alt + a letter from [AppN]) and
; the keys inside forms stay as they are.
HotkeyKey(id) {
    for d in HotkeyDefs
        if d.id = id {
            v := ""
            try v := Trim(IniRead(SettingsFile, "Hotkeys", id, ""))
            return v != "" ? v : d.key
        }
    return ""
}

HotkeyNorm(k) => StrLower(LTrim(k, "$~*"))

; "^!+s" -> "Ctrl+Alt+Shift+S"
HotkeyLabel(k) {
    k := LTrim(k, "$~*")
    out := ""
    while k != "" && InStr("^!+#<>", SubStr(k, 1, 1)) {
        c := SubStr(k, 1, 1), k := SubStr(k, 2)
        out .= c = "^" ? "Ctrl+" : c = "!" ? "Alt+" : c = "+" ? "Shift+" : c = "#" ? "Win+" : ""
    }
    return out (StrLen(k) = 1 ? StrUpper(k) : k)
}

HK(id) => HotkeyLabel(HotkeyKey(id))

; "Shift+S" for Ctrl+Alt+Shift+S, the whole thing for any other combination
HKShort(id) {
    l := HK(id)
    return SubStr(l, 1, 9) = "Ctrl+Alt+" ? SubStr(l, 10) : l
}

RegisterHotkeys() {
    HotIf()
    used := Map()
    for a in AppList
        used["^!" StrLower(a.key)] := true
    for k in ["^!p", "^!x", "^!r", "numpadadd"]
        used[k] := true
    bad := ""
    for d in HotkeyDefs {
        k := HotkeyKey(d.id)
        if used.Has(HotkeyNorm(k)) && HotkeyNorm(k) != HotkeyNorm(d.key) {
            bad .= "   " d.label ":  " HotkeyLabel(k) " is already used, so the standard " HotkeyLabel(d.key) " is used instead`n"
            k := d.key
        }
        if used.Has(HotkeyNorm(k)) {
            bad .= "   " d.label ":  " HotkeyLabel(k) " is also taken, so it has no shortcut (Customize > Shortcut keys)`n"
            continue
        }
        try {
            Hotkey k, d.fn, "On"
        } catch {
            bad .= "   " d.label ":  " HotkeyLabel(k) " isn't a key Watchlog can use, so the standard " HotkeyLabel(d.key) " is used instead`n"
            k := d.key
            if used.Has(HotkeyNorm(k))
                continue
            try Hotkey k, d.fn, "On"
        }
        used[HotkeyNorm(k)] := true
    }
    if bad != "" {
        Activity("Shortcut keys: " StrReplace(Trim(bad, "`n "), "`n", " / "))
        MsgBox "Some shortcut keys couldn't be used:`n`n" bad "`nFix them in Customize Watchlog > Shortcut keys.", "Watchlog", "Icon!"
    }
}

HotkeyWin := ""

ShowHotkeyEditor() {
    global HotkeyWin
    if IsObject(HotkeyWin) {
        try WinActivate "ahk_id " HotkeyWin.Hwnd
        return
    }
    g := WGui("+AlwaysOnTop", "Shortcut keys")
    HotkeyWin := g
    g.BackColor := "FFFFFF"
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 18, g.MarginY := 14
    g.AddText("w720", "Click a box and press the keys you want. Use Ctrl, Alt or Win with them, so a shortcut can't fire while you type. These stay as they are: pause (Ctrl+Alt+P or X), reload (Ctrl+Alt+R), the app keys and the keys inside forms.")
    ctrls := []
    half := Ceil(HotkeyDefs.Length / 2)
    top := 78
    for i, d in HotkeyDefs {
        col := i <= half ? 0 : 1
        row := i <= half ? i - 1 : i - half - 1
        x := 18 + col * 370, y := top + row * 32
        g.AddText("x" x " y" (y + 4) " w170", StrUpper(SubStr(d.label, 1, 1)) SubStr(d.label, 2))
        ctrls.Push(g.AddHotkey("x" (x + 172) " y" y " w170", LTrim(HotkeyKey(d.id), "$")))
    }
    by := top + half * 32 + 14
    g.AddButton("x18 y" by " w120 Default", "Save").OnEvent("Click", Save)
    g.AddButton("x+8 w120", "Cancel").OnEvent("Click", Close)
    g.AddButton("x+8 w200", "Back to the standard keys").OnEvent("Click", Standard)
    g.AddText("x18 y+12 w720 c707070", "Messages elsewhere in Watchlog may still show the standard key names. Saving restarts Watchlog.")
    g.OnEvent("Escape", Close)
    g.OnEvent("Close", Close)
    g.Show()

    Standard(*) {
        for i, d in HotkeyDefs
            ctrls[i].Value := LTrim(d.key, "$")
    }
    Close(*) {
        global HotkeyWin
        HotkeyWin := ""
        g.Destroy()
    }
    Save(*) {
        global HotkeyWin
        g.Opt("+OwnDialogs")
        reserved := Map()
        for a in AppList
            reserved["^!" StrLower(a.key)] := "an app key"
        for k in ["^!p", "^!x", "^!r"]
            reserved[k] := "pause / reload"
        reserved["numpadadd"] := "the call pad's + key"
        seen := Map()
        keys := []
        for i, d in HotkeyDefs {
            v := Trim(ctrls[i].Value)
            if v = ""
                v := LTrim(d.key, "$")
            if !InStr(v, "^") && !InStr(v, "!") && !InStr(v, "#") {
                MsgBox d.label ": " HotkeyLabel(v) " has no Ctrl, Alt or Win in it. Add one so it can't fire while you type.", "Shortcut keys", "Icon!"
                return
            }
            n := HotkeyNorm(v)
            if reserved.Has(n) {
                MsgBox d.label ": " HotkeyLabel(v) " is used for " reserved[n] ". Pick another key.", "Shortcut keys", "Icon!"
                return
            }
            if seen.Has(n) {
                MsgBox d.label " and " seen[n] " both use " HotkeyLabel(v) ". Give one of them another key.", "Shortcut keys", "Icon!"
                return
            }
            seen[n] := d.label
            keys.Push(v)
        }
        try {
            for i, d in HotkeyDefs {
                if HotkeyNorm(keys[i]) = HotkeyNorm(d.key)
                    IniDelete SettingsFile, "Hotkeys", d.id
                else
                    IniWrite keys[i], SettingsFile, "Hotkeys", d.id
            }
        } catch as e {
            MsgBox "Couldn't save to settings.ini:`n" e.Message, "Shortcut keys", "Icon!"
            return
        }
        Activity("Shortcut keys saved from Customize")
        HotkeyWin := ""
        g.Destroy()
        if MsgBox("Saved. Watchlog restarts now to use the new keys.", "Shortcut keys", "OKCancel Iconi") = "OK"
            Reload
    }
}

; ---- Start and end of shift --------------------------------------------
ShiftEdWin := ""

ShowShiftEditor() {
    global ShiftEdWin
    if IsObject(ShiftEdWin) {
        try WinActivate "ahk_id " ShiftEdWin.Hwnd
        return
    }
    apps := []
    for a in Cfg["StartApps"]
        apps.Push({path: a.path, win: a.win})
    g := WGui("+AlwaysOnTop", "Start and end of shift")
    ShiftEdWin := g
    g.BackColor := "FFFFFF"
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 18, g.MarginY := 14
    g.AddText("w680", "Start of shift (" HK("start") ") opens these programs in this order, waits for them, then opens the work websites. A * in a path means any version (the newest is used). A program that's already open is left alone.")
    lv := g.AddListView("xm y+10 w680 r7 -Multi NoSortHdr", ["#", "Program", "Spot it as already open by"])
    lv.ModifyCol(1, 30), lv.ModifyCol(2, 400), lv.ModifyCol(3, 230)
    g.AddButton("xm y+8 w100", "Add...").OnEvent("Click", (*) => EditRow(0))
    g.AddButton("x+6 w100", "Edit...").OnEvent("Click", EditPicked)
    g.AddButton("x+6 w100", "Remove").OnEvent("Click", Remove)
    g.AddButton("x+6 w100", "Move up").OnEvent("Click", (*) => Move(-1))
    g.AddButton("x+6 w100", "Move down").OnEvent("Click", (*) => Move(1))
    g.AddText("xm y+16 w680", "End of shift (" HK("end") ") logs out of SDS, then closes these programs (separate them with commas):")
    closeE := g.AddEdit("xm w680 r3", Cfg["CloseApps"])
    g.AddButton("xm y+14 w120 Default", "Save").OnEvent("Click", Save)
    g.AddButton("x+8 w120", "Cancel").OnEvent("Click", Close)
    g.OnEvent("Escape", Close)
    g.OnEvent("Close", Close)
    Fill()
    g.Show()

    Fill(sel := 0) {
        lv.Delete()
        for i, a in apps
            lv.Add(, i, a.path, a.win)
        if sel && sel <= apps.Length
            lv.Modify(sel, "Select Focus Vis")
    }
    EditPicked(*) {
        g.Opt("+OwnDialogs")
        row := lv.GetNext()
        if !row {
            MsgBox "Pick a program in the list first.", "Start and end of shift"
            return
        }
        EditRow(row)
    }
    EditRow(row) {
        g.Opt("+OwnDialogs")
        if row = 0 && apps.Length >= 9 {
            MsgBox "There's room for 9 programs.", "Start and end of shift"
            return
        }
        cur := row ? apps[row] : {path: "", win: ""}
        d := WGui("+AlwaysOnTop +Owner" g.Hwnd, row ? "Edit program" : "Add a program")
        d.SetFont("s10", "Segoe UI")
        d.AddText("w520", "The program or batch file to open (a * means any version):")
        pe := d.AddEdit("w420 r1", cur.path)
        d.AddButton("x+6 w90", "Browse...").OnEvent("Click", Browse)
        d.AddText("xm w520", "How to tell it's already open (optional; for example  SDS ahk_exe javaw.exe  or  ahk_exe CMPDesktop.exe). Leave it blank for the Bally programs:")
        we := d.AddEdit("xm w520 r1", cur.win)
        d.AddButton("xm y+14 w110 Default", "OK").OnEvent("Click", OK)
        d.AddButton("x+8 w110", "Cancel").OnEvent("Click", Done)
        d.OnEvent("Escape", Done)
        d.OnEvent("Close", Done)
        g.Opt("+Disabled")
        d.Show()

        Browse(*) {
            d.Opt("+OwnDialogs")
            f := FileSelect(1, "C:\", "Pick the program or batch file", "Programs (*.exe; *.bat; *.cmd; *.lnk)")
            if f != ""
                pe.Value := f
        }
        OK(*) {
            p := Trim(pe.Value, " `t`"")
            if p = "" {
                d.Opt("+OwnDialogs")
                MsgBox "Type or browse to the program first.", "Start and end of shift"
                return
            }
            w := Trim(we.Value)
            if row
                apps[row] := {path: p, win: w}
            else
                apps.Push({path: p, win: w})
            Done()
            Fill(row ? row : apps.Length)
        }
        Done(*) {
            g.Opt("-Disabled")
            d.Destroy()
            WinActivate "ahk_id " g.Hwnd
        }
    }
    Remove(*) {
        g.Opt("+OwnDialogs")
        row := lv.GetNext()
        if !row {
            MsgBox "Pick a program in the list first.", "Start and end of shift"
            return
        }
        apps.RemoveAt(row)
        Fill(Min(row, apps.Length))
    }
    Move(d) {
        row := lv.GetNext()
        if !row || row + d < 1 || row + d > apps.Length
            return
        t := apps[row], apps[row] := apps[row + d], apps[row + d] := t
        Fill(row + d)
    }
    Close(*) {
        global ShiftEdWin
        ShiftEdWin := ""
        g.Destroy()
    }
    Save(*) {
        global ShiftEdWin
        g.Opt("+OwnDialogs")
        if !apps.Length {
            MsgBox "Keep at least one program in the list (with none, Watchlog goes back to Alert Grid, SDS and CMP).", "Start and end of shift", "Icon!"
            return
        }
        try {
            Loop 9 {
                IniDelete SettingsFile, "StartOfShift", "Run" A_Index
                IniDelete SettingsFile, "StartOfShift", "Window" A_Index
            }
            for i, a in apps {
                IniWrite a.path, SettingsFile, "StartOfShift", "Run" i
                if a.win != ""
                    IniWrite a.win, SettingsFile, "StartOfShift", "Window" i
            }
            IniWrite Trim(closeE.Value), SettingsFile, "EndOfShift", "Close"
        } catch as e {
            MsgBox "Couldn't save to settings.ini:`n" e.Message, "Start and end of shift", "Icon!"
            return
        }
        Cfg["StartApps"] := []
        for a in apps
            Cfg["StartApps"].Push({path: a.path, win: a.win != "" ? a.win : DefaultStartWindow(a.path)})
        Cfg["CloseApps"] := Trim(closeE.Value)
        NoteOwnWrites()
        Activity("Start and end of shift programs saved from Customize (" apps.Length " to open)")
        ShiftEdWin := ""
        g.Destroy()
        Tip("Saved.", 1500, true)
    }
}

; ---- Autocorrect words ---------------------------------------------------
AutoEdWin := ""

ShowAutoEditor() {
    global AutoEdWin
    if IsObject(AutoEdWin) {
        try WinActivate "ahk_id " AutoEdWin.Hwnd
        return
    }
    pairs := AutoParse(FileExist(AutoFile) ? FileRead(AutoFile, "UTF-8") : AutoDefault())
    shown := []
    g := WGui("+AlwaysOnTop", "Autocorrect words")
    AutoEdWin := g
    g.BackColor := "FFFFFF"
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 18, g.MarginY := 14
    onCB := g.AddCheckbox("xm" (Cfg["Autocorrect"] ? " Checked" : ""), "Fix these words as I type in the call pad and the log forms")
    g.AddText("xm y+8 w560", "A word is fixed when you finish it with a space, Enter or punctuation, never in the middle of a word. Ctrl+Z puts the old word back. A ticked row is on.")
    search := g.AddEdit("xm y+8 w300")
    SendMessage 0x1501, 1, StrPtr("Search the list"), search
    lv := g.AddListView("xm y+6 w560 r14 Checked -Multi", ["When I type", "It becomes"])
    lv.ModifyCol(1, 200), lv.ModifyCol(2, 330)
    g.AddButton("xm y+8 w100", "Add...").OnEvent("Click", (*) => EditRow(0))
    g.AddButton("x+6 w100", "Edit...").OnEvent("Click", EditPicked)
    g.AddButton("x+6 w100", "Delete").OnEvent("Click", Remove)
    g.AddButton("x+6 w180", "Back to the built-in list").OnEvent("Click", Reset)
    g.AddButton("xm y+16 w120 Default", "Save").OnEvent("Click", Save)
    g.AddButton("x+8 w120", "Cancel").OnEvent("Click", Close)
    search.OnEvent("Change", (*) => Fill())
    lv.OnEvent("ItemCheck", Checked)
    lv.OnEvent("DoubleClick", (ctl, row) => row ? EditRow(row) : 0)
    g.OnEvent("Escape", Close)
    g.OnEvent("Close", Close)
    Fill()
    g.Show()

    Fill() {
        q := StrLower(Trim(search.Text))
        lv.Delete()
        shown := []
        for i, p in pairs {
            if q != "" && !InStr(StrLower(p.w), q) && !InStr(StrLower(p.r), q)
                continue
            shown.Push(i)
            lv.Add(p.on ? "Check" : "", p.w, p.r)
        }
    }
    Checked(ctl, item, isChecked) {
        if item >= 1 && item <= shown.Length
            pairs[shown[item]].on := isChecked ? true : false
    }
    EditPicked(*) {
        g.Opt("+OwnDialogs")
        row := lv.GetNext()
        if !row {
            MsgBox "Pick a row in the list first.", "Autocorrect words"
            return
        }
        EditRow(row)
    }
    EditRow(row) {
        g.Opt("+OwnDialogs")
        idx := row ? shown[row] : 0
        cur := idx ? pairs[idx] : {w: "", r: "", on: true}
        d := WGui("+AlwaysOnTop +Owner" g.Hwnd, row ? "Edit a word" : "Add a word")
        d.SetFont("s10", "Segoe UI")
        d.AddText("w380", "When I type (one word, no spaces):")
        we := d.AddEdit("w380 r1", cur.w)
        d.AddText("w380", "It becomes:")
        re := d.AddEdit("w380 r1", cur.r)
        d.AddButton("xm y+14 w110 Default", "OK").OnEvent("Click", OK)
        d.AddButton("x+8 w110", "Cancel").OnEvent("Click", Done)
        d.OnEvent("Escape", Done)
        d.OnEvent("Close", Done)
        g.Opt("+Disabled")
        d.Show()
        OK(*) {
            w := Trim(we.Value), r := Trim(re.Value)
            d.Opt("+OwnDialogs")
            if w = "" || r = "" || InStr(w, " ") || InStr(w, "=") {
                MsgBox "Both boxes need something, and the word you type can't have spaces or an = sign in it.", "Autocorrect words"
                return
            }
            if idx {
                pairs[idx].w := w, pairs[idx].r := r
            } else
                pairs.Push({w: w, r: r, on: true})
            Done()
            Fill()
        }
        Done(*) {
            g.Opt("-Disabled")
            d.Destroy()
            WinActivate "ahk_id " g.Hwnd
        }
    }
    Remove(*) {
        g.Opt("+OwnDialogs")
        row := lv.GetNext()
        if !row {
            MsgBox "Pick a row in the list first.", "Autocorrect words"
            return
        }
        pairs.RemoveAt(shown[row])
        Fill()
    }
    Reset(*) {
        g.Opt("+OwnDialogs")
        if MsgBox("Replace the whole list with the built-in one? Your own words are lost.", "Autocorrect words", "YesNo Icon? Default2") != "Yes"
            return
        pairs := AutoParse(AutoDefault())
        Fill()
    }
    Close(*) {
        global AutoEdWin
        AutoEdWin := ""
        g.Destroy()
    }
    Save(*) {
        global AutoEdWin, AutoStamp
        g.Opt("+OwnDialogs")
        out := "# Watchlog casino autocorrect. One fix per line:  what you type = what it becomes`n"
            . "# A fix happens when you finish the word with a space, Enter or punctuation.`n"
            . "# Ctrl+Z puts the old word back. A line starting with # is switched off.`n"
            . "# Customize Watchlog > Autocorrect words edits this file for you.`n`n"
        for p in pairs
            out .= (p.on ? "" : "# ") p.w " = " p.r "`n"
        try {
            if FileExist(AutoFile)
                FileCopy AutoFile, AutoFile ".bak", 1
            f := FileOpen(AutoFile, "w", "UTF-8-RAW")
            f.Write(out)
            f.Close()
            IniWrite onCB.Value ? "yes" : "no", SettingsFile, "CallPad", "Autocorrect"
        } catch as e {
            MsgBox "Couldn't save:`n" e.Message, "Autocorrect words", "Icon!"
            return
        }
        Cfg["Autocorrect"] := onCB.Value ? true : false
        AutoStamp := "-"
        LoadAutocorrect()
        NoteOwnWrites()
        Activity("Autocorrect list saved from Customize (" pairs.Length " words, " (onCB.Value ? "on" : "off") ")")
        AutoEdWin := ""
        g.Destroy()
        Tip("Saved.", 1500, true)
    }
}

; Reads autocorrect text into [{w, r, on}]. A "# word = fix" line is a word that's switched off.
AutoParse(text) {
    pairs := []
    for line in StrSplit(text, "`n", "`r") {
        line := Trim(line)
        on := true
        if SubStr(line, 1, 1) = "#" {
            on := false
            line := Trim(SubStr(line, 2))
        }
        eq := InStr(line, "=")
        if !eq
            continue
        w := Trim(SubStr(line, 1, eq - 1)), r := Trim(SubStr(line, eq + 1))
        if w = "" || r = "" || InStr(w, " ")
            continue
        if !on && !RegExMatch(w, "^[\p{L}\d'-]+$")
            continue
        pairs.Push({w: w, r: r, on: on})
    }
    return pairs
}

; ---- Speed and timing --------------------------------------------------
TimingWin := ""

ShowTimingEditor() {
    global TimingWin
    if IsObject(TimingWin) {
        try WinActivate "ahk_id " TimingWin.Hwnd
        return
    }
    rows := [{sec: "AlertGrid", key: "Pause", def: 40, label: "Alert Grid: wait between clicks", note: "Raise it if a clear misses a step."}
        , {sec: "AlertGrid", key: "SelectWait", def: 120, label: "Alert Grid: most it waits for Select All", note: "Raise it if only the top alert is cleared."}
        , {sec: "ITrak", key: "Pause", def: 300, label: "iTrak: wait between clicks", note: "Between the clicks that open a new daily log."}
        , {sec: "ITrak", key: "EntryWait", def: 8000, label: "iTrak: most it waits for a new log", note: "How long a full-entry log waits for the new form to open."}
        , {sec: "ITrak", key: "EntrySettle", def: 600, label: "iTrak: wait once the form is open", note: "Raise it if the first field is missed."}]
    g := WGui("+AlwaysOnTop", "Speed and timing")
    TimingWin := g
    g.BackColor := "FFFFFF"
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 18, g.MarginY := 14
    g.AddText("w640", "All in milliseconds (1000 = one second). The standard values are right for most PCs; change one only if something misses a step. Lower is faster.")
    edits := []
    for r in rows {
        cur := ""
        try cur := Trim(IniRead(SettingsFile, r.sec, r.key, r.def))
        if !IsInteger(cur)
            cur := r.def
        g.AddText("xm y+14 w280", r.label)
        edits.Push(g.AddEdit("x+6 yp-3 w80 Number", cur))
        g.AddText("x+10 yp+3 w260 c707070", "standard " r.def ".  " r.note)
    }
    g.AddButton("xm y+22 w120 Default", "Save").OnEvent("Click", Save)
    g.AddButton("x+8 w120", "Cancel").OnEvent("Click", Close)
    g.AddButton("x+8 w200", "Back to the standard values").OnEvent("Click", Standard)
    g.OnEvent("Escape", Close)
    g.OnEvent("Close", Close)
    g.Show()

    Standard(*) {
        for i, r in rows
            edits[i].Value := r.def
    }
    Close(*) {
        global TimingWin
        TimingWin := ""
        g.Destroy()
    }
    Save(*) {
        global TimingWin
        g.Opt("+OwnDialogs")
        try {
            for i, r in rows {
                v := Trim(edits[i].Value)
                if !IsInteger(v) || v < 0 || v > 60000
                    v := r.def
                if Integer(v) = r.def
                    IniDelete SettingsFile, r.sec, r.key
                else
                    IniWrite v, SettingsFile, r.sec, r.key
            }
        } catch as e {
            MsgBox "Couldn't save to settings.ini:`n" e.Message, "Speed and timing", "Icon!"
            return
        }
        NoteOwnWrites()
        Activity("Speed and timing saved from Customize")
        TimingWin := ""
        g.Destroy()
        Tip("Saved.", 1500, true)
    }
}

; ---- Full-entry daily logs ----------------------------------------------
EntryEdWin := ""

; The file an entry from src is kept in, or "" when it can't be changed from
; here (the team's shared templates file)
EntryFileFor(src) => src = "mine" ? MyTemplatesFile : (Tpl.src = "local" ? TemplatesFile : "")

ShowEntryEditor() {
    global EntryEdWin
    if IsObject(EntryEdWin) {
        try WinActivate "ahk_id " EntryEdWin.Hwnd
        return
    }
    work := []
    for e in Entries
        work.Push({name: e.name, loc: e.loc, topic: e.topic, ref: e.ref, syn: e.syn, end: e.end, src: e.src})
    g := WGui("+AlwaysOnTop", "Full-entry daily logs")
    EntryEdWin := g
    g.BackColor := "FFFFFF"
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 18, g.MarginY := 14
    g.AddText("w760", "Logs for " HK("entrypick") ": type the first letters of a name, Enter, and Watchlog opens a new daily log in iTrak and fills it in with no questions. Only logs that never need extra input belong here. Pick a log, then Edit, or Add a new one.")
    lv := g.AddListView("xm y+10 w760 r9 -Multi NoSortHdr", ["Name", "Location", "Topic", "Reference", "Clicks Now", "Kept in"])
    lv.ModifyCol(1, 130), lv.ModifyCol(2, 140), lv.ModifyCol(3, 120), lv.ModifyCol(4, 170), lv.ModifyCol(5, 70), lv.ModifyCol(6, 110)
    g.AddButton("xm y+8 w100", "Add...").OnEvent("Click", (*) => EditRow(0))
    g.AddButton("x+6 w100", "Edit...").OnEvent("Click", EditPicked)
    g.AddButton("x+6 w100", "Copy").OnEvent("Click", CopyRow)
    g.AddButton("x+6 w100", "Delete").OnEvent("Click", Remove)
    g.AddButton("x+22 w200", "Try it in iTrak...").OnEvent("Click", TryIt)
    g.AddText("xm y+14 w760 c707070", "In a synopsis, {Bay} is the bay entered at the start of shift and {Bay?} asks which bay (and keeps it for the shift). Teach the field spots once with " HK("entryteach") ".")
    g.AddButton("xm y+14 w120 Default", "Save").OnEvent("Click", Save)
    g.AddButton("x+8 w120", "Cancel").OnEvent("Click", Close)
    lv.OnEvent("DoubleClick", (ctl, row) => row ? EditRow(row) : 0)
    g.OnEvent("Escape", Close)
    g.OnEvent("Close", Close)
    Fill()
    g.Show()

    Fill(sel := 0) {
        lv.Delete()
        for e in work
            lv.Add(, e.name, e.loc, e.topic, e.ref, e.end ? "yes" : "", EntryFileFor(e.src) = "" ? "team file (read only)" : e.src = "mine" ? "my-templates.txt" : "templates.txt")
        if sel && sel <= work.Length
            lv.Modify(sel, "Select Focus Vis")
    }
    Picked() {
        g.Opt("+OwnDialogs")
        row := lv.GetNext()
        if !row
            MsgBox "Pick a log in the list first.", "Full-entry daily logs"
        return row
    }
    EditPicked(*) {
        row := Picked()
        if row
            EditRow(row)
    }
    EditRow(row) {
        g.Opt("+OwnDialogs")
        if row && EntryFileFor(work[row].src) = "" {
            MsgBox "That log is in the team's shared templates file, which can't be changed from here. Copy it and change the copy.", "Full-entry daily logs"
            return
        }
        cur := row ? work[row] : {name: "", loc: "", topic: "", ref: "", syn: "", end: false, src: Tpl.src = "local" ? "main" : "mine"}
        d := WGui("+AlwaysOnTop +Owner" g.Hwnd, row ? "Edit " cur.name : "Add a full-entry log")
        d.SetFont("s10", "Segoe UI")
        d.AddText("w520", "Name (what you type in the list):")
        ne := d.AddEdit("w520 r1", cur.name)
        d.AddText("w520", "Location (typed in full, then Enter):")
        le := d.AddEdit("w520 r1", cur.loc)
        d.AddText("w520", "Topic (typed in full, then Enter):")
        te := d.AddEdit("w520 r1", cur.topic)
        d.AddText("w520", "Reference:")
        re := d.AddEdit("w520 r1", cur.ref)
        d.AddText("w520", "Synopsis:")
        se := d.AddEdit("w520 r4 WantReturn", cur.syn)
        nowCB := d.AddCheckbox("xm" (cur.end ? " Checked" : ""), "Click End Time's Now button when the log is filled (the log is complete)")
        d.AddButton("xm y+14 w110 Default", "OK").OnEvent("Click", OK)
        d.AddButton("x+8 w110", "Cancel").OnEvent("Click", Done)
        d.OnEvent("Escape", Done)
        d.OnEvent("Close", Done)
        g.Opt("+Disabled")
        d.Show()
        OK(*) {
            n := Trim(ne.Value), l := Trim(le.Value), t := Trim(te.Value), r := Trim(re.Value)
            s := Trim(StrReplace(StrReplace(se.Value, "`r`n", " "), "`n", " "))
            d.Opt("+OwnDialogs")
            if n = "" || l = "" || t = "" || r = "" || s = "" {
                MsgBox "Every box needs something (use NA in Reference if there's nothing).", "Full-entry daily logs"
                return
            }
            for v in [n, l, t, r, s]
                if InStr(v, "|") {
                    MsgBox "A | can't be used in these boxes.", "Full-entry daily logs"
                    return
                }
            if InStr(n, "=") || SubStr(n, 1, 1) = "+" {
                MsgBox "The name can't have an = sign in it or start with +.", "Full-entry daily logs"
                return
            }
            for i, w in work
                if i != row && StrLower(w.name) = StrLower(n) {
                    MsgBox "There's already a log called " n ".", "Full-entry daily logs"
                    return
                }
            item := {name: n, loc: l, topic: t, ref: r, syn: s, end: nowCB.Value ? true : false, src: cur.src}
            if row
                work[row] := item
            else
                work.Push(item)
            Done()
            Fill(row ? row : work.Length)
        }
        Done(*) {
            g.Opt("-Disabled")
            d.Destroy()
            WinActivate "ahk_id " g.Hwnd
        }
    }
    CopyRow(*) {
        row := Picked()
        if !row
            return
        e := work[row]
        n := e.name " copy"
        while HasName(n)
            n .= " 2"
        work.InsertAt(row + 1, {name: n, loc: e.loc, topic: e.topic, ref: e.ref, syn: e.syn, end: e.end, src: Tpl.src = "local" ? "main" : "mine"})
        Fill(row + 1)
    }
    HasName(n) {
        for w in work
            if StrLower(w.name) = StrLower(n)
                return true
        return false
    }
    Remove(*) {
        row := Picked()
        if !row
            return
        if EntryFileFor(work[row].src) = "" {
            MsgBox "That log is in the team's shared templates file, which can't be changed from here.", "Full-entry daily logs"
            return
        }
        if MsgBox("Delete " work[row].name "?", "Full-entry daily logs", "YesNo Icon?") != "Yes"
            return
        work.RemoveAt(row)
        Fill(Min(row, work.Length))
    }
    TryIt(*) {
        row := Picked()
        if !row
            return
        if MsgBox("This opens a NEW daily log in iTrak and fills it in, as if you had picked " work[row].name " from the list.`n`nGo ahead?", "Full-entry daily logs", "YesNo Icon?") != "Yes"
            return
        e := work[row]
        g.Hide()
        RunEntry(e)
        g.Show()
    }
    Close(*) {
        global EntryEdWin
        EntryEdWin := ""
        g.Destroy()
    }
    Save(*) {
        global EntryEdWin
        g.Opt("+OwnDialogs")
        byFile := Map()
        for e in work {
            f := EntryFileFor(e.src)
            if f = ""
                continue
            if !byFile.Has(f)
                byFile[f] := []
            byFile[f].Push(e)
        }
        for src in ["main", "mine"] {
            f := EntryFileFor(src)
            if f != "" && !byFile.Has(f) && FileExist(f)
                byFile[f] := []
        }
        for f, list in byFile {
            if !WriteEntryLines(f, list) {
                MsgBox "Couldn't save to " f, "Full-entry daily logs", "Icon!"
                return
            }
        }
        ReloadEntries()
        NoteOwnWrites()
        Activity("Full-entry logs saved from Customize (" work.Length " logs)")
        EntryEdWin := ""
        g.Destroy()
        Tip("Saved. " Entries.Length " full-entry logs.", 2000, true)
    }
}

; Rewrites the + lines of a templates file with list, leaving every other line
; as it was (the old file is kept as .bak). Returns true when it saved.
WriteEntryLines(file, list) {
    text := ""
    if FileExist(file)
        try text := FileRead(file, "UTF-8")
    nl := InStr(text, "`r`n") ? "`r`n" : "`n"
    lines := StrSplit(StrReplace(text, "`r`n", "`n"), "`n")
    block := []
    for e in list
        block.Push("+" e.name " = " e.loc " | " e.topic " | " e.ref " | " e.syn (e.end ? " | end" : ""))
    out := [], placed := false
    for ln in lines {
        if SubStr(Trim(ln), 1, 1) = "+" {
            if !placed {
                for b in block
                    out.Push(b)
                placed := true
            }
            continue
        }
        out.Push(ln)
    }
    if !placed && block.Length {
        while out.Length && out[out.Length] = ""
            out.Pop()
        out.Push("", "# ----- FULL DAILY LOGS (Customize Watchlog > Full-entry daily logs) -----")
        for b in block
            out.Push(b)
        out.Push("")
    }
    s := ""
    for i, ln in out
        s .= ln (i < out.Length ? nl : "")
    try {
        if FileExist(file)
            FileCopy file, file ".bak", 1
        f := FileOpen(file, "w", "UTF-8-RAW")
        f.Write(s)
        f.Close()
        return true
    }
    return false
}

; Reads the full-entry logs again after the editor saved
ReloadEntries() {
    global Entries
    Entries := []
    p := ""
    main := ""
    try main := FileRead(Tpl.src = "local" ? TemplatesFile : Tpl.file, "UTF-8")
    ReadEntries(main, "templates.txt", &p, "main")
    mine := ""
    if FileExist(MyTemplatesFile)
        try mine := FileRead(MyTemplatesFile, "UTF-8")
    ReadEntries(mine, "my-templates.txt", &p, "mine")
}


; =====================================================================
;  WATCHLOG HOME  -  click the tray icon, or Ctrl+Alt+M   (v3.10.0)
;  Everything in one window, as buttons with pictures, for anyone who
;  doesn't know the shortcuts yet. Each button shows its shortcut, so
;  it doubles as a way to learn them. Along the bottom: how this PC is
;  doing (version, templates, Alert Grid, this shift's time saved),
;  and the Caps Lock guard and pause switches.
;  It closes as soon as a button is pressed, and anything that types (a
;  template, a login) goes into the window you were in before.
;  Ctrl+Alt+M again (or Esc) closes it.
; =====================================================================
; (set up by RegisterHotkeys, see HotkeyDefs)

ShowHome() {
    global HomeWin
    if IsObject(HomeWin) {
        if WinActive("ahk_id " HomeWin.Hwnd)
            CloseHome()
        else
            try WinActivate "ahk_id " HomeWin.Hwnd
        return
    }
    target := WorkWindow()
    W := 180, gap := 8, per := 5
    g := WGui("-MinimizeBox", "Watchlog  -  v" VERSION)
    g.BackColor := "F7FAFA"
    g.MarginX := 18, g.MarginY := 14
    g.SetFont("s18 bold c0E746E", "Segoe UI")
    g.AddText("xm", "Watchlog")
    g.SetFont("s10 norm c606060")
    g.AddText("x+12 yp+11", "Press a button, or learn the shortcut shown on it.")

    cardY := 0
    sh0 := SavedShift()
    fullW := per * W + (per - 1) * gap
    cardW := (fullW - 2 * 12) // 3
    Card(1, sh0.log, "logs this shift")
    Card(2, sh0.login, sh0.login = 1 ? "login this shift" : "logins this shift")
    Card(3, SavedTime(sh0.keys), "typing saved this shift")

    Group("Logs", 0x0E746E, [
        ["Call pad", "Numpad +", 0xE717, () => ShowCallPad(), true]
        , ["Find a template", HK("find"), 0xE721, () => ShowPicker(), false]
        , ["Cheat sheet", HK("cheat"), 0xE8FD, () => ShowCheatSheet(), false]
        , ["Shift journal", HK("journal"), 0xE8F1, () => ShowJournal(), false]
        , ["Quick notes", HK("notes"), 0xE70B, () => ShowNotes(), false]
        , ["Time saved", "this shift and before", 0xE916, () => ShowTimeSaved(), false]
        , ["Shift count", "exact tally of this shift", 0xE9D2, () => ShowShiftCount(), false]
        , ["Shift dashboard", HK("dashboard"), 0xE9D9, () => ShowDashboard(), false]])

    logins := []
    for rec in LoginList
        logins.Push(["Sign in  " rec.trig, rec.user, 0xE77B, HomeLogin.Bind(rec), true])
    if logins.Length
        Group("Logins  (types the username and password, like typing the shortcut)", 0x1565C0, logins)

    Group("Set up", 0x555555, [
        ["Template editor", HK("editor"), 0xE70F, () => ShowEditor(), false]
        , ["Customize", "logs, keys, lists, programs", 0xE713, () => ShowCustomize(), false]
        , ["Settings", "logins, shift, updates", 0xE713, () => ShowSettings(), false]
        , ["Tutorial", "a two-minute tour", 0xE7BE, () => ShowTutorial(), false]
        , ["Security and status", "what's kept where", 0xE72E, () => ShowSecurity(), false]
        , ["About Watchlog", "version, licence", 0xE946, () => ShowAbout(), false]
        , ["Save window layout", HK("savelayout"), 0xE74E, () => SaveLayout(), false]])

    ; How this PC is doing
    g.AddText("xm y+18 w" fullW " h1 0x10")
    Status(OutOfDate() ? "C62828" : "2E7D32", "Watchlog v" VERSION
        . (OutOfDate() ? ": UPDATE NEEDED, the team is on v" Tpl.program
        : UpdateWaiting() ? ": v" TeamProgramVersion() " is waiting in the update folder"
        : Tpl.program != "" ? ": up to date" : ""))
    Status(Tpl.src = "team-copy" || !Tpl.count ? "C62828" : "2E7D32"
        , Tpl.count " templates" (Tpl.mine ? " + " Tpl.mine " of your own" : "")
        . (Tpl.version != "" ? ", wording " Tpl.version : "")
        . (Tpl.src = "team" ? " (team file)" : Tpl.src = "team-copy" ? " (saved copy: the team file can't be reached)" : ""))
    taught := AlertTaught()
    Status(taught != "" ? "2E7D32" : "B86E00", taught = "here" ? "Alert Grid clicks are taught on this PC"
        : taught = "team" ? "Alert Grid clicks: using the team's shared setup"
        : "Alert Grid clicks aren't taught on this PC yet (Settings > Alert Grid)")
    it := ITrakTaught()
    Status(it != "" ? "2E7D32" : "B86E00", it = "here" ? "iTrak new daily log is taught on this PC"
        : it = "team" ? "iTrak new daily log: using the team's shared setup"
        : "iTrak new daily log isn't taught on this PC yet (Ctrl+Alt+Shift+I)")
    Status(BreakLeftSecs() < 0 ? "C62828" : "0E746E", BreakText())
    sh := SavedShift()
    Status("0E746E", "This shift: " sh.log " log" (sh.log = 1 ? "" : "s") ", " sh.login " login" (sh.login = 1 ? "" : "s")
        . ", " SavedTime(sh.keys) " saved")

    g.SetFont("s10 c303030")
    capsCB := g.AddCheckbox("xm y+12" (CapsGuard ? " Checked" : ""), "Caps Lock guard")
    capsCB.OnEvent("Click", (*) => ToggleCapsGuard())
    pauseCB := g.AddCheckbox("x+24 yp" (A_IsSuspended ? " Checked" : ""), "Pause all shortcuts")
    pauseCB.OnEvent("Click", (*) => TogglePause())
    g.AddButton("x" (g.MarginX + fullW - 110) " yp-6 w110 Default", "Close").OnEvent("Click", (*) => CloseHome())
    g.OnEvent("Escape", (*) => CloseHome())
    g.OnEvent("Close", (*) => CloseHome())
    HomeWin := g
    g.Show()

    ; A heading and a row (or two) of buttons
    Group(title, color, tiles) {
        g.SetFont("s11 bold c" Format("{:06X}", color), "Segoe UI")
        g.AddText("xm y+16", title)
        g.SetFont("s10 norm c202020")
        for i, t in tiles {
            pos := Mod(i - 1, per) = 0 ? "xm y+6" : "x+" gap " yp"
            IconButton(g, pos " w" W " h52", t[1] "`n" t[2], t[3], color, Go.Bind(t[4], t[5]))
        }
    }

    ; A number with a caption under it, on a panel
    Card(i, big, small) {
        if i = 1 {
            panel := g.AddText("xm y+14 w" cardW " h66 Background" LookCard(), "")
            panel.GetPos(&px, &cardY)
        } else
            panel := g.AddText("x" (g.MarginX + (i - 1) * (cardW + 12)) " y" cardY " w" cardW " h66 Background" LookCard(), "")
        panel.GetPos(&px, &py)
        g.SetFont("s20 bold c0E746E", "Segoe UI")
        g.AddText("x" (px + 14) " y" (py + 4) " w" (cardW - 28) " h34 BackgroundTrans", big)
        g.SetFont("s9 norm c606060", "Segoe UI")
        g.AddText("x" (px + 14) " y" (py + 40) " w" (cardW - 28) " BackgroundTrans", small)
        g.SetFont("s10 norm c202020")
    }

    Status(color, text) {
        g.SetFont("s10 c" color)
        g.AddText("xm y+6", "●")
        g.SetFont("s10 c303030")
        g.AddText("x+8 yp", text)
    }

    ; Closes the home window, puts the keyboard back where it was when the
    ; button types something, then does what the button says
    Go(fn, back, *) {
        CloseHome()
        if back && target
            ReturnTo(target)
        fn()
    }
}

CloseHome() {
    global HomeWin
    if IsObject(HomeWin) {
        try HomeWin.Destroy()
        HomeWin := ""
    }
}

; The window you were working in: the active one, or (after a click on the
; tray icon, which makes the taskbar active) the top one under it
WorkWindow() {
    a := WinExist("A")
    try {
        if a && !LayoutSkip(a) && !(WinGetClass("ahk_id " a) ~= "^(Shell_TrayWnd|Shell_SecondaryTrayWnd|NotifyIconOverflowWindow|TopLevelWindowForOverflowXamlIsland|Windows\.UI\.Core\.CoreWindow)$")
            return a
    }
    for id in WinGetList() {
        try {
            if LayoutSkip(id) || WinGetMinMax("ahk_id " id) = -1
                continue
            if WinGetClass("ahk_id " id) ~= "^(NotifyIconOverflowWindow|TopLevelWindowForOverflowXamlIsland|Windows\.UI\.Core\.CoreWindow)$"
                continue
            return id
        }
    }
    return 0
}

; A login button in the home window. A login locked to a program brings
; that program to the front first; one that isn't locked asks before it
; types, since it would type into whatever window is in front.
HomeLogin(rec) {
    SetTitleMatchMode 2
    if rec.win != "" {
        if !LoginWindowActive(rec.win) {
            for part in StrSplit(rec.win, "|") {
                part := Trim(part)
                if part != "" && (id := WinExist(part)) {
                    try WinActivate "ahk_id " id
                    WinWaitActive "ahk_id " id, , 2
                    break
                }
            }
        }
        if !LoginWindowActive(rec.win) {
            MsgBox "The program " rec.trig " works in isn't open:`n`n" rec.win "`n`nOpen it, then try again.", "Watchlog", "Icon!"
            return
        }
    } else {
        here := WinExist("A"), title := ""
        try title := WinGetTitle("ahk_id " here)
        if !here || title = "" || MsgBox("Type the " rec.trig " login (" rec.user ") into this window?`n`n" title, "Watchlog", "YesNo Icon? Default2") != "Yes"
            return
        ReturnTo(here)
    }
    Sleep 150
    DoLogin(rec.trig, rec.user, rec.pw, rec)
}


; =====================================================================
;  TEMPLATE EDITOR  -  Ctrl+Alt+E, the home window or the tray menu
;  (v3.10.0) Change the templates without opening templates.txt: pick
;  one on the left, change its shortcut, name or wording on the right,
;  and add or change its boxes with a small form instead of typing
;  {Name: a | b} by hand. The preview shows how the log comes out. The
;  Shared lists tab changes lists like @tables.
;  Nothing is written until Save. Save keeps a copy of the file as it
;  was (%LOCALAPPDATA%\Watchlog\template backups, the last 20), bumps
;  the "# Wording version" line, and Watchlog picks up the new wording
;  when the editor closes. Lines it doesn't touch (the notes at the top,
;  the section headings) stay exactly as they were.
;  Shortcuts don't fire while the editor is in front, so typing ;jack
;  into it doesn't open the jackpot form.
; =====================================================================
; (set up by RegisterHotkeys, see HotkeyDefs)

; The kinds of box, in the order the box form lists them
BoxKinds() {
    static kinds := [["plain", "Text you type"]
        , ["list", "A list of choices"]
        , ["shared", "A shared list (like @tables)"]
        , ["next", "Steps: opens on the one after last time"]
        , ["now", "The time now (can be changed)"]
        , ["time", "A time you type (2130 becomes 21:30)"]
        , ["money", "Money (10000 becomes 10,000)"]
        , ["percent", "A percentage (67 becomes 67%)"]
        , ["clip", "A copied number (copy it first)"]
        , ["last", "Remembers what was typed last time"]
        , ["alertcopy", "Facial rec alert # (copied in Edge)"]
        , ["matchcopy", "Facial rec match % (copied in Edge)"]]
    return kinds
}

; ---- Reading and writing the file ------------------------------------
; A templates file as lines, plus where its templates, lists and section
; headings are. Only the lines that change are ever rewritten.
EdRead(file) {
    raw := FileRead(file, "RAW")
    bom := raw.Size >= 3 && NumGet(raw, 0, "UChar") = 0xEF && NumGet(raw, 1, "UChar") = 0xBB && NumGet(raw, 2, "UChar") = 0xBF
    text := FileRead(file, "UTF-8")
    doc := {file: file, crlf: InStr(text, "`r`n") > 0, bom: bom, time: FileTimeOf(file)
        , lines: StrSplit(StrReplace(text, "`r`n", "`n"), "`n")}
    EdScan(doc)
    return doc
}

EdScan(doc) {
    doc.tpls := [], doc.lists := [], doc.sections := []
    section := ""
    for i, raw in doc.lines {
        line := Trim(raw)
        if line = ""
            continue
        c := SubStr(line, 1, 1)
        if c = "#" {
            ; a heading like  # ----- FORMS -----
            if RegExMatch(line, "^#\s*-{3,}\s*(.+?)\s*-*\s*$", &m) {
                section := EdSectionName(m[1])
                doc.sections.Push({name: section, line: i})
            }
            continue
        }
        eq := InStr(line, "=")
        if !eq
            continue
        if c = "@" {
            doc.lists.Push({line: i, name: Trim(SubStr(line, 2, eq - 2)), items: EdItems(SubStr(line, eq + 1))})
            continue
        }
        left := Trim(SubStr(line, 1, eq - 1)), body := Trim(SubStr(line, eq + 1))
        trig := left, name := ""
        if RegExMatch(left, "^(\S+)\s*\((.*)\)$", &m)
            trig := m[1], name := Trim(m[2])
        rep := RegExMatch(body, "i)\{repeat\}") > 0
        body := RegExReplace(body, "i)\s*\{repeat\}")
        doc.tpls.Push({line: i, trig: trig, name: name, body: StrReplace(body, "\n", "`n"), repeat: rep, section: section})
    }
}

; "START / END OF SHIFT  (asks which bay)" -> "Start / end of shift"
EdSectionName(s) {
    s := Trim(RegExReplace(s, "\s*\(.*$"))
    return StrUpper(SubStr(s, 1, 1)) StrLower(SubStr(s, 2))
}

EdItems(s) {
    items := []
    for it in StrSplit(s, "|")
        if Trim(it) != ""
            items.Push(Trim(it))
    return items
}

; A template back into its line:  ;trig (Name) = wording {repeat}
EdLine(t) {
    body := Trim(StrReplace(StrReplace(t.body, "`r`n", "`n"), "`n", "\n"), " `t")
    return t.trig (t.name != "" ? " (" t.name ")" : "") " = " body (t.repeat ? " {repeat}" : "")
}

EdListLine(l) {
    s := ""
    for it in l.items
        s .= (s = "" ? "" : " | ") it
    return "@" l.name " = " s
}

; "# Wording version: Oct 25, 2026 (2)" -> today's date, (3) if it's
; still the same day, otherwise (1)
EdBumpVersion(doc) {
    today := FormatTime(, "MMM d, yyyy")
    for i, line in doc.lines {
        if !RegExMatch(line, "i)^(#\s*Wording version\s*:\s*)(.*?)\s*$", &m)
            continue
        n := RegExMatch(m[2], "^(.*?)\s*\((\d+)\)$", &v) && v[1] = today ? Integer(v[2]) + 1 : 1
        doc.lines[i] := m[1] today " (" n ")"
        return today " (" n ")"
    }
    return ""
}

; Writes the file, after keeping a copy of what was there
EdWrite(doc) {
    dir := DataDir "\template backups"
    try {
        DirCreate dir
        SplitPath doc.file, , , , &stem
        FileCopy doc.file, dir "\" stem " " FormatTime(, "yyyy-MM-dd HHmmss") ".txt", 1
        ; keep the last 20
        old := []
        Loop Files dir "\*.txt"
            old.Push(A_LoopFileTimeModified "|" A_LoopFileFullPath)
        if old.Length > 20 {
            sorted := ""
            for o in old
                sorted .= o "`n"
            sorted := Sort(RTrim(sorted, "`n"))
            for o in StrSplit(sorted, "`n")
                if A_Index <= old.Length - 20
                    try FileDelete SubStr(o, InStr(o, "|") + 1)
        }
    }
    text := ""
    for i, line in doc.lines
        text .= (i > 1 ? (doc.crlf ? "`r`n" : "`n") : "") line
    f := FileOpen(doc.file, "w", doc.bom ? "UTF-8" : "UTF-8-RAW")
    f.Write(text)
    f.Close()
    doc.time := FileTimeOf(doc.file)
}

; ---- Checking a template -----------------------------------------------
; What's wrong with a template ("" if nothing). others = the shortcuts of
; the other file (team templates when editing your own, and the other way)
EdProblems(doc, idx, others) {
    t := doc.tpls[idx], trig := t.trig, p := ""
    if trig = "" || trig = ";"
        p .= "Type a shortcut, like `;jack`n"
    else if RegExMatch(trig, "[\s=(){}|]")
        p .= "The shortcut can't have spaces or = ( ) { } | in it.`n"
    else {
        if SubStr(trig, 1, 1) != ";"
            p .= "Start the shortcut with `; so it never fires while you're typing normally.`n"
        if RegExMatch(trig, "i)^(;t|;dd|;dt)")
            p .= trig " starts like a time or date stamp (;t `;dd `;dt), so it would never fire.`n"
        for j, o in doc.tpls {
            if j = idx || o.trig = ""
                continue
            if o.trig == trig
                p .= trig " is used twice in this file.`n"
            else if InStr(o.trig, trig) = 1 || InStr(trig, o.trig) = 1
                p .= trig " and " o.trig " start the same way, so the shorter one fires before you finish typing the longer one.`n"
        }
        for o in others.trigs
            if InStr(o, trig) = 1 || InStr(trig, o) = 1
                p .= trig (o == trig ? " is" : " and " o " start the same way: " o " is") " already " others.what ".`n"
        for l in LoginList
            if InStr(l.trig, trig) = 1 || InStr(trig, l.trig) = 1
                p .= trig " clashes with the login shortcut " l.trig ".`n"
    }
    if RegExMatch(t.name, "[=()]")
        p .= "The name can't have = ( or ) in it.`n"
    body := t.body
    if Trim(body, " `t`r`n") = ""
        p .= "The wording is empty.`n"
    depth := 0, bad := false
    Loop Parse body {
        if A_LoopField = "{"
            depth += 1, bad := bad || depth > 1
        else if A_LoopField = "}"
            depth -= 1, bad := bad || depth < 0
    }
    if bad || depth != 0
        p .= "A { has no matching } (or the other way round).`n"
    have := Map()
    have.CaseSense := false
    for l in doc.lists
        have[l.name] := true
    for k in Lists
        have[k] := true
    for tok in EdTokens(body) {
        if tok.key = ""
            p .= "A box has no name: " tok.code "`n"
        for opt in StrSplit(tok.opts, "|")
            if SubStr(Trim(opt), 1, 1) = "@" && !have.Has(SubStr(Trim(opt), 2))
                p .= "There's no shared list called " Trim(opt) ".`n"
    }
    return RTrim(p, "`n")
}

; The boxes in some wording: [{pos, len, code, key, opts}] ({repeat} left out)
EdTokens(body) {
    toks := [], pos := 1
    while p := RegExMatch(body, "\{([^{}]*)\}", &m, pos) {
        spec := m[1], c := InStr(spec, ":")
        key := Trim(c ? SubStr(spec, 1, c - 1) : spec)
        if !(StrLower(key) = "repeat" && !c)
            toks.Push({pos: p, len: m.Len, code: m[0], key: key, opts: c ? SubStr(spec, c + 1) : ""})
        pos := p + m.Len
    }
    return toks
}

; ---- One box, as the box form shows it -------------------------------
BoxParse(spec) {
    c := InStr(spec, ":")
    b := {name: Trim(c ? SubStr(spec, 1, c - 1) : spec), kind: "plain", mins: 0, thousands: false, pick: false
        , fromcopy: false, list: "", items: [], caps: false, upper: false, blankMode: 1, blank: ""
        , prefix: "", suffix: "", numprefix: "", condWhen: "", condVal: "", keep: []}
    if !c
        return b
    kinds := []
    for opt in StrSplit(SubStr(spec, c + 1), "|") {
        opt := Trim(opt), low := StrLower(opt)
        if opt = ""
            continue
        if RegExMatch(low, "^(now|time|money|percent|clip|alertcopy|matchcopy|last|next)$")
            kinds.Push({k: low, opt: opt})
        else if RegExMatch(low, "^now\s*\+\s*(\d+)$", &n)
            kinds.Push({k: "now", opt: opt, mins: Integer(n[1])})
        else if low = "thousands"
            b.thousands := true
        else if low = "pick"
            b.pick := true
        else if low = "fromcopy"
            b.fromcopy := true
        else if low = "caps"
            b.caps := true
        else if low = "upper"
            b.upper := true
        else if low = "tidy" || low = "several" || low = "saved"
            b.keep.Push(opt)       ; bvs -> BVs, several (no tick box for them): kept as they are
        else if SubStr(opt, 1, 1) = "@" && b.list = ""
            b.list := SubStr(opt, 2)
        else if b.condWhen = "" && RegExMatch(opt, "i)^if\s+(.+?)\s*=\s*(.*)$", &cm)
            b.condWhen := cm[1], b.condVal := cm[2]
        else if SubStr(low, 1, 6) = "blank="
            b.blank := SubStr(opt, 7), b.blankMode := b.blank = "" ? 2 : 3
        else if SubStr(low, 1, 7) = "prefix="
            b.prefix := SubStr(opt, 8)
        else if SubStr(low, 1, 7) = "suffix="
            b.suffix := SubStr(opt, 8)
        else if SubStr(low, 1, 13) = "numberprefix="
            b.numprefix := SubStr(opt, 14)
        else if SubStr(opt, 1, 1) = "@" || RegExMatch(low, "^if\s")
            b.keep.Push(opt)       ; a second list or condition: kept as it is
        else
            b.items.Push(opt)
    }
    ; The kind is the first kind word; any other one is kept as it is
    for i, k in kinds {
        if i = 1 {
            b.kind := k.k
            if k.HasOwnProp("mins")
                b.mins := k.mins
        } else
            b.keep.Push(k.opt)
    }
    if b.kind = "plain"
        b.kind := b.list != "" ? "shared" : b.items.Length ? "list" : "plain"
    return b
}

BoxListy(kind) => kind = "list" || kind = "shared" || kind = "next"

BoxBuild(b) {
    o := []
    switch b.kind {
        case "now": o.Push(b.mins ? "now+" b.mins : "now")
        case "plain", "list", "shared":
        default: o.Push(b.kind)
    }
    if b.kind = "money" && b.thousands
        o.Push("thousands")
    if BoxListy(b.kind) {
        if b.pick
            o.Push("pick")
        if b.fromcopy
            o.Push("fromcopy")
        if b.kind = "shared" && b.list != ""
            o.Push("@" b.list)
        for it in b.items
            o.Push(it)
    }
    if b.caps
        o.Push("caps")
    if b.upper
        o.Push("upper")
    if b.numprefix != ""
        o.Push("numberprefix=" b.numprefix)
    if b.prefix != ""
        o.Push("prefix=" b.prefix)
    if b.suffix != ""
        o.Push("suffix=" b.suffix)
    if b.blankMode = 2
        o.Push("blank=")
    else if b.blankMode = 3 && b.blank != ""
        o.Push("blank=" b.blank)
    if b.condWhen != ""
        o.Push("if " b.condWhen "=" b.condVal)
    for k in b.keep
        o.Push(k)
    s := ""
    for x in o
        s .= (s = "" ? "" : " | ") x
    return "{" b.name (s != "" ? ": " s : "") "}"
}

; What a box is, in words, for the list of boxes
BoxKindName(b) {
    for k in BoxKinds()
        if k[1] = b.kind
            name := k[2]
    if b.kind = "now" && b.mins
        name := "The time now + " b.mins " minutes"
    if BoxListy(b.kind) && b.pick
        name .= " (must pick)"
    return name
}

BoxDetails(b) {
    d := []
    if b.kind = "shared"
        d.Push("@" b.list)
    if BoxListy(b.kind) && b.items.Length
        d.Push(b.items.Length = 1 ? b.items[1] : b.items.Length " choices")
    if b.thousands && b.kind = "money"
        d.Push("3.3 = 3,300")
    if b.caps
        d.Push("capitals in machine #s")
    if b.upper
        d.Push("ALL CAPITALS")
    if b.prefix != "" || b.suffix != ""
        d.Push("adds " b.prefix "..." b.suffix)
    if b.numprefix != ""
        d.Push(b.numprefix " before a number")
    if b.blankMode = 2
        d.Push("empty = nothing")
    else if b.blankMode = 3
        d.Push("empty = " b.blank)
    if b.condWhen != ""
        d.Push(b.condVal " when a box starts with " b.condWhen)
    if b.fromcopy && BoxListy(b.kind)
        d.Push("job title from the copy")
    s := ""
    for x in d
        s .= (s = "" ? "" : ",  ") x
    return s
}

; The log as it comes out with the boxes as they open (a list on its first
; choice, the time now, the rest left as XX). Never reads the clipboard.
EdPreview(body, doc) {
    known := Map()
    known.CaseSense := false
    for k, v in Lists
        known[k] := v
    for l in doc.lists
        known[l.name] := l.items
    fields := [], vals := [], seen := Map()
    for tok in EdTokens(body) {
        if seen.Has(tok.key)
            continue
        seen[tok.key] := true
        b := BoxParse(SubStr(tok.code, 2, -1))
        ph := b.blankMode = 2 ? "" : b.blankMode = 3 ? b.blank
            : b.kind = "now" || b.kind = "time" ? "XX:XX" : b.kind = "money" ? "XX,XXX" : b.kind = "percent" || b.kind = "matchcopy" ? "XX%" : "XX"
        v := ""
        if b.kind = "now"
            v := FormatTime(DateAdd(A_Now, b.mins, "Minutes"), "HH:mm")
        else if BoxListy(b.kind) {
            items := b.items
            if b.kind = "shared" && known.Has(b.list) && known[b.list].Length
                items := known[b.list]
            v := items.Length ? items[1] : ""
        }
        if v = ""
            v := ph
        else {
            if b.caps
                v := RegExReplace(v, "(\w*\d\w*)", "$U1")
            v := b.prefix v b.suffix
            if b.upper
                v := StrUpper(v)
            if b.numprefix != "" && RegExMatch(v, "^\d")
                v := b.numprefix v
        }
        fields.Push({key: tok.key})
        vals.Push(v)
    }
    return FillTemplate(body, fields, vals)
}

; ---- The editor window ------------------------------------------------
ShowEditor(startTab := 1) {
    global EditorWin
    if IsObject(EditorWin) {
        try WinActivate "ahk_id " EditorWin.Hwnd
        return
    }
    if IsObject(CurForm) {
        MsgBox "Finish or close the form that's open first.", "Template editor"
        return
    }
    ClosePicker()
    ; The two files: the team's (or templates.txt) and your own
    teamFile := Cfg["SharedTemplates"] != "" ? Cfg["SharedTemplates"] : TemplatesFile
    teamName := Cfg["SharedTemplates"] != "" ? "Team templates" : "templates.txt"
    canTeam := Tpl.src != "team-copy" && FileExist(teamFile)
    ed := {doc: "", which: canTeam ? 1 : 2, cur: 0, rows: [], dirty: false, saved: false, teamOk: false, curList: 0
        , loading: false, boxes: [], others: {trigs: [], what: ""}}

    g := WGui("+AlwaysOnTop", "Template editor  -  v" VERSION)
    EditorWin := g
    g.BackColor := "FFFFFF"     ; the same white as the tab pages
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 14, g.MarginY := 12
    g.AddText("xm y+2", "Editing:")
    fileDD := g.AddDropDownList("x+8 yp-3 w380", [teamName (Cfg["SharedTemplates"] != "" ? " (everyone's)" : ""), "My own templates (my-templates.txt, just me)"])
    fileT := g.AddText("x+12 yp+3 w440 c707070", "")
    tabs := g.AddTab2("xm y+12 w960 h650 Choose" startTab, ["Templates", "Shared lists"])

    ; ---- Templates tab
    tabs.UseTab(1)
    search := g.AddEdit("Section w300")
    SendMessage 0x1501, 1, StrPtr("Search: a shortcut, name or any word"), search    ; grey hint
    lv := g.AddListView("xs y+6 w300 h470 -Multi NoSortHdr", ["Shortcut", "Name", "Section"])
    lv.ModifyCol(1, 90), lv.ModifyCol(2, 120), lv.ModifyCol(3, 70)
    bNew := g.AddButton("xs y+8 w96", "New")
    bCopy := g.AddButton("x+6 w96", "Copy")
    bDel := g.AddButton("x+6 w96", "Delete")

    rx := "xs+320"
    g.AddText(rx " ys+3", "Shortcut:")
    trigE := g.AddEdit("x+6 yp-3 w130")
    g.AddText("x+16 yp+3", "Name:")
    nameE := g.AddEdit("x+6 yp-3 w318")
    g.AddText(rx " y+12", "Section:")
    secDD := g.AddDropDownList("x+6 yp-3 w210")
    repCB := g.AddCheckbox("x+16 yp+4", "Several in one log (an Add another button)")
    g.AddText(rx " y+14 w600", "Wording. Type the log as it should read; the boxes are the parts in { }.")
    bodyE := g.AddEdit(rx " y+4 w610 r5 Multi WantReturn")
    g.AddText(rx " y+10", "Boxes in this log (double-click one to change it):")
    boxLV := g.AddListView(rx " y+4 w610 r5 -Multi NoSortHdr", ["Box", "What goes in it", "Details"])
    boxLV.ModifyCol(1, 130), boxLV.ModifyCol(2, 230), boxLV.ModifyCol(3, 230)
    bAddBox := g.AddButton(rx " y+6 w150", "Add a box...")
    bEditBox := g.AddButton("x+6 w150", "Change box...")
    bDelBox := g.AddButton("x+6 w150", "Remove box")
    g.SetFont("s9 c707070")
    g.AddText(rx " y+10", "How it will look (lists on their first choice, empty boxes as XX):")
    g.SetFont("s10 c000000")
    prevE := g.AddEdit(rx " y+4 w610 r4 ReadOnly -TabStop BackgroundF1F5F5")
    probT := g.AddText(rx " y+6 w610 r3 cC62828", "")

    ; ---- Shared lists tab
    tabs.UseTab(2)
    llv := g.AddListView("Section w300 h470 -Multi NoSortHdr", ["List", "Choices"])
    llv.ModifyCol(1, 150), llv.ModifyCol(2, 120)
    bNewList := g.AddButton("xs y+8 w96", "New list")
    bRenList := g.AddButton("x+6 w96", "Rename")
    bDelList := g.AddButton("x+6 w96", "Delete")
    g.AddText("xs+320 ys", "A shared list is used by every box that names it, so changing it here")
    g.AddText("xs+320 y+0", "changes all of them (like @tables for every table template).")
    lnameT := g.AddText("xs+320 y+14 w600", "")
    g.AddText("xs+320 y+8", "Choices, one per line:")
    litemsE := g.AddEdit("xs+320 y+4 w400 r16 Multi WantReturn")
    lusedT := g.AddText("xs+320 y+8 w600 r3 c505050", "")
    tabs.UseTab()

    tabs.GetPos(&tx, &ty, &tw, &th)
    bSave := g.AddButton("x" tx " y" (ty + th + 10) " w120", "Save")
    bClose := g.AddButton("x+6 w120", "Close")
    statT := g.AddText("x+14 yp+5 w680", "")

    fileDD.OnEvent("Change", SwitchFile)
    search.OnEvent("Change", (*) => Filter())
    lv.OnEvent("ItemSelect", (ctl, row, sel) => sel ? Load(row) : 0)
    for c in [trigE, nameE, bodyE]
        c.OnEvent("Change", Changed)
    repCB.OnEvent("Click", Changed)
    secDD.OnEvent("Change", MoveSection)
    bNew.OnEvent("Click", NewTpl)
    bCopy.OnEvent("Click", CopyTpl)
    bDel.OnEvent("Click", DeleteTpl)
    bAddBox.OnEvent("Click", (*) => BoxDlg(0))
    bEditBox.OnEvent("Click", (*) => BoxDlg(boxLV.GetNext() ? boxLV.GetNext() : -1))
    boxLV.OnEvent("DoubleClick", (ctl, row) => row ? BoxDlg(row) : 0)
    bDelBox.OnEvent("Click", RemoveBox)
    llv.OnEvent("ItemSelect", (ctl, row, sel) => sel ? LoadList(row) : 0)
    litemsE.OnEvent("Change", ListChanged)
    bNewList.OnEvent("Click", NewList)
    bRenList.OnEvent("Click", RenameList)
    bDelList.OnEvent("Click", DeleteList)
    bSave.OnEvent("Click", (*) => Save())
    bClose.OnEvent("Click", CloseEd)
    g.OnEvent("Close", CloseEd)
    g.OnEvent("Escape", CloseEd)

    if !Open(ed.which) {
        EditorWin := ""
        g.Destroy()
        return
    }
    fileDD.Value := ed.which
    if !canTeam
        fileT.Text := "The team file can't be reached right now, so only your own templates can be changed."
    g.Show()
    search.Focus()

    ; -- loading a file
    Open(which) {
        file := which = 1 ? teamFile : MyTemplatesFile
        if which = 1 && !canTeam {
            g.Opt("+OwnDialogs")
            MsgBox "The team templates file can't be reached right now (is OneDrive running?), so it can't be changed.", "Template editor", "Icon!"
            return false
        }
        if which = 2 && !FileExist(MyTemplatesFile) && !MakeMineFile()
            return false
        try doc := EdRead(file)
        catch as e {
            g.Opt("+OwnDialogs")
            MsgBox "Couldn't open " file ":`n" e.Message, "Template editor", "Icon!"
            return false
        }
        ed.doc := doc, ed.which := which, ed.dirty := false, ed.cur := 0, ed.curList := 0
        ; the other file's shortcuts, to warn about clashes
        ed.others := {trigs: [], what: which = 1 ? "one of your own templates (my-templates.txt)" : "a team template"}
        for t in TemplateList
            if (which = 1) = (t.src = "mine")
                ed.others.trigs.Push(t.trig)
        fileT.Text := file
        secs := []
        for s in doc.sections
            secs.Push(s.name)
        secDD.Delete()
        if secs.Length
            secDD.Add(secs)
        secDD.Enabled := secs.Length > 0
        search.Value := ""
        Filter()
        FillLists()
        Status()
        return true
    }

    SwitchFile(*) {
        want := fileDD.Value
        if want = ed.which
            return
        if !AskSave() || !Open(want)
            fileDD.Value := ed.which
    }

    ; Unsaved changes: Yes saves, No drops them, Cancel stays. True = go on.
    AskSave() {
        if !ed.dirty
            return true
        g.Opt("+OwnDialogs")
        r := MsgBox("Save your changes first?", "Template editor", "YesNoCancel Icon? Default1")
        if r = "Cancel"
            return false
        return r = "No" || Save()
    }

    ; -- the list on the left
    Filter(keep := 0) {
        q := StrLower(Trim(search.Value))
        ed.rows := []
        lv.Opt("-Redraw")
        lv.Delete()
        for i, t in ed.doc.tpls {
            if q != "" && !InStr(StrLower(t.trig " " t.name " " t.body " " t.section), q)
                continue
            ed.rows.Push(i)
            lv.Add(, t.trig, t.name, t.section)
        }
        lv.Opt("+Redraw")
        row := 0
        for r, i in ed.rows
            if i = keep
                row := r
        if !row && ed.rows.Length
            row := 1
        if row {
            lv.Modify(row, "Select Focus Vis")
            Load(row)
        } else
            Load(0)
    }

    Load(row) {
        ed.cur := row ? ed.rows[row] : 0
        on := ed.cur > 0
        for c in [trigE, nameE, bodyE, repCB, boxLV, bAddBox, bEditBox, bDelBox, bCopy, bDel]
            c.Enabled := on
        secDD.Enabled := on && ed.doc.sections.Length
        if !on {
            ed.loading := true
            trigE.Value := "", nameE.Value := "", bodyE.Value := "", repCB.Value := 0
            ed.loading := false
            boxLV.Delete(), prevE.Value := "", probT.Text := ""
            return
        }
        t := ed.doc.tpls[ed.cur]
        ed.loading := true
        trigE.Value := t.trig
        nameE.Value := t.name
        bodyE.Value := StrReplace(t.body, "`n", "`r`n")
        repCB.Value := t.repeat
        if ed.doc.sections.Length {
            for i, s in ed.doc.sections
                if s.name = t.section
                    secDD.Choose(i)
        }
        ed.loading := false
        Refresh()
    }

    ; What's in the boxes now, into the template and its line
    Changed(*) {
        if ed.loading || !ed.cur
            return
        t := ed.doc.tpls[ed.cur]
        nt := Trim(trigE.Value), nn := Trim(nameE.Value), nb := StrReplace(bodyE.Value, "`r`n", "`n"), nr := repCB.Value
        if nt == t.trig && nn == t.name && nb == t.body && nr = t.repeat
            return
        t.trig := nt, t.name := nn, t.body := nb, t.repeat := nr
        ed.doc.lines[t.line] := EdLine(t)
        for r, i in ed.rows
            if i = ed.cur
                lv.Modify(r, , t.trig, t.name)
        Dirty()
        Refresh()
    }

    Refresh() {
        t := ed.doc.tpls[ed.cur]
        boxLV.Opt("-Redraw")
        boxLV.Delete()
        ed.boxes := []
        seen := Map()
        for tok in EdTokens(t.body) {
            if seen.Has(tok.key)
                continue
            seen[tok.key] := true
            b := BoxParse(SubStr(tok.code, 2, -1))
            ed.boxes.Push(tok)
            boxLV.Add(, b.name, BoxKindName(b), BoxDetails(b))
        }
        boxLV.Opt("+Redraw")
        try prevE.Value := StrReplace(EdPreview(t.body, ed.doc), "`n", "`r`n")
            . (t.repeat ? "`r`n(Add another puts more lines like this one in the same log)" : "")
        catch
            prevE.Value := "(can't show this yet: check the { } boxes)"
        probT.Text := EdProblems(ed.doc, ed.cur, ed.others)
    }

    Dirty() {
        ed.dirty := true
        Status()
    }

    Status(msg := "") {
        statT.Text := msg != "" ? msg : ed.dirty ? "Changes not saved yet." : ed.doc.tpls.Length " templates, " ed.doc.lists.Length " shared lists. Nothing changed yet."
        bSave.Enabled := ed.dirty
    }

    ; -- new, copy, delete, move to another section
    ; The line number a new template goes in at: the end of its section
    InsertAt(section) {
        last := 0, head := 0
        for t in ed.doc.tpls
            if t.section = section
                last := t.line
        for s in ed.doc.sections
            if s.name = section
                head := s.line
        if last
            return last + 1
        if head
            return head + 1
        return ed.doc.lines.Length + 1
    }

    AddLine(at, line) {
        ed.doc.lines.InsertAt(Min(at, ed.doc.lines.Length + 1), line)
        EdScan(ed.doc)
        Dirty()
        search.Value := ""
        for i, t in ed.doc.tpls
            if t.line = at {
                Filter(i)
                return
            }
        Filter()
    }

    NewTpl(*) {
        section := ed.cur ? ed.doc.tpls[ed.cur].section : ed.doc.sections.Length ? ed.doc.sections[ed.doc.sections.Length].name : ""
        trig := ";new", n := 1
        while UsedTrig(trig)
            trig := ";new" (++n)
        AddLine(InsertAt(section), trig " (New template) = Type the log here.")
        trigE.Focus()
        SendMessage 0xB1, 0, -1, trigE
    }

    CopyTpl(*) {
        if !ed.cur
            return
        t := ed.doc.tpls[ed.cur]
        trig := t.trig "2", n := 2
        while UsedTrig(trig)
            trig := t.trig (++n)
        c := {trig: trig, name: t.name != "" ? t.name " (copy)" : "", body: t.body, repeat: t.repeat}
        AddLine(t.line + 1, EdLine(c))
        trigE.Focus()
        SendMessage 0xB1, 0, -1, trigE
    }

    UsedTrig(trig) {
        for t in ed.doc.tpls
            if t.trig = trig
                return true
        return false
    }

    DeleteTpl(*) {
        if !ed.cur
            return
        t := ed.doc.tpls[ed.cur]
        g.Opt("+OwnDialogs")
        if MsgBox("Delete " t.trig (t.name != "" ? " (" t.name ")" : "") "?`n`nIt's gone once you Save (a copy of the old file is kept in the backups).", "Template editor", "YesNo Icon? Default2") != "Yes"
            return
        ed.doc.lines.RemoveAt(t.line)
        next := ed.cur
        EdScan(ed.doc)
        Dirty()
        Filter(Min(next, ed.doc.tpls.Length))
    }

    MoveSection(*) {
        if ed.loading || !ed.cur || !secDD.Value
            return
        t := ed.doc.tpls[ed.cur]
        want := ed.doc.sections[secDD.Value].name
        if want = t.section
            return
        line := ed.doc.lines[t.line]
        ed.doc.lines.RemoveAt(t.line)
        EdScan(ed.doc)
        at := InsertAt(want)
        ed.doc.lines.InsertAt(Min(at, ed.doc.lines.Length + 1), line)
        EdScan(ed.doc)
        Dirty()
        for i, x in ed.doc.tpls
            if x.line = at
                Filter(i)
    }

    ; -- boxes
    ; row 0 = add a new box at the cursor; -1 = the box the cursor is in
    BoxDlg(row) {
        if !ed.cur
            return
        t := ed.doc.tpls[ed.cur]
        raw := StrReplace(StrReplace(bodyE.Value, "`r`n", "`n"), "`n", "`r`n")
        selA := 0, selB := 0
        DllCall("SendMessage", "Ptr", bodyE.Hwnd, "UInt", 0xB0, "UInt*", &selA, "UInt*", &selB)   ; EM_GETSEL
        tok := ""
        if row = -1 {
            ; the box the cursor is in, if any
            ; the cursor's place counted without the line breaks' extra character
            StrReplace(SubStr(raw, 1, selA), "`r`n", , , &breaks)
            at := selA - breaks
            for x in EdTokens(StrReplace(raw, "`r`n", "`n"))
                if at >= x.pos - 1 && at <= x.pos - 1 + x.len
                    tok := x
            if !tok {
                g.Opt("+OwnDialogs")
                MsgBox "Pick a box in the list first (or click inside one in the wording).", "Template editor"
                return
            }
        } else if row > 0
            tok := ed.boxes[row]
        b := tok ? BoxParse(SubStr(tok.code, 2, -1)) : BoxParse("")
        names := []
        for l in ed.doc.lists
            names.Push(l.name)
        for k in Lists
            if !HasVal(names, k)
                names.Push(k)
        BoxForm(g, b, names, tok ? "" : NamesInUse(t.body), Done)

        Done(code) {
            body := StrReplace(bodyE.Value, "`r`n", "`n")
            if tok {
                nb := BoxParse(SubStr(code, 2, -1))
                ; the first one is replaced; any other spot with the same box gets the new name
                body := SubStr(body, 1, tok.pos - 1) code SubStr(body, tok.pos + tok.len)
                if nb.name !== tok.key {
                    for x in EdTokens(body)
                        if x.key == tok.key
                            body := StrReplace(body, x.code, "{" nb.name SubStr(x.code, 2 + StrLen(x.key)), , , 1)
                }
                bodyE.Value := StrReplace(body, "`n", "`r`n")
                Changed()
                return
            }
            ; a new box goes where the cursor was
            raw := StrReplace(body, "`n", "`r`n")
            bodyE.Value := SubStr(raw, 1, selA) code SubStr(raw, selB + 1)
            Changed()
            bodyE.Focus()
            SendMessage 0xB1, selA + StrLen(code), selA + StrLen(code), bodyE
        }
    }

    NamesInUse(body) {
        names := Map()
        names.CaseSense := false
        for x in EdTokens(body)
            names[x.key] := true
        return names
    }

    RemoveBox(*) {
        row := boxLV.GetNext()
        if !ed.cur || !row
            return
        key := ed.boxes[row].key
        body := StrReplace(bodyE.Value, "`r`n", "`n")
        for x in EdTokens(body)
            if x.key == key
                body := StrReplace(body, x.code, "", , , 1)
        body := RegExReplace(body, " {2,}", " ")
        bodyE.Value := StrReplace(body, "`n", "`r`n")
        Changed()
    }

    ; -- shared lists
    FillLists(keep := 0) {
        llv.Opt("-Redraw")
        llv.Delete()
        for l in ed.doc.lists
            llv.Add(, "@" l.name, l.items.Length)
        llv.Opt("+Redraw")
        if ed.doc.lists.Length {
            row := keep && keep <= ed.doc.lists.Length ? keep : 1
            llv.Modify(row, "Select Focus Vis")
            LoadList(row)
        } else
            LoadList(0)
    }

    LoadList(row) {
        ed.curList := row
        litemsE.Enabled := row > 0, bRenList.Enabled := row > 0, bDelList.Enabled := row > 0
        ed.loading := true
        if !row {
            lnameT.Text := "No shared lists in this file yet. New list makes one.", litemsE.Value := "", lusedT.Text := ""
            ed.loading := false
            return
        }
        l := ed.doc.lists[row]
        s := ""
        for it in l.items
            s .= it "`r`n"
        litemsE.Value := s
        ed.loading := false
        lnameT.Text := "@" l.name "   (in a box it's written  {Table: @" l.name "})"
        used := UsedBy(l.name)
        lusedT.Text := used != "" ? "Used by: " used : "Not used by any template in this file yet."
    }

    UsedBy(name) {
        used := ""
        for t in ed.doc.tpls
            if RegExMatch(t.body, "i)[:|]\s*@\Q" name "\E\s*[|}]")
                used .= (used = "" ? "" : ", ") t.trig
        return used
    }

    ListChanged(*) {
        if ed.loading || !ed.curList
            return
        l := ed.doc.lists[ed.curList]
        items := []
        for it in StrSplit(StrReplace(litemsE.Value, "`r`n", "`n"), "`n")
            if Trim(it) != ""
                items.Push(Trim(StrReplace(StrReplace(StrReplace(it, "|"), "{"), "}")))
        l.items := items
        ed.doc.lines[l.line] := EdListLine(l)
        llv.Modify(ed.curList, , "@" l.name, items.Length)
        Dirty()
        if ed.cur
            Refresh()
    }

    NewList(*) {
        g.Opt("+OwnDialogs")
        ib := InputBox("Name of the new list (one word, like tables or pits):", "New shared list", "w360 h140")
        if ib.Result != "OK"
            return
        name := Trim(ib.Value, " @`t")
        if !RegExMatch(name, "^[\w-]+$") {
            MsgBox "A list name is one word: letters, numbers, - or _.", "Template editor", "Icon!"
            return
        }
        for l in ed.doc.lists
            if l.name = name {
                MsgBox "There's already a list called @" name ".", "Template editor", "Icon!"
                return
            }
        ; after the last list, or before the first template
        at := ed.doc.lists.Length ? ed.doc.lists[ed.doc.lists.Length].line + 1
            : ed.doc.tpls.Length ? ed.doc.tpls[1].line : ed.doc.lines.Length + 1
        ed.doc.lines.InsertAt(Min(at, ed.doc.lines.Length + 1), "@" name " = ")
        EdScan(ed.doc)
        Dirty()
        for i, l in ed.doc.lists
            if l.name = name
                FillLists(i)
        litemsE.Focus()
    }

    RenameList(*) {
        if !ed.curList
            return
        l := ed.doc.lists[ed.curList]
        g.Opt("+OwnDialogs")
        ib := InputBox("New name for @" l.name " (every template that uses it is changed too):", "Rename list", "w380 h150", l.name)
        if ib.Result != "OK"
            return
        name := Trim(ib.Value, " @`t")
        if name == l.name
            return
        if !RegExMatch(name, "^[\w-]+$") {
            MsgBox "A list name is one word: letters, numbers, - or _.", "Template editor", "Icon!"
            return
        }
        old := l.name
        l.name := name
        ed.doc.lines[l.line] := EdListLine(l)
        for t in ed.doc.tpls {
            nb := RegExReplace(t.body, "i)([:|]\s*)@\Q" old "\E(?=\s*[|}])", "$1@" name)
            if nb != t.body {
                t.body := nb
                ed.doc.lines[t.line] := EdLine(t)
            }
        }
        EdScan(ed.doc)
        Dirty()
        FillLists(ed.curList)
        Filter(ed.cur)
    }

    DeleteList(*) {
        if !ed.curList
            return
        l := ed.doc.lists[ed.curList]
        g.Opt("+OwnDialogs")
        if (used := UsedBy(l.name)) != "" {
            MsgBox "@" l.name " is used by " used ". Change those boxes first, then delete the list.", "Template editor", "Icon!"
            return
        }
        if MsgBox("Delete the list @" l.name "?", "Template editor", "YesNo Icon? Default2") != "Yes"
            return
        ed.doc.lines.RemoveAt(l.line)
        EdScan(ed.doc)
        Dirty()
        FillLists(ed.curList)
        Filter(ed.cur)
    }

    ; -- saving and closing
    Save() {
        g.Opt("+OwnDialogs")
        probs := ""
        for i, t in ed.doc.tpls
            if (p := EdProblems(ed.doc, i, ed.others)) != ""
                probs .= t.trig ":  " StrReplace(p, "`n", "`n      ") "`n"
        if probs != "" && MsgBox("These need fixing:`n`n" probs "`nWatchlog skips a template with a problem (and says why) until it's fixed. Save anyway?", "Template editor", "YesNo Icon! Default2") != "Yes"
            return false
        if ed.which = 1 && Cfg["SharedTemplates"] != "" && !ed.teamOk {
            if MsgBox("This is the team's templates file. Saving changes the wording on every bay once OneDrive syncs it.`n`nSave it?", "Template editor", "YesNo Icon? Default1") != "Yes"
                return false
            ed.teamOk := true
        }
        if FileTimeOf(ed.doc.file) != ed.doc.time
            && MsgBox("Someone (or OneDrive) changed this file since the editor opened it.`n`nSave over it anyway? (No = keep theirs: close the editor and open it again.)", "Template editor", "YesNo Icon! Default2") != "Yes"
            return false
        ver := ed.which = 1 ? EdBumpVersion(ed.doc) : ""
        try EdWrite(ed.doc)
        catch as e {
            MsgBox "Couldn't save " ed.doc.file ":`n" e.Message "`n`nIf OneDrive is syncing, press Save again in a moment.", "Template editor", "Icon!"
            return false
        }
        ed.dirty := false, ed.saved := true
        Activity("Template editor: saved " ed.doc.file " (" ed.doc.tpls.Length " templates" (ver != "" ? ", wording version " ver : "") ")")
        Status("Saved" (ver != "" ? " (wording version " ver ")" : "") ". The new wording works as soon as you close the editor.")
        return true
    }

    CloseEd(*) {
        global EditorWin
        if !AskSave()
            return true
        EditorWin := ""
        g.Destroy()
        if ed.saved {
            Tip("Loading the new templates...", 1500, true)
            Sleep 300
            ReloadOnce()
        }
    }
}

; The box form: what a box is called, what goes in it, and the extras.
; done(code) gets the finished box, like {Amount: money | thousands}.
BoxForm(owner, b, listNames, inUse, done) {
    d := WGui("+AlwaysOnTop +Owner" owner.Hwnd, b.name = "" ? "Add a box" : "Box: " b.name)
    d.SetFont("s10", "Segoe UI")
    d.MarginX := 16, d.MarginY := 12
    d.AddText("w520", "Name (shown above the box on the form):")
    nameE := d.AddEdit("w300", b.name)
    d.AddText("w520 y+12", "What goes in it:")
    names := [], idx := 1
    for i, k in BoxKinds() {
        names.Push(k[2])
        if k[1] = b.kind
            idx := i
    }
    kindDD := d.AddDropDownList("w360 r12 Choose" idx, names)

    d.SetFont("s10 bold")
    d.AddText("xm y+14", "Choices")
    d.SetFont("s10 norm")
    listT := d.AddText("xm y+6", "Shared list:")
    choices := listNames.Clone()
    lidx := 0
    for i, n in choices
        if n = b.list
            lidx := i
    if !lidx && b.list != ""
        choices.Push(b.list), lidx := choices.Length
    listDD := d.AddDropDownList("x+8 yp-3 w200" (lidx ? " Choose" lidx : ""), choices)
    itemsT := d.AddText("xm y+10 w520", "Choices, one per line:")
    s := ""
    for it in b.items
        s .= it "`r`n"
    itemsE := d.AddEdit("xm w520 r6 Multi WantReturn", s)
    pickCB := d.AddCheckbox("xm" (b.pick ? " Checked" : ""), "Must pick one of the choices (no typing your own)")
    fromCB := d.AddCheckbox("xm" (b.fromcopy ? " Checked" : ""), "Open on the job title found in the copied text")
    minsT := d.AddText("xm y+8", "Plus this many minutes:")
    minsE := d.AddEdit("x+8 yp-3 w60 Number", b.mins ? b.mins : "")
    thouCB := d.AddCheckbox("xm y+8" (b.thousands ? " Checked" : ""), "A decimal point means thousands (3.3 becomes 3,300)")

    d.SetFont("s10 bold")
    d.AddText("xm y+14", "Extras (optional)")
    d.SetFont("s10 norm")
    capsCB := d.AddCheckbox("xm y+6" (b.caps ? " Checked" : ""), "Capitals in machine numbers (b1410 becomes B1410)")
    upperCB := d.AddCheckbox("xm" (b.upper ? " Checked" : ""), "ALL CAPITALS (rn becomes RN)")
    d.AddText("xm y+10", "If it's left empty, leave:")
    blankDD := d.AddDropDownList("x+8 yp-3 w150 Choose" b.blankMode, ["XX", "nothing", "this text:"])
    blankE := d.AddEdit("x+8 yp w140", b.blank)
    d.AddText("xm y+10", "When filled in, put in front:")
    prefixE := d.AddEdit("x+8 yp-3 w70", b.prefix)
    d.AddText("x+12 yp+3", "and after:")
    suffixE := d.AddEdit("x+8 yp-3 w70", b.suffix)
    d.AddText("xm y+10", "Put in front of a number only:")
    numE := d.AddEdit("x+8 yp-3 w120", b.numprefix)
    d.AddText("xm y+10", "Fill in")
    condValE := d.AddEdit("x+8 yp-3 w100", b.condVal)
    d.AddText("x+8 yp+3", "when another box starts with")
    condWhenE := d.AddEdit("x+8 yp-3 w80", b.condWhen)

    d.SetFont("s9 c707070")
    d.AddText("xm y+14", "In the wording it's written:")
    d.SetFont("s10 c000000", "Consolas")
    codeE := d.AddEdit("xm w520 r2 ReadOnly -TabStop BackgroundF1F5F5")
    d.SetFont("s10", "Segoe UI")
    okB := d.AddButton("xm y+12 w120 Default", "OK")
    d.AddButton("x+6 w120", "Cancel").OnEvent("Click", Cancel)
    okB.OnEvent("Click", OK)
    d.OnEvent("Escape", Cancel)
    d.OnEvent("Close", Cancel)
    for c in [nameE, itemsE, minsE, blankE, prefixE, suffixE, numE, condValE, condWhenE]
        c.OnEvent("Change", Update)
    for c in [kindDD, listDD, blankDD]
        c.OnEvent("Change", Update)
    for c in [pickCB, fromCB, thouCB, capsCB, upperCB]
        c.OnEvent("Click", Update)
    owner.Opt("+Disabled")
    Update()
    d.Show()
    nameE.Focus()

    ; Reads the form into the box, greys out what doesn't apply
    Read() {
        b.name := Trim(StrReplace(StrReplace(StrReplace(StrReplace(nameE.Value, ":"), "{"), "}"), "|"))
        b.kind := BoxKinds()[kindDD.Value][1]
        b.list := listDD.Text
        b.items := []
        for it in StrSplit(StrReplace(itemsE.Value, "`r`n", "`n"), "`n")
            if (it := Trim(Clean(it))) != ""
                b.items.Push(it)
        b.pick := pickCB.Value, b.fromcopy := fromCB.Value
        b.mins := IsInteger(minsE.Value) ? Integer(minsE.Value) : 0
        b.thousands := thouCB.Value, b.caps := capsCB.Value, b.upper := upperCB.Value
        b.blankMode := blankDD.Value, b.blank := Clean(blankE.Value)
        b.prefix := Clean(prefixE.Value), b.suffix := Clean(suffixE.Value), b.numprefix := Clean(numE.Value)
        b.condVal := Clean(condValE.Value), b.condWhen := Trim(StrReplace(Clean(condWhenE.Value), "="))
        return b
    }

    Clean(s) => StrReplace(StrReplace(StrReplace(s, "|"), "{"), "}")

    Update(*) {
        Read()
        listy := BoxListy(b.kind)
        listT.Enabled := listDD.Enabled := b.kind = "shared"
        itemsT.Enabled := itemsE.Enabled := listy
        itemsT.Text := b.kind = "shared" ? "Extra choices besides the list (optional), one per line:" : b.kind = "next" ? "Steps, in order, one per line:" : "Choices, one per line:"
        pickCB.Enabled := fromCB.Enabled := listy
        minsT.Enabled := minsE.Enabled := b.kind = "now"
        thouCB.Enabled := b.kind = "money"
        blankE.Enabled := blankDD.Value = 3
        codeE.Value := BoxBuild(b)
    }

    OK(*) {
        Read()
        d.Opt("+OwnDialogs")
        err := ""
        if b.name = ""
            err := "Give the box a name, like Machine or Amount."
        else if StrLower(b.name) = "repeat"
            err := "repeat is a special word. Pick another name."
        else if (b.kind = "list" || b.kind = "next") && !b.items.Length
            err := "Type at least one choice."
        else if b.kind = "shared" && b.list = ""
            err := "Pick a shared list (make one on the Shared lists tab first)."
        if err != "" {
            MsgBox err, "Box", "Icon!"
            return
        }
        if IsObject(inUse) && inUse.Has(b.name)
            && MsgBox("This log already has a box called " b.name ". Both spots get the same answer.`n`nUse the same name anyway?", "Box", "YesNo Icon? Default2") != "Yes"
            return
        code := BoxBuild(b)
        Cancel()
        done(code)
    }

    Cancel(*) {
        owner.Opt("-Disabled")
        d.Destroy()
        try WinActivate "ahk_id " owner.Hwnd
    }
}

; Makes my-templates.txt with its notes at the top (the first time)
MakeMineFile() {
    if FileExist(MyTemplatesFile)
        return true
    text := "
    (
# =====================================================================
#  MY TEMPLATES - your own extra templates
#  These go on top of the team's templates, for you only. Same format
#  as templates.txt (the notes at the top of it explain it all).
#  If the team file already uses a trigger, yours is skipped, so the
#  team wording always wins. Save this file and the script reloads.
#  The template editor (Ctrl+Alt+E) changes this file for you too.
#
#  Example (take the # off the start of the line to use it):
#  ;mynote (My note) = Operator note at {Time: now}: {Note}
# =====================================================================

    )"
    try FileAppend text, MyTemplatesFile, "UTF-8"
    catch as e {
        MsgBox "Couldn't make my-templates.txt:`n" e.Message, "Watchlog", "Icon!"
        return false
    }
    WatchTimes[MyTemplatesFile] := FileTimeOf(MyTemplatesFile)
    return true
}


; =====================================================================
;  LOOK  (v3.22.0)  -  the dark theme with a blue accent
;  Every window is made with WGui instead of Gui. It works out the colours
;  from the ones the window asks for (dark text becomes light, white
;  panels become dark, the old teal becomes the blue accent), so the
;  windows stay readable either way. Customize > "Dark look" turns it off
;  ([Look] Dark=no in settings.ini).
; =====================================================================

LookOn() => Cfg.Has("Dark") && Cfg["Dark"]

; Dark or light for the windows opened from now on
SetDarkLook(on) {
    Cfg["Dark"] := on
    try IniWrite(on ? "yes" : "no", SettingsFile, "Look", "Dark")
    NoteOwnWrites()
    Tip("Saved. Windows you open from now on use the " (on ? "dark" : "light") " look.", 2500, true)
    BuildTrayMenu()
}

; The panel colour behind the numbers on the home window
LookCard() => LookOn() ? "262C34" : "E3EEEE"

LookRGB(c) {
    if !RegExMatch(c, "i)^[0-9A-F]{6}$")
        return ""
    v := Integer("0x" c)
    return [v >> 16, (v >> 8) & 255, v & 255]
}

LookLum(rgb) => (0.299 * rgb[1] + 0.587 * rgb[2] + 0.114 * rgb[3]) / 255

; A text colour for the dark look
LookText(c) {
    if (rgb := LookRGB(c)) = ""
        return c
    if !LookOn()                                                                       ; light look: only the old teal changes
        return rgb[1] + 40 < rgb[2] && rgb[1] + 40 < rgb[3] && Abs(rgb[2] - rgb[3]) < 40 ? "1F6FEB" : c
    mx := Max(rgb[1], rgb[2], rgb[3]), mn := Min(rgb[1], rgb[2], rgb[3])
    lum := LookLum(rgb)
    if mx - mn < 40
        return lum < 0.3 ? LOOK_FG : lum < 0.7 ? LOOK_MUTED : c
    if rgb[1] + 40 < rgb[2] && rgb[1] + 40 < rgb[3] && Abs(rgb[2] - rgb[3]) < 40     ; the old teal
        return LOOK_ACCENT
    if rgb[3] > rgb[1] + 60 && rgb[3] > rgb[2]                                        ; blues
        return "7DB8FF"
    return Format("{:02X}{:02X}{:02X}", rgb[1] + (255 - rgb[1]) * 0.5, rgb[2] + (255 - rgb[2]) * 0.5, rgb[3] + (255 - rgb[3]) * 0.5)
}

; A window colour for the dark look: the light backgrounds turn dark
LookBack(c) {
    if !LookOn() || (rgb := LookRGB(c)) = ""
        return c
    return LookLum(rgb) > 0.8 ? LOOK_BG : c
}

; "s10 norm c606060" -> the same with the colour fixed
LookFontOpts(o) {
    out := "", pos := 1
    while RegExMatch(o, "i)(?<![A-Za-z0-9])c([0-9A-F]{6})(?![A-Za-z0-9])", &m, pos) {
        out .= SubStr(o, pos, m.Pos - pos) "c" LookText(m[1])
        pos := m.Pos + m.Len
    }
    return out SubStr(o, pos)
}

LookInit() {
    static done := false
    if done || !LookOn()
        return
    done := true
    try {
        ux := DllCall("GetModuleHandle", "Str", "uxtheme", "Ptr")
        DllCall(DllCall("GetProcAddress", "Ptr", ux, "Ptr", 135, "Ptr"), "Int", 2)      ; dark controls and menus
        DllCall(DllCall("GetProcAddress", "Ptr", ux, "Ptr", 136, "Ptr"))
    }
}

LookTheme(hwnd, name) {
    try DllCall("uxtheme\SetWindowTheme", "Ptr", hwnd, "Str", name, "Ptr", 0)
}

; Dark title bar, then dark controls
LookWindow(g) {
    if !LookOn()
        return
    try {
        v := Buffer(4, 0)
        NumPut("Int", 1, v)
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", g.Hwnd, "Int", 20, "Ptr", v, "Int", 4)
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", g.Hwnd, "Int", 19, "Ptr", v, "Int", 4)
    }
    for hwnd, c in g
        try LookControl(c)
}

LookControl(c) {
    switch c.Type, false {
        case "Edit", "ListBox", "TreeView":
            c.Opt("+Background" LOOK_FIELD)
            LookTheme(c.Hwnd, "DarkMode_Explorer")
        case "ComboBox", "DDL":
            c.Opt("+Background" LOOK_FIELD)
            LookTheme(c.Hwnd, "DarkMode_CFD")
        case "ListView":
            bgr := (v) => ((v & 255) << 16) | (v & 0xFF00) | (v >> 16)
            SendMessage(0x1001, 0, bgr(Integer("0x" LOOK_FIELD)), c)       ; background
            SendMessage(0x1026, 0, bgr(Integer("0x" LOOK_FIELD)), c)       ; text background
            SendMessage(0x1024, 0, bgr(Integer("0x" LOOK_FG)), c)          ; text
            LookTheme(c.Hwnd, "DarkMode_Explorer")
            if hdr := SendMessage(0x101F, 0, 0, c)
                LookTheme(hdr, "DarkMode_ItemsView")
        case "Button", "CheckBox", "Radio", "GroupBox":
            LookTheme(c.Hwnd, "DarkMode_Explorer")
    }
}

class WGui extends Gui {
    __New(o?, t?, e?) {
        super.__New(o?, t?, e?)
        if LookOn() {
            LookInit()
            super.BackColor := LOOK_BG
            super.SetFont("c" LOOK_FG)
        }
        SetTimer(LookWindow.Bind(this), -60)           ; once more, for anything added after Show
    }
    SetFont(o := "", f := "") {
        if o = "" && f = "" && LookOn()
            return super.SetFont("c" LOOK_FG)
        return super.SetFont(LookFontOpts(o), f)
    }
    BackColor {
        get => super.BackColor
        set => super.BackColor := LookBack(value)
    }
    AddTab2(o := "", p := "") => super.AddTab2(LookOn() ? o " Buttons" : o, p)
    AddTab3(o := "", p := "") => super.AddTab3(LookOn() ? o " Buttons" : o, p)
    Show(o?) {
        LookWindow(this)
        return super.Show(o?)
    }
}
