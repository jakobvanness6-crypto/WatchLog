#Requires AutoHotkey v2.0
#SingleInstance Force
; Speed: AutoHotkey pauses 100 ms after every window switch by default,
; and keeps a running record of every line it runs. Neither is needed here.
SetWinDelay 10
SetControlDelay 0
ListLines False
KeyHistory 0

; =====================================================================
;  WATCHLOG  v3.3.0   (called Log Templates before v3.0.1)
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
VERSION := "3.4.2"
VERSION_DATE := "Oct 21, 2026"
TemplatesFile := A_ScriptDir "\templates.txt"
IconFile := A_ScriptDir "\Watchlog.ico"
MyTemplatesFile := A_ScriptDir "\my-templates.txt"
SettingsFile := A_ScriptDir "\settings.ini"
NotesFile := A_MyDocuments "\Quick Notes.md"
; Kept on this PC only (not synced): the activity log and the last good
; copy of the team templates
DataDir := EnvGet("LOCALAPPDATA") "\Watchlog"
RegKey := "HKCU\Software\Watchlog"
ActivityFile := DataDir "\activity.log"
TeamCopyFile := DataDir "\team templates (last good copy).txt"
LastUsedFile := DataDir "\last used.ini"   ; boxes that remember (bay), this PC only
SavedFile := DataDir "\time saved.ini"      ; the time saved tracker (numbers only)
Cfg := Map()
TemplateList := []
Lists := Map()          ; @lists from templates.txt, e.g. @tables
Lists.CaseSense := false
AppList := []
LoginList := []
CurForm := ""
JustFired := 0
ReminderGui := ""
WatchTimes := Map()
JournalNotified := false
Picker := ""            ; the template finder (Ctrl+Alt+Space) while it's open
SettingsWin := ""       ; the Settings window while it's open
FirstRun := false       ; true when this PC had no settings.ini yet
ReloadAt := 0           ; when an automatic reload was asked for
UpdateOffered := ""     ; the update already offered this run (Later = don't ask again)
Tpl := {src: "", file: "", count: 0, version: "", code: "", note: "", mine: 0, program: ""}   ; where the templates came from

MoveFromOldName()

; Signs this PC has run Watchlog before (used if settings.ini goes missing)
RanBefore := FileExist(ActivityFile) != ""
Loop Reg RegKey
    RanBefore := true

TrimActivity()
Activity("Started v" VERSION " on " A_ComputerName " (Windows user " A_UserName ") from " A_ScriptDir)
OnExit(LogExit)
OnError(LogError)
LoadSettings()
LoadTemplates()
LoadApps()
StartWatching()
CleanJournal()
SetTimer CleanJournal, 6 * 3600000

; The Watchlog icon (Watchlog.ico next to this file; the green H without it)
if FileExist(IconFile)
    try TraySetIcon IconFile

; Right-click the tray icon for these
A_IconTip := "Watchlog v" VERSION "  (" VERSION_DATE ")" (OutOfDate() ? "  - UPDATE NEEDED" : "")
A_TrayMenu.Insert("1&", "Watchlog v" VERSION "  (" VERSION_DATE ")" (OutOfDate() ? "  - update needed" : ""), (*) => ShowVersion())
A_TrayMenu.Insert("2&")
A_TrayMenu.Insert("3&", "Find a template", (*) => ShowPicker())
A_TrayMenu.Insert("4&", "Cheat sheet", (*) => ShowCheatSheet())
A_TrayMenu.Insert("5&", "Shift journal", (*) => ShowJournal())
A_TrayMenu.Insert("6&", "Time saved", (*) => ShowTimeSaved())
A_TrayMenu.Insert("7&")
A_TrayMenu.Insert("8&", "Settings (logins, templates, journal)", (*) => ShowSettings())
A_TrayMenu.Insert("9&", "Security and status", (*) => ShowSecurity())
A_TrayMenu.Insert("10&", "Activity log", (*) => OpenActivity())
A_TrayMenu.Insert("11&", "Make a copy to share", (*) => MakeShareCopy())
A_TrayMenu.Insert("12&")
A_TrayMenu.Insert("13&", "Edit my templates", (*) => EditMine())
A_TrayMenu.Insert("14&", Cfg["SharedTemplates"] != "" ? "Edit team templates" : "Edit templates", (*) => EditFile(Cfg["SharedTemplates"] != "" ? Cfg["SharedTemplates"] : TemplatesFile))
A_TrayMenu.Insert("15&", "Edit settings file (advanced)", (*) => EditFile(SettingsFile))
A_TrayMenu.Insert("16&", "Open script folder", (*) => Run(A_ScriptDir))
A_TrayMenu.Insert("17&", "End of shift (close apps)", (*) => EndOfShift())
A_TrayMenu.Insert("18&")

; A newer Watchlog in the team folder: offer it before anything else
CheckForUpdate()
AnnounceVersion()
; First time on this PC: the setup window (it's the Settings window)
if FirstRun
    ShowSettings(true)


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
    return InStr(A_ScriptDir, "OneDrive") && !ProcessExist("OneDrive.exe")
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
        try code := CheckCode(FileRead(A_ScriptFullPath, "UTF-8"))
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
            . "Get the new Watchlog.ahk from whoever looks after the tool, put it in place of this one:`n" A_ScriptFullPath "`n`nthen press Ctrl+Alt+R.", "Watchlog - update needed", "Icon!"
    }
}

