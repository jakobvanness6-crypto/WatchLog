#Requires AutoHotkey v2.0
; Builds Watchlog.exe: the AutoHotkey v2 (64-bit) program with Watchlog.ahk inside it,
; the same way AutoHotkey's own compiler does it. Run with:
;   AutoHotkey64.exe build.ahk <base AutoHotkey64.exe> <out Watchlog.exe> <Watchlog.ahk> <files folder> <resources folder>
; <files folder> holds templates.txt, README.txt, QUICK START.txt, LICENCE.txt and LaunchWork.bat (built into the exe);
; <resources folder> holds what mk_resources.py wrote. build-log.txt shows "-> 1" for every step that worked.
base := A_Args[1], out := A_Args[2], script := A_Args[3], files := A_Args[4], res := A_Args[5]
logFile := res "\build-log.txt"
try FileDelete logFile
FileCopy base, out, 1
h := DllCall("BeginUpdateResourceW", "str", out, "int", 0, "ptr")
if !h {
    FileAppend "BeginUpdateResource failed " A_LastError "`n", logFile
    ExitApp 1
}
AddRes(type, name, file) {
    global h, logFile
    buf := FileRead(file, "RAW")
    if IsInteger(name)
        ok := DllCall("UpdateResourceW", "ptr", h, "ptr", type, "ptr", name, "ushort", 0x409, "ptr", buf, "uint", buf.Size)
    else
        ok := DllCall("UpdateResourceW", "ptr", h, "ptr", type, "str", name, "ushort", 0x409, "ptr", buf, "uint", buf.Size)
    FileAppend "add " type " " name " " buf.Size " -> " ok "`n", logFile
}
AddRes(10, 1, script)
; FileInstall looks these up by the file name in capitals
for name in ["templates.txt", "README.txt", "QUICK START.txt", "LICENCE.txt", "LaunchWork.bat"]
    AddRes(10, StrUpper(name), files "\" name)
Loop 8
    AddRes(3, 100 + A_Index, res "\icon" (100 + A_Index) ".bin")
AddRes(14, 159, res "\group159.bin")
AddRes(16, 1, res "\version.bin")
ok := DllCall("EndUpdateResourceW", "ptr", h, "int", 0)
FileAppend "end -> " ok "`n", logFile
ExitApp ok ? 0 : 1