; Tray menu > the version line at the top
ShowVersion() {
    MsgBox "Watchlog v" VERSION "  (" VERSION_DATE ")`n`n" VersionStatus()
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
    Activity("Error on line " e.Line ": " e.Message)
    return 0
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
    if !FileExist(Cfg["LaunchWork"]) && FileExist(A_ScriptDir "\LaunchWork.bat")
        Cfg["LaunchWork"] := A_ScriptDir "\LaunchWork.bat"
    Cfg["CitrixTab"] := Trim(IniRead(SettingsFile, "Paths", "CitrixTab", "Citrix|apps.gcgaming.com"))
    Cfg["LaunchWait"] := Trim(IniRead(SettingsFile, "Paths", "LaunchWait", "20"))
    Cfg["ChromeAccount"] := Trim(IniRead(SettingsFile, "Paths", "ChromeAccount", ""))
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
    Cfg["CloseApps"] := Trim(IniRead(SettingsFile, "EndOfShift", "Close", "outlook.exe, olk.exe, ms-teams.exe, Teams.exe, javaw.exe, CMPDesktop.exe, wfica32.exe, Spotify.exe, chrome.exe, msedge.exe, explorer.exe"))

    ; Programs Ctrl+Alt+L opens before LaunchWork.bat: [StartOfShift] Run1 ... Run9
    ; A * in a path means "any version" (the newest one found is used).
    ; WindowN (optional) = how to spot it already open, so it isn't opened twice.
    Cfg["StartApps"] := []
    hasSection := false
    try hasSection := IniRead(SettingsFile, "StartOfShift") != ""
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
    rec := {trig: trig, user: user, win: win, remind: remind}
    rec.timer := ShowLoginReminder.Bind(rec)
    HotIf(win != "" ? MakeWindowCheck(win) : NotInSettings)
    Hotstring(":*C:" trig, (*) => DoLogin(trig, user, fallbackPw, rec))
    HotIf
    LoginList.Push(rec)
    if remind
        ResumeReminder(rec)
    if win = "" && SubStr(trig, 1, 1) != ";"
        return "   " trig " has no `; in front, so it can fire in a chat or email and send your password.`n"
    return ""
}

MakeWindowCheck(win) {
    return (*) => LoginWindowActive(win)
}

LoginWindowActive(win) {
    SetTitleMatchMode 2
    return WinActive(win) && !SettingsActive()
}

; Shortcuts don't fire in the Settings window, so typing ;me into its
; Shortcut box doesn't type a password there
SettingsActive() => IsObject(SettingsWin) && WinActive("ahk_pid " DllCall("GetCurrentProcessId"))
NotInSettings(*) => !SettingsActive()

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
    SendInput "{Text}" user
    SendInput "{Tab}"
    SendInput "{Text}" pw
    SendInput "{Enter}"
    CountSaved("login", StrLen(user) + StrLen(pw) + 2 - StrLen(trig))
    pw := ""
    StartReminder(rec)
    ; The activity log notes where a password was typed (never the password)
    exe := ""
    try exe := WinGetProcessName("A")
    Activity("Login typed: " trig " (" user ") into " (exe != "" ? exe : "an unknown window"))
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

ShowLoginReminder(rec) {
    global ReminderGui
    CloseReminder()
    g := Gui("+AlwaysOnTop +ToolWindow", "Login reminder")
    g.SetFont("s11", "Segoe UI")
    g.MarginX := 16, g.MarginY := 12
    g.AddText(, "Time to log in again  (" rec.remind " minutes since the last one)`n`n      " rec.trig "      " rec.user)
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
        if MsgBox("There's no settings.ini in this folder:`n" A_ScriptDir "`n`n"
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
    Loop Files A_ScriptDir "\settings-*.ini" {
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
LaunchWork=LAUNCHPATH
LaunchWait=20
CitrixTab=Citrix|apps.gcgaming.com
; Optional: the Google account the start-of-shift websites open in
; (blank = Chrome's last used one)
ChromeAccount=

[StartOfShift]
; Programs Ctrl+Alt+L opens first (up to Run9), then it runs LaunchWork.
; A * means any version, so upgrades don't break these.
Run1=C:\BallyTechnologies\AlertGridUI*\AlertGridUI\AlertGridUI.bat
Run2=C:\BallyTechnologies\SDSUI*\SDSUI\SDSUI.bat
Run3=C:\BallyTechnologies\CMPDesktop*\CMPDesktop\CMPDesktop.exe

[EndOfShift]
; Programs Ctrl+Alt+Shift+L closes (separate with commas)
Close=outlook.exe, olk.exe, ms-teams.exe, Teams.exe, javaw.exe, CMPDesktop.exe, wfica32.exe, Spotify.exe, chrome.exe, msedge.exe, explorer.exe

; APP HOTKEYS - Ctrl+Alt + Key switches to the app, or opens it.
; Add more as [App3], [App4] ... up to [App9].
; Taken keys: Q O I H P X R L E J K
; Built in already: T Teams, U Outlook, Y Spotify, G Chrome. To change one,
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
    text := StrReplace(text, "LAUNCHPATH", A_MyDocuments "\LaunchWork.bat")
    FileAppend text "`n", SettingsFile, "UTF-16"
    FirstRun := true
    Activity("First run on this PC: new settings.ini made in " A_ScriptDir)
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
    Activity("Templates: " TemplateSummary())
    if main.text = "" && main.note = ""
        problems .= "Can't find templates.txt. It needs to be in the same folder as this script:`n" A_ScriptDir "`n`n"
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
    if IsObject(CurForm) || IsObject(SettingsWin)
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
        if line != "" && !InStr("#@", SubStr(line, 1, 1)) && InStr(line, "=")
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
        default: s := "templates.txt in " A_ScriptDir
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

; Turns each template line into a trigger. Returns how many were added.
AddTemplates(content, src, label, trigs, &problems) {
    added := 0
    Loop Parse content, "`n", "`r" {
        line := Trim(A_LoopField)
        if line = "" || SubStr(line, 1, 1) = "#" || SubStr(line, 1, 1) = "@"
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
        isForm := RegExMatch(text, "\{[^{}]+\}") > 0
        HotIf NotInSettings
        Hotstring(":*C:" trig, MakeTemplateHandler(text, name != "" ? name : trig, repeat, trig))
        HotIf
        TemplateList.Push({trig: trig, name: name, text: text, form: isForm, repeat: repeat, src: src})
        added += 1
    }
    return added
}

MakeTemplateHandler(text, title, repeat := false, trig := "") {
    return (*) => RunTemplate(text, title, repeat, trig)
}

; trig = the shortcut typed, for the time saved tracker
RunTemplate(text, title, repeat := false, trig := "") {
    ; Swallow a Space or Enter typed out of habit right after the trigger
    global JustFired := A_TickCount
    ; A trigger typed into the template finder: close it and run the
    ; template in the window you were typing in
    if PickerActive()
        ClosePicker(true)
    fields := ParseFields(text)
    if fields.Length = 0 {
        out := FixArticles(text)
        Paste(out)
        Journal(title, out)
        CountSaved("log", StrLen(out) - StrLen(trig))
        return
    }
    FormPaste(title, fields, vals => FillTemplate(text, fields, vals), repeat, StrLen(trig))
}

; Finds every {blank} in the text and turns it into a form box (once per name)
ParseFields(text) {
    fields := [], seen := Map()
    ; Last-used values for "last" and "next" boxes, read once for the whole
    ; form. They're kept on this PC (not in settings.ini, which OneDrive
    ; syncs); before v3.3 they were in settings.ini, so that's the fallback.
    last := Map()
    last.CaseSense := false
    if InStr(text, "last") || InStr(text, "next") {
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
            clip := Trim(A_Clipboard)
            f.def := RegExMatch(clip, "^\d{4,8}$") ? clip : ""
            hint := "  (copy it first to auto-fill)"
        } else if low = "last" {
            f.remember := true
            f.def := last.Has(key) ? last[key] : ""
        } else if low = "next" {
            f.remember := true, f.nextStep := true
        } else if low = "pick" {
            pick := true
        } else if low = "caps" {
            f.caps := true
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
    WinWaitActive "ahk_id " hwnd, , 2
    Sleep WinActive("ahk_exe wfica32.exe") ? 400 : 50
}

; Fast paste: backs up your clipboard, pastes the text, then restores it
; keep = true leaves the text on the clipboard afterwards (used by forms, so
; if the paste doesn't land you can still press Ctrl+V yourself).
Paste(text, keep := false) {
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

FormPaste(title, fields, build, repeat := false, trigLen := 0) {
    target := WinExist("A")
    g := Gui("+AlwaysOnTop +ToolWindow", title)
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 14, g.MarginY := 12
    ctrls := [], starts := []
    for f in fields {
        g.AddText(A_Index > 1 ? "y+10" : "", f.label)
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
    done := []          ; finished entries so far, when "Add another" is used
    typed := 0          ; keystrokes typed into the form, for the time saved tracker
    autoVals := Map()   ; boxes filled in by an "if" option, and with what
    ; How the log will come out, updated as you type
    g.SetFont("s9")
    g.AddText("y+14 c707070", "How it will look:")
    preview := g.AddEdit("w420 r5 ReadOnly -TabStop VScroll BackgroundF1F5F5")
    lastPreview := ""
    g.SetFont("s10")
    for c in ctrls
        c.OnEvent("Change", Changed)
    Changed()
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

    Cancel(*) {
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

    ShowPreview() {
        out := ""
        for entry in done
            out .= entry "`r`n"
        out .= build(Collect(false))
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
                if f.HasOwnProp("caps")
                    v := RegExReplace(v, "(\w*\d\w*)", "$U1")
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
                }
            }
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

    AddAnother(*) {
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
        ; With "Add another", a last set of boxes left empty is skipped
        if !(done.Length && Untouched()) {
            typed += TypedNow()
            done.Push(build(Collect()))
        }
        out := ""
        for entry in done
            out .= (A_Index > 1 ? "`n" : "") entry
        SetForm("")
        g.Destroy()
        CountSaved("log", StrLen(out) - trigLen - typed)
        ; Give the window you were typing in a moment to take the keyboard
        ; back (Citrix needs longer) - otherwise the paste can get lost
        ReturnTo(target)
        Paste(out, true)
        Journal(title, out)
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

CheckForEdits() {
    if IsObject(CurForm) || IsObject(SettingsWin) || IsObject(Picker)
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
^!q:: {
    ib := InputBox("Type your note. Start with a tag like #todo, #incident or #idea:", "Quick Note", "w450 h120")
    if ib.Result != "OK" || Trim(ib.Value) = ""
        return
    note := Trim(ib.Value)
    if SaveNote(NotesFile, note) {
        Tip("Note saved", 1000)
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

^!o:: Run 'notepad.exe "' NotesFile '"'


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

Journal(title, text) {
    global JournalNotified
    mode := Cfg["JournalSave"]
    if mode = "off"
        return
    entry := FormatTime(, "HH:mm") "  " title "`n"
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
JournalStats(file) {
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
        name := Trim(e[2])
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

^!j:: ShowJournal()

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
    head := "Shift started " st.started "`n"
        . st.total " logs, " st.first " to " st.last
        . (st.ended != "" ? "   (ended " st.ended ")" : latest.open ? "   (still going)" : "")

    sv := SavedShift()
    if sv.keys > 0
        head .= "`nTime saved this shift: " SavedTime(sv.keys) " (" Commas(sv.keys) " keystrokes)"
    g := Gui("+AlwaysOnTop", "Shift journal  -  v" VERSION)
    g.SetFont("s10", "Segoe UI")
    g.AddText("w460", head)
    g.SetFont("s10", "Consolas")
    g.AddEdit("w460 r14 ReadOnly -WantReturn", st.list)
    g.SetFont("s10", "Segoe UI")
    g.AddButton("w112 Default", "Copy summary").OnEvent("Click", CopySummary)
    g.AddButton("x+4 w112", "Open journal").OnEvent("Click", OpenIt)
    g.AddButton("x+4 w112", "Time saved").OnEvent("Click", (*) => (g.Destroy(), ShowTimeSaved()))
    g.AddButton("x+4 w112", "Close").OnEvent("Click", (*) => g.Destroy())
    g.OnEvent("Escape", (*) => g.Destroy())
    g.Show()

    CopySummary(*) {
        A_Clipboard := st.summary
        g.Destroy()
        Tip("Summary copied. Paste it with Ctrl+V.")
    }

    OpenIt(*) {
        g.Destroy()
        Run 'notepad.exe "' file '"'
    }
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
    if Cfg["SharedTemplates"] = ""
        return ""
    SplitPath Cfg["SharedTemplates"], , &dir
    f := dir "\Watchlog.ahk"
    return f = A_ScriptFullPath ? "" : f
}

; The version of the team folder's Watchlog.ahk, or "" if there isn't one
TeamProgramVersion() {
    f := TeamProgramFile()
    if f = "" || !FileExist(f)
        return ""
    try text := FileRead(f, "UTF-8")
    catch
        return ""
    return RegExMatch(text, 'm)^VERSION := "([\d.]+)"', &m) ? m[1] : ""
}

; True when the team folder has a newer Watchlog than this one
UpdateWaiting() {
    v := TeamProgramVersion()
    return v != "" && VerCompare(v, VERSION) > 0
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
CountSaved(kind, keys) {
    try {
        day := FormatTime(, "yyyy-MM-dd")
        d := SavedRow(IniRead(SavedFile, "Days", day, ""))
        d.%kind% += 1, d.keys += keys
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
        }
        sh.%kind% += 1, sh.keys += keys
        IniWrite sh.log "," sh.login "," sh.stamp "," sh.keys, SavedFile, "Shift", "Counts"
        IniWrite A_Now, SavedFile, "Shift", "Last"
    }
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

ShowTimeSaved() {
    first := ""
    try first := IniRead(SavedFile, "Info", "First", "")
    rows := [["This shift", SavedShift()]
        , ["Today", SavedSince(FormatTime(, "yyyy-MM-dd"))]
        , ["Last 7 days", SavedSince(FormatTime(DateAdd(A_Now, -6, "Days"), "yyyy-MM-dd"))]
        , ["Last 30 days", SavedSince(FormatTime(DateAdd(A_Now, -29, "Days"), "yyyy-MM-dd"))]
        , ["Since " (first != "" ? FormatTime(StrReplace(first, "-") "000000", "MMM d, yyyy") : "the start"), SavedSince("")]]
    g := Gui("+AlwaysOnTop", "Time saved  -  v" VERSION)
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
    g.AddButton("xm+352 y+12 w100", "Copy report").OnEvent("Click", CopyIt)
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
;  TIME & DATE STAMPS
;  ;t  = @21:42      ;dd = 2026-10-13      ;dt = 2026-10-13 @21:42
;  (not in the template finder's search box, so ;t can be searched for,
;  and not in Settings)
; =====================================================================
#HotIf !PickerActive() && !SettingsActive()
:*:;t:: {
    SendInput "{Text}@" FormatTime(, "HH:mm")
    CountSaved("stamp", 6 - 2)
}

:*:;dd:: {
    SendInput "{Text}" FormatTime(, "yyyy-MM-dd")
    CountSaved("stamp", 10 - 3)
}

:*:;dt:: {
    SendInput "{Text}" FormatTime(, "yyyy-MM-dd") " @" FormatTime(, "HH:mm")
    CountSaved("stamp", 17 - 3)
}
#HotIf


; =====================================================================
;  APP SWITCHING  (apps are set up in settings.ini)
;  Ctrl+Alt+I = show the current window's title and program name
; =====================================================================
LoadApps() {
    taken := "QOIHPXRLEJK"
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
            , {name: "Chrome",  key: "G", win: "ahk_exe chrome.exe",   path: "chrome.exe"}] {
        if InStr(named, "|" a.name "|") || InStr(taken, a.key)
            continue
        Hotkey "^!" StrLower(a.key), MakeSwitchHandler(a.name, a.win, a.path)
        AppList.Push({name: a.name, key: a.key})
        taken .= a.key
    }

    if problems != ""
        MsgBox "Some apps in settings.ini were skipped:`n`n" problems, "Watchlog", "Icon!"
}

MakeSwitchHandler(name, win, path) {
    return (*) => SwitchTo(name, win, path)
}

; Switches to the app, minimizes it if it's already in front, or opens it
SwitchTo(name, match, runTarget := "") {
    SetTitleMatchMode 2
    if match != "" && WinExist(match) {
        if WinActive(match)
            WinMinimize
        else
            WinActivate
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

^!i:: {
    title := WinGetTitle("A")
    exe := WinGetProcessName("A")
    A_Clipboard := "Title: " title "  |  Program: " exe
    Tip("Title: " title "`nProgram: " exe "`n(Copied to clipboard)", 5000)
}


; "Chrome" or "Edge" if one has a window open, otherwise ""
; (both can run in the background with no window, which doesn't count)
BrowserOpen() {
    for exe, name in Map("chrome.exe", "Chrome", "msedge.exe", "Edge")
        for id in WinGetList("ahk_class Chrome_WidgetWin_1 ahk_exe " exe)
            if SafeTitle(id) != ""
                return name
    return ""
}

; =====================================================================
;  START OF SHIFT  -  Ctrl+Alt+L
;  Opens the programs in [StartOfShift] (any version) first, waits for
;  their windows, then runs LaunchWork.bat for the websites and switches
;  Chrome to the Citrix Receiver tab last.
;  If Chrome or Edge is already open, it asks before opening the websites
;  again, so you don't end up with every tab twice.
; =====================================================================
^!l:: {
    sites := true
    if (browser := BrowserOpen()) != ""
        sites := MsgBox(browser " is already open, so the work websites are probably open too.`n`n"
            . "Open them again?", "Start of shift", "YesNo Icon? Default2") = "Yes"
    CoordMode "ToolTip", "Screen"
    began := A_TickCount
    secs := IsNumber(Cfg["LaunchWait"]) ? Max(Cfg["LaunchWait"], 20) : 20   ; the apps get at least 20 s
    Tip("Opening work apps...", 0, true)
    missing := ""

    SetTitleMatchMode 2
    started := []       ; how to spot each app it opened
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
            Sleep 1000
        try Run p, dir
        catch {
            missing .= "   " target "`n"
            continue
        }
        started.Push(app.win)
    }

    ; Wait until the apps it opened have their windows up, so they don't
    ; pop up over Chrome afterwards. LaunchWait = the most it waits (seconds
    ; from pressing Ctrl+Alt+L); anything slower than that is left to finish.
    deadline := began + secs * 1000
    for w in started {
        if w = ""
            continue
        while !WinExist(w) && A_TickCount < deadline
            Sleep 200
    }
    Sleep 1500          ; let the apps finish drawing
    Tip("Opening websites...", 0, true)
    ; Websites next, once the apps are up, so the Citrix tab is the last thing to take the screen
    path := Cfg["LaunchWork"]
    if !sites {
        ; skipped - the browser was already open
    } else if FileExist(path) {
        ; Tell LaunchWork which Chrome profile has the ChromeAccount signed in
        prof := ChromeProfileFor(Cfg["ChromeAccount"])
        if Cfg["ChromeAccount"] != "" && prof = ""
            missing .= "   Chrome profile for " Cfg["ChromeAccount"] "   (sign in to it in Chrome on this PC once)`n"
        SplitPath path, , &dir
        ; cmd /c strips the outer pair of quotes, so the whole line gets an extra pair
        Run A_ComSpec ' /c ""' path '"' (prof != "" ? ' "' prof '"' : "") '"', dir, "Hide"
    } else {
        missing .= "   " path "   (LaunchWork in settings.ini)`n"
    }

    Tip("")
    CitrixTab(sites)
    KeepChromeFront(started)
    if missing != ""
        MsgBox "These weren't found, so they didn't open:`n`n" missing "`nCheck [StartOfShift] and LaunchWork in settings.ini", "Watchlog", "Icon!"
}


; Switches Chrome to the Citrix Receiver tab: the one whose title has
; CitrixTab (settings.ini, default "Citrix") in it. A tab still loading
; shows its address as the title, which has Citrix in it too.
; wait = true when the websites were just opened: Chrome gets up to 15
; seconds to open its window, and three goes round the tabs. If the tab
; isn't there, Chrome ends up back on the tab it started on. It stops if
; you click into another window meanwhile.
CitrixTab(wait) {
    want := Cfg["CitrixTab"]
    if want = ""
        return
    ; a tab that is still opening is named after its address, not "Citrix Workspace"
    if !InStr(want, "apps.gcgaming.com")
        want .= "|apps.gcgaming.com"
    stopAt := A_TickCount + (wait ? 15000 : 0)
    rounds := wait ? 3 : 1
    drift := 0
    Loop {
        ; the Citrix tab may already be showing in one of the Chrome windows
        for id in ChromeWindows() {
            if TabHas(SafeTitle(id), want) {
                WinActivate "ahk_id " id
                Activity("Citrix tab: already showing in a Chrome window (" SafeTitle(id) ")")
                return
            }
        }
        if hwnd := ChromeWindow() {
            WinActivate "ahk_id " hwnd
            if !WinWaitActive("ahk_id " hwnd, , 2) {
                Activity("Citrix tab: Chrome would not come to the front (front window is " WinGetTitle("A") ")")
                return
            }
            ; Ctrl+Tab through the tabs until it's back where it started
            first := SafeTitle(hwnd)
            seen := first
            Loop 30 {
                if TabHas(SafeTitle(hwnd), want) {
                    Activity("Citrix tab: found it (" SafeTitle(hwnd) ")")
                    return
                }
                if !WinActive("ahk_id " hwnd) {
                    ; another window (a Java app opening, say) took the focus: take it back, a few times
                    if ++drift > 3 {
                        Activity("Citrix tab: gave up, focus kept leaving Chrome (now " WinGetTitle("A") ")")
                        return
                    }
                    WinActivate "ahk_id " hwnd
                    if !WinWaitActive("ahk_id " hwnd, , 2)
                        return
                }
                SendInput "^{Tab}"
                Sleep 150
                seen .= " | " SafeTitle(hwnd)
                if SafeTitle(hwnd) = first
                    break
            }
            if --rounds <= 0 {
                Activity("Citrix tab: not found. Tab titles seen: " seen)
                return
            }
        }
        if A_TickCount >= stopAt {
            Activity("Citrix tab: gave up, " (hwnd ? "tab not found" : "no Chrome window appeared"))
            return
        }
        Sleep 1000          ; Chrome or its tabs still opening
    }
}

; The front-most Chrome window with a title (Chrome also keeps hidden
; windows with no title in the background), or 0
ChromeWindow() {
    for id in ChromeWindows()
        return id
    return 0
}

; A window's title, or "" if the window closed while Chrome was opening
; or closing tabs
SafeTitle(id) {
    try return WinGetTitle("ahk_id " id)
    return ""
}

; Every Chrome window that has a title, front-most first
ChromeWindows() {
    list := []
    for id in WinGetList("ahk_class Chrome_WidgetWin_1 ahk_exe chrome.exe")
        if SafeTitle(id) != ""
            list.Push(id)
    return list
}

; The Java apps sometimes open their windows late and jump to the front over
; Chrome. For 25 seconds after the start-of-shift tabs are done, whenever one
; of the apps it opened takes the front, Chrome goes back on top (at most 6
; times), so the Citrix tab is what you see first.
KeepChromeFront(started) {
    stopAt := A_TickCount + 25000
    st := {tries: 0}
    Guard() {
        if A_TickCount > stopAt || st.tries >= 6 {
            SetTimer Guard, 0
            return
        }
        for w in started {
            if w = "" || !WinActive(w)
                continue
            target := 0
            for id in ChromeWindows()
                if TabHas(SafeTitle(id), Cfg["CitrixTab"] "|apps.gcgaming.com") {
                    target := id
                    break
                }
            if !target
                target := ChromeWindow()
            if target {
                st.tries += 1
                WinActivate "ahk_id " target
                Activity("Citrix tab: " w " came to the front, Chrome put back on top")
            }
            break
        }
    }
    SetTimer Guard, 500
}

; True when the title has any of the "|"-separated words in it
TabHas(title, words) {
    for w in StrSplit(words, "|")
        if w != "" && InStr(title, w)
            return true
    return false
}


; Finds which Chrome profile folder ("Default", "Profile 2" ...) has this
; Google account signed in, by reading Chrome's own "Local State" file.
; Each PC can have a different folder for the same account, so it's
; looked up every time. Returns "" if the account isn't found.
ChromeProfileFor(email) {
    if email = ""
        return ""
    stateFile := EnvGet("LOCALAPPDATA") "\Google\Chrome\User Data\Local State"
    if !FileExist(stateFile)
        return ""
    try json := FileRead(stateFile, "UTF-8")
    catch
        return ""
    at := RegExMatch(json, 'i)"user_name"\s*:\s*"\Q' email '\E"')
    if !at
        return ""
    ; the profile's folder name is the nearest "Default": { or "Profile N": { before it
    prof := "", pos := 1
    while (p := RegExMatch(json, '"(Default|Profile \d+)"\s*:\s*\{', &m, pos)) && p < at {
        prof := m[1]
        pos := p + m.Len
    }
    return prof
}


; =====================================================================
;  END OF SHIFT  -  Ctrl+Alt+Shift+L
;  Asks first, then closes every work app listed in settings.ini
;  ([EndOfShift] Close=...). Apps get a normal close, so anything
;  that needs saving can still ask you.
; =====================================================================
$^!+l:: EndOfShift()

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
^!k:: {
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
;  Opens templates.txt, or your own my-templates.txt when the team's
;  shared file is in use (the team file is changed by whoever keeps it:
;  tray menu > Edit team templates, if SharePoint lets you save it).
; =====================================================================
$^!e:: {
    if Cfg["SharedTemplates"] != ""
        EditMine()
    else
        EditFile(TemplatesFile)
}

; Tray menu > Edit my templates (makes the file the first time)
EditMine() {
    if !FileExist(MyTemplatesFile) {
        text := "
        (
# =====================================================================
#  MY TEMPLATES - your own extra templates
#  These go on top of the team's templates, for you only. Same format
#  as templates.txt (the notes at the top of it explain it all).
#  If the team file already uses a trigger, yours is skipped, so the
#  team wording always wins. Save this file and the script reloads.
#
#  Example (take the # off the start of the line to use it):
#  ;mynote (My note) = Operator note at {Time: now}: {Note}
# =====================================================================

        )"
        try FileAppend text, MyTemplatesFile, "UTF-8"
        catch as e {
            MsgBox "Couldn't make my-templates.txt:`n" e.Message, "Watchlog", "Icon!"
            return
        }
        WatchTimes[MyTemplatesFile] := FileTimeOf(MyTemplatesFile)
    }
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
^!Space:: ShowPicker()

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

    g := Gui("+AlwaysOnTop", "Find a template  -  v" VERSION)
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
            lv.Add(, t.trig, t.name != "" ? t.name : t.trig, (t.repeat ? "Form, several" : t.form ? "Form" : "Instant") (t.src = "mine" ? " (mine)" : ""))
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
        tip.Text := "Next time you can type  " t.trig "  anywhere instead of opening this. "
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
        RunTemplate(t.text, t.name != "" ? t.name : t.trig, t.repeat, t.trig)
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
;  Logins, where the templates come from, the shift journal and starting
;  with Windows, without editing settings.ini. Nothing changes until
;  Save. Passwords typed here go straight into Windows Credential Manager
;  on this PC, and removing a login deletes its saved password too.
; =====================================================================
SetSettingsWin(v) {
    global SettingsWin := v
}

ShowSettings(welcome := false) {
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
    st := {logins: CopyLogins(), shared: Cfg["SharedTemplates"]}
    keepDays := [7, 14, 30, 60, 90, 365, 0]
    keepNames := ["7 days", "14 days", "30 days", "60 days", "90 days", "1 year", "Never"]
    if !IndexOf(keepDays, Cfg["KeepDays"])
        keepDays.InsertAt(1, Cfg["KeepDays"]), keepNames.InsertAt(1, Cfg["KeepDays"] " days")
    modes := ["full", "counts", "off"]

    g := Gui("+AlwaysOnTop", (welcome ? "Welcome to Watchlog" : "Watchlog settings") "  -  v" VERSION)
    SetSettingsWin(g)
    g.SetFont("s10", "Segoe UI")
    if welcome {
        g.SetFont("s12 bold")
        g.AddText("w620", "Welcome! Two quick things and you're set.")
        g.SetFont("s10 norm")
        g.AddText("w620", "1.   Add the logins you'd like typed for you (or skip this).`n"
            . "2.   If your team keeps its templates on SharePoint, pick that file under Templates.`n"
            . "Then press Save. You can change any of this later: right-click the H icon near the clock > Settings.")
    }
    Heading("Logins")
    g.AddText("xm w620", "Type a login's shortcut and it types the username, Tab, the password and Enter. Passwords are kept in Windows Credential Manager on this PC only, never in a file.")
    lv := g.AddListView("xm w620 r5 -Multi NoSortHdr", ["Shortcut", "Username", "Only in", "Reminder", "Password on this PC"])
    lv.ModifyCol(1, 95), lv.ModifyCol(2, 165), lv.ModifyCol(3, 100), lv.ModifyCol(4, 80), lv.ModifyCol(5, 176)
    g.AddButton("xm w120", "Add...").OnEvent("Click", (*) => LoginBox(0))
    g.AddButton("x+6 w120", "Edit...").OnEvent("Click", (*) => LoginBox(Picked()))
    g.AddButton("x+6 w160", "Change password...").OnEvent("Click", (*) => LoginBox(Picked(), true))
    g.AddButton("x+6 w120", "Remove").OnEvent("Click", RemoveLogin)
    lv.OnEvent("DoubleClick", (ctl, row) => row ? LoginBox(row) : 0)

    Heading("Templates")
    g.AddText("xm w620", "The team's shared templates file (in SharePoint, synced by OneDrive). Leave it blank to use templates.txt in this folder.")
    pathBox := g.AddEdit("xm w408 r1 ReadOnly", st.shared)
    g.AddButton("x+6 w100", "Browse...").OnEvent("Click", Browse)
    g.AddButton("x+6 w100", "Clear").OnEvent("Click", ClearShared)
    info := g.AddText("xm w620 r2", "")
    g.AddText("xm w620", "Your own extra templates go in my-templates.txt (tray menu > Edit my templates).")

    Heading("Shift journal")
    modeDD := g.AddDropDownList("xm w330 Choose" Max(1, IndexOf(modes, Cfg["JournalSave"]))
        , ["Save each log's time, name and text", "Save only the time and template name", "Don't keep a shift journal"])
    g.AddText("x+14 yp+4", "Delete shift files after")
    keepDD := g.AddDropDownList("x+6 yp-4 w100 Choose" IndexOf(keepDays, Cfg["KeepDays"]), keepNames)

    Heading("Windows")
    startCB := g.AddCheckbox("xm" (StartupShortcuts().Length ? " Checked" : ""), "Start Watchlog when I sign in to Windows")

    g.AddButton("xm y+18 w120 Default", "Save").OnEvent("Click", Save)
    g.AddButton("x+6 w120", "Cancel").OnEvent("Click", Close)
    if welcome
        g.AddText("x+14 yp+4 w360", "Then: type a shortcut like `;jack in iTrak, or press Ctrl+Alt+Space to find one by name.")
    g.OnEvent("Escape", Close)
    g.OnEvent("Close", Close)
    Refresh()
    ShowInfo()
    g.Show()
    WinActivate "ahk_id " g.Hwnd

    Heading(text) {
        g.SetFont("s10 bold")
        g.AddText("xm y+16", text)
        g.SetFont("s10 norm")
    }

    Refresh(sel := 0) {
        lv.Delete()
        for x in st.logins
            lv.Add(, x.trig, x.user, x.win, x.remind ? x.remind " min" : ""
                , x.pw != "" ? "new one, saved on Save" : CredExists(x.user) ? "saved" : "not yet (asks once)")
        if sel
            lv.Modify(sel, "Select Focus Vis")
    }

    ShowInfo() {
        if st.shared = "" {
            cnt := 0
            try cnt := CountTemplates(FileRead(TemplatesFile, "UTF-8"))
            info.Text := "Using templates.txt in this folder (" cnt " templates)."
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
        d := Gui("+AlwaysOnTop +Owner" g.Hwnd, row ? "Login " cur.trig : "Add a login")
        d.SetFont("s10", "Segoe UI")
        d.AddText("w420", "Shortcut you'll type. Start it with `; so it never fires while you're typing normally:")
        tb := d.AddEdit("w420", cur.trig)
        d.AddText("w420", "Username:")
        ub := d.AddEdit("w420", cur.user)
        d.AddText("w420", row ? "New password (leave it blank to keep the one saved on this PC):" : "Password (or leave it blank and it asks the first time you use it):")
        pb := d.AddEdit("w420 Password")
        d.AddText("w420", "Optional: only works when the window's title has this in it (like iTrak):")
        wb := d.AddEdit("w420", cur.win)
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
    }

    ClearShared(*) {
        st.shared := ""
        pathBox.Value := ""
        ShowInfo()
    }

    Save(*) {
        g.Opt("+OwnDialogs")
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
        try {
            WriteLogins(st.logins)
            IniWrite st.shared, SettingsFile, "Templates", "Shared"
            IniWrite modes[modeDD.Value], SettingsFile, "Journal", "Save"
            IniWrite keepDays[keepDD.Value], SettingsFile, "Journal", "KeepDays"
        } catch as e {
            MsgBox "Couldn't save settings.ini:`n" e.Message "`n`nIf OneDrive is syncing, press Save again in a moment.", "Watchlog", "Icon!"
            return
        }
        SetStartup(startCB.Value)
        names := ""
        for x in st.logins
            names .= (names = "" ? "" : ", ") x.trig " " x.user
        Activity("Settings saved: logins " (names = "" ? "none" : names)
            . "; team templates " (st.shared = "" ? "none (templates.txt in this folder)" : st.shared)
            . "; journal " modes[modeDD.Value] ", kept " (keepDays[keepDD.Value] ? keepDays[keepDD.Value] " days" : "forever")
            . "; start with Windows " (startCB.Value ? "on" : "off"))
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
    g := Gui("+AlwaysOnTop", "Security and status  -  v" VERSION)
    g.SetFont("s10", "Segoe UI")
    g.AddText("w780", "What Watchlog keeps on this PC, where it is, and what it never keeps. Checked just now.")
    g.SetFont("s9", "Consolas")
    ; -TabStop: the report starts at the top, not all selected
    g.AddEdit("w780 r30 ReadOnly -WantReturn -TabStop", report)
    g.SetFont("s10", "Segoe UI")
    g.AddButton("w150 Default", "Copy report").OnEvent("Click", CopyIt)
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

SecurityReport() {
    nl := "`r`n"
    r := "WATCHLOG v" VERSION " (" VERSION_DATE ")  -  security and status" nl
    r .= "Checked " FormatTime(, "yyyy-MM-dd HH:mm") " on " A_ComputerName ", Windows user " A_UserName nl
    r .= "Program:   " A_ScriptFullPath nl
    r .= "Version:   v" VERSION ", program check code " ProgramCode() ". " VersionStatus() nl
    r .= "OneDrive:  " (!InStr(A_ScriptDir, "OneDrive") ? "the program folder isn't in OneDrive"
        : ProcessExist("OneDrive.exe") ? "running, so this PC gets changes as they sync" : "NOT running, so this PC may have older files") nl

    r .= nl "PASSWORDS" nl
    r .= "  Kept in Windows Credential Manager on this PC only, saved as `"Watchlog: <username>`"." nl
    r .= "  Never written to a file, never synced, never in the shift journal or the activity log." nl
    r .= "  Each PC asks once. Removing a login in Settings deletes its password from this PC." nl
    if LoginList.Length {
        for l in LoginList
            r .= "    " Format("{:-10}", l.trig) " " Format("{:-22}", l.user)
                . (CredExists(l.user) ? "saved on this PC" : "not saved yet (asks the first time)")
                . (l.win != "" ? ", only works in " l.win : "") nl
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
    Loop Files A_ScriptDir "\settings-*.ini"
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
    files := [[A_ScriptFullPath, "Watchlog.ahk"], [tplFrom, "templates.txt"]
        , [A_ScriptDir "\QUICK START.txt", "QUICK START.txt"], [A_ScriptDir "\README.txt", "README.txt"]
        , [A_ScriptDir "\settings.example.ini", "settings.example.ini"], [Cfg["LaunchWork"], "LaunchWork.bat"]
        , [IconFile, "Watchlog.ico"]]
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
^!h:: ShowCheatSheet()

ShowCheatSheet() {
    forms := "", quick := "", apps := ""
    for t in TemplateList {
        line := "   " Format("{:-12}", t.trig) "  " t.name (t.repeat ? "  (Ctrl+Enter adds another)" : "") (t.src = "mine" ? "  (mine)" : "") "`n"
        if t.form
            forms .= line
        else
            quick .= line
    }
    for l in LoginList
        quick .= "   " Format("{:-12}", l.trig) "  Login: " l.user (l.win != "" ? "  (only in " l.win ")" : "") (l.remind ? "  (reminder after " l.remind " min)" : "") "`n"
    for a in AppList
        apps .= "   " a.key "  " a.name "`n"

    text := "Can't remember one?  Ctrl+Alt+Space finds a template by name or any word.`n`n"
        . "FORMS   (Tab = next box, Enter = insert, Esc = cancel)`n" forms
        . "`nQUICK TEMPLATES`n" quick
        . "`nSTAMPS`n   `;t  time        `;dd  date        `;dt  date + time`n"
        . "`nAPPS   (Ctrl+Alt + letter)`n" apps
        . "`nHOTKEYS   (Ctrl+Alt + letter)`n"
        . "   Q  add note          O  open notes        J  shift journal`n"
        . "   L  start of shift    Shift+L  end of shift (closes everything)`n"
        . "   I  window info       E  edit templates    Space  find a template`n"
        . "   K  log out of SDS (properly, so the account doesn't lock)`n"
        . "   P / X  pause-resume  R  reload            H  this cheat sheet`n"
        . "`nRight-click the tray icon (the teal Watchlog one) for Settings and Security and status.`n"
        . "`nv" VERSION " (" VERSION_DATE ")   Templates: " (Tpl.src = "local" ? "templates.txt in this folder" : "the team file")
        . (Tpl.version != "" ? ", wording version " Tpl.version : "") (Tpl.mine ? ", plus " Tpl.mine " of yours" : "")
        . "`nSettings are in:  " A_ScriptDir

    g := Gui("+AlwaysOnTop", "Shortcut Cheat Sheet  -  v" VERSION)
    ; Fixed-width font so the shortcut columns line up
    g.SetFont("s10", "Consolas")
    g.AddText("+0x80", text)
    g.SetFont("s10", "Segoe UI")
    g.AddButton("Default w80", "OK").OnEvent("Click", (*) => g.Destroy())
    g.OnEvent("Escape", (*) => g.Destroy())
    g.Show()
}


; =====================================================================
;  SCRIPT CONTROLS (these keep working even while paused)
;  Ctrl+Alt+P  or  Ctrl+Alt+X = pause / resume all shortcuts
;  Ctrl+Alt+R = reload (after editing templates.txt or settings.ini)
; =====================================================================
#SuspendExempt
^!p::
^!x:: {
    Suspend -1
    SoundBeep A_IsSuspended ? 400 : 900, 150
    Tip(A_IsSuspended ? "Shortcuts PAUSED" : "Shortcuts ON", 1500, true)
}

^!r:: Reload
#SuspendExempt False
