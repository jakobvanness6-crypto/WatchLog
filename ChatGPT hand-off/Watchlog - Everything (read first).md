# Watchlog: everything in one file (hand-off for ChatGPT)

Made 2026-10-25. Current program version: v3.29.0. Wording version is the "# Wording version:" line in templates.txt below.

Watchlog is my AutoHotkey v2 tool for casino surveillance work. It types log entries (iTrak) from short triggers like ;audit or ;evict, fills small forms with a live preview, handles logins (passwords live in Windows Credential Manager, never in files), opens the work programs at start of shift, logs out of SDS at end of shift, clears Alert Grid alerts, keeps a shift journal, quick notes, a time-saved tally, and self-updates from a team folder. It ships as a standalone Watchlog.exe built from Watchlog.ahk.

How I work:
- I test on a Windows work PC and report errors with line numbers.
- Send complete updated files, never snippets. I want to do as little by hand as possible.
- AutoHotkey v2 only (not v1 syntax).
- Never ask for or include real passwords.
- Suggestions go on "Pending changes" first. Nothing changes until I say "build it", then it's one new version (small batch bumps the third digit, bigger the second). Bump "# Program version:" in templates.txt with each release. Wording-only changes to templates.txt ship right away without a version bump.

Redactions in this bundle: my personal email, account names, work username and a PC name were replaced with placeholders. Work website links in LaunchWork.bat were replaced with placeholders. No settings.ini, passwords, .exe or .zip files are included. Program code is unchanged.

Contents of this file, in order:
1. PROJECT-NOTES.md (design notes, history, gotchas; read first)
2. README.txt (the user manual)
3. docs/Pending changes.md
4. docs/Next Steps and Ideas.md
5. templates.txt (all template wording)
6. QUICK START.txt
7. settings.example.ini (example only, no real values)
8. LaunchWork.bat (links removed)
9. build/build.ahk and build/mk_resources.py (how the exe is built)
10. Text of the docs I gave my supervisor, manager and IT (Overview, Summary, IT Summary, Template Wording Review, Demo Run Sheet)

Watchlog.ahk itself (the program, about 10,900 lines) is a separate file in this bundle.


---

# FILE 1: PROJECT-NOTES.md

# Watchlog (formerly Log Templates) — Project Notes

AutoHotkey v2 tool for casino surveillance work (Bay operator, Windows work PCs).
Built Oct 13–14, 2026. Version numbers: small fixes/tweaks bump the third digit (2.7.1, 2.7.2), bigger feature batches the second (2.8). STANDING RULE (Jakob, 2026-10-30): whenever the version number changes, update ALL docs to that same version (README, QUICK START, this file, templates.txt Program version, docs/source md then rebuild docx/pdf with docs/source/build-docs.py, ChatGPT hand-off via tools/make-chatgpt-handoff.py <ver> plus its zip, IT READ ME, Pending changes header). Current version: **v3.29.0** (Oct 31: BREAK TRACKER: IsBreakLog(e) (name starts Break) -> BreakBegin(win) at end of RunEntry; BreakWatch timer 2 s ends it when that window closes; last used.ini [Break] Since/Used/OpenSince/Win; settings.ini [Break] Minutes=60; BreakText() on home Status line, dashboard tab 1, SetIconTip(); BreakReset() in StartOfShift and 14 h after Since; EntryEndNow() hotkey id endnow Ctrl+Alt+Shift+E. Jakob said no reminders. Before that v3.28.0 (Oct 30: SAFEGUARDS batch 2: RepeatLastLog (LastRun set in RunEntry, hotkey id repeatlog Ctrl+Alt+Shift+R), DailyBackup() at startup into LOCALAPPDATA\Watchlog\Backups\<date> (keeps 14; BackupSources/BackupInto/ShowRestore, tray Advanced), GoBackVersion() (swaps in the newest older "Watchlog v* (backup)" kept by updates; last used.ini [Updates] Skip stops that version being offered again; SkippedVersion() used by UpdateWaiting). Then Alert Grid step 5 timing: GridFront retries 2 s, no-more click waits >=250 ms, taught box waits 2 s; v3.27.2 fixed variable `joined` clashing with nested Joined() in FormPaste (load error). Earlier: SDS hourly sign-in FIX: Jakob's Activity log said `SDS sign-in: no saved login is locked to SDS` (LoginForWindow() needs the login's Window= active AND a trigger starting with `;`; focus can move in the 1 s after WinActivate). New SdsLoginRec(sds): LoginForWindow, re-activate SDS and retry once, then any login with SDS in its Window=, then IsSdsLogin(); the failure line now lists login triggers and windows (no passwords). Cause not confirmed: ask for Settings > Logins SDS row if it still fails. Before that **v3.27.0** (Oct 30: FAILURE SAFEGUARDS batch 1: LoginBlockedWin() (DoLogin refuses to type a no-Window= login into notepad/outlook/olk/ms-teams/teams/winword/excel/onenote/slack/whatsapp/discord, Watchlog's own windows or any title with Daily Log Entry) and refused logins now Tip; ReturnTo() returns whether the window came back and FormPaste's Submit calls KeepOnClip() (log stays on the clipboard + beep) instead of pasting when it didn't; GridFront() before the first click and the right-click in ClearAlerts (not before the menu click: the popup menu is active then); CheckScale() at startup compares itrak.ini/alertgrid.ini [Clicks] DPI with A_ScreenDPI (alert teach now writes DPI); FormPaste keeps a form closed with Esc in global Cancelled for 10 min (restored on the same title, `restored` stops a second Esc re-saving it); LogError shows a plain MsgBox (T20) and returns 1. Not done yet from the list: file backups, restore, go-back-to-previous-version, repeat last log. Jakob's SDS hourly sign-in does nothing (reported 22:44): asked for the Activity log lines; likely the login refusing silently (now shows a Tip). Not run. Before that **v3.26.3** (Oct 30: FIX, Jakob: `mfill ...` on the pad then Ctrl+Enter opened an empty form. PadShortcut now knows `mfill` (the first word is removed before PadParse reads the fill lines) and recognises the OLD no-code-word shorthand: a first line that PadParse reads as machine fills (`n3 190800 bvs`) runs ;mfill, and one it reads as a jackpot (`c2102 11421.11 win 3 cash`) runs ;jack, both with no form (hints go). Before that **v3.26.2** (Oct 30: DAILY LOG FILLS for ;fill ;open ;auto ;jack ;bv ;mfill (templates.txt `>>` parts: fill `%pit% | Table Fill |`, open/auto `%pit% | Table Opening/Closing | NA`, jack `%slots% | Jackpot |` (typing Jackpot / Table Win needs spaces around the slash, so only Jackpot is typed), bv `%slots% | Emergency Pull |` (the real iTrak text), mfill `ABM/NRT | ATM/NRT/CTR fill |`; Reference empty where Jakob fills it). Groundwork: FillDerive() replaces %pit% (digit of the first @tables item found in the log, looked up in the `@pit = 2=Pit 2 | 3=Pit 3` list) and %slots% (letter of the first machine, `@slots = A=Alpha Slots | B=Bravo Slots | C=Charlie Slots | D=Delta Slots`) via ListMapGet(); the maps are ordinary @ lists so the template editor handles them. `>>` now works with {repeat} (TemplateFill uses the last tail, FillWording strips every tail). `D` = Delta Slots is a GUESS (Jakob said "sometimes D"); Auto-close Reference NA and the exact iTrak topic names are assumptions. Not run. Before that **v3.26.1** (Oct 30: FIX, Jakob: Alert Grid clearing stopped finishing (the clear-acknowledged click, taught step 5). Cause: my v3.24.1 fallback set ackedFirst and the end of ClearAlerts then skipped AlertClearAcked, so alerts acknowledged in this run were never cleared. Now it always runs at the end; the fallback calls AlertClearAcked(c, grid, gap, false) (button only, no no-more step); if only acknowledged alerts existed (never `done`) it finishes with the full helper. v3.26.0 (shorthand) never shipped separately: 3.26.1 includes it. Before that **v3.26.0** (Oct 30: SHORTHAND LINES. CallPadMakeLog (Ctrl+Enter) calls PadShortcut(PadText): first word fill/open/auto/jack/bv/account (or `auto` as the LAST word: `201 auto`), or any other template trigger without the ; (generic: opens its form with normal PadHints). It returns {trig, hints}; hints is a Map built for the codes (rows [{table,amount}] for fill/open/auto, jack object + machine + time, asset, reason, account, `expect` = boxes it must fill, `go`). The global PadShort holds it while RunTemplate runs so PadHints() returns it; PadFill gained rows (Table forms), time boxes, Asset #, Reason, Account #; PadSetRow handles table rows; FormPaste calls Submit() right after filling when hints go is true and padUsed >= expect (no form). PadAmount: k = x1000, plain number <100 = thousands only for fill (5.5 = 5500). PadTable: 205 -> BJ205 when unique in @tables. ;account template is now a daily-log fill (Guest Services | Account under review | M6 (417)), wording version Oct 30 2026 (3). Not run (sandbox blocks AHK). Before that **v3.25.1** (Oct 30: FIX, v3.25.0 would not start: Jakob's screenshot `Error: Missing """` line 6258. In AHK v2 a space followed by `;` INSIDE a quoted string starts a comment, so the new Settings text "(a ; by default..." lost its closing quote. Fixed with `; (also two more strings). RULE: never write ` ;` inside a string; use `;. After building, grep the diff for it. Before that **v3.25.0** (Oct 30: CODE WORD PREFIX SETTING. Jakob: operators may use ; for other things. settings.ini [Triggers] Prefix= (default ;; 1-3 chars, no letters/digits/space/colon/backtick; validated in LoadSettings into Cfg["Prefix"]). Files and internal logic keep `;`; TrigKey(t) swaps a leading ; for the prefix ONLY where the hotstring is registered (AddLogin, AddTemplates) and where triggers are shown (finder, finder tip, login list, cheat sheet, login reminder). The ;t/;dd/;dt stamps are no longer static `:*:;t::` hotstrings: RegisterStamps() registers them (StampTime/StampDate/StampDateTime) after RegisterHotkeys(). Settings > General has the box; Save reloads. The template editor and its messages still show `;`. Not run (sandbox blocks AHK). Before that **v3.24.1** (Oct 30: ALERT GRID FALLBACK. ClearAlerts: when the right-click menu's Acknowledge box doesn't appear (acknowledged alerts in the selection make Java refuse the menu), it clears the acknowledged alerts first via the new AlertClearAcked() (clear button + no-more step, factored out of the end of ClearAlerts), once per clear (ackedFirst), without using up one of the 3 tries, then goes again. Skipped when ClearX/ClearY aren't taught. Jakob did not say what the refusal looks like (a popup? its title): Escape is sent as before. Not run (sandbox blocks AHK). Before that **v3.24.0** (Oct 30: CODE WORDS THAT FILL THE DAILY LOG. A templates.txt line can end with ` >> Location | Topic | Reference [| end]`; AddTemplates sets `fill` (SplitTop checks 3+ parts), RunTemplate/FormPaste pass it on, TemplateFill() splits the finished text at the last ` >> ` and calls RunEntry(e, true), which reuses an open Daily Log Entry window (the active one first) and only clicks New daily log when none is open. Shift held (Shift+Enter on the form, or Shift when a no-box code word fires) pastes just the wording via FillWording(). The `;cards` template got `>> Pit 2 | Card Change | NA` as a GUESS: Jakob must correct Location/Topic/Reference. Not run: the sandbox blocked running AHK, so this is unvalidated. Before that **v3.23.0** (Oct 30: EDGE-ONLY. The company bans Chrome in about 2 weeks. Ctrl+Alt+L now opens only two tabs in one Edge window with one `msedge.exe` command (OLG iTrak facial rec first = [Paths] FaceUrl, blank = skip; Citrix Receiver last = CitrixUrl), then EdgeToFront() activates the Edge window whose title has CitrixTab/apps.gcgaming.com. REMOVED: LaunchWork.bat use (file still shipped for double-click), Ctrl+Tab tab hunting, KeepChromeFront, ChromeProfileFor, ChromeAccount setting; Ctrl+Alt+G is Edge; chrome.exe dropped from end-of-shift list. Saved window layouts for Chrome windows won't restore: re-save once (Ctrl+Alt+Shift+S) on each bay. Jakob said the tab hunting cost time and was buggy. Built with build/rebuild-resources.py (script, LaunchWork, README, QUICK START, templates resources replaced); validate/Wine run was blocked by the classifier, NOT run. Docs source md and ChatGPT hand-off still say Chrome. v3.22.2: Settings tab height 350 -> 400 (Logins tick box was cut off under Save/Cancel at his display scale). v3.22.1: light is the DEFAULT again (settings.ini [Look] Dark default no; tray menu "Dark look" and Customize switch it; light mode still maps the old teal to blue 1F6FEB); Jakob saw dark text on dark with the first dark-by-default build (cause unknown, probably an unmapped colour). Before that v3.22.0: DARK LOOK. Jakob: dark scheme, blue accent. Every `Gui(` is now `WGui(` (28 sites; only the red CapsGui stays plain). `class WGui extends Gui` at the end of Watchlog.ahk: __New sets dark BackColor/font colour and a deferred LookWindow pass; SetFont remaps `cRRGGBB` through LookText (dark ink -> LOOK_FG, grey -> LOOK_MUTED, teal -> LOOK_ACCENT 4C9AFF, blues lightened, other saturated colours mixed 50% with white); BackColor setter maps light colours to LOOK_BG; AddTab2/AddTab3 add `Buttons` (the tab body is then not drawn, so the dark window shows through); Show() calls LookWindow, which sets the dark title bar (DwmSetWindowAttribute 20/19) and styles controls (Edit/ListBox/TreeView/ComboBox backgrounds, ListView LVM_SETBKCOLOR/TEXTBKCOLOR/TEXTCOLOR, SetWindowTheme DarkMode_Explorer / DarkMode_CFD / DarkMode_ItemsView). LookInit calls uxtheme ordinal 135 (ForceDark) and 136. Settings: Cfg["Dark"] from settings.ini [Look] Dark (default yes); Customize has a tick box. LOOK_* globals live next to VERSION (they must be set before the auto-execute ends). Home window has three stat cards (Card helper, absolute positions). IconButton glyph colours go through LookText. Only Wine-tested (screenshots via xvfb + import; Wine draws buttons/lists light, so the real dark buttons are unverified on Windows 10/11). Six Interior/Exterior/Parking Officer/Supervisor `+` lines added to templates.txt. Before that, v3.21.0: CUSTOMIZE screens (Jakob: "edit the program through a UI"). ShowCustomize hub (tray "Customize Watchlog...", home Set up tile "Customize") opens: ShowEntryEditor (full-entry logs; Entries now carry src main/mine; WriteEntryLines rewrites only the "+" lines, .bak kept, ReloadEntries; team file = read only; "Try it" calls RunEntry), ShowHotkeyEditor (HotkeyDefs table of 21 rebindable ^! keys; static `^!x::` lines REMOVED and registered by RegisterHotkeys() after LoadApps(); overrides in settings.ini [Hotkeys] id=key; HK()/HKShort() labels used by tray, home and cheat sheet; conflict checks vs app keys, ^!p/x/r, numpadadd; WindowInfo() replaces the old ^!i block), ShowShiftEditor ([StartOfShift] Run1-9/Window1-9, [EndOfShift] Close; Cfg["StartApps"] updated live), ShowAutoEditor (autocorrect.txt as a table, [CallPad] Autocorrect, AutoParse), ShowTimingEditor ([AlertGrid] Pause/SelectWait, [ITrak] Pause/EntryWait/EntrySettle; default values deleted from the ini), ShowEditor(startTab) for Shared lists. NoteOwnWrites() stops the 2-second auto-reload (CheckForEdits) after an editor saved (hotkey editor reloads on purpose). TEST GOTCHA: any harness that writes settings.ini triggers the auto-reload and kills the test thread: run `SetTimer CheckForEdits, 0` first. Hotkeys cannot fire under Wine, so only registration (no warnings at startup = all 21 registered) was tested, not pressing keys. Before that **v3.20.3** (Oct 30: +Start full-entry log, `{Bay?}` in a synopsis = RunEntry always InputBox-asks the bay (default = last stored Bay of any age), stores Bay + Bay.at (so `{Bay}` for End / {Bay: saved} reuses it for 14 h). Start does NOT click End Time Now (not stated by Jakob; add `| end` to the line if he wants it). Wine-tested. Before that **v3.20.2** (Oct 30: (1) End full-entry log `+End = Surveillance | Duty | NA | End of Shift Bay {Bay} Operator | end`: 5th teach step EndNowX/Y in itrak.ini [Fields] (optional in EntryLoad; untaught = Tip + Activity line, run Ctrl+Alt+Shift+F again), RunEntry clicks it after the Synopsis when the entry ends with `| end` (+1 key); {Bay} expanded by SavedBay() (LastUsed Bay if Bay.at < 14 h, else InputBox). (2) Box option `saved` ({Bay: saved}, ;end uses it): remember-writes now also store key.at = A_Now; ParseField sets f.savedVal when < 14 h; RunTemplate drops saved boxes from the form (merge()), no form at all when none left; BoxParse keeps `saved`. ;start still `{Bay: last}`. Wine tests pass (fake main + entry windows with a Now button). Before that **v3.20.1** (Oct 30: fix, the daily log form is its OWN Citrix window ("Daily Log Entry - N/A - \\Remote", wfica32.exe), not part of the "iTrak" window, so teaching failed ("click not inside the iTrak window"). Field spots now measured from EntryWin() ([ITrak] EntryWindow=); RunEntry snapshots EntryWins() before ITrakNewLog(false), waits up to EntryWait (8000 ms) for a NEW one, EntrySettle 600 ms, activates it. Wine fake with a second window opening at varying positions passes. Before that **v3.20.0** (Oct 30: (1) FULL-ENTRY DAILY LOGS: lines `+Name = Location | Topic | Reference | Synopsis` in templates.txt/my-templates.txt (ReadEntries -> global Entries; AddTemplates/CountTemplates skip "+" lines); Ctrl+Alt+F ShowEntryPick (edit + listbox, Up/Down via #HotIf, Enter runs RunEntry); RunEntry = ITrakNewLog(false) (now returns true/false, count param), Sleep [ITrak] EntryWait (1500), then for each field click the taught spot (itrak.ini [Fields] LocationX/Y TopicX/Y ReferenceX/Y SynopsisX/Y W H, client-area numbers, ITrakSpot) and type: Location/Topic EntryType (SendEvent {Text}, key delay 20) + Enter, Reference EntryType, Synopsis Paste(keep). Never touches End Time or Save. Keys counted: 2 + 5 per drop-down + len+1 for Reference and Synopsis; CountSaved("log", keys, "Full log: Name") + Journal. Ctrl+Alt+Shift+F TeachEntryFields (4 hovers + F8). Ready-made: Break, Table Drop, Card Destruction. Not shared with the team yet. UNTESTED against real iTrak/Citrix (Wine test with a fake wfica32 window: pick list, clicks, typing, paste, counts all OK). (2) SDS reminder: DoLogin no longer starts the log-in-again reminder (and deletes the saved LastLogin) when the login was typed into SDS with ResignMinutes on; registry "SdsLogin <user>"=1 marks it, ShowLoginReminder/AddLogin also skip for marked logins (before this only Window= containing SDS skipped). (3) Home window: the whole Shift group removed. Before that **v3.19.3** (Oct 29: (1) window layout told SDS and Alert Grid apart: both are javaw.exe and SaveLayout/RestoreLayout matched by exe + nth in front-to-back (WinGetList) order, so after SignInStarted brought SDS to the front it took Alert Grid's saved spot. LayoutKind(hwnd, exe) gives "AlertGrid"/"SDS"/"Java" for javaw windows (title start; title not saved), saved as kind= per [Wn] with [Layout] format=2; restore matches exe|kind. Old files (no format=2) keep the old matching and show a one-time MsgBox to re-save ([Layout] asked=1). (2) box option `several` (ParseField f.several, BoxParse keeps it): in FormPaste, multi Map; those boxes start empty (ClearBox), Add another pushes the box value into its list and clears only that box, preview/Submit build ONE entry with Joined() -> JoinList ("A, B and C"), duplicates dropped; also fixes Add another on forms whose only box is a list (Untouched ignores lists). templates.txt ;open/;auto = {Table: @tables | several | blank=XXXXX} ... {repeat}. Wine-tested with fake javaw.exe windows (old matching swaps them, new doesn't) and the forms; built with rebuild-resources.py on the v3.19.2 exe. Script-for-IT zip refreshed to v3.19.3. Before that **v3.19.2** (Oct 29: Alert Grid teach step 6, the click for the casino's new "no more alerts" box, last after the clear-acknowledged button. alertgrid.ini [Clicks] NoMoreX/NoMoreY (+ NoMoreBox = exact box title, spot measured from that box; empty = inside the Alert Grid window, AlertSpot like ClearX); ALERT_KEYS has them so Share my setup carries them; the clear code waits 0.8 s for the box (exact title, javaw.exe) after the ClearX click and clicks it; untaught = skipped; TeachAlerts ends in AlertTeachDone(). Built without running AutoHotkey (rebuild-resources.py on the v3.19.1 exe), not run under Wine. Before that **v3.19.1** (Oct 27: copyright and licence, step 1 of making it proprietary. COPYRIGHT constant ("Copyright (c) 2026 Jakob Blair Vanness. All rights reserved.") near VERSION; LicenceText() + ShowAbout() (tray "About Watchlog", home "Set up" tile); line also in ShowVersion, SecurityReport, cheat sheet foot (OK button moved to bottom + 62), small grey text under the tutorial buttons. LICENCE.txt: FileInstall'd by InstallBuiltIns, built in as RCDATA LICENCE.TXT (build.ahk list), copied by CopyForSharing; LegalCopyright in mk_resources.py. Release zip = exe + LICENCE/README/QUICK START/templates only; script zip lives in "for IT (on request)". Built WITHOUT running AutoHotkey: build/rebuild-resources.py rebuilds the .rsrc section on the v3.19.0 exe (same AHK 2.0.18 base); not run under Wine. Compile protection is nil: the script is plain text in RCDATA 1. Before that **v3.19.0** (Oct 27: iTrak new daily log: Ctrl+Alt+D ITrakNewLog() finds the Citrix window (ITrakWin(): [ITrak] Window= default "iTrak ahk_exe wfica32.exe", title like "iTrak - [Daily Log] - \\Remote"), activates it, MouseMove + Click on the taught spot(s) (1 or 2 clicks, Pause 300 ms between), puts the mouse back, CountSaved("", 2, "iTrak new daily log") (ItemKind "other"). Ctrl+Alt+Shift+I TeachITrak() writes itrak.ini [Clicks] X1 Y1 (X2 Y2) Clicks W H DPI measured from the client area; ITrakSpot() follows the nearest edge when resized (like AlertSpot); refuses when outside the window or off screen, or when resized and [ITrak] RefuseIfResized=yes. Team copy: itrak.ini beside the team templates, section Clicks-<A_ScreenDPI> (ITrakTaught() here/team/""); tray iTrak menu, Settings > Alert Grid tab, home tile, Security status line, cheat sheet. Wine-tested with a fake iTrak (10 cases pass); the teach step itself and the real Citrix click are untested. Before that **v3.18.0** (Oct 26: Alert Grid clear works on any layout: AlertLoad() reads alertgrid.ini [Clicks] (or the team copy, AlertTeamFile() = alertgrid.ini beside the team templates file, section Clicks-<A_ScreenDPI>, used only when this PC has no RowX); Basis=client means row/clear spots are measured from the client area (WinGetClientPos), old files are converted once with Alert Grid open; AlertSpot() keeps the clear button relative to its nearest edge using GridW/GridH (the row stays top-left); MenuLine= (teach last question / Settings) makes ClearAlerts use Down xN + Enter when AlertMenuFlips() (row + MenuDY + 60 past the work-area bottom) or after a missed menu click; refuses when the row spot is outside the window or off-screen; ShareAlertSetup() (tray Alert Grid menu, Settings button) writes the numbers to the team file; AlertTaught() = here/team/"" replaces FileExist(AlertFile) in Caps Lock, Settings and Security. Wine-tested with a fake Alert Grid (moved, resized, maximised, minimised, low on screen with and without MenuLine, shrunk, team copy, old file): all pass; real Java menu/arrow keys untested. Before that **v3.17.6** (Oct 26: Alert Grid clear "option A" speed pass Jakob chose: 5-point AlertColumn, ~20 ms Ctrl+A hold, SelectWait 120, no Caps wait; aim ~40-90 ms slower than the pre-3.13 clear, which went Ctrl+A, 40 ms, right-click). Before that **v3.17.5** (Oct 26: waits trimmed further after Jakob said v3.17.4 worked but was slower than before: modifier wait <=250 ms total, SelectWait 200, lone alert 50 ms, 5 ms poll). Before that **v3.17.4** (Oct 26: faster clear for busy lists, ~20 pixel reads, 15 ms polling; Jakob says up to a dozen alerts per second arrive, so keep ClearAlerts fast). Before that **v3.17.3** (Oct 26: lone-alert clear waits 100 ms via AlertIsPlain(column colours all equal)). Before that **v3.17.2** (Oct 26: single-alert Alert Grid clear was slow, wait cut to 300 ms, SelectWait default 300, no minimum). Before that **v3.17.1** (Oct 26: Alert Grid clear fix: ClearAlerts waits for modifier keys up (KeyWait), AlertSelectAll() sends held Ctrl+A, AlertColumn() samples pixel colours below the clicked row and the code waits (up to SelectWait, min 800) for a change, re-sending Ctrl+A at half time; Activity notes when no change was seen. Cause: Java grid missing a fast Ctrl+A burst, then the right-click only hit the first row. Wine-tested only with a fake list. Before that **v3.17.0** (Oct 26: journal edits count everywhere: Journal(title,text,keys) writes `HH:MM  Title  [k112]` (keystrokes saved); JournalStats strips the tag; on Save in Ctrl+Alt+J, JournalApplyEdit(old,new,day) diffs the log first-lines (LogsMissingFrom), removed logs go through AdjustCount/CountBump (ShiftItems, DayItems, Days, Shift Counts, clamped at 0) with their tag's keys (untagged old logs = average for the type), added logs count with their tag or 0 keys; renaming keeps the tag so keys move. Wine-tested with fake edits. Before that **v3.16.0** (Oct 26: Shift dashboard, Ctrl+Alt+Shift+D: ShowDashboard() with tabs This shift / Week / Month, Copy summary, Save as a sheet (HTML to HomeDir\Shift Reports); CountSaved also writes [DayItems] day|name=n,keys in time saved.ini (TrimDayItems keeps 400 days); ItemKind() splits logs / alert clears / other. Wine-tested (screenshots of all three tabs; fixed text-over-tab placement and an unassigned DashWin global) and exe built with build/build.ahk; zip Watchlog v3.16.0.zip; not yet tried on his PC. Before that **v3.15.0** (Oct 26: Ctrl+Alt+J journal window is editable: counts on top, the shift's whole text in an Edit below; Save merges with the file (keeps logs added meanwhile via a prefix/tail check, refuses if the file changed another way); closing asks to save. Cheat sheet redrawn as three teal columns (Section() helper, fixed 22 px rows). Security and status: traffic-light strip + Tab3 with one tab per report section (SecuritySections splits SecurityReport on capital-letter headings; Copy full report still copies the text). JournalStats(file, text) takes text. Wine screenshots checked). Before that **v3.14.2** (Oct 26, verification run: caps' n/a -> NRT/ATM only in boxes whose name has machine/nrt/atm (Location boxes left alone); autocorrect plurals for every entry (handpays -> hand pays); AutoFixEdit checks autocorrect.txt at most once a second; a call pad saved before a reload keeps its real age (PadStamp from the file time) so an old call can't fill forms; the template editor keeps the `tidy` option (it used to turn unknown options into list items); BUG FIXED: the form autocorrect hook tested Type(c) = "Edit", which is never true in AHK v2 (Type() gives "Gui.Edit"), so before v3.14 forms had no autocorrect at all; now c.Type. clip and fromcopy boxes now read CopiedText(), which ignores a log Watchlog itself left on the clipboard (LeftOnClip, set in Paste when keep): before, ;audit after ;account picked the account # as the Employee # and the job title out of the last log; settings.example.ini gained [AlertGrid], [Reminder], [SDS], [Updates]. Wine harness: all 35 templates build, pad shorthand, combos, undo OK). Before that **v3.14.1** (Oct 26: AutoFixEdit re-reads autocorrect.txt on every fix check, so # switching a word off works without reopening the pad). Before that **v3.14.0** (Oct 26: fixes from Jakob's first full test pass. New box option `tidy` (PadNote: bvs -> BVs, bvs divert -> BVs/Divert) on ;mfill's Note; `caps` also turns a lone n/a before one digit into NRT/ATM; autocorrect now hooks ComboBox boxes too (child Edit via FindWindowEx; NOTE control Type must be read as ctrl.Type, Type(ctrl) returns Gui.Edit) and fixes plurals of acronyms (titos -> TITOs); ;firm Department defaults to Operations Supervisor; cheat sheet shows (works in any program) for unlocked logins; Ctrl+Alt+L gaps shortened (500 ms between apps, 800 ms settle); Quick Notes Notepad warning forces title match mode 2; wording Oct 26, 2026 (1)). Before that **v3.13.1** (a v3.13.2 that added NRT5 was built and withdrawn on Oct 26: NRTs only go up to 4, Jakob was typing test logs; fill lines for machines that don't exist (n5) are ignored). (Oct 25: Time saved counts the keys typed on the call pad. PadKeys (keys typed on the pad for this call, stored in the call pad files as `start|keys`) is added to `typed` in FormPaste Submit (+2 for the + key and Ctrl+Enter) when pad data filled the form (padUsed); boxes the pad filled (padMarks) are skipped in TypedNow so nothing is counted twice; CallPadUsed() resets PadKeys. Wine-tested: 23 keys for a 2-line fill. Before that **v3.13.0** (Oct 25: call pad shorthand. CallPadMakeLog() now only copies PadText to the clipboard and hides the pad; PadParse(text) reads lines `n3 190800 bvs` / `a1 100000` (NRT1-4, ATM1-5, k = thousand; PadNote(): text with 'div' or 'bvd' -> BVs/Divert, bv/bvs -> BVs, else as typed) into hints["fills"] and `c2102 11421.11 win 3` into hints["jack"] (only when exactly one); PadFill() returns {n, rows}: for a form with a Machine list holding the fill machines (;mfill) FormPaste walks the rows with PadSetRow() + AddAnother() so every machine gets its own line; ;jack uses jack.machine/amount/window; Submit calls CallPadUsed() when pad data was used (call -> Earlier calls, pad emptied). ;mfill in templates.txt got `{Note: prefix=( | suffix=) | blank=}` (wording Oct 25, 2026 (3)): his Documents\Watchlog\templates.txt must be replaced. ClearAlerts() waits [AlertGrid] SelectWait (default 200 ms) after Ctrl+A instead of Pause*1. Tested under Wine (parsing, ;mfill 4 rows, ;jack, pad cleared); NOT on his PC. Before that **v3.12.1** (Oct 25: WAP and R4 taken out of the default autocorrect list at Jakob's request; otherwise v3.12.0 below). Before that **v3.12.0** (Oct 25: the call pad and casino autocorrect. Jakob gets most log info by phone call and held the phone with head and shoulder, so one-handed matters. ShowCallPad() (Numpad + via `#HotIf CallPadKeyOn()`, which is off while a Watchlog window is active so + still types in Watchlog's own boxes; Ctrl+Alt+N always; N added to taken app keys; `[CallPad] Key=off` frees +): small AlwaysOnTop window, Edit `Pad`, PadText/PadStart/PadStamp/PadHistory globals, saved 700 ms after typing to DataDir `call pad.txt` and `call pad history.txt` (this PC only, wiped by CallPadEndShift() from JournalEnd(), ignored after 14 h). Buttons: Make a log (Ctrl+Enter -> hide, ReturnTo target, ShowPicker), Copy all, Paste into window, New call, Earlier calls menu. PadHints() reads PadText (90 min) for machine `[A-Za-z]\d{3,5}|NRT\d|ATM\d`, a table from Lists["tables"], money ($4,000 or 4k), 8-digit alert #; only when exactly one distinct value. FormPaste calls PadFill() (labels containing machine, ^table, amount unless the form has Buy-in, tito value, ^alert #; list boxes only take an existing item) and tags the label '(from your call pad)'. Autocorrect: AutoMap from AutoDefault() (SOP glossary acronyms + handpay/cashbox/softcount/mainbank/shortpay) or, if it exists, HomeDir\autocorrect.txt (tray > Advanced > Edit the autocorrect list creates it; the file is then the whole list); LoadAutocorrect() re-reads on mtime change; AutoFixEdit(ctrl) is an Edit Change handler using EM_GETSEL/EM_SETSEL/EM_REPLACESEL (undoable), works on a LF copy of the text and converts positions (Edit counts CRLF as 2), fixes a word when a space, newline or . , ; : ! ? ) follows it; attached to the pad and to every plain Edit in FormPaste. Jakob OK'd MEAL RAM WAN GM (WAP and R4 off from v3.12.1) (the glossary is Confidential: only acronym spellings are kept). Tested under Wine (autocorrect incl. across a line break and Ctrl+Z, hints, form fill, end-of-shift wipe); NOT tested on his PC. Not built yet: shorthand-to-log formatter (needs his examples). Before that **v3.11.0** (Oct 25: the shift count. CountSaved(kind, keys, name := "") now also tallies per item in time saved.ini section [ShiftItems] (name=times,keys; "=" in names becomes "-"; the section is deleted when a new shift starts in CountSaved or by the Start a new count button, which sets Shift Ended=1). Names: template title, "Login "+trigger, "Stamp `;t/dd/dt", "Alert Grid clear", "Switch to "+app (SwitchTo, keys 0). ShowShiftCount() (tray, home tile, button in Time saved) lists them most used first with totals and Copy report. Tested under Wine (counts and window); not tested on his PC. Before that **v3.10.1** (Oct 25: SDS signs back in by itself. DoLogin starts StartSdsResign() when the active window title starts with SDS (62 min, `[SDS] ResignMinutes=`, 0 = off, Cfg SdsResign, last login in HKCU LastSDSLogin so a reload resumes it); SdsResignDue() finds the SDS login screen (SdsLoginScreen(): title ^SDS without Welcome), waits for 1.5 s of no typing (max 15 s), activates it, DoLogin via LoginForWindow(), puts the previous window back; still Welcome -> looks again every minute up to 6 times (SdsTries). ShowLoginReminder returns silently for a login whose Window= contains SDS while this is on. Settings > Logins has a tick box + minutes. Tested under Wine against a fake SDS (javaw.exe copy): login typed, previous window put back, nothing typed while Welcome; not tested on his PC. Before that **v3.10.0** (Oct 25: the visual menus. (1) Watchlog home window: ShowHome(), a plain click on the tray icon (A_TrayMenu.Default + ClickCount 1) or Ctrl+Alt+M (M added to the taken app keys); big IconButton tiles in groups Logs / Shift / Logins (one per LoginList entry, HomeLogin(): a locked login brings its window up, an unlocked one asks first) / Set up, plus a status strip (version, templates, Alert Grid taught, this shift) and Caps guard / pause ticks; WorkWindow() finds the window to type into after a tray click. (2) Tray menu rebuilt by BuildTrayMenu(): A_TrayMenu.Delete() drops the AutoHotkey items; sub-menus Alert Grid, Windows (WinMenu holds the Caps guard tick), Advanced (Security, Activity log, share copy, Notepad editing, folder, update folder, Pause, Reload); Exit at the bottom. (3) Icons: GlyphIcon() draws a glyph from Segoe Fluent Icons / Segoe MDL2 Assets into a 32-bit HICON (none if neither font file is in C:\Windows\Fonts); MenuItem() and IconButton() use it. (4) Settings in six tabs (Tab2, white BackColor: Tab3 drew every label black under Wine): Logins, Templates, Start / end of shift (SignIn, AfterStart, LaunchWait, LaunchWork, ChromeAccount, [EndOfShift] Close), Alert Grid (taught?, Teach button, CapsLockClears, Pause), Updates ([Updates] Folder + what is waiting there, ProgramVersionOf()), General (journal, Caps guard, start with Windows). Only changed values are written. LoadSettings now treats [StartOfShift] as custom only if it has a RunN= line (Settings can write SignIn= alone). (5) Template editor ShowEditor(), Ctrl+Alt+E (Notepad editing moved to tray > Advanced): works on the file as lines (EdRead/EdScan/EdLine/EdWrite), only changed lines rewritten, section headings from "# ----- NAME -----"; box form BoxForm() with BoxParse/BoxBuild (12 kinds from BoxKinds()); preview EdPreview() never reads the clipboard; EdProblems() checks clashes, braces, lists; Save backs up to %LOCALAPPDATA%\Watchlog\template backups (last 20), bumps "# Wording version" (main file only), asks once before writing the team file and if the file changed since opening; reload happens when the editor closes (CheckForEdits waits while EditorWin is open; shortcuts are off in the editor via SettingsActive()). Refactors: QuickNote(), StartOfShift(), SDSLogout(), TogglePause(), MakeMineFile(). Tested under Wine (round trip of every template line and box, add/change box, new template, lists, save, close, settings tabs); not yet tested on his PC. Before that v3.9.5 (Oct 25: plain Caps Lock (guard on, caps off, Alert Grid open and taught) calls ClearAlerts(); [AlertGrid] CapsLockClears=no turns it off; otherwise the old "hold Shift" tooltip. Jakob picked Caps Lock as a one-key shortcut. Needs the Caps Lock guard on. Before that v3.9.4 (Oct 25: login reminder beep is an option again: Settings > Login reminder checkbox, [Reminder] Beep=yes|no, default no (Cfg ReminderBeep). Before that v3.9.3 (Oct 25: login reminder no longer beeps (SoundBeep removed from ShowLoginReminder; the Ctrl+Alt+P pause beep stays). Before that v3.9.2 (Oct 25: ClearAlerts faster (waits 40 ms between clicks, [AlertGrid] Pause= in settings.ini sets it, no fixed sleeps after the dialogs) and retries up to 3 times if the Acknowledge box or the Successful box does not show (a new alert re-draws the list and drops the selection). Fake Alert Grid still clears. Real timing not tested. Before that v3.9.1 (Oct 25: each Alert Grid clear adds 3 keystrokes to Time saved (CountSaved("", 3), keys only, no log/login/stamp count; CountSaved skips the category when kind is ""). Before that v3.9.0 (Oct 25: (1) SwitchTo offers a login after bringing a Bally program (path has SDSUI/CMPDesktop/AlertGridUI) to the front, or after launching it and waiting for its window: OfferLogin() asks (T6 = no on timeout) and DoLogin()s the login whose Window= lock matches the active window (LoginForWindow()); login rec now keeps pw=fallbackPw. (2) Ctrl+Alt+L: SignInStarted(startedApps) after the apps' windows are up, only for apps it just opened, one Yes/No question (T20 = no), then activate + 1.5 s + DoLogin + 3 s each; [StartOfShift] SignIn=no turns it off. (3) [Updates] Folder= (Cfg UpdateFolder) replaces the team folder as the source in TeamProgramFile(); tray "Choose my own update folder" (DirSelect, writes settings.ini, reloads). Tested under Wine: sign-in into a fake SDS window (user, Tab, pw, Enter typed); real programs not tested, nor whether focus is in the username box on launch. Before that v3.8.5 (Oct 25: 5th teach spot, the button that clears the acknowledged alerts (ClearX/ClearY inside the Alert Grid window), clicked at the end of ClearAlerts if taught. Re-teach needed to add it. Before that v3.8.4 (Oct 24: teach has a 4th spot, the OK button of the Acknowledgement Successful box (OkX/OkY inside that window); ClearAlerts clicks it, or presses Enter if none taught. Before that v3.8.3 (Oct 24: teach step no longer uses #HotIf TeachMode hotkeys (his F8 presses did nothing); TeachWait polls GetKeyState for F8 or Ctrl+Alt+Shift+A, Ctrl+Alt+Esc cancels, TeachBusy guard, TeachRun wrapped in try with an error box; TeachBusy and NotesWin initialised at the top with the other globals. Polling not testable under Wine. Before that v3.8.2 (Oct 24: Jakob's first runs were "cancelled" in the activity log: the teach step swallowed Esc, which he presses to close the right-click menu. Cancel is now Ctrl+Alt+Esc and Esc passes through. Before that v3.8.1 (Oct 24: teach step also accepts Ctrl+Alt+Shift+A as the capture key (F8 may need Fn on his laptop; his first teach run ended silently, no Saved message), and cancel/timeout now show a tooltip and log it. Before that v3.8.0 (Oct 24: Alert Grid clear-all. Ctrl+Alt+A = ClearAlerts(): finds window ^Alert Grid \( (javaw.exe), activates it, Click row / ^a / right-click row / click menu item at taught offset / waits for window ^Acknowledge$ and clicks Submit at taught offset inside that window / waits for ^Alert Grid$ box and sends Enter / restores mouse and previous window. Ctrl+Alt+Shift+A = TeachAlerts(): F8 at three spots (TeachMode #HotIf), saved in %LOCALAPPDATA%\Watchlog\alertgrid.ini (RowX/RowY inside Alert Grid window, MenuDX/DY from the row click, SubmitX/Y inside the Acknowledge window). A added to taken app keys, tray items, cheat sheet. Never types the password (the Acknowledge box has login/password filled). Jakob chose clear-everything (no alert-type whitelist). Tested under Wine against a fake javaw.exe Alert Grid (full flow); teach step (F8 hooks) and the real Alert Grid NOT tested. Before that v3.7.1 (Oct 24: Quick notes fix. Jakob saved a stale Notepad tab of Quick Notes.md over new notes. Ctrl+Alt+O is now ShowNotes() (Watchlog window, reads file fresh, RefreshNotes after Ctrl+Alt+Q, MergeNotesBackup moves the this-PC backup into Quick Notes.md); Ctrl+Alt+Q warns if a Notepad window titled Quick Notes is open. Tested under Wine (save, merge, refresh); exe rebuilt. Before that v3.7.0 (Oct 24: window layout and Caps Lock guard moved in from Desk Helper. SaveLayout/RestoreLayout(auto)/LayoutSkip (skips own PID, AutoHotkey*, minimised, tool windows), layout.ini in DataDir (exe name + nth + x,y,w,h,max, matched by exe and z-order), ^!+s save, ^!w restore; Ctrl+Alt+L calls RestoreLayout(true) after CitrixTab and before KeepChromeFront (re-activates the window that was active; `[Layout] AfterStart=no` off). Caps: `#HotIf CapsGuard` $CapsLock / $+CapsLock, BuildCapsTag/CheckCaps timer 150 ms, no beeps (coworkers), guard saved in last used.ini [Caps] Guard, tray toggle CAPS_MENU. Tray menu renumbered (23 items). W added to taken app keys. Tested under Wine: layout save/restore with two Notepads, caps tag/toggle; exe built from the v3.6.0 exe as base (resources replaced) and /selftest OK. Real CapsLock presses and Ctrl+Alt+L auto-restore not tested. Overviews/IT summary not updated yet. Before that v3.6.0 (Oct 22: ;face fills alert # and match % from your last two copies in Edge (CopyMemory, NoteCopy via OnClipboardChange, in memory only, 8-digit alert / number%, 2 min, ForgetCopy after insert; alertcopy keeps the last alert # in last used.ini and warns SAME/LOWER); ;audit Employee type opens on the job title found in the copy (fromcopy, TitleFromCopy), clip boxes take a number out of a longer copy (NumberFromCopy). Pick-or-type list boxes complete as you type (Complete() inside FormPaste, CB_SETEDITSEL, only when text grew). New box options alertcopy, matchcopy, fromcopy. Wording version Oct 22 2026 (6), new ;man template (garbage sweep). Logic tested under Wine; real Edge copies not. Before that v3.5.0 (Oct 22: Watchlog.exe + one-step install + tutorial. Built with build/build.ahk + build/mk_resources.py (AutoHotkey 2.0.18 64-bit base exe, script in RCDATA #1, FileInstall resources TEMPLATES.TXT/README.TXT/QUICK START.TXT/LAUNCHWORK.BAT, icons 101-108 + group 159 from Watchlog.ico, version resource); HomeDir = script folder, or Documents\\Watchlog for the exe unless settings.ini sits beside it; exe self-installs to %LOCALAPPDATA%\\Programs\\Watchlog (+ Start menu, Startup, Uninstall key, /uninstall), /selftest arg, CloseOtherCopies also closes a running Watchlog.ahk, first run offers to copy settings from Documents\\AutoHotkey; self-update works with Watchlog.exe in the team folder (running exe moved to backup, new copied in, restarted); ShowTutorial() (6 pages, practice boxes, TutorialWin flag keeps journal and time saved clean); tray > Tutorial. Tested under Wine: install, 6 tutorial pages, uninstall, exe self-update, settings copy, update over installed copy. Not testable under Wine: typing triggers into the practice boxes. Before that v3.4.3 (Oct 22: login window lock takes several programs separated by `|` (LoginWindowActive splits on |), re-checked in DoLogin just before typing; LoginBox in Settings has a Pick window button (PickWindow(): `#HotIf PickMode` LButton/Esc hotkeys, globals PickMode/PickHwnd declared at the top; Citrix gets ahk_exe wfica32.exe, browsers/Java get title + ahk_exe); Settings list shows "(any program)" for unlocked logins and the Security report flags them. Lock test of LoginWindowActive and validation done under Wine; the click itself (hook) can't be tested there. Before that v3.4.2 (Oct 21: ;audit Location box now has `caps` (m3 gives M3); window-title reads in the start-of-shift Chrome code go through SafeTitle() so a Chrome window closing mid-read can no longer show an error box; Ctrl+Alt+L header comment updated to the v3.4.0 order. Wording version Oct 21, 2026 (3). Validated and the ;audit form driven under Wine. Before that v3.4.1 (Oct 21 housekeeping: Log Templates.ahk stub retired (moved to archive/, no longer in the zip or repo, README updated; the script's one-time MoveFromOldName code stays), old release zips moved to archive/old-releases/. Oct 21: new box option `suffix=` (added after what you type, only if something is typed; applied after prefix= in Collect). Used in ;refuse: `{Signs observed: prefix=( | suffix=) | blank=}` gives "...due to showing signs of intox (slurred speech)." and nothing when empty (the empty box also drops the space before it). ;refuse replaces ;noid/;insuf/;expired/;intox (Jakob merged them; 33 templates). Tested under Wine by driving the real form. Before that v3.4.0 (Oct 21: start-of-shift order changed at Jakob's request so apps don't fight for the screen: [StartOfShift] apps first (1 s apart), wait for their windows (LaunchWait, now at least 20 s, default 20), 1.5 s settle, THEN LaunchWork.bat websites, then CitrixTab and KeepChromeFront. Validated only (Ctrl+Alt+L hotkey body can't be called under Wine). Before that v3.3.3 (Oct 21: Jakob: SDS pops up after the Chrome tabs and takes the screen; he signs into Citrix first. KeepChromeFront(started) runs a 500 ms timer for 25 s after CitrixTab: if a window of an app it opened (the started titles) becomes active, it re-activates the Chrome window showing the Citrix tab (max 6 times) and logs "Citrix tab: X came to the front, Chrome put back on top". State kept in an object, not a captured variable (AHK v2 has no nonlocal). Tested with a fake late window under Wine. Before that v3.3.2 (Oct 21: CitrixTab matches any of several "|"-separated words (default Citrix|apps.gcgaming.com, and the domain is always added), because Jakob found a tab that is still opening is named something else than "Citrix Workspace"; new TabHas(). Before that v3.3.1 (Oct 21: CitrixTab() first looks through every titled Chrome window for the Citrix tab, takes the focus back up to 3 times if another window (Java app) steals it while cycling tabs, and writes what happened to the activity log ("Citrix tab: found it / not found, tab titles seen: ... / gave up, focus kept leaving Chrome"). Jakob: the tab is titled "Citrix Workspace" and Chrome does come forward but not onto that tab; cause not confirmed, so check the activity log after Ctrl+Alt+L. New ChromeWindows(). Tested with a fake Chrome under Wine. Before that v3.3.0 (Oct 20: Ctrl+Alt+K = LogOutSDS() on its own (K added to taken keys, cheat sheet). Self-update: TeamProgramFile() = Watchlog.ahk in the folder of [Templates] Shared=; CheckForUpdate() at startup (before AnnounceVersion, which skips its out-of-date box when the update is waiting) and the file is watched, so a change reloads and re-offers; Yes -> /Validate the copy, back up this file to %LOCALAPPDATA%\Watchlog\Watchlog vX (backup).ahk, FileCopy over A_ScriptFullPath (+ .ico), Reload; Later = not asked again this run. LastUsed now in %LOCALAPPDATA%\Watchlog\last used.ini (settings.ini [LastUsed] read as fallback), so ;start doesn't make OneDrive sync settings.ini. Tested under Wine: update 3.3.0 -> 3.4.0 from a team folder, broken copy refused, bay remembered locally, SDS logout. Before that v3.2.1 (Oct 18: Citrix paste fix. iTrak sometimes got nothing, not even on a manual Ctrl+V, after a ;audit whose employee # came from an iTrak copy. Paste() no longer calls ClipboardAll() or empties the clipboard when keep is set or the target is wfica32.exe (Citrix = keep, log stays on clipboard); it sets A_Clipboard once, waits 300 ms before ^v in Citrix. Not testable under Wine (no Citrix); Notepad paste and restore for non-Citrix instant templates re-tested. Before that v3.2.0 (Oct 18: time saved tracker, the supervisor's idea for hard numbers. CountSaved(kind, keys) after every insert: instant template = len(out) - len(trigger); form = len(all entries) - len(trigger) - TypedNow() per entry set (1 per box + length of each changed box, a list pick = 1, blank box = its placeholder length so XXXXX saves nothing); login = len(user)+len(pw)+2 - len(trigger) (pw length only, never stored); ;t/;dd/;dt = 4/7/14. %LOCALAPPDATA%\Watchlog\time saved.ini: [Days] yyyy-MM-dd=logs,logins,stamps,keys; [Shift] Start/Last/Counts/Ended (new shift after JournalEnd or 6 h idle); [Info] First. Tray > Time saved (6th item, menu renumbered): ListView this shift/today/7/30 days/since first + Copy report; Ctrl+Alt+J shows this shift's time and a Time saved button; Security and status lists the file. 200 keystrokes/min = 40 wpm. RunTemplate/MakeTemplateHandler/FormPaste take the trigger. Tested under Wine. Before that v3.1.2 (Oct 18: EndOfShift calls LogOutSDS() first: finds the javaw.exe window titled ^SDS.*Welcome, the ToolbarWindow32 with exactly 5 buttons (TB_BUTTONCOUNT), clicks button 4 at TB_GETBUTTONSIZE width*3.5 (ControlClick NA, then a real Click fallback), waits for the #32770 javaw dialog containing "logged out", ControlClicks Button1 (checked to say Yes), success = dialog gone and no Welcome window within 10 s; any failure -> OKCancel MsgBox asking to log out by hand, Cancel closes nothing; steps logged to the activity log. Tested under Wine against a fake SDS (AHK copied as javaw.exe with a real toolbar). Before that v3.1.1 (Oct 18: Ctrl+Alt+L no longer brings iTrak to the front (Jakob: it never worked) and has no fixed 5 s wait; Bally apps 1 s apart with no trailing pause, waits for their windows up to LaunchWait, then CitrixTab(sites) activates the front titled Chrome window and Ctrl+Tabs until the title contains [Paths] CitrixTab (default Citrix; a loading tab's title is its URL, which has Citrix in it), up to 3 rounds / 15 s when the sites were just opened, stopping back on the start tab or if focus leaves Chrome. iTrakWindow setting dropped. Tested with a fake Chrome under Wine. Before that v3.1.0 (Oct 18: optimization pass, no wording or behaviour changes: SetWinDelay 10 / SetControlDelay 0 / ListLines False / KeyHistory 0 at the top; Tip(msg, ms, center) helper with a named ClearTip timer replaces the ad-hoc ToolTip+closure timers; ReturnTo(hwnd) shared by form Submit and the finder (non-Citrix wait 100 -> 50 ms, Citrix 400 kept; Paste's clipboard-restore waits unchanged); ParseFields reads [LastUsed] once per form and passes it to ParseField; preview only redraws when its text changed; forms use Segoe UI, margins 14/12, gaps between boxes, shaded preview, Cancel + Insert (or Add another + Insert) bottom-right; reminder/journal windows Segoe UI; cheat sheet tray-icon wording fixed. Before that v3.0.2 (Oct 18: `thousands` option on money boxes, used by ;player Buy-in/Amount: a number with a decimal point x1000, 3.3 -> 3,300; whole numbers unchanged. Before that v3.0.1, Oct 17: login reminder bottom-right + Esc closes it from anywhere via `#HotIf IsObject(ReminderGui)`; live "How it will look" preview Edit in FormPaste (Collect(false) = no LastUsed writes); `{Amount: if ATM=100000}` option fills a box while another box starts with ATM unless typed over; digits-only in a list box map to the unique item matching `^\D*<digits>$`; `;open`, `;mfill` (several per log), `;fill` {repeat}. Renamed to Watchlog (Jakob picked it Oct 18, then asked for everything renamed): Watchlog.ahk + Log Templates.ahk stub; MoveFromOldName() on start closes the old process, moves %LOCALAPPDATA% folder, HKCU key, Startup .lnk; credentials migrate lazily in CredLoad (tested under Wine); IconFile = Watchlog.ico next to the script (TraySetIcon, startup shortcut, share copy; icon source icon/make-icon.py, teal so it differs from Round's navy). OneDrive-not-running MsgBox on load removed (Jakob, Oct 18); `# Program version: X` line in templates.txt (Tpl.program) drives OutOfDate()/VersionStatus(): load MsgBox + tray tip/menu "update needed" + version box/Security report; ProgramCode() = CheckCode of the .ahk. ;expired added. Tested under Wine. Before that v3.0, Oct 16: team edition, focused on security, tracking and sharing. `[Templates] Shared=` points at the team's templates.txt in a SharePoint library synced by OneDrive; it's read on load, cached to %LOCALAPPDATA%\Log Templates\team templates (last good copy).txt, and used from the cache (with a note + TrayTip, retry every 60 s) when SharePoint can't be read. `# Wording version: ...` line + a CRC32 check code (XXXX-XXXX, CRLF-normalised) identify the wording; changes are logged with old -> new code. my-templates.txt (same folder as the script) adds personal templates marked (mine); a trigger already in the team file is skipped and reported. Ctrl+Alt+E opens my-templates.txt when a team file is set. First run (no settings.ini) offers to restore the newest settings-*.ini OneDrive conflict copy, else writes a fresh settings.ini and opens the Settings window as a Welcome. Tray > Settings: logins ListView (Add/Edit/Change password/Remove; passwords go straight to Credential Manager, Remove deletes the credential), team templates Browse/Clear, journal Save + KeepDays (7/14/30/60/90/365/never, default 30), start with Windows (Startup-folder shortcut). Typed triggers don't fire while Settings is active. Tray > Change a login password is gone (it's in Settings). Journal files older than KeepDays are deleted on load and every 6 h. Activity log %LOCALAPPDATA%\Log Templates\activity.log (start/exit, templates loaded/changed, settings saved, password moved/saved, login used, errors by line; never passwords or log text; halved at 200 KB). Tray > Security and status: live report (passwords per login, settings.ini password check, template source/version/check code, journal mode/folder/retention, everything else stored, what it never does, conflict copies) with Copy report. Tray > Make a copy to share: copies the .ahk, templates (the team file if set), QUICK START.txt, README.txt, settings.example.ini (generic, no real usernames) and LaunchWork.bat into <folder>\Log Templates v3.0; never settings.ini, my-templates.txt, journal, notes or activity log. New QUICK START.txt (one page). Tested under Wine with fake logins; hotstring firing and the Settings guard against typed triggers couldn't be tested there. Wine gotchas: a reload leaves Wine's "Could not close the previous instance" prompt (the old process exits slowly), so the harness runs a clicker; TestRun must wait for startup MsgBoxes; never name a local after a function. Jakob chose the approval route over a no-install HTML version). Oct 16 (templates.txt only, no version change, wording version "Oct 16, 2026 (2)"): `;selfex` Self-exclusion (quick) and `;found` Abandoned credits - taken to Security (Amount money, Machine caps). `;found` is the unclaimed case; `;abandon` stays for when the patron is found and paid. 33 templates. Before that **v2.9** (Oct 16: template finder. Ctrl+Alt+Space or tray > Find a template opens a search box + ListView (Shortcut / Template / Type) + read-only preview with blanks shown as [Name] + a line naming the trigger to type next time. Search (`FindTemplates`): lowercase, non-alphanumerics (except #) become spaces, so ;bv = bv; every word must match the trigger, name or wording; score trigger exact 100 > trigger prefix 60 > name word start 40 > trigger/name contains 20 > wording word start 10 > wording contains 5; ties keep templates.txt order; empty search lists everything. Up/Down/PgUp/PgDn/Enter are #HotIf PickerActive() hotkeys so they work while typing in the box; Enter/double-click/Insert closes it, re-activates the window you were in (Citrix wait) and calls RunTemplate. A full trigger typed in the box fires its hotstring, and RunTemplate closes the finder first; DoLogin returns without typing while the finder is active; ;t/;dd/;dt sit under #HotIf !PickerActive(). If a form is open the hotkey goes back to the form. TemplateList entries now carry `text`. Cheat sheet top line and first-run welcome mention it. Tested under Wine: search ranking, insert of a form (;fill) and an instant (;drop) template into Notepad, preview follows the selection, Esc/toggle close, login guard. Wine's keyboard hook doesn't see sent keys, so hotstrings and the Up/Down/Enter hotkeys were tested by calling their functions. Wine test gotcha: a long harness needs a long enough wait loop, or it looks like a hang). Before that **v2.8.2** (Oct 16: several machines in one `;bv` log. `{repeat}` in a template line (stripped at load) gives the form an "Add another (Ctrl+Enter)" button: it saves that entry, clears the boxes back to their starting values (lists to their first/next choice), and counts in the title ("(2 added)"); Insert joins all entries with new lines; a last set with no plain box typed in is skipped. One journal entry for the lot. Tested under Wine: A1234 #5678 (Full) + B2345 (Defective) pasted as two lines, single-machine and ;fill unchanged. Ctrl+Enter itself couldn't be tested under Wine (its keyboard hook doesn't catch it; the GUI took it as the default button), so on Windows it relies on the same #HotIf hook as Enter. Before that **v2.8.1** (Oct 16: Ctrl+Alt+J said "No logs saved this shift yet" even though the journal file had entries with time lines (Jakob confirmed). Cause (found later under Wine): `A_LoopFileName > newest` with newest = "" throws "Expected a Number but got an empty string" in AHK v2, so after the first log every write fell back to %LOCALAPPDATA% and Ctrl+Alt+J found nothing. Lesson: never use < or > on strings that can be empty; use StrCompare(). AHK can be run in the container: ahk-binary from PyPI + wine64/xvfb from apt. v2.8.1 tested OK under Wine; rewrote the lookup to find the file by date (today, then 1-2 days back) with FileExist instead of Loop Files + regex + string >, counted with a forward LastPos() instead of reverse InStr, sorted without Sort(), and made Ctrl+Alt+J say which case it hit (no file, folder error, read error, no time lines) with the error text). Before that **v2.8** (Oct 15: shift journal. Every inserted template (quick or form, never logins) is appended to `Documents\Shift Journal\yyyy-MM-dd.txt` (date the shift started) as `HH:mm  Name` plus the text indented 7 spaces. A shift starts with a `=== Shift started ... (PC) ===` line; it ends with `=== Shift ended HH:mm ===` written by Ctrl+Alt+Shift+L (on Yes), or after 6 h with no logs. The newest file by name is continued while open, so night shifts past midnight stay in one file. Ctrl+Alt+J / tray > Shift journal shows counts per template name for the last shift, Copy summary (one line: `Shift summary (first - last): N logs. 12 Audit, ...`) and Open journal. `[Journal] Save=full|counts|off` (default full). OneDrive down: falls back to %LOCALAPPDATA%\Log Templates\Shift Journal (this PC) with one TrayTip. J added to taken app keys. Jakob asked for it on Oct 16 after being told to check with his manager about keeping log text outside iTrak; Save=counts is the answer if not allowed). Before that **v2.7.2** (Oct 15: `@name = A | B` lines in templates.txt are shared lists used as `{Table: @tables}`; `@tables` drives ;fill, ;cards, ;auto, ;player; unknown list names are reported with the line number. `caps` blank option uppercases words containing a digit (b1410 -> B1410, "nrt2 and nrt4" -> "NRT2 and NRT4"), on every machine box incl. ;abandon Found at/Patron found at. `;credits` renamed `;abandon`. ;medical has a "What the review showed" box; ;account has an Account # box (`blank=`, so the # stays when empty; no clip, Jakob doesn't copy them); ;insuf says "refused one patron entry"; ;player buy-in gets a $. Ctrl+Alt+L asks "Open them again?" (default No) before LaunchWork when Chrome or Edge has a titled window open. Jakob tested all of v2.7.1 on Oct 15 and it worked apart from the duplicate tabs). Before that **v2.7.1** (Oct 15: `;audit` has Jakob's 27 employee types, Dealer first/default; form lists show up to 12 rows). Before that **v2.7** (Oct 15: all templates fire instantly `:*C:`, Space/Enter within 500 ms after a trigger is swallowed, script rejects triggers that are a prefix of another (incl. logins); `;count` renamed `;countstep`; forms focus first empty-or-list box; built-in app hotkeys T Teams (msteams:), U Outlook (shell:AppsFolder AUMID), Y Spotify (spotify:), G Chrome, overridable by [AppN] with same Name, Key=none disables; link-style Paths skip the file check; Ctrl+Alt+T find-notes-by-tag removed; Jakob confirmed all four app hotkeys open and switch correctly, Oct 15). Before that **v2.6** (Oct 15: version shown on tray hover, top of tray menu (click = version + OneDrive status), a corner note on every load, cheat sheet title; startup warning when OneDrive.exe isn't running. Bump VERSION and VERSION_DATE with every change). Before that **v2.5** (Oct 15: forms leave the log on the clipboard and wait for Citrix to take focus back before pasting; `prefix=` blank option; empty blank drops the space before it; Quick Notes falls back to %LOCALAPPDATA%\Log Templates\Quick Notes (this PC).md when OneDrive isn't running; ;fill/;cards table list UT201 FB202 UT203 RO204 BJ205 BJ206). Before that **v2.4** (login reminder via `Remind=` minutes per [LoginN], last-login time kept in HKCU\Software\Log Templates so reloads don't reset it; auto-reload when templates.txt/settings.ini saved, skips while a form is open or a file is missing; script's own LastUsed writes don't trigger it). Before that **v2.3.2** (Ctrl+Alt+L ~5 s: websites first, Bally apps 1 s apart, LaunchWait = total seconds, default 5, no 15 s iTrak wait). Before that **v2.3.1** (Ctrl+Alt+L skips Bally apps whose window is already open). Before that **v2.3** (Oct 14: start-of-shift websites open in the Chrome profile for `ChromeAccount` in settings.ini; OLG iTrak page now opens in Chrome too). Before that: **v2.2.1** (Oct 14: safer logins, passwords in Credential Manager, any-version Bally paths, soft count next step; 2.2.1 reports why a password couldn't be moved). Oct 14: logins working on 2.2.1 with `;` triggers (confirmed by Jakob).

---

## Files (all live in `Documents\AutoHotkey\` on the work OneDrive)

| File | What it is | Who edits it |
|---|---|---|
| `Watchlog.ahk` | The program (renamed from Log Templates.ahk in v3.0.1) | Claude / rarely |
| `Watchlog.ico` | Tray/shortcut icon (source: icon/make-icon.py) | Rarely |
| `templates.txt` | Wording of every template, plain English | Jakob, or a supervisor later |
| `settings.ini` | Personal: logins (trigger, user, optional window), LaunchWork path, start-of-shift programs, app hotkeys, end-of-shift list, last-used values | Each person. Since v2.2 it holds **no passwords** (they're in Windows Credential Manager on each PC). Still don't share it. `settings.example.ini` is a copy. |
| `LaunchWork.bat` | Opens the work websites (lives in `Documents\`, not the AutoHotkey folder). Since v2.2 the Bally apps are opened by the script instead. | Claude / Jakob |
| `Quick Notes.md` | Created by the notes hotkey in `Documents\` | Automatic |
| `my-templates.txt` | v3.0: the operator's own extra templates, merged with the team file | Each person |
| `QUICK START.txt` | v3.0: one-page setup guide for a new operator | Claude |
| `%LOCALAPPDATA%\Watchlog\` (was `Log Templates` before v3.0.1, moved automatically) | v3.0: activity.log and the team templates last good copy (this PC only) | Automatic |

Startup: a shortcut to `Watchlog.ahk` (Watchlog.lnk) in `shell:startup` on each PC (the Startup folder does not sync between PCs).

---

## Features

**Templates** (`;trigger` + space/Enter). Defined in templates.txt. A template with `{blanks}` becomes a fill-in form automatically.
- Form keys: Tab / Shift+Tab move, Enter inserts, Esc cancels. Blank box keeps its placeholder.
- Options inside a blank (combine with `|`): `now`, `now+20`, `time`, `money`, `percent`, `clip`, `last`, `next` (list opens on the item after last time's; used by `;count`), `pick`, `blank=XXX`, or a list of choices (first is the default).
- `a/an {Who: ...}` picks the right article. `\n` = new line.

**Current triggers** (31): jack, audit, medical, evict (trespass; Reason and Length are pick-or-type lists, added Oct 16, templates.txt only), face (Result stays a plain box: Jakob says it's always Rejected) · start, end (ask bay, remember last) · interior, exterior, parking, noid, insuf, intox (form: Signs observed, in brackets; added Oct 16, templates.txt only), inventory, account, drop · close, auto, cards, fill, player · bv, abandon, aml, maint · countstep, counttables, countslots, countpull · destroy, badge — all prefixed with `;`. Since v2.7 they fire instantly (no Space/Enter), so no trigger may be a prefix of another.

**Stamps:** `;t` = @21:42, `;dd` = date, `;dt` = date + time (fire instantly, no space needed).

**Logins** (settings.ini `[Login1..9]`, fire instantly): `;prd`, `;jakob`, `;jv`. Types user, Tab, password, Enter. One app needs logging into every hour.
- Optional `Window=` per login limits it to one program (uses `HotIf`).
- Passwords live in Windows Credential Manager as "Watchlog: <username>" (CredLoad moves an old "Log Templates: <username>" one on first use) (persist = this PC only, doesn't sync). On load, any password still in settings.ini is saved there, verified, then deleted from the file. A login with no saved password asks once (masked). Tray > Change a login password.
- Startup warns about any login trigger with no `;` and no `Window=`.

A supervisor sets phone reminders for the hourly login; the Remind feature is for him too (team version).

**Hotkeys (Ctrl+Alt + …):** Q add note · O open notes · T Teams · U Outlook · Y Spotify · G Chrome · S SDS · C CMP · I window info · L start of shift · Shift+L end of shift · E edit templates · H cheat sheet · P/X pause · R reload.

**Tray menu (right-click the H):** Cheat sheet, Edit templates, Edit settings, Open script folder, Change a login password, End of shift.

**Start of shift (Ctrl+Alt+L):** opens `[StartOfShift] Run1..9` 2 s apart (defaults to AlertGrid, SDS, CMP if the section is missing), runs LaunchWork.bat hidden (websites), waits `LaunchWait` seconds (default 10), brings iTrak to front, then lists anything not found.

**Wildcard paths:** a `*` in an app or StartOfShift path matches any version folder; the newest (by the numbers in the name, so 15_14_2 > 15_9) that exists wins.

**End of shift (Ctrl+Alt+Shift+L):** confirm (default No) → normal-close every window of the listed programs → after 5 s, offers force-close for anything left (default No). explorer.exe is special-cased: only File Explorer windows (`ahk_class CabinetWClass`), never force-killed (it runs the taskbar).

---

## Work environment details

- Oct 15: on one bay OneDrive wasn't running: error 362 "cloud file provider is not running" on Quick Notes, the script was still v2.3.2 (v2.4 never synced) and it didn't start at sign-in. Fix: make sure OneDrive runs; right-click the AutoHotkey folder > Always keep on this device.
- Bally / LNW apps (folder names include version numbers; v2.2 settings use `*` so upgrades don't break them):
  - AlertGrid: `C:\BallyTechnologies\AlertGridUI15_9\AlertGridUI\AlertGridUI.bat` → window "Alert Grid (15.0.9.1)", `javaw.exe`
  - SDS: `C:\BallyTechnologies\SDSUI15_9\SDSUI\SDSUI.bat` → title contains "SDS", `javaw.exe`
  - CMP: `C:\BallyTechnologies\CMPDesktop15_14_2\CMPDesktop\CMPDesktop.exe` → `CMPDesktop.exe`
- iTrak runs through Citrix → `wfica32.exe`, title "iTrak - [Daily Log] - \\Remote". Its launcher link is single-use, so it can't be auto-launched, only closed.
- Outlook is the new Outlook (`olk.exe`). Spotify = `Spotify.exe`.
- End-of-shift close list: outlook.exe, olk.exe, ms-teams.exe, Teams.exe, javaw.exe, CMPDesktop.exe, wfica32.exe, Spotify.exe, chrome.exe, msedge.exe, explorer.exe
- Chrome account: `[Paths] ChromeAccount=` (Jakob: [personal email removed], not [account name removed]). Ctrl+Alt+L reads Chrome's `%LOCALAPPDATA%\Google\Chrome\User Data\Local State` to find which profile folder has that account (differs per PC) and passes it to LaunchWork.bat as %1 (`--profile-directory`).
- OLG iTrak (facial rec, itrakappprod.olgnetwork.ca) opens in **Edge** by Jakob's choice; the other sites in Chrome. The Citrix Receiver (casino iTrak) page was in an old LaunchWork.bat on another bay; now opened in Chrome: https://apps.gcgaming.com/Citrix/GCGCWeb/ (the .ica launch from it is still manual).
- Oct 14 (fixed: old LaunchWork.bat removed from that bay's startup): on another bay the Bally apps opened twice and Spotify threw an error at sign-in. Neither current file launches Spotify, so an old LaunchWork.bat or shortcut is likely running at Windows sign-in on that bay (shell:startup) - asked Jakob to check.
- iTrak (Citrix Daily Log) opening a new log on sign-in is iTrak's own behaviour, not the script.
- LaunchWork opens (Bally apps now opened by the script): Citrix Receiver web page, iTrak login page, scheduling, Names & Photos sheet, GIO, training PDF, Oracle learning. Teams/Outlook/Spotify deliberately removed.
- Operators work different bays on different shifts; same OneDrive account syncs files between bay PCs.

---

## Decisions & preferences

- Every template trigger starts with `;` (avoids firing inside normal words; builds muscle memory).
- No trigger may start with `;t`, `;dd`, `;dt` (those stamps fire instantly) — script refuses them with a message.
- Login triggers must never be the real username (would fire inside email addresses and type the password).
- Prefilled times are fine where Jakob asked for them (audit: now → now+20). Avoid prefilling values that would silently end up wrong in a log.
- Keep his personal version; a team version would be a copy with an empty settings.ini. Get surveillance manager + IT approval before sharing. Passwords moved to Windows Credential Manager in v2.2 at his request (was: kept in settings.ini).
- Jakob prefers getting the complete file back rather than snippets to paste.
- Claude can't run AHK (Windows only); Jakob tests on the work PC and reports errors with line numbers.

---

## AutoHotkey v2 lessons learned (bugs hit and fixed)

1. A single-line hotstring `::abc::text` is literal replacement text — use `{ }` braces to run code.
2. A space followed by `;` starts a comment, even inside quotes — escape it as `` `; ``.
3. Literal quotes inside a string: `` `" `` (not `""`).
4. Pasting needs CRLF line breaks — bare `` `n `` gets ignored by many apps. `Paste()` converts.
5. Closures in a loop capture the variable, not the value — create hotkeys/hotstrings through a helper function.
6. Built-in GUI Tab/Enter didn't work on the work PC — forms handle Tab/Shift+Tab/Enter with `#HotIf` hotkeys instead.
7. Some Ctrl+Alt hotkeys get grabbed by other software — `$` prefix (hook) fixes it; tray menu is the fallback.
8. Windows 11 Notepad opens files as tabs behind other windows — EditFile() activates the window.
9. In .bat files every `%` in a URL must be `%%`.
10. An unclosed `}` shows up as "hotkeys not allowed inside functions" on a later line.
11. Downloaded files can land as `name (1).ahk` or `templates.txt.txt` — check names and turn on file extensions.
12. OneDrive sync conflicts make copies named `file-<PCNAME>` (e.g. `settings-PCNAME`). If settings.ini goes missing on reload, the script silently creates a fresh one with no logins (symptom: no logins on the cheat sheet). Fix: rename the real file back to settings.ini.

13. Variable names are case-insensitive and share a namespace with functions: a local `t`, `out` or `pause` clashes with a function `T()`, `Out()` or the built-in `Pause` ("local variable has not been assigned"). Pick names that aren't functions.
14. Under Wine, Text and Checkbox controls inside a Tab3 draw as black boxes (no theme). v3.10.0 uses Tab2 with a white window background instead.

---

## Open items / ideas

- v2.2 needs testing on the work PC (Credential Manager move, `;prd`, Ctrl+Alt+L opening the Bally apps, `;count` next step).
- Ideas list with reasoning: `docs/Next Steps and Ideas.md` (items 1–4 done in v2.2).
- Supervisor/IT approval before sharing. Team copy is built in v3.0 (tray > Make a copy to share, QUICK START.txt); the SharePoint library still needs setting up.
- Overview docs (Oct 16): the full overview was rewritten in Jakob's own first-person voice because his supervisor said it read like AI and his manager is wary of AI; a one-page summary for the manager was added. Keep both plain and personal: few bold lead-ins, no hedging boilerplate. Files: docs/Log Templates - Overview.pdf/.docx and docs/Log Templates - Summary.pdf/.docx.
- `;noid` wording confirmed by Jakob: "refused one patron entry due to no ID." (`;insuf` still says "refused one patron").
- Badge picker assumes badges 17-01 to 17-09.
- Optional: "Start automatically at login" tray option; Spotify app hotkey; searchable template picker for new users.
- Estimated savings: ~1,800 keystrokes / ~11 min per shift (30 logs, 10 logins), ~2¾ h per month at 15 shifts.


---

# FILE 2: README.txt

```text
=======================================================================
  WATCHLOG  v3.29.0  -  README
  Shortcuts for surveillance log entries, logins and shift start/end
=======================================================================
Copyright (c) 2026 Jakob Blair Vanness. All rights reserved.
Watchlog is used only with the copyright holder's permission. No
copying, sharing, changing or redistributing it, in whole or in part,
without written permission. Provided "as is", without warranty. The
full licence is in LICENCE.txt (and tray menu > About Watchlog).


Watchlog (called Log Templates before v3.0.1) runs quietly in the
background: its icon, a white log page with an eye on a teal square,
sits in the tray near the clock. You type a short trigger like ;jack
and it turns into a finished log entry. It also types logins, opens your work apps at the
start of a shift, closes them at the end, and keeps quick notes.

Click the teal icon (or press Ctrl+Alt+M) for the Watchlog home window:
every feature as a button with a picture, each showing its shortcut.
Right-click the icon for the menu (section 11).

Can't remember a trigger?  Ctrl+Alt+Space  finds a template by name or
any word in it (see section 3).
Quickest way to see everything on your PC:  Ctrl+Alt+H  (cheat sheet).
The cheat sheet is built from the templates and settings on that PC,
so it always matches what's set up there.

New to it? Read QUICK START.txt first (one page).
A team can share one templates file on SharePoint (section 13), and
tray menu > Security and status shows everything the tool keeps and
where (section 15).


CONTENTS
  1. Files
  2. Hotkeys (Ctrl+Alt + a key)
  3. Typed shortcuts (triggers)
  4. Fill-in forms
  5. Template list
  6. Logins and passwords
  7. Hourly login reminder
  8. Start of shift (Ctrl+Alt+L)
  9. End of shift (Ctrl+Alt+Shift+L)
 10. Shift journal (Ctrl+Alt+J)
 11. Tray menu
 12. Editing templates.txt
 13. Team templates and your own templates
 14. Settings window and settings.ini reference
 15. Security, privacy and the activity log
 16. Setting it up on another PC, or for a new operator (the exe)
 17. Troubleshooting
 18. Rules worth keeping


-----------------------------------------------------------------------
 1. FILES
-----------------------------------------------------------------------
Watchlog.exe installs itself to %LOCALAPPDATA%\Programs\Watchlog and
keeps these files in Documents\Watchlog (on OneDrive). The script
version keeps them next to Watchlog.ahk (for example
Documents\AutoHotkey). Either way:

  Watchlog.exe        The program (or Watchlog.ahk, the script version,
                      which IT can have on request: see section 16).
                      You shouldn't need to edit it.
  Watchlog.ico        The icon. Without it the tray shows a green H.
  templates.txt       The wording of every template. Edit freely. (If
                      the team's shared copy is set up, that one is
                      used instead. See section 13.)
  my-templates.txt    Your own extra templates (optional, section 13).
  settings.ini        Your personal settings: logins (no passwords),
                      start/end of shift programs, app hotkeys, and the
                      last values you used. Tray menu > Settings changes
                      it for you. Keep it private.
  settings.example.ini  An example with no real usernames, to show others.
  QUICK START.txt     One page for someone new.
  README.txt          This file.
  LICENCE.txt         The licence: who owns Watchlog and how it may be
                      used.

Elsewhere:
  LaunchWork.bat      Opens iTrak facial rec and the Citrix page in Edge, for
                      double-clicking. Ctrl+Alt+L no longer uses it since
                      v3.29.0 (Documents, or the program folder).
  Quick Notes.md      Your quick notes (Documents). Made automatically.
  Shift Journal       A folder in Documents with every log you insert,
                      one file per shift. Made automatically.
  activity.log        What the tool did and when, on this PC only
                      (%LOCALAPPDATA%\Watchlog). See section 15.

MOVING FROM LOG TEMPLATES
  Watchlog was called Log Templates before v3.0.1. Put Watchlog.ahk,
  Watchlog.ico in the folder, then double-click Watchlog.ahk. The first
  time it runs on each PC it moves everything over by itself:
    - closes the old Log Templates if it's still running
    - saved passwords: each one moves to the new name ("Watchlog:
      <username>") the first time it's used, so nobody types them again
    - %LOCALAPPDATA%\Log Templates becomes %LOCALAPPDATA%\Watchlog
    - the Startup shortcut now starts Watchlog
  settings.ini, templates.txt, my-templates.txt, Quick Notes.md and the
  Shift Journal keep their names. Tray menu > Activity log lists what
  was moved. The old Log Templates.ahk isn't needed any more and can be
  deleted.

Save templates.txt, my-templates.txt or settings.ini (or have the team
file change on SharePoint) and the script reloads by itself within a
couple of seconds. No need to press anything.


-----------------------------------------------------------------------
 2. HOTKEYS  (hold Ctrl+Alt and press the key)
-----------------------------------------------------------------------
  Ctrl+Alt+Space    Find a template: type part of its name or any word
                    in it, then Enter. See section 3.
  Ctrl+Alt+H        Cheat sheet (laid out in three columns since v3.15.0):
                    every template, login, app and hotkey on this PC.
  Ctrl+Alt+M        Watchlog home (v3.10.0): one window with a button for
                    everything (templates, shift, logins, setup) and how
                    this PC is doing. Clicking the tray icon opens it too.

  Ctrl+Alt+L        Start of shift. Opens the Bally apps (AlertGrid,
                    SDS, CMP) first, skips any already open, then opens
                    iTrak facial rec and the Citrix page in Edge.
                    See section 8.
  Ctrl+Alt+Shift+L  End of shift. Asks first (default No), logs you out
                    of SDS properly, then closes all work apps. See
                    section 9.
  Ctrl+Alt+K        Log out of SDS properly (the lock button, then Yes),
                    so the account doesn't get locked. SDS stays open at
                    its login screen.
  Ctrl+Alt+J        Shift journal: how many of each log you've done this
                    shift, with a Copy summary button. See section 10.
  Ctrl+Alt+Shift+S  Save where your windows are right now (window layout).
  Ctrl+Alt+W        Put the windows back where you saved them. See the
                    WINDOW LAYOUT notes in section 16.

  Ctrl+Alt+S        SDS: switch to it, minimise it if it's already in
                    front, or open it if it isn't running.
  Ctrl+Alt+C        CMP: same as above.
  Ctrl+Alt+T        Teams         (same: switch, minimise or open)
  Ctrl+Alt+U        Outlook
  Ctrl+Alt+Y        Spotify
  Ctrl+Alt+G        Edge
                    (SDS and CMP come from [App1]/[App2] in settings.ini.
                    Teams, Outlook, Spotify and Edge are built in. You
                    can change their letters or add more, see section 14.)

  Ctrl+Alt+Q        Quick note. Type a note starting with a tag like
                    #todo, #incident or #idea. It's saved with the date
                    and time in Documents\Quick Notes.md.
  Ctrl+Alt+S, C ... (v3.9.0) The SDS and CMP app keys now also offer to log you in
                    once the program is in front: "Log in to SDS as ...?" Enter =
                    yes, Esc (or 6 seconds) = no. It uses the saved login locked to
                    that program (your ;prd). Only say yes on the login screen.
  Ctrl+Alt+L        (v3.9.0) at the end it asks "Sign in to SDS, CMP, Alert Grid
                    now?" and, on yes, signs into the programs it just opened.
                    [StartOfShift] SignIn=no turns the question off.
  Tray > Advanced > Choose my own update folder   (v3.9.0; also Settings > Updates) a folder of your
                    own, so you can test a build without the team getting it.
  Ctrl+Alt+A        Clear ALL alerts in Alert Grid (v3.8.0). Brings Alert Grid to
                    the front, does Ctrl+A, right-click, Acknowledge as received,
                    Submit and OK, then puts you back where you were. It clears
                    everything in the list, so look first. Never types a password.
  Caps Lock         (v3.9.5) With the Caps Lock guard on, the plain Caps Lock key does
                    nothing, so when Alert Grid is open it clears all the alerts (same
                    as Ctrl+Alt+A). Caps Lock still turns itself off when it is on.
                    [AlertGrid] CapsLockClears=no in settings.ini turns this off.
                    v3.17.1: it waits for you to let go of Ctrl/Alt/Caps Lock first, holds
                    Ctrl+A properly, watches the list turn blue and presses Ctrl+A again
                    if it didn't take, so it no longer clears only the top alert.
                    [AlertGrid] SelectWait= is now the longest it waits for that (ms,
                    default 120). With a single alert (nothing under it
                    to turn blue) it waits only about 0.04 s (v3.17.3). v3.17.4-6 trimmed every wait so a clear
                    stays quick when alerts are arriving many a second.
  Ctrl+Alt+Shift+A  Teach it the clicks, once per PC: clear alerts by hand and press
                    F8 (or Ctrl+Alt+Shift+A again if F8 needs the Fn key) over the top row,
                    the menu item, Submit, the final OK and the little button that clears the
                    acknowledged alerts (Ctrl+Alt+Esc cancels). Last it asks which line
                    of the right-click menu "Acknowledge as received" is (1 = top).
                    v3.18.0: Alert Grid can be anywhere and any size, maximised or not.
                    The spots are measured from inside the Alert Grid window, the
                    clear-acknowledged button keeps up with the edge it sits by when
                    the window is resized, and when Alert Grid is low on the screen
                    (the menu opens upward) it picks the menu line with the arrow keys.
                    A teach from an older version is changed over by itself the first
                    time. If Alert Grid is too small or off the screen it says so and
                    clicks nothing.
                    v3.26.1: fixes v3.24.1, which skipped the final clear-acknowledged click
                    after the fallback below. That button is now always clicked at the end.
                    v3.24.1: if the right-click menu doesn't open because acknowledged
                    alerts are in the list (Alert Grid only allows the menu on unacknowledged
                    ones), the clear-acknowledged button is clicked first (and the no-more-
                    alerts click), then the unacknowledged alerts are cleared as usual. It
                    needs the clear-acknowledged button taught (step 5 of the teach).
                    v3.19.2: after the clear button there's one more click, the box that
                    says there are no more alerts. It's step 6 of the teach (re-teach once:
                    an older teach still works but skips that click).
  Ctrl+Alt+D        (v3.19.0) Opens a NEW DAILY LOG in iTrak. iTrak has no keyboard
                    shortcut for it, so Watchlog brings the iTrak window (the Citrix
                    window, title "iTrak - [Daily Log]") to the front, moves the mouse
                    to the spot you taught and clicks (twice if it takes a button and
                    a menu line), then puts the mouse back. You stay in iTrak, ready
                    to type. It only clicks while iTrak really is in front.
  Ctrl+Alt+Shift+I  Teach it that click, once per PC: it asks if opening a new daily
                    log takes one click or two, then you hover over the button (and
                    the menu line) and press F8 (nothing is clicked for you while
                    teaching). The spot is measured from inside the iTrak window, so
                    the window can be anywhere; a spot near the right or bottom edge
                    follows that edge when the window is resized. If the window is
                    too small or off the screen it says so and clicks nothing.
                    settings.ini [ITrak]: Window= (part of the title, then ahk_exe,
                    default "iTrak ahk_exe wfica32.exe"), Pause= (ms between the two
                    clicks, default 300), RefuseIfResized=yes (don't click if the
                    window isn't the size it was when taught). Numbers only are kept,
                    in %LOCALAPPDATA%\Watchlog\itrak.ini.
  Ctrl+Alt+F        (v3.20.0) FULL-ENTRY DAILY LOGS, for logs that never change (Break,
                    Table Drop, Card Destruction). A short list opens: type the first
                    letters of the log's name (br, ta, ca), press Enter. Watchlog clicks
                    New daily log (the Ctrl+Alt+D click), waits for the new "Daily Log
                    Entry" window to open, then clicks Location, Topic, Reference and
                    Synopsis in turn: Location and Topic are typed in full
                    and accepted with Enter, Reference is typed, the Synopsis is pasted.
                    It asks nothing. It does not touch End Time and does not save: you
                    click Now and Save yourself. Each is counted in Time saved and the
                    shift journal ("Full log: Break"): 5 keystrokes for each drop-down,
                    the full length of the Reference and Synopsis plus 1 for each click,
                    and 2 for the new-log click.
                    The logs are lines in templates.txt (or my-templates.txt):
                      +Name = Location | Topic | Reference | Synopsis
                    e.g. +Break = Surveillance | Duty | NA | Break
                    Five come ready-made: Break, Table Drop, Start (start of shift), End
                    (end of shift) and Card Destruction. Start asks which bay (offering
                    the last one) and keeps it for the shift; End uses it without asking. A line that ends with | end also clicks End Time's
                    Now button once the log is filled (the End log does); {Bay} in a
                    synopsis is the bay entered at the start of shift (v3.20.2); {Bay?} always
                    asks which bay and keeps the answer for the shift (v3.20.3).
  Ctrl+Alt+Shift+E  Click End Time Now in the daily log in front (v3.29.0)
  Ctrl+Alt+Shift+R  Repeat the last full-entry log (new daily log, same boxes) (v3.29.0)
  Ctrl+Alt+Shift+F  Teach the four spots once per PC: open a new, empty daily log in iTrak,
                    run this, hover over Location, Topic, Reference, Synopsis and End Time's Now button (5 spots) and press F8
                    on each (nothing is clicked for you). The daily log form is its own window
                    (title "Daily Log Entry - N/A - \\Remote"), and the spots are measured from
                    inside it, so it can open anywhere but should stay the same size.
                    settings.ini [ITrak]: EntryWindow= (what to look for, default "Daily Log
                    Entry ahk_exe wfica32.exe"), EntryWait= (most ms to wait for the form after
                    New daily log, default 8000), EntrySettle= (ms to let it draw, default 600).
                    Not shared with the team yet.
  Tray > iTrak > Share my setup with the team   (v3.19.0) puts this PC's iTrak click
                    in itrak.ini in the team folder, filed by screen scaling, for PCs
                    that haven't been taught. A PC's own teach always wins.
  Tray > Alert Grid > Share my setup with the team   (v3.18.0) puts this PC's taught
                    clicks (numbers only) in alertgrid.ini in the team folder, filed by
                    screen scaling. A PC that hasn't been taught uses them, so teammates
                    don't have to teach. A PC's own teach always wins.
  Ctrl+Alt+O        Show all your quick notes in a window that is always up to
                    date (Open in Notepad button inside). v3.7.1
                    (Ctrl+Alt+T used to find notes by tag. It was
                    removed in v2.7 and T is now Teams.)

  Numpad +          The call pad (v3.12.0): a small pad to jot a phone call into with
  (or Ctrl+Alt+N)   one hand. See CALL PAD AND AUTOCORRECT below. The + key on the number
                    pad opens it from any program except Watchlog's own windows;
                    Shift+ or Ctrl+ with it still types a +.
                    [CallPad] Key=off in settings.ini gives the + key back.

  Ctrl+Alt+E        The template editor (v3.10.0): change wording, add
                    templates and boxes, change lists like @tables,
                    without Notepad. See section 12. (Notepad is still
                    there: tray menu > Advanced.)
  Ctrl+Alt+I        Window info. Shows the title and program name of the
                    window in front and copies them. Use it when you
                    need a Window= line in settings.ini.

  Ctrl+Alt+P        Pause / resume every shortcut (high beep = on,
  Ctrl+Alt+X        low beep = paused). Same thing, two keys. Handy if
                    a trigger keeps firing where you don't want it.
  Ctrl+Alt+R        Reload the script. Rarely needed now that it reloads
                    on save, but it still works.

Ctrl+Alt+P, X and R keep working while shortcuts are paused.
The login reminder (section 7) still pops up while paused.


-----------------------------------------------------------------------
 3. TYPED SHORTCUTS  (triggers)
-----------------------------------------------------------------------
Every trigger starts with ; (semicolon), which makes it unlikely to
fire inside a normal word. Every trigger fires the moment you finish
typing it, so pause shortcuts (Ctrl+Alt+P) if you need to type one
literally.

  Templates      Just type the trigger, no Space or Enter needed.
                 e.g.  ;interior
                 A Space or Enter pressed out of habit in the next half
                 second is ignored, so it won't add a stray space or
                 submit a form early.
                 Triggers are case sensitive: ;jack works, ;JACK doesn't.

  Stamps         Fire the moment you finish typing (no Space needed):
                   ;t    @21:42              (time)
                   ;dd   2026-10-14          (date)
                   ;dt   2026-10-14 @21:42   (date and time)

  Logins         Fire the moment you finish typing. They type the
                 username, press Tab, type the password and press
                 Enter. Your login triggers are listed on the cheat
                 sheet (Ctrl+Alt+H). See section 6.

Templates paste the text, and your clipboard is put back the way it was
afterwards.

CAN'T REMEMBER A TRIGGER?  Ctrl+Alt+Space  (or tray menu > Find a template)
  A search box opens with every template listed. Type part of a name
  (jack), a trigger (;bv), or any word from the log (ambulance,
  defective, trespass) and the list narrows as you type.
    Up / Down      choose a template (PgUp / PgDn jump 10)
    Enter          insert it where you were typing, exactly as if you'd
                   typed its trigger (a form opens if it has blanks).
                   Double-clicking a template does the same.
    Esc            close without inserting
  Below the list it shows the wording, with the blanks in [brackets],
  and the trigger to type next time so you can skip the search.
  Typing a whole trigger in the search box runs it straight away, just
  like anywhere else. Logins never fire in the search box.
  Press Ctrl+Alt+Space again to close it.


-----------------------------------------------------------------------
 4. FILL-IN FORMS
-----------------------------------------------------------------------
A template with blanks in it opens a small form instead of pasting
straight away. Fill it in and it pastes the finished entry where you
were typing.

  Tab / Shift+Tab   next / previous box
  Enter             insert the entry
  Ctrl+Enter        add another (only on forms with an "Add another"
                    button, like ;bv)
  Esc               cancel (nothing is pasted)

  - "How it will look" at the bottom of every form shows the finished
    log as you fill in the boxes. With "Add another", the ones already
    added show above the one you're on.
  - The cursor starts in the first box you'd fill in: the first empty
    box or list. Boxes already filled with a time or a copied number
    are skipped (e.g. ;audit starts on Employee type).
  - A box you leave empty keeps a placeholder like XX or AXXXX. That
    makes a missing detail easy to spot, but it doesn't stop the entry
    being pasted. Check for leftover XX before you save the log.
  - Some boxes do work for you:
      time boxes      2130 becomes 21:30, 930 becomes 09:30
      money boxes     10000 becomes 10,000  (the $ is in the template)
                      In ;player, a decimal point means thousands:
                      3.3 becomes 3,300 and 1.5 becomes 1,500
                      (500 stays 500)
      percent boxes   67 becomes 67%
      machine boxes   letters come out as capitals: b1410 becomes
                      B1410, nrt2 and nrt4 becomes NRT2 and NRT4
      "now" boxes     already filled with the current time
      "now+20" boxes  filled with the time 20 minutes from now
      clip boxes      if you copied an employee # (4-8 digits) first,
                      it's already filled in (a longer copy works too, if
                      it has just one number like that in it)
      ;audit type     if the text you copied has a job title in it (Pit
                      Manager, Dealer...), the type box opens on it
      ;face           the alert # (8 digits) and the match % you copied
                      from the facial rec page in Edge fill themselves in,
                      in either order. Details under "Facial rec copies".
      list boxes      pick from the list, or type over it, depending
                      on the template. Typing the start of an item fills
                      in the rest (d becomes Dealer, ca becomes Cage
                      Cashier); keep typing to replace it, Backspace
                      to remove it. Typing just the number picks the
                      item ending in it: 202 becomes FB202
      ATM amount      (;mfill) fills in 100,000 when you pick an ATM;
                      type over it if it's different
      Bay box         remembers the bay you typed last time
      Step box        (;countstep) opens on the step after the last one
                      you used, and wraps back to the start
  - "a/an" in a template picks the right word for what follows it
    ("an employee", "a guest").
  - Several in one log (;bv): fill in the first machine and press
    "Add another" (or Ctrl+Enter). The boxes clear for the next one and
    the form's title counts how many are added. Insert pastes them all
    as one log, one machine per line:
        A1234 #5678 (Full)
        B2345 (Defective)
    If the boxes are empty when you press Insert, that last one is
    skipped. The shift journal counts it as one log.
  - Several tables on one line (;open, ;auto, v3.19.3): pick a table,
    press "Add another" (or Ctrl+Enter) and pick the next. The table box
    starts empty and clears each time; Insert pastes one line:
        BJ205, BJ206 and RO204 Opened.
    A table added twice is only listed once.


-----------------------------------------------------------------------
 5. TEMPLATE LIST  (as of v3.0, from templates.txt)
-----------------------------------------------------------------------
Forms (open a form):
  ;jack         Supervisor jackpot: amount, machine, window #, time paid
  ;audit        Employee audit: type, employee # (clip), from now to
                now+20, location
  ;medical      Medical: employee/guest, location, what the review
                showed, outcome (pick one)
  ;evict        Trespass: location, reason, length
  ;face         Facial recognition alert: alert #, result, match %
  ;start        Start of shift, Bay (remembers last bay)
  ;end          End of shift, Bay (remembers last bay)
  ;open         Table opened: table (Ctrl+Enter adds another, same line)
  ;auto         Table closed and auto-close started: table (Ctrl+Enter
                adds another, same line)
  ;cards        Card change on a table
  ;fill         Table fill: table and amount (Ctrl+Enter adds another table)
  ;mfill        Machine fill: NRT or ATM and amount (Ctrl+Enter adds another)
  ;player       Player log: player # (or RN if not rated), spot, table,
                buy-in, up/down
  ;bv           Emergency BV pull: machine, asset # (left out if empty),
                reason. Add another for several machines in one log.
  ;abandon      Abandoned credits review: found at, patron found at,
                TITO value
  ;found        Abandoned credits printed off and taken to Security:
                amount, machine
  ;aml          AML alert: alert #, machine, time (now)
  ;firm         NRT firmware check: department/title (starts as Operations Supervisor), location/NRT # (n2 becomes NRT2), DUB # (with the fixed shot note)
  ;maint        Machine maintenance
  ;countstep    Soft count step (time now, opens on the next step)
  ;counttables  Soft count: table totals
  ;countslots   Soft count: slots total
  ;countpull    Soft count: emergency pull
  ;badge        Pass 17-01 to 17-09: contractor employee (type the company over XXXXX) or interview
  ;account      Account review: account # (the # stays if left empty)
  ;refuse       Refused entry: how many patrons (one to 5, or type
                it), the reason (no ID, insufficient ID, expired ID,
                signs of intox) and, if you fill it in, what you
                observed, put in brackets after the reason

Quick (paste straight away):
  ;interior     Interior door check
  ;exterior     Exterior door check
  ;parking      Parking lot patrol
  ;selfex       Self-exclusion: patron taken into PlaySmart
  ;inventory    Inventory transfer, Delta Podium to Main Bank
  ;drop         Table drop
  ;man          Garbage sweep (EVS Attendant escorted into Cage Mantrap)
  ;close        Table closing (tray lids, tokes)
  ;destroy      Card destruction

If you add or change templates, the cheat sheet (Ctrl+Alt+H) is always
the up-to-date list. This one is a snapshot.


-----------------------------------------------------------------------
 6. LOGINS AND PASSWORDS
-----------------------------------------------------------------------
Right-click the tray icon > Settings. The Logins list shows each login
shortcut, its username, where it works, its reminder, and whether this
PC has its password saved (never the password itself).
  Add...               shortcut, username, and the password (or leave
                       the password blank and it asks the first time
                       you use the login). Optional: only works in one
                       program's window, and a log-in-again reminder.
  Edit...              change any of it (double-click a login works too)
  Change password...   type the new one. Do this on each PC you use.
  Remove               removes the login, and when you press Save it
                       also deletes its saved password from this PC
Nothing changes until you press Save. The script then reloads.

Typing a login's shortcut types:
  username, Tab, password, Enter

Passwords are NOT in settings.ini. They're kept in Windows Credential
Manager on each PC, named "Watchlog: <username>". They're tied
to your Windows sign-in, so anyone using the PC while you're signed in
could use your login shortcuts. Lock the PC (Win+L) when you step away.
They don't sync through OneDrive, so each other bay PC asks for a
login's password once, the first time you use it there (the box hides
what you type).

To see or delete saved passwords yourself: Control Panel > Credential
Manager > Windows Credentials, entries starting "Watchlog:".

The window lock keeps a login from firing anywhere else. A login can be
locked to one program or to several, separated by | (for example
"SDS ahk_exe javaw.exe | ahk_exe CMPDesktop.exe | AlertGrid"). It types
only while one of them is in front, and checks again just before it
types. In Settings, Add or Edit a login and press Pick window: click the
program you want and its name is filled in (press it again to add
another). Logins without a lock work in any program, so the ; at the
start is their only protection; the Settings list shows "(any program)"
for them and Security and status says so. The Settings window won't save
a shortcut without a ; unless it has a window lock. (Windows' own lock
screen can't be typed into by any program like this.)

Login shortcuts never fire in the template finder or the Settings
window, so typing one there can't type a password. Each time a login is
used, the activity log notes the username and the program it went into
(never the password). See section 15.

If an old settings.ini still has a Password= line, the script moves it
into Credential Manager, deletes it from the file and tells you.


-----------------------------------------------------------------------
 7. HOURLY LOGIN REMINDER
-----------------------------------------------------------------------
SDS SIGNS BACK IN BY ITSELF (v3.10.1)
SDS logs you out an hour after you sign in. When you sign in to SDS with
its saved login (by typing the shortcut, the Yes/No question, or Ctrl+Alt+L),
Watchlog starts a 62-minute countdown. When it runs out and SDS is back on
its login screen, SDS comes to the front, the saved login is typed, and the
window you were in is put back. If SDS still says Welcome it looks again
every minute (up to 6 times). Because of this, the "log in again" pop-up
is not shown for the SDS login. Settings > Logins has the tick box and the
number of minutes (settings.ini: [SDS] ResignMinutes=62, 0 = off). Nothing
is typed unless SDS is really on its login screen.

For an app that signs you out every hour. In tray menu > Settings, edit
that login and put 55 in "remind me to log in again after this many
minutes". (In settings.ini it's a Remind=55 line under that login.)

Each time you use that login, a 55-minute countdown starts. When it runs
out you get a small pop-up in the bottom-right corner
saying it's time to log in again, with the trigger to use. It doesn't
take the keyboard away from the window you're typing in, and it only
makes no sound unless you tick "Beep when the login reminder pops up" in Settings (v3.9.4), so it's easy to miss if you're away. Press
Esc (from any window) or click OK to close it, or just log in again:
using the login closes the pop-up and restarts the countdown.

The countdown survives a reload (the last login time is kept on the PC),
so saving templates.txt doesn't reset it.


-----------------------------------------------------------------------
 8. START OF SHIFT  (Ctrl+Alt+L)
-----------------------------------------------------------------------
What happens, in order (about 20 seconds):
  1. A "Opening work apps..." message shows in the middle of the screen.
  2. The programs in [StartOfShift] open one second apart (AlertGrid,
     SDS, CMP). Any it can see are already open are skipped, so pressing
     it twice normally won't give you two copies. (It spots them by
     window title, so an app still starting up can be missed.)
  3. It waits until those programs have their windows up (LaunchWait
     seconds at most, never less than 20).
  4. It opens two tabs in one Edge window (if Edge is already open, it
     asks first whether to open them again; No is the default, so you
     don't get every tab twice): facial rec (OLG iTrak) first, then the
     Citrix Receiver page, so Citrix is the tab you see and you can
     launch iTrak from there. Since v3.23.0 nothing else is opened and
     no tabs are searched for. The addresses are FaceUrl and CitrixUrl
     in settings.ini (also in Settings); blank FaceUrl = not opened.
  5. It puts your saved window layout back, then brings the Edge window
     with the Citrix page to the front.
  6. If anything couldn't be found, a message lists it.

Still manual: launching iTrak itself from the Citrix page (its launch
file only works once, so it can't be automated).

Bally version numbers: paths use * (e.g. AlertGridUI*) so a new
version number in the folder name (15_9 to 15_14) doesn't break the
path. The newest version folder found is used. If an upgrade changes
the folder layout or file names, the path in settings.ini still needs
updating.


-----------------------------------------------------------------------
 9. END OF SHIFT  (Ctrl+Alt+Shift+L, or tray menu)
-----------------------------------------------------------------------
  1. Asks "Log out of SDS and close all work apps?" and reminds you to enter your End of
     Shift log first (Ctrl+Alt+J has your shift summary). Default is
     No, so a stray Enter does nothing. Yes also ends the shift in the
     shift journal.
  2. Logs you out of SDS properly first (closing it while logged in
     locks the account): it clicks the lock button next to the red X
     and answers Yes to "will be logged out". If it can't do that, it
     asks you to log out of SDS yourself and closes nothing until you
     press OK.
  3. Closes every window of the programs in [EndOfShift] Close= the
     normal way, so anything unsaved can still ask you.
     Default list: Outlook (old and new), Teams, the Bally apps, CMP,
     iTrak (Citrix), Spotify, Edge, and File Explorer windows.
  4. Waits 5 seconds. If anything is still open, it lists it and offers
     to force it closed (default No; unsaved work in it would be lost).

File Explorer is special: only its folder windows are closed. It's
never force-closed, because the same program runs the taskbar.


-----------------------------------------------------------------------
 10. SHIFT JOURNAL  (Ctrl+Alt+J)
-----------------------------------------------------------------------
Every log you insert, quick or form, is also saved with the time it
went in. Logins and passwords are never saved.

Ctrl+Alt+J opens the journal window (v3.15.0): the count of each log at
the top, and below it every log of this shift as text you can EDIT. Click
in it, fix a typo or delete a line, then Save changes (Undo edits puts back
what was saved; closing asks if you have unsaved edits). A log inserted
while the window is open is kept: it is added after your text. If the file
was changed by something else meanwhile, nothing is overwritten and the
window tells you (Copy shift text keeps what you typed). Copy summary uses
the edited text.
  Edits count everywhere (v3.17.0): each log in the journal now has a tag
  like [k112] after its title, the keystrokes that log saved. When you
  Save changes, a log you removed comes off Shift count, this shift's
  numbers, Time saved (day, week, month, since the start) and the Shift
  dashboard, with exactly its own keystrokes. Renaming a log's title (keep
  the [k] tag) moves it to the other log type; a log you type in by hand
  counts as one log saving nothing unless you give it a [k] tag. Logs from
  before v3.17.0 have no tag, so they come off at the average for their
  type. Logins, stamps, Alert Grid clears and app switches aren't in the
  journal, so they stay as counted. The tags don't show in the counts or in
  Copy summary.

SHIFT COUNT (tray > Shift count, the Shift count tile on the home window,
or the Shift count button in Time saved)
  An exact tally of one shift, item by item: how many of each template
  (by name), each login, each time stamp (;t ;dd ;dt), each Alert Grid
  clear and each app switch (Ctrl+Alt+T, U, G and so on), with the
  keystrokes each one saved and a total. It starts by itself with the
  first thing you do, starts again after End of shift (or 6 hours of
  nothing), and "Start a new count" restarts it by hand. Copy report
  puts the numbers on the clipboard. Numbers only: never log text or
  passwords. Kept in time saved.ini, same as Time saved.

SHIFT DASHBOARD (Ctrl+Alt+Shift+D, tray > Shift dashboard, or the Dashboard
button in Shift count / Time saved)  -  new in v3.16.0
  Three tabs. This shift: tiles for logs, alert clears, typing saved and
  shift length, then logs by type as bars. Week and Month: one row per day
  (logs, alert clears, typing saved), the top log types, and on Month the
  busiest day and the previous 30 days for comparison. Copy summary puts
  a plain-text shift summary on the clipboard; Save as a sheet writes a
  one-page HTML sheet to Shift Reports (next to settings.ini) and opens it
  to print. The tick box leaves typing saved off the copy and the sheet.
  "Alert clears" counts each Clear all, not each alert. Numbers only: log
  type names and counts, never log text, employee numbers, patron names,
  machine or alert numbers. Kept on this PC in time saved.ini ([DayItems]),
  nothing sent anywhere. Week and Month fill in from the day v3.16.0 is
  installed (older days show logs and typing saved only).

TIME SAVED (tray > Time saved, or the Time saved button in Ctrl+Alt+J)
  Every log, login and time stamp adds up the keystrokes it saved: the
  length of what went in, minus what you typed (the shortcut, what you
  put in the boxes, one Tab or Enter per box). A box left blank saves
  nothing. Time is worked out at 40 words a minute (200 keystrokes).
  The window shows this shift, today, the last 7 and 30 days, and
  everything since the first day, with a Copy report button.
  Ctrl+Alt+J shows this shift's time saved at the top.
  Only the numbers are kept, per day, in
  %LOCALAPPDATA%\Watchlog\time saved.ini on this PC. No log text.

Where: Documents\Shift Journal, one plain text file per shift, named
by the date the shift started (2026-10-15.txt). A night shift that
runs past midnight stays in one file. A new shift starts with the
first log after Ctrl+Alt+Shift+L, or after 6 hours with no logs.

What a file looks like:
  === Shift started Thu Oct 15, 2026  18:02  (BAY3-PC) ===

  18:20  Audit
         Surveillance observed Dealer Employee # 1234567 from ...

  18:41  Jackpot
         Operations Supervisor advised of a $10,000 Supervisor ...

Ctrl+Alt+J (or tray menu > Shift journal) shows this shift's count of
each log, for example 12 Audit, 3 Jackpot, 9 Soft count step.
  Copy summary   copies one line you can paste into your End of
                 Shift log, e.g.
                 Shift summary (18:20 - 05:47): 47 logs. 12 Audit, ...
  Open journal   opens the shift's file in Notepad, so you can copy a
                 log again if iTrak or Citrix lost it.

Settings (tray menu > Settings > Shift journal):
  Save each log's time, name and text      (the default; Save=full)
  Save only the time and template name     (Save=counts)
  Don't keep a shift journal               (Save=off)
  Delete shift files after 7, 14, 30 (the default), 60 or 90 days,
  1 year, or Never  (KeepDays= in settings.ini, 0 = never)
If your manager would rather log text isn't kept outside iTrak, use
"only the time and template name". The summary still works.

Old shift files are deleted automatically once they're older than the
KeepDays setting (checked at start-up and every few hours). Only files
named like 2026-10-15.txt in the journal folders are touched, never one
from the last two days. The activity log notes how many were deleted.
You can also delete any of them yourself at any time.

If OneDrive isn't running, the journal goes to a folder on that PC
instead (%LOCALAPPDATA%\Watchlog\Shift Journal (this PC)) and a
notice says so once.


-----------------------------------------------------------------------
 11. TRAY MENU  (right-click the Watchlog icon near the clock)
-----------------------------------------------------------------------
A plain click on the icon opens the Watchlog home window (Ctrl+Alt+M).
Right-click it for this menu (v3.10.0: each item has a small picture,
and the less-used items sit in sub-menus):

  Watchlog v3.10.0 (date)       Which version is running, whether
                                it's up to date, the program check
                                code, and where the templates come from
  Watchlog home                 Same as Ctrl+Alt+M (bold: a click on
                                the icon does this)
  Call pad                      Same as Numpad + (v3.12.0)
  Find a template               Same as Ctrl+Alt+Space
  Cheat sheet                   Same as Ctrl+Alt+H
  Shift journal                 Same as Ctrl+Alt+J
  Quick notes                   Same as Ctrl+Alt+O
  Time saved                    How much typing Watchlog has saved
                                (see TIME SAVED in section 10)
  Shift count                   Exact tally of this shift, item by item
                                (see SHIFT COUNT in section 10)
  Shift dashboard               Same as Ctrl+Alt+Shift+D (v3.16.0)
  Start of shift                Same as Ctrl+Alt+L
  End of shift (close apps)     Same as Ctrl+Alt+Shift+L
  iTrak >                       New daily log (Ctrl+Alt+D), Teach the click
                                (Ctrl+Alt+Shift+I), Full-entry log (Ctrl+Alt+F),
                                Teach the daily log fields (Ctrl+Alt+Shift+F),
                                Share my setup (v3.19.0)
  Alert Grid >                  Clear all alerts (Ctrl+Alt+A), Teach the
                                clicks (Ctrl+Alt+Shift+A), Share my setup
                                with the team (v3.18.0)
  Windows >                     Save window layout, Put windows back,
                                Caps Lock guard (ticked = on)
  Template editor               Same as Ctrl+Alt+E (section 12)
  Settings                      Section 14
  Tutorial                      The guided tour again
  About Watchlog                Version, copyright and the licence
  Advanced >                    Security and status (15), Activity log
                                (15), Make a copy to share (16), Edit
                                templates / my templates / settings in
                                Notepad, Open Watchlog folder, Choose my
                                own update folder, Pause all shortcuts,
                                Reload
  Exit Watchlog                 Closes it (start it again from the
                                Start menu)

DAILY LOG FILLS FOR THE SHORTHAND LOGS  (v3.26.2)
  ;fill, ;open, ;auto, ;jack, ;bv and ;mfill (and so the call pad shorthand for them) now also
  open a new daily log in iTrak, or use the one already open, and fill Location, Topic and
  Reference, like ;cards and ;break. Reference is left empty on purpose where you fill it
  yourself (fill, jack, bv, mfill). Shift+Enter on the form still pastes just the wording.
      ;fill   Pit | Table Fill |            ;open, ;auto   Pit | Table Opening/Closing | NA
      ;jack   Slots | Jackpot |   ;bv   Slots | Emergency Pull |
      ;mfill  ABM/NRT | ATM/NRT/CTR fill |
  The Pit and Slots come from the log itself: %pit% in a code word's Location is the pit of
  the first table (2xx = Pit 2, 3xx = Pit 3) and %slots% the area of the first machine (the
  letter: C2102 = Charlie Slots). They are looked up in two lists near the top of templates.txt
  that you can change or extend (a new letter, a new pit) without a new program version:
      @pit = 2=Pit 2 | 3=Pit 3
      @slots = A=Alpha Slots | B=Bravo Slots | C=Charlie Slots | D=Delta Slots
  If it can't tell, that box is left empty and a short message says so.

CHANGING THE ; IN FRONT OF CODE WORDS  (v3.25.0)
  Settings > General > "Type this in front of code words and logins" (settings.ini
  [Triggers] Prefix=). Use 1 to 3 symbols, no letters, digits, spaces or colons (for
  example . or // or \). After you Save, Watchlog reloads and every code word, login
  shortcut that starts with ; and the time and date stamps (;t ;dd ;dt) are typed with
  your prefix instead: with . you type .jack, .t, .dd. It is per PC (settings.ini), so
  each operator picks their own. templates.txt, my-templates.txt and the shared team
  file keep the ; in them, so they work the same everywhere. The cheat sheet (Ctrl+Alt+H),
  the template finder and the login list show your prefix. Pick one you don't type in
  normal writing, because a code word fires the moment it is typed. Messages in the
  template editor still show the ; from the file.

CODE WORDS THAT FILL THE DAILY LOG  (v3.24.0)
  A code word can fill a whole iTrak daily log instead of pasting text. In templates.txt
  (or my-templates.txt) put  >> Location | Topic | Reference  at the end of its line:
      ;cards (Card change) = Card change on {Table: @tables}. >> Pit 2 | Card Change | NA
  Type ;cards and answer the boxes. Watchlog then fills the daily log that is open in
  iTrak (the one in front if several), or clicks New daily log and opens one if none is
  open, and fills Location, Topic, Reference and the Synopsis (the wording before >>).
  {Boxes} work in Location, Topic and Reference too. End Time and Save are left to you,
  or add  | end  last to click End Time's Now. It works from any window, uses the same
  taught spots as Ctrl+Alt+F, stops if iTrak loses the front, and counts in Time saved.
  To paste just the wording where you are instead, press Shift+Enter on the form (or hold
  Shift when a code word with no boxes fires). A line with >> but fewer than three parts
  after it is reported in the problems list.

CUSTOMIZE WATCHLOG  (v3.21.0: tray menu > Customize Watchlog, or the Customize button on the home window)
  Screens for the things that used to mean editing a file. Each opens in its own
  window and applies when you save. Nothing here touches your passwords.
  - Full-entry daily logs: a list of the logs Ctrl+Alt+F fills in. Add, Edit, Copy,
    Delete; the Edit box has Name, Location, Topic, Reference, Synopsis and a tick for
    "Click End Time's Now button". "Try it in iTrak" runs the picked log for real. Saved
    as the + lines in templates.txt (or my-templates.txt), the old file kept as .bak.
    A log from the team's shared file can't be changed here (copy it first).
  - Shortcut keys: pick a different key for any Ctrl+Alt shortcut (find a template, the
    call pad, quick note, notes, journal, start and end of shift, home, template editor,
    window info, save/put back layout, log out of SDS, the Alert Grid and iTrak keys, the
    full-entry log and its teach key, the dashboard, the cheat sheet). Click a box and
    press the keys; use Ctrl, Alt or Win with them; two shortcuts can't share a key. Not
    changeable: pause (Ctrl+Alt+P or X), reload (Ctrl+Alt+R), the app keys, the keys
    inside forms. Kept in settings.ini [Hotkeys] (id=key); "Back to the standard keys"
    clears them. Saving restarts Watchlog. The tray menu, home window and cheat sheet show
    the keys you picked; some messages elsewhere may still show the standard names.
  - Start and end of shift: the programs Ctrl+Alt+L opens, in order (Add, Edit, Remove,
    Move up/down; a * in a path means any version; "spot it by" is how it tells a program
    is already open) and the list of programs the end of shift closes. Kept in
    settings.ini [StartOfShift] Run1...Run9, Window1...Window9 and [EndOfShift] Close.
  - Shared lists: opens the template editor on its Shared lists tab (tables, machines...).
  - Autocorrect words: the list in autocorrect.txt as a table: tick = on, Add, Edit,
    Delete, search, "Back to the built-in list", and a switch for autocorrect as a whole.
    The old file is kept as autocorrect.txt.bak.
  - Speed and timing: the waits for Alert Grid (between clicks, for Select All) and iTrak
    (between clicks, for a new log, after the form opens). Standard values are shown;
    "Back to the standard values" clears them. settings.ini [AlertGrid] and [ITrak].
  - Logins and reminders, Caps Lock, journal, updates: open Settings on the right tab.
  Settings, the template editor and the autocorrect editor all still work as before.

LOOK  (v3.22.0, light by default since v3.22.1)
  Every Watchlog window uses a blue accent (the old teal is gone). The home window
  has three panels at the top: logs this shift, logins this shift and typing saved
  this shift. Tabs (Settings, the template editor, the dashboard) are drawn as a
  row of buttons.
  There is also a dark look: tray menu > Dark look (a tick shows when it is on), or
  Customize Watchlog > the "Dark look" tick box (settings.ini [Look] Dark=yes or no).
  It applies to windows opened from then on. In the dark look, dark text turns light and
  white panels turn dark; on Windows 10/11 the buttons, lists and scroll bars go dark
  too. The Caps Lock banner stays red.

WATCHLOG HOME  (click the icon, or Ctrl+Alt+M)
  Big buttons in three groups: Logs (call pad, find a template, cheat
  sheet, journal, quick notes, time saved, shift count, dashboard), Logins
  (one button per saved login) and Set up (template editor, settings,
  tutorial, security and status, about, save window layout) plus a Customize
  button (see above). The Shift
  buttons (start, end, log out of SDS, clear Alert Grid, new iTrak daily
  log, put windows back) were removed in v3.20.0: use the shortcuts, or the
  cheat sheet (Ctrl+Alt+H) if you forget them. Each button shows its shortcut, so new
  operators learn them as they go. It closes when you press a button,
  and anything that types goes into the window you were in before.
  A login button brings up the program its login is locked to; a login
  that isn't locked asks which window first ("Type the ;jakob login
  into this window?").
  Along the bottom: whether this PC is up to date, the templates and
  wording version, whether Alert Grid is taught, this shift's time
  saved, and ticks for the Caps Lock guard and pausing all shortcuts.

The tray menu is the backup if another program ever grabs a Ctrl+Alt
hotkey. "Change a login password" moved into Settings in v3.0.

WHICH VERSION AM I RUNNING?  AM I UP TO DATE?
  Hover over the icon, or look at the top of the tray menu. Every time
  the script loads it also shows "Watchlog v3.7.0 running" in the
  bottom-right corner for a few seconds.

  The templates file has a line near the top, "# Program version:
  3.4.2", saying which version everyone should be on. With a team
  templates file on SharePoint, whoever hands out a new
  Watchlog.ahk changes that line too, and then any PC still on an
  older version:
    - gets a pop-up saying it's out of date and where the new file goes
    - shows "update needed" on the tray icon and the tray menu
    - says "OUT OF DATE" in the version box and in Security and status
  When it's current, the load note says "(up to date)".

  Click the version line at the top of the tray menu to see whether
  you're up to date and the program check code (like 47E3-2566). The
  same code on two PCs means exactly the same Watchlog.ahk, so
  comparing codes catches a copy that was changed by hand.

UPDATING EVERYONE (with a team templates file on SharePoint)
  Put the new Watchlog.ahk (and Watchlog.ico) in the same SharePoint
  folder as the team templates.txt, and change its "# Program version:"
  line. When OneDrive brings it down, each PC asks "Update now?". Yes
  checks that the new file loads, keeps the old one as a backup in
  %LOCALAPPDATA%\Watchlog, swaps the new one in and reloads. Later asks
  again next time Watchlog starts. It only ever updates from that one
  folder, and a file that doesn't load is refused (the PC stays on its
  version and the activity log says why).


-----------------------------------------------------------------------
 12. EDITING templates.txt
-----------------------------------------------------------------------
SDS SIGN-IN FIX  (v3.29.0)
  The hourly SDS sign-in could stop with "no saved login is locked to SDS" when something else
  took the keyboard a moment after SDS came to the front. It now brings SDS back and tries
  again, then uses the login whose Only in names SDS (or the one last typed into SDS), even
  without a ; in front. If it still can't, the Activity log lists your logins and the program
  each is locked to (no passwords).

SAFEGUARDS  (v3.27.0)
  Things Watchlog now refuses or warns about, instead of failing quietly:
  - A login with no program set (no Window= / Only in) is never typed into Notepad,
    Outlook, Teams, Word, Excel, OneNote, Slack, WhatsApp, Discord, Watchlog's own windows
    or the iTrak Daily Log Entry window. It says so on screen. Set Only in for a login to
    lock it to its program. A refused login of any kind (wrong window in front) now also
    shows a message, not just an Activity log line.
  - A form's log is pasted only if the window you started it in comes back to the front
    (it waits up to 2 seconds). If not, nothing is pasted, it beeps, and the log stays on the
    clipboard: click where it goes and press Ctrl+V.
  - Alert Grid clearing stops if a pop-up takes the front before the first click or the
    right-click (it gets one second to bring Alert Grid back).
  - At start-up Watchlog compares the Windows display scale with the one the iTrak and Alert
    Grid clicks were taught at, and warns if it changed. Alert Grid clicks taught before
    v3.27.0 have no scale saved: teach once (Ctrl+Alt+Shift+A) to get the warning.
  - A form closed with Esc keeps what you typed for 10 minutes: opening the same log again
    puts it back (Esc again, without changing anything, throws it away). Kept in memory only.
  - An unexpected error now shows a short plain box ("That didn't finish, but Watchlog is
    still running") with the line number, instead of AutoHotkey's error window.

BREAK TIME TRACKER  (v3.29.0)
  You get 60 minutes of break a shift, split however you like. Watchlog keeps count:
  - ;break (or the Break full-entry log) starts the clock when it fills the daily log. The
    break ends when you Save & Close that Daily Log Entry window. Nothing else to press.
  - Break time left shows on the home window, the shift dashboard ("This shift" tab) and when
    you hover over the tray icon, e.g. "Break: 42 min left (18 of 60 used)" or
    "On break 12 min, 30 min left".
  - Ctrl+Alt+Shift+E clicks End Time's Now button in the daily log in front (or the break
    log). It uses the spot taught with Ctrl+Alt+Shift+F.
  - The count starts over at Start of shift (Ctrl+Alt+L), or 14 hours after the first break.
  - settings.ini [Break] Minutes=60 sets the allowance. If you close a break log by mistake,
    only the first one counts.
  Built, NOT run (the sandbox can't run AutoHotkey).

MORE SAFEGUARDS  (v3.28.0)
  - Repeat the last log: Ctrl+Alt+Shift+R opens a new daily log in iTrak and fills it in with
    the same boxes as the last full-entry log (code word, call pad shorthand or Ctrl+Alt+F).
    Change the key in Customize > Shortcut keys.
  - Backups: the first start of each day Watchlog copies your templates.txt, my-templates.txt,
    settings.ini, autocorrect list and the taught click files (no passwords: Windows keeps
    those) to %LOCALAPPDATA%\Watchlog\Backups\<date>. The last 14 are kept. Tray > Advanced >
    Back up my settings and templates now makes one by hand.
  - Tray > Advanced > Restore from a backup... puts a backup back (what you have now is
    backed up first) and reloads.
  - Tray > Advanced > Go back to the previous version... puts back the copy Watchlog kept
    when it last updated and restarts on it. That newer version isn't offered again until
    you choose "Offer the skipped update again" (same menu).
  - Alert Grid (v3.27.3): the check that Alert Grid is in front now retries for 2 seconds, and
    the "no more alerts" click waits at least 250 ms for its box.
  Built, NOT run (the sandbox can't run AutoHotkey).

SHORTHAND LINES ON THE CALL PAD  (v3.26.0)
  Start the first line on the pad with a code word (no ; needed), press Ctrl+Enter, and
  the log is made. If the line has everything it goes in with no form; if something is
  missing the form opens with what it found already filled in.
      fill 205 5.5            table fill BJ205 $5,500  (5.5 and 5 mean thousands, 5k = $5,000,
                              500 = $500; two fills: fill 205 5.5 303 10)
      open 201 202 203        tables opened, on one line (a number is enough: 201 = UT201)
      201 auto                tables auto-closed (auto can come first or last: 201 202 auto)
      jack c2102 11421.11 w3 cash 2130      jackpot: machine, amount, window, time paid (military
                              time, optional; cash is the default wording)
      bv c2102 4471 full      emergency BV pull (full or def, for defective)
      mfill n3 190800 bvs     machine fill (v3.26.3), one fill per line for several; the older
                              n3 190800 bvs and c2102 11421.11 win 3 cash, with no code word,
                              now also make the log when you press Ctrl+Enter
      account 123456          account under review: fills the iTrak daily log (Guest
                              Services | Account under review | M6 (417))
  Any other code word first (cards ry301, aml 123 b1410) opens that log's form with the
  pad filled in as before. The older way still works: jot, Ctrl+Enter, then type the
  trigger. Careful: a call that starts with one of your code words as its first word will
  open that log's form when you press Ctrl+Enter.

CALL PAD AND AUTOCORRECT  (Numpad +, v3.12.0; shorthand v3.13.0)
Most of what goes into a log arrives on a phone call. The call pad is a
small window to jot it into while you talk, so it replaces the paper
notepad. It opens with the cursor in the box (one key, no mouse), stamps
the time of your first key, and keeps the text if you press Esc.

  Esc               Hides the pad. The text stays until New call.
  Ctrl+Enter        Make a log (v3.13.0): copies the call to the clipboard,
                    hides the pad and takes you back to the window you were
                    in. Then type any log's trigger (like ;jack): its boxes
                    are already filled in from the saved call, marked
                    "(from your call pad)". When that log is inserted the
                    call moves to Earlier calls and the next Numpad + opens
                    a fresh, empty pad (one call is one log).
                    (Cancelling the form keeps the call on the pad.)
                    What it picks up:
                      machine   B1410, NRT2, ATM3 (a letter and 3 to 5 digits)
                      table     any table in the @tables list, like UT201
                      amount    $4,000 or 4k  (not in ;player, which has Buy-in)
                      alert #   an 8-digit number (;aml)
                    A box is only filled when the pad holds exactly one of
                    that kind. Two different machines leaves the box empty.
                    Lists you pick from are only set to an item that exists.

SHORTHAND ON THE PAD  (v3.13.0), one per line:
  n3 190800 bvs         machine fill: NRT3 $190,800 (BVs)   (n1-n4 or nrt1-4)
  a1 100000             ATM1 $100,000                        (a1-a5 or atm1-5)
  n1 5000 bvs/divert    NRT1 $5,000 (BVs/Divert)   (any text with "div" in it)
  n2 90k                NRT2 $90,000        (k = thousand)
    Type ;mfill: the first fill is in the boxes and the form adds the
    others by itself (Add another), so the log has one line per machine.
    The new Note box on ;mfill is the text in brackets after the amount.
    Words after the amount other than bvs or divert go in the brackets as
    typed. Typing bvs straight into the Note box works the same (v3.14.0). (templates.txt wording Oct 25, 2026 (3) has the Note box: copy
    the new templates.txt into Documents\Watchlog, or the team folder.)
  c2102 11421.11 win 3 cash
                    a jackpot: type ;jack and the machine (C2102), the
                    amount ($11,421.11, cents kept) and the window (#3) are
                    filled in. The wording already says "paid all cash".
                    Time paid is not filled in (jot-time shorthand is not built).
  Copy all          Copies the pad text. Paste into window puts it where you
                    were typing.
  New call          Puts this call under "Earlier calls this shift" (the
                    last 8) and starts a fresh pad.

Time saved (v3.13.1): the keys you type on the pad for a call (and the + key and
Ctrl+Enter) count as typed when that call's log is inserted. The boxes the
pad filled are not counted a second time, so the saving is the log's length
minus what you actually typed on the pad.

The pad text and the earlier calls are kept on this PC only
(%LOCALAPPDATA%\Watchlog\call pad.txt and call pad history.txt), never in
settings.ini, the shared folder or the activity log. They are wiped at end
of shift (Ctrl+Alt+Shift+L) and are ignored after 14 hours.

Casino autocorrect fixes slang and acronyms as you type in the call pad and
in the log form boxes (typed boxes and boxes with a list, v3.14.0), when you
finish the word with a space, Enter or punctuation (tito becomes TITO,
handpay becomes hand pay, titos becomes TITOs). Ctrl+Z puts the old
word back. The built-in list comes from the SOP glossary acronyms: ABM AGCO AJM
APC CCOM CVT CFE CPU XVU CTR EPROM GMS GBHC IOC OLG PTM PMGR ROMSIG TITO MEAL RAM
WAN GM, plus handpay, cashbox, softcount, mainbank and shortpay.
Tray menu > Advanced > Edit the autocorrect list saves the list as
autocorrect.txt in the Watchlog folder and opens it in Notepad. That file is
then the whole list: add lines like  wrong = right, or put # in front of one
to switch it off. A saved change is used within a second (v3.14.1).
[CallPad] Autocorrect=no turns it off. It does not run in other programs.

THE TEMPLATE EDITOR  (Ctrl+Alt+E, v3.10.0)
  The easy way. At the top, pick the file: the team's templates (or
  templates.txt) or your own my-templates.txt.
  Templates tab: the list on the left (type in the search box to find
  one). Pick one and change its shortcut, name, section or wording on
  the right. The boxes in it are listed underneath: Add a box opens a
  small form (name, what goes in it: text, a list, a shared list,
  steps, the time now, a time, money, a percentage, a copied number,
  remember last time, facial rec alert # or match %, plus extras like
  capitals, what to leave when empty, something in front or after).
  The new box goes where the cursor is in the wording. Double-click a
  box (or Change box) to change it; Remove box takes it out.
  "How it will look" shows the finished log; anything wrong (a clash
  with another shortcut, a missing } or list) shows in red.
  New, Copy and Delete under the list. Several in one log = {repeat}.
  Shared lists tab: pick @tables (or any list), one choice per line.
  Rename changes every template that uses it.
  Save writes the file: it keeps a copy of the old one first
  (%LOCALAPPDATA%\Watchlog\template backups, the last 20) and moves
  the "# Wording version" line on. Saving the team's file asks once,
  since it changes every bay. If someone else saved the file while you
  had it open, it asks before writing over theirs. The new wording
  works as soon as you close the editor. Shortcuts don't fire inside
  the editor, so typing ;jack there is safe.

BY HAND IN NOTEPAD
Tray menu > Advanced > Edit templates in Notepad opens it. Save and the
script reloads by itself. The same rules apply to my-templates.txt and
to the team's shared file. The top of templates.txt has the full
instructions; the short version:

  ;trigger (Name) = the text that gets pasted

  - Start every trigger with ; and use no spaces in it.
  - No trigger can be the start of another one, because it would fire
    before you finish typing the longer one (that's why the soft count
    step is ;countstep, not ;count). The script tells you if two clash.
  - Don't start a trigger with ;t ;dd or ;dt (those are the stamps).
    The script skips such lines and tells you.
  - (Name) is optional. It shows on the form and the cheat sheet.
  - Lines starting with # are notes and are ignored.
  - \n makes a new line.

Blanks (any of these makes the template a form):
  {Machine}                    plain box
  {Who: employee | guest}      list you can pick from or type over
  {Outcome: pick | A | B}      list you must pick from
  {From: now}                  time box filled with the time now
  {To: now+20}                 time box filled with now + 20 minutes
  {Time paid: time}            time box (2130 becomes 21:30)
  {Amount: money}              10000 becomes 10,000
  {Match: percent}             67 becomes 67%
  {Employee #: clip}           fills in a copied employee #
  {Type: fromcopy | A | B}     opens the list on the item found in the
                               copied text
  {Alert #: alertcopy}         the 8-digit alert # copied in Edge (used
                               by ;face), checked against the last one
  {Match: matchcopy}           the match % copied in Edge (used by ;face)
  {Bay: last}                  remembers what you typed last time
  {Bay: saved}                 like last, but a bay entered in the last 14
                               hours (at the start of shift) is used without
                               asking; asks as usual if there isn't one (v3.20.2)
  {Step: next | A | B | C}     opens on the step after last time's
  {Machine: blank=AXXXX}       what to leave if the box is empty
                               (otherwise it leaves XX)
  {Asset #: prefix=# | blank=} adds # in front only if you fill it in;
                               blank= leaves nothing if empty
  {Signs: prefix=( | suffix=) | blank=}
                               adds ( ) around it only if you fill it in
  {Machine: caps}              capitals in machine numbers
                               (b1410 becomes B1410; in a Machine or
                               NRT box n3 becomes NRT3, a1 ATM1)
  {Note: tidy}                 bvs becomes BVs, bvs divert BVs/Divert
  {Table: @tables}             uses the @tables list (see below)
  {repeat}                     at the end of a form: adds an "Add
                               another" button (several in one log,
                               one per line)
  {Table: @tables | several}   with {repeat}: Add another adds to this
                               box instead, all on one line
                               ("BJ205, BJ206 and RO204 Opened.")
  Combine options with |, e.g. {Employee #: clip | blank=XXXXXXX}
  The same blank used twice in one template is one box that fills both.

Shared lists: a line starting with @ near the top of the file is a list
any blank can use. The table list is written once:
  @tables = UT201 | FB202 | UT203 | RO204 | BJ205 | BJ206 | RY301 | MP302 | BJ303 | BJ304 | BJ305 | RO306
and ;fill, ;cards, ;auto and ;player all use it, so adding a table is
one edit. If a template uses a list that doesn't exist, the script
tells you which line.

If a line has a mistake, a message tells you which file and line number
was skipped. The rest still work.

Wording version: the line "# Wording version: Oct 16, 2026" near the
top is shown in Security and status and on the cheat sheet. Change it
whenever you change the wording, so anyone can tell which version they
have.


-----------------------------------------------------------------------
 13. TEAM TEMPLATES AND YOUR OWN TEMPLATES
-----------------------------------------------------------------------
TEAM TEMPLATES (one shared file for everyone)
  The team keeps one templates.txt in a SharePoint document library.
  Whoever looks after the wording (a supervisor) can edit it; everyone
  else can read it. SharePoint keeps every earlier version of the file
  and who saved it (in SharePoint: the file's ... menu > Version
  history), so any change can be checked or rolled back.

  Each PC syncs that library through OneDrive (on SharePoint, press
  Sync, or "Add shortcut to My files"). Then in tray menu > Settings >
  Templates, press Browse and pick the templates.txt in the synced
  folder. Settings saves it as Shared= under [Templates] in settings.ini.

  From then on:
  - Everyone's Watchlog uses that file. When it changes and
    OneDrive syncs it, every PC reloads by itself and shows "The team's
    templates were updated". The activity log records the change.
  - A copy is kept on each PC (%LOCALAPPDATA%\Watchlog\team
    templates (last good copy).txt). If SharePoint can't be reached
    (OneDrive not running, not synced yet), that copy is used, a notice
    says so, and it switches back by itself once the file can be read.
  - Security and status shows the wording version and a check code
    (like 47E3-2566). Two PCs with the same check code have exactly the
    same wording, which makes "is everyone on the new wording?" a quick
    check.
  - The template editor (Ctrl+Alt+E) can change the team file; saving it
    asks first, and SharePoint's permissions decide whether you can.
    Tray menu > Advanced > Edit team templates in Notepad opens it too.
  Tip: right-click the synced folder > "Always keep on this device".

YOUR OWN TEMPLATES (my-templates.txt)
  In the template editor, pick "My own templates" at the top (or tray
  menu > Advanced > Edit my templates in Notepad). It makes
  my-templates.txt in the program folder the first time. Same format as templates.txt. These are added
  on top of the team's (or your templates.txt), for you only:
  - A trigger the team file already uses is skipped (and you're told),
    so the team wording always wins.
  - You can use the team's shared lists, like {Table: @tables}, and add
    your own @lists.
  - They show as "(mine)" in the template finder and the cheat sheet.
  - Make a copy to share never includes it.


-----------------------------------------------------------------------
 14. SETTINGS WINDOW AND settings.ini REFERENCE
-----------------------------------------------------------------------
Tray menu > Settings covers the everyday settings without editing the
file. It's also the Welcome window the first time Watchlog runs on
a PC. Since v3.10.0 it has tabs:
  Logins          add, edit, remove, change password (section 6), and
                  the reminder beep
  Templates       the team's shared file: Browse / Clear (section 13),
                  and a button for the template editor
  Start / end of shift
                  sign in to the Bally programs after Ctrl+Alt+L (SignIn),
                  put the windows back after it (AfterStart), how long it
                  waits for the programs (LaunchWait), the Edge pages
                  (FaceUrl, CitrixUrl), and what end of
                  shift closes ([EndOfShift] Close)
  Alert Grid      taught on this PC, using the team's setup, or not; Teach
                  and Share buttons, Caps Lock clears (CapsLockClears), wait
                  between clicks (Pause), the menu line of "Acknowledge as
                  received" (for the arrow keys)
  Updates         your own update folder ([Updates] Folder), and what
                  version is waiting there
  General         shift journal (what's saved, when old files go), the
                  Caps Lock guard, start Watchlog with Windows
Save writes settings.ini and reloads. Cancel changes nothing. Settings
you didn't change aren't written, so settings.ini stays short.

Everything else is in settings.ini (tray menu > Advanced > Edit
settings file).
Save it and it reloads itself.

[Templates]
  Shared=    the team's shared templates file. Blank = templates.txt
             in the program folder.

[Login1] ... [Login9]
  Trigger=   what you type, starting with ;
  User=      the username it types
  Window=    optional: only works while this program is in front. Several
             programs: separate them with |  (Settings > Pick window
             fills this in for you)
  Remind=    optional: minutes until the login reminder pops up
  (No password here. See section 6.)

[Paths]
  LaunchWait=     the most seconds Ctrl+Alt+L waits for the programs'
                  windows before opening the Edge pages (default 20, never less)
  FaceUrl=        the iTrak facial rec page Ctrl+Alt+L opens in Edge first
                  (blank = not opened)
  CitrixUrl=      the Citrix Receiver page it opens last in Edge
  CitrixTab=      words from the Citrix page's window title, split with |,
                  so Ctrl+Alt+L can bring that Edge window to the front. A
                  page still opening is named after its address, so
                  apps.gcgaming.com is always tried too (default:
                  Citrix|apps.gcgaming.com)
  (LaunchWork= and ChromeAccount= from older versions are ignored.)

[StartOfShift]
  Run1= ... Run9=        programs Ctrl+Alt+L opens. * = any version.
  Window1= ... Window9=  optional: how to spot it already open. The
                         three Bally apps are recognised automatically.
  (If this section is missing, it opens AlertGrid, SDS and CMP.)

[Journal]
  Save=      full (default), counts or off. See section 10.
  KeepDays=  days before old shift files are deleted (default 30,
             0 = keep them all)

[EndOfShift]
  Close=   program names to close, separated by commas

[App1] ... [App9]   Ctrl+Alt + Key switches to the app or opens it
  Name=    shown on the cheat sheet
  Key=     one letter. Taken: Q O I H P X R L E J (plus S and C if
           you keep SDS and CMP). Key=none turns an app off.
  Path=    the program or .bat that opens it (* = any version), or a
           link like msteams: for Microsoft Store apps
  Built in: T Teams, U Outlook, Y Spotify, G Edge. To give one a
  different letter, add an [AppN] with the same Name and a new Key.
  Window=  how to find its window (Ctrl+Alt+I shows a window's info)

[LastUsed]
  From before v3.3. The last bay and soft count step are now kept on
  each PC (%LOCALAPPDATA%\Watchlog\last used.ini), so OneDrive doesn't
  sync a change to settings.ini every time you use ;start. Old values
  here are still read until the new file has them.


-----------------------------------------------------------------------
 15. SECURITY, PRIVACY AND THE ACTIVITY LOG
-----------------------------------------------------------------------
Tray menu > Security and status shows all of this for the PC you're on,
checked live. Since v3.15.0 it opens with green/amber/red lights (no password
in settings.ini, version up to date, OneDrive running, nothing sent anywhere)
and one tab per part: Passwords, Templates, Journal, Kept on this PC, Never.
Copy full report (to paste into an email to IT
or a supervisor) copies the whole thing as text. It never shows a password.

WHAT IT KEEPS, AND WHERE
  Passwords        Windows Credential Manager on that PC only, as
                   "Watchlog: <username>". Never in a file, never
                   synced, never in the journal or activity log. Removing
                   a login in Settings deletes its password from the PC.
  settings.ini     Login shortcuts and usernames, app paths and journal
                   options. No passwords. Security and status checks
                   the file has none in it.
  Last used        The last value typed in boxes that remember one
                   (like the bay), on this PC only.
  Templates        Wording only. The team file on SharePoint, plus a
                   copy on each PC for when SharePoint can't be reached.
  Shift journal    A copy of each log you insert (or only the time and
                   name, or nothing), in Documents\Shift Journal.
                   Deleted after 30 days by default.
  Quick notes      Only what you type with Ctrl+Alt+Q, in
                   Documents\Quick Notes.md, until you delete it.
  Call pad         The text on the call pad and the last 8 calls, on that PC
                   only, wiped at end of shift (see CALL PAD above).
  Activity log     See below. On that PC only.
  Registry         The time of the last login per username, for the
                   log-in-again reminder (HKCU\Software\Watchlog).

WHAT IT NEVER DOES
  - It makes no internet connections and sends nothing anywhere itself.
    Files reach other PCs only through your own OneDrive and SharePoint
    sync, under your Microsoft 365 permissions. (Ctrl+Alt+L opens two
    work pages in Edge, the same as clicking their links.)
  - It doesn't keep what you type. It only watches for its own
    shortcuts.
  - It types a password only when you type that login's shortcut, and
    never in the template finder or the Settings window.

THE ACTIVITY LOG  (tray menu > Activity log)
  %LOCALAPPDATA%\Watchlog\activity.log, on that PC only. One line
  per event, with the date and time:
    - started (version, PC name, Windows user, program folder)
    - where the templates came from (team file or local, how many,
      wording version, check code), and any lines that were skipped
    - team templates changed (old and new check code), or the saved copy
      being used because SharePoint couldn't be reached
    - settings saved (login shortcuts and usernames, team file, journal
      options, start with Windows)
    - a password saved, moved out of settings.ini, or deleted (the
      username only)
    - each login used: the shortcut, the username and the program it
      was typed into (never the password)
    - shift journal files deleted by the clean-up
    - a copy made to share, and where
    - errors (line number and message)
  It never holds a password or the text of a log. It trims itself once
  it passes 200 KB, so it stays small.


-----------------------------------------------------------------------
 16. SETTING IT UP ON ANOTHER PC, OR FOR A NEW OPERATOR
-----------------------------------------------------------------------
WINDOW LAYOUT (v3.7.0)
  Arrange your windows the way you like them, press Ctrl+Alt+Shift+S, and
  Ctrl+Alt+W puts them back any time (tray menu: Save window layout / Put
  windows back). Ctrl+Alt+L also puts them back by itself at the end of
  the start of shift, once everything is open; the window you were in
  stays in front. If you never saved a layout, it does nothing.
  - Add  [Layout]  AfterStart=no  to settings.ini to stop the automatic
    part (Ctrl+Alt+W still works).
  - What is kept: the program name, position and size of each window, as
    numbers, in %LOCALAPPDATA%\Watchlog\layout.ini. This PC only: it is
    not synced, because each bay's screens are different. No titles and no
    contents.
  - Windows are matched by program, in the order they sit on the screen, so
    two Edge windows go back to the first and second spots saved.
    Minimised windows and Watchlog's own windows are left alone.
  - SDS and Alert Grid are the same program (Java), so since v3.19.3 the
    layout also notes which one each window is (from the start of its
    title; the title itself isn't kept) and they can't swap spots. A
    layout saved before v3.19.3 asks once to be saved again.
  - W is no longer free for an app hotkey ([AppN] Key=W is skipped).

CAPS LOCK GUARD (v3.7.0)
  Plain Caps Lock can't turn Caps Lock ON by accident: Shift+Caps Lock
  turns it on. Plain Caps Lock still turns it off (when it's already off it
  just shows a short reminder). While it's on, a red "CAPS LOCK ON" tag sits
  at the top right of the screen. No sounds. Tray menu > Caps Lock guard
  (ticked = on) turns the whole thing off on this PC; Ctrl+Alt+P pauses it
  along with the other shortcuts. Nothing is stored except that on/off
  choice (last used.ini).

FACIAL REC COPIES (v3.6.0)
  The facial rec page won't copy the alert # and the match % together, so
  Watchlog remembers your last copy of each. Copy the alert # (8 digits),
  copy the match (65%), in either order, then type ;face.
  - Only an 8-digit number or a percentage, copied in Edge, is remembered.
  - It is kept in memory only: never written to a file, forgotten after
    2 minutes or as soon as the log is inserted, and gone when Watchlog
    closes.
  - Alert numbers count up, so the last alert # logged is kept on this PC
    (last used.ini, a number only). The alert # box says if the copied one
    is the SAME as, or LOWER than, the last one logged.
  - Copies in other programs (like Citrix) are never read.

THE EXE (Watchlog.exe, v3.5.0 and later)
  Double-click Watchlog.exe on any PC. It asks "Install Watchlog on this
  PC?". Yes copies it to %LOCALAPPDATA%\Programs\Watchlog (no
  administrator rights), adds a Start menu entry and the Start with
  Windows shortcut, and lists it under Settings > Apps. A tutorial opens
  the first time. Your settings, templates and journal go in
  Documents\Watchlog, which OneDrive syncs between your bays. If the
  script version ran on that PC before (settings in Documents\AutoHotkey),
  it offers to copy your logins and your own templates across.
  Running a newer Watchlog.exe later offers to update the installed one.
  With a team folder set up, put the new Watchlog.exe next to the team
  templates.txt: each PC asks "Update now?", checks the new file starts,
  keeps the old one as a backup in %LOCALAPPDATA%\Watchlog, and restarts.
  To remove it: Settings > Apps > Watchlog > Uninstall. It asks whether
  to delete the saved passwords too, and keeps your settings and journal.
  It isn't code-signed, so Windows may say "Windows protected your PC"
  the first time: More info > Run anyway (or ask IT to allow it).

THE SCRIPT VERSION (for IT, on request)
  From v3.19.1 the release zip has only Watchlog.exe and its guides.
  The readable script (Watchlog.ahk, with the icon, the two build files
  and settings.example.ini) isn't handed out with it any more. If IT
  wants to read or check it, ask Jakob: he sends it to them directly as
  a separate "Watchlog vX script for IT" zip of the same version, under
  the same licence. Don't post it in the team folder.

YOUR OWN OTHER BAY PCs (script version)
  1. AutoHotkey v2 must be installed on that PC.
  2. Make sure OneDrive has synced the AutoHotkey folder.
  3. Double-click Watchlog.ahk. Then tray menu > Settings: tick
     "Start Watchlog when I sign in to Windows" and Save. (The
     Startup folder doesn't sync, so each PC needs this once.)
  4. Sign in to Edge with your work account once on that PC.
  5. The first time you use each login there, type its password once.

A NEW OPERATOR
  1. Tray menu > Advanced > Make a copy to share. Pick a folder (a SharePoint or
     Teams folder works). It makes a "Watchlog v3.7.0" folder with
     only: the program (Watchlog.exe, or Watchlog.ahk for the script
     version), the templates (the team's, if that's in use),
     QUICK START.txt, README.txt and LaunchWork.bat (the script version
     also gets the icon and settings.example.ini). It never copies your
     settings.ini, my-templates.txt, shift journal, notes, activity log
     or passwords, and it lists what it left out. The activity log
     records the copy.
  2. The new operator double-clicks Watchlog.exe and presses Yes. The
     tutorial asks only for their logins; the team templates are set in
     Settings. QUICK START.txt walks them through it. (With the script
     version they copy the folder to their own Documents and
     double-click Watchlog.ahk instead.)


-----------------------------------------------------------------------
 17. TROUBLESHOOTING
-----------------------------------------------------------------------
"There's no settings.ini in this folder"
  OneDrive may still be syncing, or it renamed the file to something
  like settings-PCNAME.ini (it does that when two PCs save it at once).
  Press Yes to check again. If it finds a settings-PCNAME.ini, it offers
  to use it, which puts your logins back. Tip: avoid changing settings
  on two PCs at the same time. Security and status lists any of these
  copies still lying around.

A login typed the wrong password
  Tray menu > Settings > pick the login > Change password, on that PC.

"The team templates file isn't there" / "couldn't be opened"
  Start OneDrive and let it sync. The last good copy is used meanwhile,
  so every template keeps working, and it switches back by itself.

A trigger fires somewhere it shouldn't
  Ctrl+Alt+P pauses everything. For a login, give it a window lock in
  Settings.

A Ctrl+Alt hotkey does nothing
  Another program may have grabbed it. Use the tray menu instead.

Apps open twice at the start of shift
  Something old is in shell:startup on that PC (e.g. an old
  LaunchWork). Remove it; only the Watchlog shortcut belongs there.

Ctrl+Alt+L says a Bally app wasn't found
  Check the path in [StartOfShift]. Keep the * in place of the version.

Ctrl+Alt+L opens Edge but not the Citrix page
  Check CitrixUrl in Settings (Start / end of shift).

"Some templates weren't loaded"
  The message gives the file and line numbers. Usually a missing = or a
  space in the trigger, or a trigger that's in the file twice.

Notepad opened behind other windows
  Windows 11 Notepad opens files as tabs. The script tries to bring it
  forward; if not, check the Notepad window on the taskbar.

Something else broke
  Take a screenshot of the error (it shows a line number) and send it
  to Claude. The activity log also has the line number.


-----------------------------------------------------------------------
 18. RULES WORTH KEEPING
-----------------------------------------------------------------------
  - Start every trigger with ; .
  - Never make a login trigger the same as your real username, or it
    would type your password inside an email address. The script warns
    you at startup about any login trigger with no ; and no window lock.
  - Don't share settings.ini. To give the tool to someone, use tray
    menu > Advanced > Make a copy to share.
  - Never put passwords in templates.txt, settings.ini or a note.
  - Before sharing the tool with the team, get the surveillance
    manager's and IT's OK.
```


---

# FILE 3: docs/Pending changes.md

# Watchlog: Pending changes

Suggestions collected for the next version. Nothing here is built yet.
When Jakob says to build, all of these go into one new version and this list is cleared.

Current version: v3.29.0 (Oct 31, 2026): break time tracker (;break log window watched until Save & Close, 60 min per shift, home/dashboard/tray tip, Ctrl+Alt+Shift+E End Time Now). Before that v3.28.0: safeguards batch 2 (repeat last log Ctrl+Alt+Shift+R, daily backups, restore, go back to previous version) on top of v3.27.3 Alert Grid step-5 timing, v3.27.2 load fix and v3.27.1 SDS sign-in fix (built, NOT run: the sandbox blocked running AutoHotkey).

## Waiting to be built

### Plan: failure safeguards (Oct 30, NOT built, waiting on Jakob's list of failures he has actually hit, and "build it")

From a read-through of Watchlog.ahk v3.23.0. Already safe today: login locked to a window is re-checked just before typing; full-entry logs (Ctrl+Alt+F) re-check iTrak is in front before every click; the call pad saves itself so a crash can't lose a call; a team templates file that won't load falls back to the last good copy; self-update tests the new file first and keeps the old one; OneDrive conflict copies of settings.ini show in the Security window; errors go in the activity log.

Ranked by how much harm the failure does. Speed cost is for a normal run where nothing goes wrong.

1. **Passwords only typed into a safe window.** Today: a login with no window lock types name, Tab, password, Enter into whatever is in front (only the finder and Settings are blocked). If the iTrak daily log, the call pad, Notepad, Teams or Outlook has the keyboard, the password lands there in plain text. Safeguard: refuse to type when the front window is one of those, say why, and offer once to lock that login to its program. Speed cost: none (one check).
2. **A form's log only pastes into the window you started in.** Today: after Enter on a form, Watchlog waits up to 2 seconds for that window to come back, then pastes anyway, even if it closed or a pop-up took the front. The log goes into the wrong window or nowhere. Safeguard: if it isn't back, don't paste; beep and show "The log is on the clipboard: click where it goes and press Ctrl+V". Speed cost: none.
3. **Alert Grid clearing stops if Alert Grid loses the front partway.** Today: it checks only at the start, so a pop-up arriving mid-run gets the right-click, menu and Submit clicks. Safeguard: check before each click and stop with a tip. Speed cost: under 1 ms per click, so a dozen alerts a second stays the same.
4. **Display scale changed since the clicks were taught.** Today: the scale is saved when iTrak spots are taught but never checked, so after a Windows scale change the clicks land in the wrong place without warning. Safeguard: compare at start-up (iTrak and Alert Grid) and warn once with how to fix it. Speed cost: none during the shift.
5. **Esc on a form doesn't throw away what you typed.** Today: Esc or the X closes the form and the boxes are gone. Safeguard: keep a cancelled form for 10 minutes (memory only, not on disk); reopening the same template fills the boxes back in with a note, Esc again clears them. Speed cost: none.
6. **Paste one of my last logs again.** Today: if a paste went missing you retype it, or dig in the shift journal. Safeguard: a pick list of this shift's last 5 logs (hotkey to choose), Enter pastes it again. Kept in memory only. Speed cost: none.
7. **templates.txt goes blank or half-synced.** Today: only the team file has a fallback; the local templates.txt does not, so a half-synced OneDrive copy loses templates silently. Safeguard: keep a last good copy on this PC; if templates.txt loads empty or with far fewer templates than last time, use the copy and warn. Speed cost: none (at load only).
8. **Settings get broken or overwritten.** Today: no backups of settings.ini, itrak.ini, alertgrid.ini or the window layout, and a OneDrive conflict copy is only mentioned in the Security window. Safeguard: one backup a day on this PC (keep 7), tray "Restore settings from a backup", and a tray message when a conflict copy appears. Speed cost: none.
9. **A bad update.** Today: the old version is kept but going back is by hand. Safeguard: tray "Go back to v(previous)" when a backup exists. Speed cost: none.
10. **An error mid-shift.** Today: AutoHotkey's raw error box with code appears and that action stops. Safeguard: a short plain message ("That didn't finish. Watchlog is still running.") with a Copy details button for reporting the line number. Speed cost: none.

Not proposed: an auto-restart helper if Watchlog closes (needs a second program or a scheduled task, more for IT to approve).

Questions for Jakob: which of these has actually happened to you? Anything else that has gone wrong on shift? Build all ten, or only some?

### Plan: shorthand line to finished log (Oct 30, step 1 of 2, NOT built, waiting on Jakob's examples and "build it")

**The idea.** You write one short line the way you jot it on paper, and Watchlog turns it into the finished log using the template you already have. No form when the line has everything; the form only opens when something is missing, with what it found already filled in.

**Where you type it.** On the call pad (Numpad +, as now). The first word is the code word of a template, with or without the `;`. Ctrl+Enter makes the log as it does today. Plain jottings with no code word in front keep working exactly as now (they still fill the next form).

**What happens.**
- Every box in that template has an answer from the line: the finished log goes straight into the window you were in (iTrak, Notepad...), counted in Time saved. No form.
- Something is missing: the usual form opens, found boxes say "(from your call pad)", the cursor sits in the first empty one.
- Boxes with a `blank=` that can stay empty (Note, Signs observed, Reason (only if up)...) do not count as missing.

**How the words are read** (order does not matter for most):
- Money: `5k`, `5000`, `5,000`, `$5000`, `11421.11` -> $5,000 / $11,421.11 (same as the pad does now).
- Table: any table in your tables list, any case; the number alone works when it is unique (`205` -> BJ205).
- Machine: a letter + 3 to 5 digits -> caps (`b1410` -> B1410); `n3` -> NRT3, `a1` -> ATM1.
- Pick lists: the first letters of a choice (`def` -> Defective, `exp` -> expired ID, `up`/`dn` -> Up/Down, `24`/`ind` -> 24 hour/indefinite).
- Numbers for # boxes (Alert #, Asset #, Player #, Window #) are taken in the order the template asks for them; `w3` or `win 3` always means the window.
- Anything left over goes into the one free-text box, if the template has one (Note, What the review showed...).
- Several items in a "several" or "Add another" template are all used (`open 201 202 203`, two fills in one line).

**Examples with today's templates** (made-up values):

| You type | You get |
|---|---|
| `fill 205 5k` | BJ205 $5,000 |
| `fill 205 5k 303 10k` | BJ205 $5,000 / BJ303 $10,000 (two lines, as Add another does) |
| `open 201 202 203` | UT201, FB202, UT203 Opened. (one line, as the several box does) |
| `cards ry301` | Card change on RY301. |
| `bv c2102 4471 full` | C2102 #4471 (Full) |
| `found b1410 45.20` | Operations Supervisor advised printing off abandoned credits in the amount of $45.20 from B1410. Funds taken to Security as found. |
| `aml 123 b1410` | AML Alert #123 populated at B1410 (time now). Review showed nothing suspicious. |
| `maint n2 n4` | NRT2 and NRT4 Maintenance. |
| `refuse 2 exp` | Security Officer refused entry to 2 patrons due to expired ID. |
| `jack c2102 11421.11 w3 2130` | the full jackpot sentence, time paid 21:30 (time format to confirm) |
| `player 123456 3 205 2k up 5k` | Player #123456 playing Spot 3, BJ205, In $2,000, Up $5,000. |
| `medical guest kitchen` | form opens (What the review showed / Outcome still needed), Who and Location already filled |

**Your own short codes (optional).** You can give any template a second, shorter code just for the pad, for example `f` for fill or `o` for open, in Customize. Safer than changing the real code words.

**Questions for Jakob before building:**
1. Five to ten real lines the way you jot them on the paper pad (fake numbers are fine), and what each should become.
2. How do you write times (2130, 9:30p, 930)? 24-hour in the log?
3. Should it also work outside the call pad, for example typing `;fill 205 5k` straight into iTrak and pressing a key? (Harder inside Citrix: see step 2.)

### Idea: "Info From" department search (Jakob's coworker, Oct 30, NOT built)
In iTrak's Info From section you attach anyone involved. Watchlog should not pick the person (no people data stored). It can do the boring part instead: open the Info From search, type the department, and then stop so you double-click the right name.
- How it would run: after a full-entry log or template fills in, a small list pops up: Cage, Security, Slots, Table Games, Surveillance, ... (type first letters, Enter). Watchlog clicks the taught Info From search spot, types the department, presses Enter, and leaves the results for you to double-click. Esc = skip, nothing attached.
- Logs that always need the same department can have it set ahead of time (for example `| from Security` on the line), and the list still shows with that one already highlighted, so you can change it with one key.
- A hotkey can also do it on its own, at any time, for any open log.
- Confirmed by Jakob (Oct 30, with screenshot): the Info From button is inside the Daily Log Entry window. Click it, a list drops down (Personnel, Subject, Contact, Company, Remove Selected, Remove All), click Personnel, click into a search bar, type, Enter runs the search. Department searches work. Watchlog would do those clicks and typing, then stop so you double-click the name.
- Teach spots (like the full-entry logs): Info From button, Personnel, and the search bar. Subject, Contact and Company could use the same idea later.
- Screenshots from Jakob (Oct 30): clicking Personnel opens its own "Personnel" window with a "Look For:" box at the top, Find Now / Clear, a results grid (Last Name, First Name, Middle Name, Gender, Property, Department, Position, Personnel ID) and Select / Cancel at the bottom. So the spots are: Info From button, Personnel (in the dropdown), and the Look For box in the new window (measured from that window, like the entry window). He is still sending the department names (his list so far shows Audit, HR, Marketing, Security, Surveillance, Property, Tables, Slots, Cage, OPS, Food & Beverage (FOH), Food & Beverage (BOH), which look like the department names; to confirm).
- Department list CONFIRMED complete for now (Jakob, Oct 30): Audit, HR, Marketing, Security, Surveillance, Property, Tables, Slots, Cage, OPS, Food & Beverage (FOH), Food & Beverage (BOH).
- Must be editable (Jakob's rule: the program stays editable): the list lives in a shared list in templates.txt (like @tables, for example `@departments = ...`) AND gets a screen in Customize Watchlog to add, rename, reorder and remove departments, with the same backup-on-save as the other editors. Shipped with the 12 above.

### Step 2 (after step 1): autocorrect everywhere, including Citrix/iTrak
Your autocorrect list working in every program, not just the call pad and form boxes. Gotcha to plan around: inside Citrix, Watchlog must not read or empty the clipboard to fix a word (the Citrix clipboard can stick); fix by typing (backspaces + the right word) instead, and test in iTrak first. On/off switch and a "skip these programs" list. Design comes after step 1 ships.



- **More full-entry logs** (Jakob, Oct 30): rule: only logs needing NO extra input; fixed-except-one-detail logs (tables, cards, maint...) keep their code word and are NOT in the list; no table closing. Added in templates.txt (no new version): Garbage Sweep (Cage ManTrap, Security Escort, M6 (972,973), synopsis as ;man, no End Time click). Interior / Exterior / Parking: approved, but officer vs supervisor varies; proposal: separate entries (Interior Supervisor, Interior Officer, Exterior Supervisor, ...), type the first letters + Enter. Waiting on Location, Topic, Reference and End Time click for those three.
- **Not doing** (Jakob, Oct 30): sharing the daily log field spots to Bay 2/3 (monitors differ, spots would break); safety stop (iTrak already will not overwrite an open log).


- Time paid shorthand on the jackpot line (for example a 4-digit time) and what he jots when it is not all cash (cheque? part cash?): asked, no answer yet.
- Shorthand for other logs: see the plan at the top (step 1).
- Copy memory for any program (machine, table, alert #, money from a Ctrl+C), only if the call pad is not enough.
- Optional quick insert when every form box is already filled (off by default).
- Autocorrect list could be shared from the team folder beside templates.txt.

## Done in v3.29.0 (Oct 30)
- Fix: the hourly SDS sign-in stopped with "no saved login is locked to SDS". It now brings SDS back and retries, then falls back to the login whose Only in names SDS, and logs the logins' triggers and windows if it still can't.

## Done in v3.27.0 (Oct 30)
- Failure safeguards, first batch (items 1 to 5 and 10 of the plan below): passwords never typed into Notepad, mail, chat, Office, Watchlog's windows or the daily log when a login has no program set; refused logins show a message; form logs aren't pasted into the wrong window (they stay on the clipboard); Alert Grid stops if a pop-up takes the front; display scale warning at start-up; a form closed with Esc comes back for 10 minutes; plain error box.
- Still in the plan: 6 repeat a recent log, 7 templates.txt backup, 8 settings backups and restore, 9 go back to the previous version.

## Done in v3.26.3 (Oct 30)
- Fix: `mfill n3 190800 bvs` (and the old `n3 190800 bvs` with no code word, and `c2102 11421.11 win 3 cash` for a jackpot) pressed with Ctrl+Enter on the call pad now make the log directly instead of opening an empty form.

## Done in v3.26.2 (Oct 30)
- ;fill ;open ;auto ;jack ;bv ;mfill also fill the iTrak daily log (Location, Topic, Reference as Jakob gave them; Reference left empty for him on fill, jack, bv and mfill). Pit comes from the table (@pit list), Alpha/Bravo/Charlie Slots from the machine letter (@slots list), both editable in templates.txt: groundwork for more automation. Open: is D = Delta Slots? exact iTrak topic names; Auto-close Reference assumed NA.

## Done in v3.26.1 (Oct 30)
- Fix: Alert Grid clearing no longer skips the final clear-acknowledged click (step 5) after the acknowledged-alerts fallback of v3.24.1 (Jakob: it stopped finishing). v3.26.0 was never sent on its own; 3.26.1 includes its shorthand lines.

## Done in v3.26.0 (Oct 30)
- Shorthand lines on the call pad: first word a code word, then Ctrl+Enter makes the log with no form when the line is complete. `fill 205 5.5`, `open 201 202 203`, `201 auto`, `jack c2102 11421.11 w3 cash 2130`, `bv c2102 4471 full`, `account 123456`. Any other code word first opens its form with the pad filled in.
- ;account is now a daily-log fill: Guest Services | Account under review | M6 (417), "Account #XXXXXX reviewed, not banned player. Account cleared and Guest Services notified."
- Not done: `;found` and `;aml` shorthand (Jakob said leave them). Still open: shorthand for more logs, optional short codes (f for fill) in Customize, typing a shorthand line outside the pad.

## Done in v3.25.1 (Oct 30)
- Fix: v3.25.0 failed to start with Missing quote on line 6258 (a space then ; inside a string is a comment in AutoHotkey). The new prefix text in Settings now escapes it.

## Done in v3.25.0 (Oct 30)
- New setting: the character(s) typed in front of code words, logins and the stamps (;t ;dd ;dt) instead of ; (Settings > General, or settings.ini [Triggers] Prefix=). 1 to 3 symbols. Per PC; templates files keep the ;. Saves and reloads.
- Not changed: the template editor still shows ; (it edits the files).

## Done in v3.24.1 (Oct 30)
- Alert Grid: when acknowledged alerts are in the list, the right-click menu won't open. Now, if the Acknowledge box doesn't show, Watchlog clicks the clear-acknowledged button first (and the no-more-alerts click), then clears the unacknowledged alerts as usual. Once per clear; costs nothing when there are no acknowledged alerts. Needs the clear button taught. Jakob to say what Alert Grid shows when the right-click is refused (a popup? its title).

## Done in v3.24.0 (Oct 30)
- Code words that fill the whole iTrak daily log: end a templates.txt line with ` >> Location | Topic | Reference` (add `| end` last to click End Time Now). Typing the code word (and answering its boxes) fills the open daily log, or opens a new one if none is open, from any window. Shift+Enter on the form, or Shift held when a no-box code word fires, pastes just the wording instead. First one: `;cards` (Card change) with GUESSED Location/Topic/Reference "Pit 2 | Card Change | NA": Jakob to correct.
- Still open: more code words to convert (Jakob to say which), and a Customize screen box for it.

## Done in v3.23.0 (Oct 30)
- Edge-only start of shift: Ctrl+Alt+L opens iTrak facial rec and the Citrix page in one Edge window (FaceUrl, CitrixUrl). Removed Ctrl+Tab tab hunting, keep-on-top guard, Chrome profile lookup, ChromeAccount and LaunchWork.bat use; Ctrl+Alt+G is Edge. Each bay re-saves the window layout once. Built without running AutoHotkey (Wine run blocked).
- Docs: all versions brought to 3.23.0 (Overview and IT Summary said 3.10.1), docx/pdf rebuilt, ChatGPT hand-off rebuilt.

## Done in v3.22.2 (Oct 30)
- Settings window: the tab area is taller (350 -> 400), so the "Beep when a log-in-again reminder pops up" tick on the Logins tab is no longer cut off by Save and Cancel (Jakob's screenshot, display scaling makes text taller than under Wine).

## Done in v3.22.1 (Oct 30)
- Jakob's first look at the dark theme: dark text on a dark background somewhere, so light is now the default (blue accent kept, teal gone) and dark is a switch: tray menu > Dark look, or Customize. Dark text on dark probably came from a colour I did not remap; if he turns dark on again and sees it, ask for a screenshot.

## Done in v3.22.0 (Oct 30)
- Dark look with a blue accent in every window (Jakob: "I like a dark colour scheme", blue or forest green, my pick: blue). Built as a WGui class that remaps the colours each window asks for; Customize > "Dark look" turns it off ([Look] Dark=no). Tabs show as a row of buttons.
- Home window: three panels at the top (logs, logins, typing saved this shift).
- Interior, Exterior and Parking Officer/Supervisor full-entry logs (six, in templates.txt, no End Time click).
- Docs brought up to v3.22.0: README, QUICK START, the plain Overview, the IT Summary and the one-page Summary (Word and PDF). The "(with screenshots)" overview was NOT redone (needs new screenshots).
- Not tested on a real Windows PC: only under Wine, which draws buttons and lists light. The dark buttons, list headers and scroll bars rely on Windows' own dark mode, so check them on the bay.

## Done in v3.21.0 (Oct 30)
- The Start full-entry log also clicks End Time's Now button (Jakob asked; goes out with this build).
- Customize Watchlog (tray menu and a Customize button on the home window): screens for the full-entry daily logs (add, edit, copy, delete, try), the shortcut keys (21 of them can be changed; pause, reload, app keys and form keys stay), the programs opened and closed at the start and end of shift, the shared lists (opens the template editor on that tab), the autocorrect words, and the speed and timing values; logins, reminders, Caps Lock, journal and updates open Settings on the right tab.
- The tray menu, home window and cheat sheet show the shortcut keys you picked.
- Saving from these screens applies right away, with no automatic restart (the hotkey screen restarts Watchlog).
- Not tested: pressing the shortcut keys (Wine can't fire hotkeys), so a changed key is checked only for being registered.

## Done in v3.20.3 (Oct 30)
- Start of shift full-entry log: "start" in the Ctrl+Alt+F list. Surveillance, Duty, NA, synopsis "Start of Shift Bay (bay) Operator". It always asks which bay (offering the last one) and keeps the answer for the shift; the End log and ;end then use it without asking. It leaves End Time alone (add `| end` to its line in templates.txt if you want the Now click too).

## Done in v3.20.2 (Oct 30)
- Confirmed on Jakob's PC: the End log fills in about 4 seconds, against about 15 s by hand (7 s was his best). Real timing for the manager pitch.
- End of shift full-entry log: type "end" in the Ctrl+Alt+F list: Surveillance, Duty, NA, synopsis "End of Shift Bay (your bay) Operator", then End Time's Now button is clicked. New fifth teach step (End Time's Now button): run Ctrl+Alt+Shift+F again.
- The bay entered at the start of shift is kept for the shift (14 hours): the ;end template and the End log no longer ask for it (new box option {Bay: saved}; asks as before if no bay was entered at the start).

## Done in v3.20.1 (Oct 30)
- Fix for the daily log teach step ("the click position wasn't in the iTrak window"): the daily log form is its own window titled "Daily Log Entry - N/A - \\Remote", so the field spots are now measured from that window, and the fill waits for the new form to open instead of a fixed pause.

## Done in v3.20.0 (Oct 30)
- Full-entry daily logs: Ctrl+Alt+F opens a pick list (type the first letters, Enter) of never-changing logs; Watchlog opens a new daily log in iTrak and fills Location, Topic, Reference and Synopsis with no questions. Break, Table Drop and Card Destruction are ready-made in templates.txt (lines `+Name = Location | Topic | Reference | Synopsis`). End Time and Save stay yours. Ctrl+Alt+Shift+F teaches the four field spots once per PC. Counted in Time saved and the journal ("Full log: Break"): 5 keystrokes per drop-down, full length of Reference and Synopsis plus 1 per click, 2 for the new-log click.
- SDS login reminder: no "log in again" reminder for a login typed into SDS while "Sign back into SDS by itself" is ticked (it was only skipped when the login was locked to SDS with Window=). Untick the box to get the reminder back.
- Home window: the whole Shift section is gone (shortcuts and the cheat sheet remain).
- Not tried on a real iTrak/Citrix: Wine test with a fake iTrak window passed (pick list, clicks, typing, paste, counts).
- Still open from this thread: more full-entry logs from Jakob (he is sending 3-5; 3 done), End Time Now click is NOT used, sharing the field spots with the team, other home window trimming.

## Shipped without a version (templates.txt only)
- Oct 30 (night): ;jack topic typed as Jackpot (the drop-down item is "Jackpot / Table Win" and needs spaces around the slash, so the short word is typed), ;bv topic Emergency Pull. The topic box is not case sensitive. Wording version Oct 30, 2026 (5).
- Oct 30 (later): the eight code words that match a full-entry log now fill the daily log too: ;start and ;end (click End Time Now), ;interior, ;exterior, ;parking (Officer/Supervisor pick box, same Location/Topic as the + lines), ;drop, ;man, ;destroy. Ctrl+Alt+F and the + lines are unchanged. Wording version Oct 30, 2026 (2). Not tested on a bay.
- Oct 30: `;break` code word fills a daily log (Surveillance | Duty | NA, synopsis Break), same as the Ctrl+Alt+F Break entry. Needs v3.24.0 or newer. Wording version Oct 30, 2026 (1). `;cards` confirmed working.
- Oct 29: ;open and ;auto got {repeat} (one table per line); replaced the same day by v3.19.3's one-line list.

## Done in v3.19.3 (Oct 29)
- Start of shift no longer puts SDS where Alert Grid goes. Both are the same Java program (javaw.exe) and the layout matched them by front-to-back order, so after the start of shift sign-in left SDS in front it took Alert Grid's spot. Save window layout now notes which one each Java window is (Alert Grid, SDS or other, from the start of its title; the title isn't saved) and Put windows back matches on that. A layout saved before v3.19.3 still works the old way and asks once to be saved again (Ctrl+Alt+Shift+S).
- Several tables on one line: ;open and ;auto take Add another (Ctrl+Enter) and paste "BJ205, BJ206 and RO204 Opened." New box option | several (README, template options). The table box starts empty; a table added twice is listed once.
- Tested under Wine with fake SDS and Alert Grid windows (the old matching swapped them, the new one doesn't) and the forms. The real Bally windows only on a bay.

## Done in v3.19.2 (Oct 29)
- Alert Grid teach has a new step 6 (the casino added a click that says there are no more alerts, last in the sequence, after the clear-acknowledged button). Hover over the box's button and press F8. Saved as NoMoreX/NoMoreY (+ NoMoreBox, the box's title, when it's a separate box; measured from that box) in alertgrid.ini and included in Share my setup with the team. Old teaches work and skip the click until re-taught. Waits up to 0.8 s for the box, so no extra delay when it isn't there. Built without running AutoHotkey (not run under Wine).

## Done in v3.19.1 (Oct 27)
- Copyright and licence (step 1 of making Watchlog proprietary): "Copyright (c) 2026 Jakob Blair Vanness. All rights reserved." and a short licence (permission only, no copying/sharing/changing/redistributing, provided as is). New About Watchlog window (tray menu and home window); the line also shows under the tutorial, in the version box, at the bottom of the cheat sheet and in Security and status; Copyright field in the exe's file properties; block at the top of README, QUICK START, templates.txt and Watchlog.ahk; LICENCE.txt in the zip, built into the exe and in Make a copy to share.
- Release zip has only Watchlog.exe and the text files. The script version is in "for IT (on request)" in the project files, for Jakob to send IT directly.
- Built with build/rebuild-resources.py (Python, swaps the resources in the v3.19.0 exe) because running AutoHotkey under Wine was blocked this time: not run or tested under Wine.

## Done in v3.19.0 (Oct 27)
- Ctrl+Alt+D opens a new daily log in iTrak (a taught mouse click, or two if it takes a button and a menu line), Ctrl+Alt+Shift+I teaches it. Measured from inside the iTrak window, follows the nearest edge on resize, refuses when the window is too small or off screen, can be shared through the team folder (tray > iTrak). Settings > Alert Grid tab, tray, home tile, Security status and cheat sheet updated. Wine-tested with a fake iTrak (10 cases); the teach step and the real Citrix click can only be tried on a bay.

## Done in v3.18.0 (Oct 26)
- Alert Grid clear works wherever Alert Grid is and whatever its size: spots measured from inside the window (old teach files change over by themselves), the clear-acknowledged button follows its nearest edge on resize, the teach asks which menu line "Acknowledge as received" is (also in Settings > Alert Grid) and the arrow keys pick it when the menu opens upward near the bottom of the screen or a menu click misses, and it refuses (clicks nothing) when Alert Grid is too small or off the screen. Tray > Alert Grid > Share my setup with the team puts the numbers in alertgrid.ini in the team folder (per screen scaling) for PCs that haven't been taught. Not done: UI Automation / Java Access Bridge, picture search. Wine-tested with a fake Alert Grid (11 cases pass); the real Java menu and arrow keys only on a bay.

## Done in v3.17.6 (Oct 26)
- Alert Grid clear, option A (Jakob): no Caps Lock wait, modifier wait only while Ctrl/Alt/Shift are really down (max 250 ms), Ctrl+A held ~20 ms, 5 colour reads instead of ~20, SelectWait default 120 (Ctrl+A re-pressed halfway), lone alert 40 ms.

## Done in v3.17.5 (Oct 26)
- Alert Grid clear faster again (Jakob: still slower than before): key-release wait capped at 250 ms in total, SelectWait default 200, lone alert 50 ms, 5 ms polling, no extra pause after the list turns blue.

## Done in v3.17.4 (Oct 26)
- Alert Grid clear made quicker for busy lists (about a dozen alerts a second): shorter Ctrl+A hold, 15 ms polling, about 20 colour reads instead of 100.

## Done in v3.17.3 (Oct 26)
- Alert Grid clear with a single alert: the row is already blue from the click, so a plain column under it now means only a 100 ms wait.

## Done in v3.17.2 (Oct 26)
- Alert Grid clear with a single alert was slow (waited 800 ms for a colour change that never comes): wait is now 300 ms.

## Done in v3.17.1 (Oct 26)
- Alert Grid clear (Ctrl+Alt+A, Caps Lock) no longer clears just the top alert half the time: waits for Ctrl/Alt/Shift/Caps Lock to be let go, holds Ctrl+A like a real keypress, watches the list turn selected (presses Ctrl+A again if it didn't), then right-clicks. Wine-tested only with a fake list that ignores the first Ctrl+A.

## Done in v3.17.0 (Oct 26)
- Edits in the shift journal count everywhere: each log carries a [k] tag with its exact keystrokes saved; removing, renaming or adding logs in Ctrl+Alt+J and pressing Save changes updates Shift count, this shift, Time saved and the dashboard. Old untagged logs use the type's average.

## Done in v3.16.0 (Oct 26)
- Shift dashboard (Ctrl+Alt+Shift+D, tray, buttons in Shift count / Time saved): This shift, Week and Month tabs, Copy summary, Save as a sheet (HTML in Shift Reports). Per-day log counts by type filed in time saved.ini [DayItems] (400 days). Numbers only. Wine-tested only; exe built.

## Done in v3.15.0 (Oct 26)
- Shift journal window (Ctrl+Alt+J) is editable, with Save changes / Undo edits, safe against logs arriving while it is open.
- Cheat sheet (Ctrl+Alt+H) redrawn in three coloured columns.
- Security and status redrawn: green/amber/red status lights and one tab per section.

## Done in v3.14.2 (Oct 26, verification run)
- Form autocorrect never ran before v3.14 (wrong control type check); fixed. Plurals for every fix. N/A expand only in Machine/NRT boxes, not Location. An old saved call no longer fills forms after a restart. The template editor keeps `tidy`. Copy boxes (Employee #, Employee type) no longer pick a number or job title out of the last log Watchlog pasted. settings.example.ini lists the Alert Grid, reminder beep, SDS sign-back-in and update folder settings.

## Done in v3.14.1 (Oct 26)
- Switching a fix off with # works while the pad is open.

## Done in v3.14.0 (Oct 26)
- From the first full test pass: ;mfill note tidy (bvs -> BVs), autocorrect in drop-down boxes and plurals (titos -> TITOs), N/A expand to NRT/ATM in machine boxes, ;firm default Operations Supervisor, unlocked logins in the cheat sheet, faster Ctrl+Alt+L, Quick Notes Notepad warning match fix.
- Still open: autocorrect everywhere (above), the Notepad-only key problems (C2, C3, C4, C6, G8: retest elsewhere), R11 retest, and the skipped tests (H5, H10, H11, I5, K4, P5, P12, P13, P14, Q15, R12, S5).

## Done in v3.13.1 (Oct 25)
- Time saved counts the keys typed on the call pad (the pad's own typing is the cost, the boxes it fills are not counted twice).

## Done in v3.13.0 (Oct 25)
- Make a log copies the call to the clipboard and hides the pad; the next log's form fills from the saved call; after that log is inserted the call moves to Earlier calls and the pad is empty.
- Machine fill shorthand: `n3 190800 bvs` -> NRT3 $190,800 (BVs), `a1 100000` -> ATM1 $100,000, `(BVs/Divert)`; several lines open ;mfill with every machine added automatically. New Note box on ;mfill (wording Oct 25, 2026 (3)).
- Jackpot shorthand: `c2102 11421.11 win 3 cash` fills machine, amount (cents kept) and window in ;jack.
- Alert Grid clear: waits [AlertGrid] SelectWait (default 200 ms) after Ctrl+A, for the Caps Lock clear that sometimes cleared only the top alert. Not confirmed fixed.

## Done in v3.12.1 (Oct 25)
- WAP and R4 taken out of the default autocorrect list.

## Done in v3.12.0 (Oct 25)
- Call pad: Numpad + (Ctrl+Alt+N backup) opens a jot pad, one hand, time stamped at the first key, Esc hides and keeps the text, Make a log (Ctrl+Enter) opens the finder and the forms fill machine, table, amount and alert # from the pad, Copy all, Paste into window, New call, Earlier calls this shift. Kept on this PC only, wiped at end of shift.
- Casino autocorrect in the pad and the form boxes, from the SOP glossary acronyms (list in autocorrect.txt via tray > Advanced > Edit the autocorrect list). Jakob OK'd MEAL RAM WAN and the rest. Ctrl+Z undoes a fix.

## Done in v3.11.0 (Oct 25)
- Shift count: exact per-item tally of one shift (templates by name, logins, stamps, Alert Grid clears, app switches) with keystrokes saved. Jakob said "build it".
- Wording review sheet: the four old refusal rows are now the one `;refuse` row, with all its choices spelled out.


## Done Oct 21 (no version change)

- Overview: the Ctrl+Alt+L line is back, now saying apps first, then websites, ending on the Citrix page (v3.4.0 order). Done in both overview versions; later overview edits go in the plain version first, then the illustrated one is rebuilt. Overview easier to follow, screenshots version, time saved section, SDS logout line and Ctrl+Alt+K are all done too. Both say v3.4.1 now.
- settings.example.ini: the example login was `;me`, which clashes with `;medical` (it would fire first and the template got skipped); now `;login`. LaunchWait example is 20, matching the "at least 20" note.
- README: `suffix=` added to the box options list.

## Built in v3.10.1 (Oct 25)

- SDS signs itself back in 62 minutes after an SDS login (Settings > Logins; [SDS] ResignMinutes=, 0 = off). Replaces the 55-minute pop-up for logins locked to SDS.

## Docs refreshed for v3.10.1 (Oct 25)

- Overview (plain and illustrated), IT Summary and Summary updated; no new screenshots. Test notes in docs/Test notes v3.10.md.

## Built in v3.10.0 (Oct 25)

- Watchlog home window: click the tray icon or Ctrl+Alt+M. Buttons with pictures in four groups (Logs, Shift, Logins, Set up), each showing its shortcut, and a status strip (up to date, templates, Alert Grid taught, this shift's time saved) with Caps Lock guard and pause ticks.
- Tray menu tidied: a picture beside each item; Alert Grid, Windows and Advanced sub-menus; AutoHotkey's own items gone (Pause and Reload under Advanced); Exit at the bottom.
- Settings in tabs (Logins, Templates, Start / end of shift, Alert Grid, Updates, General). New boxes and ticks for what used to be settings.ini only: sign in after start of shift, windows back after start, launch wait, LaunchWork.bat, Google account, what end of shift closes, Caps Lock clears alerts, wait between Alert Grid clicks, own update folder, Caps Lock guard.
- Template editor (Ctrl+Alt+E): change shortcut, name, section and wording; add, change and remove boxes with a form; live preview and problem check; New, Copy, Delete; Shared lists tab (@tables) with Rename; Save keeps a backup and bumps the wording version. Notepad editing is under tray > Advanced.

## templates.txt only, Oct 25 (no version change)

- New `;firm` (NRT firmware check): Department/Title, Location/NRT#, then a new line `DUB#` + number. Wording version Oct 25, 2026 (1). 35 templates.

## Built in v3.9.5 (Oct 25)

- Plain Caps Lock clears the Alert Grid alerts (guard on, Alert Grid open); CapsLockClears=no turns it off.

## Built in v3.9.4 (Oct 25)

- Login reminder beep is a Settings checkbox (default off).

## Built in v3.9.3 (Oct 25)

- The login reminder (SDS etc.) no longer beeps.

## Built in v3.9.2 (Oct 25)

- Alert Grid clear is faster and retries up to 3 times if a new alert drops the selection ([AlertGrid] Pause= is the wait between clicks, default 40 ms).

## Built in v3.9.1 (Oct 25)

- Alert Grid clears count 3 keystrokes each in Time saved (keystrokes only).

## Built in v3.9.0 (Oct 25)

- App keys for SDS and CMP offer to log you in after bringing the program forward (asks, Enter = yes, Esc or 6 s = no; uses the login locked to that program).
- Ctrl+Alt+L ends by offering to sign into the Bally programs it just opened (SignIn=no turns it off).
- Own update folder: tray > Choose my own update folder ([Updates] Folder=).


## Built in v3.8.5 (Oct 25)

- Alert Grid: 5th teach spot, the button that clears acknowledged alerts, clicked at the end of Ctrl+Alt+A.

## Built in v3.8.4 (Oct 24)

- Alert Grid teach has a 4th spot (the final OK button), clicked instead of pressing Enter.

## Built in v3.8.3 (Oct 24)

- Teach step reads F8 / Ctrl+Alt+Shift+A by polling the keys instead of hotkeys (F8 did nothing on his PC with Alert Grid in front).

## Built in v3.8.2 (Oct 24)

- Teach step: Esc no longer cancels (it was swallowed, and he uses it to close the menu); Ctrl+Alt+Esc cancels.

## Built in v3.8.1 (Oct 24)

- Teach step for the Alert Grid key also accepts Ctrl+Alt+Shift+A as the capture key (in case F8 needs Fn), and says so when it is cancelled or times out. Rolled in with the v3.8.0 items below.

## Built in v3.8.0 (Oct 24)

- Alert Grid clear-all: Ctrl+Alt+A from any window clears every alert (Ctrl+A, right-click, Acknowledge as received, Submit, OK) and puts you back. Ctrl+Alt+Shift+A teaches the three click spots once per PC (F8). Never types the password. Tested under Wine with a fake Alert Grid; real one and the teach step not tested.
- Pit 3 tables RY301 MP302 BJ303 BJ304 BJ305 RO306 added to @tables (wording version Oct 24, 2026 (1)).

## Built in v3.7.1 (Oct 24)

- Quick notes: Ctrl+Alt+O opens a Watchlog window that always reads Quick Notes.md fresh (Open in Notepad button inside), refreshes when a note is added, and moves notes saved on this PC while OneDrive was off into Quick Notes.md. Ctrl+Alt+Q warns if Quick Notes.md is open in Notepad (a stale tab saved over new notes). Tested under Wine; not tested with real Notepad.

## Built in v3.7.0 (Oct 24)

- Window layout moved in from Desk Helper (layout confirmed working on Jakob's PC): Ctrl+Alt+Shift+S saves, Ctrl+Alt+W puts back, also on the tray menu. Stored per PC in %LOCALAPPDATA%\Watchlog\layout.ini (numbers only). Ctrl+Alt+L puts the layout back by itself at the end (after the Citrix tab step, keeps the window you were in in front); `[Layout] AfterStart=no` turns that off. Minimised windows and Watchlog's own windows are left alone. W added to the taken app keys.
- Caps Lock guard moved in too, with no beep anywhere: Shift+Caps Lock turns it on, plain Caps Lock only turns it off (a short tooltip reminder when it's already off), red CAPS LOCK ON tag top right while on. Tray menu > Caps Lock guard (ticked) switches it on/off per PC (last used.ini [Caps]); default on. Not testable under Wine: the real CapsLock key hook; the state, tag and toggle were tested.
- Desk Helper is now retired (files kept in desk-helper/; don't run both, they use the same keys).
- Not tested: Ctrl+Alt+L auto-restore on a real start of shift, real CapsLock presses.

## Built in v3.6.0 (Oct 22)

- `;face` fills itself: remembers your last copy of the alert # (exactly 8 digits) and the match % (e.g. 65%) in memory only (Edge only, 2 minutes, cleared on insert), in either order. The alert # box warns if the copied number is the same as or lower than the last one logged (kept on this PC, number only).
- `;audit`: the Employee type opens on the job title found in the copied text, if any; the Employee # `clip` box now also works from a longer copy with exactly one 4-8 digit number in it.
- Pick-or-type lists complete as you type (d becomes Dealer, ca becomes Cage Cashier); on every such box in every template. Only when text is added, so Backspace never fights you; drop-down-only (`pick`) lists unchanged.
- New box options: `alertcopy`, `matchcopy`, `fromcopy`. Wording version Oct 22, 2026 (5).
- Not tested: real Edge copy events and the clipboard watcher on Windows (Wine only tested the logic).

## Built in v3.5.0 (Oct 22)

- Watchlog.exe: one file, no AutoHotkey needed. It installs itself (Start menu, Start with Windows, Settings > Apps, uninstall) and keeps settings in Documents\Watchlog. First run offers to copy settings from the script version.
- Guided tutorial on first run (tray > Tutorial any time): logins, a quick entry, a form, finding a code, handy keys. Nothing from it goes in the journal or time saved.
- Team-folder updates work with Watchlog.exe too (backup kept, restarts by itself).
- build/ has the two files that make the exe.

Ideas for later: visual template editor, Help/About window, code signing if IT asks, build the exe with a GitHub Action.

## Built in v3.4.3 (Oct 22)

- Login window lock takes several programs separated by `|`; checked again just before the password is typed (blocked tries go in the activity log).
- Settings > Add/Edit login has a Pick window button: click the program and its name is filled in. Browsers/Java programs also get the title (to be trimmed); Citrix gets `ahk_exe wfica32.exe`.
- Settings list and Security report say "(any program)" for logins with no lock.
- Jakob's own shortcuts: `;prd` = CMP, SDS, AlertGrid; `;jv` = facial rec iTrak, OLG RTMS; his third = daily log iTrak (Citrix) and Windows sign-in (the real lock screen can't be typed into).

## Built in v3.4.2 (Oct 21)

- `;audit` Location box has `caps`, so m3 gives M3.
- Start-of-shift Chrome code reads window titles through SafeTitle(), so a window closing mid-read can't show an error box. Ctrl+Alt+L header comment brought up to the v3.4.0 order.

## Built in v3.4.1 (Oct 21)

- New box option `suffix=` (added after what you type, only if something is typed).
- `;refuse` replaces `;noid`, `;insuf`, `;expired` and `;intox`: number of patrons (one to 5), reason list, and a Signs observed box that goes in brackets only when filled in. 33 templates.

## Built in v3.4.0 (Oct 21)

- Ctrl+Alt+L order (Jakob): SDS, AlertGrid and CMP open first and it waits for their windows (at least 20 s), then the websites, then the Citrix tab comes to the front last.

## Built in v3.3.1 to v3.3.3 (Oct 21)

- Citrix tab: searches every Chrome window, also matches apps.gcgaming.com (a tab still opening has that as its title), takes the focus back if another window grabs it, and writes "Citrix tab:" lines to the activity log.
- For 25 s after start of shift, if one of the apps it opened jumps in front, Chrome goes back on top (at most 6 times).

## Built in v3.3.0 (Oct 20)

- SDS logout shortcut (Jakob, Oct 20: yes; a sure way for everyone to log out properly): Ctrl+Alt+K (free key) runs the same LogOutSDS() as end of shift, leaves SDS open at its login screen, and says if it couldn't. Add K to the taken keys.
- Program updates from the team folder (from Jakob's Oct 20 question on whether everyone gets the current version through OneDrive). Today only the wording syncs; each person's Watchlog.ahk is their own copy and only shows "update needed". Proposal: whoever looks after the tool puts Watchlog.ahk (+ Watchlog.ico) next to the team templates.txt on SharePoint. When that copy's VERSION is newer, Watchlog asks "Update to vX now?", keeps a backup of the old file, copies the new one over itself and reloads. Only from that SharePoint folder (supervisor-edit only). Goes on the IT review list.
- Fewer OneDrive conflict copies: the "last used" box values (like the bay) are written to settings.ini, which OneDrive syncs, on every ;start/;end. Same person on two bays at once can make settings-PCNAME.ini conflict copies. Move LastUsed to %LOCALAPPDATA%\Watchlog so settings.ini only changes when settings are changed.
- Also: the README's Ctrl+Alt+L line still said it brings iTrak to the front (fixed).

## Built in v3.2.1 (Oct 18)

- Citrix paste lag (Jakob, Oct 18; happened before today's versions too): sometimes a form's paste doesn't show in iTrak, a manual Ctrl+V doesn't either, then both land later (two copies). Fix: when the target is Citrix (wfica32.exe), wait ~300 ms after putting the log on the clipboard before sending Ctrl+V, so Citrix can hand the new clipboard to the session first.
- Later the same night ;audit stopped pasting into iTrak at all, even by hand, while the log was on the clipboard and pasted fine elsewhere. Likely cause: Paste() read the old clipboard (ClipboardAll) and emptied it before setting the log. After copying an employee number in iTrak, that clipboard belongs to Citrix, so reading it makes Citrix fetch it back, which can leave Citrix's clipboard stuck. Fix: pasting into Citrix never saves or restores the old clipboard (the log stays on it), the clipboard is set in one step, and there's a 300 ms wait before Ctrl+V.

## Built in v3.2.0 (Oct 18)

- Time saved tracker (Jakob, Oct 18, his supervisor's idea: hard numbers after a few weeks of use). Every insert works out keystrokes saved = length of the finished entry minus what was actually typed (the code, the box contents, one Tab/Enter per box). Logins and ;t/;dd/;dt stamps count the same way. Converted to time at 40 words a minute (200 keystrokes a minute), the same rate as the overview. Totals kept per day in %LOCALAPPDATA%\Watchlog (numbers only, never log text or passwords). Shown in Ctrl+Alt+J (this shift) and a tray "Time saved" window (this shift, today, last 7 days, last 30 days, since first use) with a Copy report button. Opening/closing apps (Ctrl+Alt+L, end of shift) not counted, since there's nothing to measure. Blank boxes (placeholder left in) count as nothing saved.

## Built in v3.1.2 (Oct 18)

- End of shift (Ctrl+Alt+Shift+L) logs out of SDS before closing anything (Jakob: closing it logged in locks the user out). Clicks the lock button (4th of 5 on SDS's toolbar, next to the red X), answers Yes to "User ... will be logged out of SDS application", and checks the Welcome window is gone. If any step fails, it asks you to log out yourself and closes nothing until OK.

## Built in v3.1.1 (Oct 18)

- Ctrl+Alt+L (Jakob asked, Oct 18): stop trying to bring iTrak to the front (it never worked) and drop the fixed 5 s wait. It opens everything it does now, waits only until the Bally apps it started have their windows up (5 s at most), then switches to Chrome and steps through its tabs until the Citrix Receiver tab is showing (title contains "Citrix"). Keep the 1 s gap between the Bally apps; drop the pause after the last one. No Citrix tab found = leaves Chrome as it is.

## Built in v3.1.0 (Oct 18)

Optimization pass (Jakob: "build it", Oct 18). Same templates and wording; no behaviour changes beyond speed and looks.
- Faster window switching: SetWinDelay down from AHK's default 100 ms (it pauses on every switch to iTrak or a form). Turn off ListLines/KeyHistory to save a little CPU.
- Quicker form open and paste outside Citrix: trim the fixed waits. Citrix waits stay as they are so pastes aren't lost.
- Lighter forms: settings.ini "last used" values are read once per form instead of on each lookup, and the preview only redraws when the text actually changes.
- One look everywhere: Segoe UI in every window (forms are plain right now), even spacing, buttons lined up bottom-right, and a shaded preview box. The cheat sheet keeps a fixed-width font only where the shortcuts line up.
- Code tidy: merge repeated bits (the tooltip timers, the iTrak/Citrix focus-and-wait code) into shared helpers.

## Built in v3.0.2 (Oct 18)

- `;player` (Oct 18): Buy-in and Amount boxes read a number with a decimal point as thousands: 3.3 -> $3,300, 1.5 -> $1,500, 0.5 -> $500. Whole numbers stay as typed (500 -> $500). New `thousands` option on money boxes.
- `;player`: typing RN (refused name, not rated) in the Player # box gives "Player RN"; a number still gives "Player #12345". New `numberprefix=` and `upper` box options.

## Built in v3.0.1 (Oct 17)

- Login reminder: bottom-right corner instead of the middle, Esc closes it from any window (OK is the default button when it has focus).
- Live "How it will look" preview at the bottom of every form; with Add another, earlier entries show above.
- `;mfill` fills in 100,000 when an ATM is picked (new `if ATM=100000` option), still editable.
- Typing just a number in a list box picks the item ending in it (202 -> FB202, 206 -> BJ206).
- New `;open` Table opening: "FB202 Opened."
- New `;expired` Refused - expired ID: "Security Officer refused one patron entry due to expired ID."
- The OneDrive-not-running warning on load is gone. Instead, a `# Program version: 3.0.1` line in templates.txt says which version the team is on; an older PC gets a pop-up, "update needed" on the tray icon/menu, and OUT OF DATE in the version box and Security and status. The version box also shows a program check code (same code = same .ahk).
- Renamed to **Watchlog** with its own icon (Watchlog.ico: white log page with an eye on teal). Only the shown name changed: the file is still Log Templates.ahk, and saved passwords ("Log Templates: <user>"), %LOCALAPPDATA%\Log Templates and the registry key keep the old name so nothing is lost. New startup shortcuts are called Watchlog.lnk and use the icon; Make a copy to share includes the icon. (Updated Oct 18: Jakob asked for everything to be renamed.) The program file is now Watchlog.ahk; Log Templates.ahk is a small file that only starts Watchlog. On first run on each PC Watchlog closes the old Log Templates, moves %LOCALAPPDATA%\Log Templates to %LOCALAPPDATA%\Watchlog and HKCU\Software\Log Templates to Watchlog, and repoints the Startup shortcut. Saved passwords move to "Watchlog: <user>" the first time each is used. Overview and summary docs renamed (Watchlog - Overview / Summary, PDF and Word).

Done Oct 17 (templates.txt only, no version change): `;fill` takes several tables (Ctrl+Enter). New `;mfill` Machine fill (NRT1-4, ATM1-5 and amount, several per log).

Done Oct 16 (templates.txt only, no version change): `;evict` Reason list (showing signs of intoxication, being verbally abusive towards staff, being in violation of their trespass) and Length list (24 hour, indefinite). `;face` Result stays a plain box because Jakob says it's always Rejected.

## Still to check

Nothing. Jakob ran through the v3.0 features on his PC on Oct 16 (including Ctrl+Enter in `;bv`) and said the tests went well.

Added Oct 16 (templates.txt only): `;selfex` Self-exclusion and `;found` Abandoned credits - taken to Security.

## Not built (decided Oct 16)

- No-install HTML version for coworkers: Jakob chose to go for management/IT approval of the full tool instead.
- Compiled .exe: not built; AutoHotkey v2 gets installed (part of the IT review).

## Built in v3.0 (Oct 16): secure, trackable, easy to share

- Team templates: `[Templates] Shared=` path to the team's templates.txt on SharePoint (picked in Settings), with a last good copy on each PC, a wording version line and a check code. Changes reload every bay and are logged.
- my-templates.txt for each operator's own extras, marked (mine); they can't replace a team template. Ctrl+Alt+E opens it when a team file is set.
- First-run Welcome (Settings window) and tray > Settings: logins and passwords, team file, journal mode, how long journal files are kept (default 30 days), start with Windows. Change a login password moved here.
- Shift journal files older than the KeepDays setting are deleted automatically.
- Activity log on each PC, and tray > Security and status (live report with Copy report) and tray > Activity log.
- Tray > Make a copy to share, plus QUICK START.txt, a rewritten README and a generic settings.example.ini.
- Overview updated with a security section, then rewritten in a plainer first-person voice; one-page summary for the manager added.

## Built in v2.9 (Oct 16)

- Template finder: Ctrl+Alt+Space (or tray > Find a template) searches templates by name, trigger or any word in the wording, shows a preview and the trigger to type next time, and Enter inserts it.

## Built in v2.8.2 (Oct 16)

- Several machines in one `;bv` log: "Add another (Ctrl+Enter)" button, one machine per line, switched on by `{repeat}` in templates.txt.

## Built in v2.8.1 (Oct 16)

- Ctrl+Alt+J rewritten to find the journal by date and count more simply; it now says which case it hit when it can't show the summary.
- (templates.txt only, no version change) `;intox`: refused one patron entry due to showing signs of intox, with the signs observed in brackets.

## Built in v2.8 (Oct 15)

- Shift journal: every log saved with the time to Documents\Shift Journal, one file per shift. Ctrl+Alt+J shows counts with a Copy summary button. `[Journal] Save=full | counts | off`.

## Built in v2.7.2 (Oct 15)

- `caps` option: machine numbers come out in capitals (b1410 -> B1410) in `;jack`, `;bv`, `;aml`, `;countpull`, `;maint` and `;abandon` Found at / Patron found at.
- `;credits` renamed `;abandon`.
- Ctrl+Alt+L asks before opening the websites again when Chrome or Edge is already open (No is the default).
- One shared table list (`@tables` at the top of templates.txt) used by `;fill`, `;cards`, `;auto` and `;player`.
- `;medical`: "What the review showed" box instead of the placeholder wording.
- `;account`: Account # box (not from the clipboard); the # stays if it's left empty.
- `;insuf` now says "refused one patron entry due to insufficient ID".
- `;player`: $ in front of the buy-in.

## Built in v2.7.1 (Oct 15)

- `;audit` employee types: Jakob's full list of 27, Dealer first as the default. "sous chef and chef de partie" became two entries, and so did "General Maintenance and Facilities Manager" (Jakob gave the reading a thumbs-up).
- Form drop-downs show up to 12 rows at once.

## Built in v2.7 (Oct 15)

- Forms start on the first empty box or list (`;audit` starts on Employee type).
- Templates fire instantly; `;count` renamed `;countstep`; clashing triggers are refused with a message.
- App hotkeys: Ctrl+Alt+T Teams, U Outlook, Y Spotify, G Chrome.
- Ctrl+Alt+T find notes by tag removed.

## Queued (Jakob 2026-10-30, build only when he says "build it")
Six full-entry logs, none click End Time Now, Reference NA:
- +Interior Officer / +Interior Supervisor: Back of House - Non Sensitive | Call - Radio | NA | Security Officer (or Supervisor) performed interior door check
- +Exterior Officer / +Exterior Supervisor: Parking Lot | Call - Radio | NA | Security Officer (or Supervisor) performed exterior door check
- +Parking Officer / +Parking Supervisor: Parking Lot | Call - Radio | NA | Security Officer (or Supervisor) performed parking lot patrol
(templates.txt only, no version bump.)

### Department search for Info From (planned Oct 31, NOT built, waiting on Jakob's OK of the defaults and "build it")
Info From drop-down > Personnel > Look For box (matches the start of the text: dealer works, dealers doesn't; marketing lowercase; F&B; security/audit either case) > Find Now; Jakob picks the person and clicks Select himself.
Departments so far: dealer, security, audit, F&B, marketing (he named only these five).
Proposed defaults per code word: fill/open/auto dealer, jack security, bv security, mfill audit, account marketing; a department word in a call pad shorthand line overrides it. Needs a once-per-PC teach of the Info From drop-down and Personnel line.


---

# FILE 4: docs/Next Steps and Ideas.md

# Watchlog (formerly Log Templates): Next Steps and Ideas

Written 2026-10-14 against v2.1 (`Log Templates.ahk`, `templates.txt`, `settings.example.ini`, `LaunchWork.bat`).
Line numbers refer to v2.1 of `Log Templates.ahk`. **Items 1–4 were built in v2.2 (Oct 14).**

---

## Part 1: Improvements worth making now (ranked by value)

### 1. Make the logins safe to fire by accident
**What's there now.** Logins are instant hotstrings (`:*C:`, line 64) that type the username, Tab, the password, then **Enter** (lines 69-74) into whatever window has focus. They fire in any app.

**The risk.** `prd` has no `;` in front of it, so typing "prd" as a word in a Teams chat, an email, or an iTrak narrative sends `[work username removed]`, Tab, your password, Enter. In a chat, Enter posts it. Every other trigger got a `;` for exactly this reason; this one slipped through.

**The fix.**
- Rename `prd` to `;prd` in settings.ini (no code change needed).
- Add an optional `Window=` line to each `[LoginN]` (same format as the App sections, e.g. `Window=iTrak`). When it's set, the login only fires while that window is in front, using `#HotIf`/`HotIf` like the form keys already do (line 376). Logins without a `Window=` keep working as they do today.

### 2. Get the passwords out of a file that syncs to OneDrive
**What's there now.** `settings.ini` holds the passwords in plain text, and the whole AutoHotkey folder syncs through the work OneDrive to every bay PC and to Microsoft's cloud. Anyone with access to that OneDrive (or a stolen session) can read them.

**The fix.** Store each password in **Windows Credential Manager** instead (the same vault Windows uses for saved network passwords). The script reads it with a `DllCall` to `CredReadW`, so settings.ini only keeps the trigger and username. The first time a login fires on a PC with no saved password, the script asks for it once (masked box) and saves it to that PC's vault.
- Trade-off: you enter each password once per bay PC (the vault doesn't sync), and again when it changes. Most people find that worth it.
- This also makes the team version much easier to get past IT, since the shared files would contain no secrets at all.
- Your choice to keep passwords in the file is noted in PROJECT-NOTES; this is an option, not a requirement.

### 3. Survive Bally upgrades without editing three files
**What's there now.** The version number is baked into every Bally path (`AlertGridUI15_9`, `SDSUI15_9`, `CMPDesktop15_14_2`) in **three places**: LaunchWork.bat, settings.ini `[App1]`/`[App2]`, and the first-run template in the script (lines 107, 113). The day IT upgrades CMP, Ctrl+Alt+C, Ctrl+Alt+L and the batch file all break at once.

**The fix.** Allow a `*` in an app Path, e.g. `C:\BallyTechnologies\CMPDesktop*\CMPDesktop\CMPDesktop.exe`. The script finds the newest matching folder with `Loop Files` and runs that. Then move the three Bally launches out of LaunchWork.bat and have Ctrl+Alt+L start them itself, so there's one place to look. (The window matches already ignore version: `ahk_exe CMPDesktop.exe`, `SDS ahk_exe javaw.exe`.)

### 4. Soft count: default to the next step
**What's there now.** `;count` is a pick-or-type list of 9 steps in order, but the box always opens on step 1 (`Choose1`, line 306), so for 8 of the 9 entries you scroll down.

**The fix.** A new blank option, `next`, that remembers which step you used last (the same way `last` remembers the bay, line 219) and opens on the one after it. Usage: `{Step: next | Count Team entered... | ...}`. After the last step it wraps back to the first. Saves a few keystrokes on every count entry, and it's harder to skip a step.

### 5. Pasting into iTrak through Citrix (only if you've seen it)
**What's there now.** `Paste()` puts the text on the clipboard, presses Ctrl+V, waits 150 ms, then puts your old clipboard back (lines 283-285). iTrak runs through Citrix (`wfica32.exe`), which copies the clipboard across to the remote session on its own schedule.

**Possible problem (inferred, not confirmed).** If Citrix is slow, it can grab the restored old clipboard instead of the log, so the wrong text lands in iTrak. If you've ever seen a log paste as something you copied earlier, this is why.

**The fix.** Wait longer (around 500 ms) when the target window is Citrix, and make the delay a setting.

### 6. Small polish
- **Auto-reload.** Check every couple of seconds whether templates.txt or settings.ini was saved, and reload by itself. No more forgetting Ctrl+Alt+R.
- **Audit reminder.** `;audit` already knows the end time (`now+20`). Offer a tray pop-up at that time: "Audit on Employee # 1234567 ends now."
- **Hourly login reminder.** PROJECT-NOTES says one app needs a login every hour. A gentle reminder at 55 minutes beats getting kicked out mid-entry.
- **Badge picker.** `;badge` hard-codes `17-0` + 1-9 (templates.txt). If badges ever go past 9 or the prefix changes, make the whole badge number the list.
- **Wording check.** Settled Oct 21: the four refusal templates are now one `;refuse` with one wording ("refused entry to ...").

---

## Part 2: Bigger directions it could grow into

### A. A shift journal
Every time a template is inserted, also append it (with the time) to a daily file like `Shift Log 2026-10-14.txt`. That one change unlocks a lot:
- **End-of-shift summary**: "12 audits, 3 jackpots, 2 medicals, soft count complete", ready to paste into your End of Shift entry.
- **Backup**: if iTrak or Citrix drops an entry, the text is still there to re-paste.
- **Handover**: the next operator on that bay sees what happened, since the file syncs.
- Store it next to Quick Notes, under your own OneDrive. (Check with your manager whether a local copy of log text is OK under your retention rules; it may be fine, or it may need to stay summary-only.)

### B. Guided procedures, not just templates
Soft count is already a sequence of 9 steps. The same idea fits other multi-step events: a medical (notified, review, EMS called, outcome, supervisor told) or a jackpot (advised, review, payout). A procedure walks you through each step with the time filled in, so nothing gets skipped and the log reads the same no matter who wrote it. This is where the tool stops being a typing shortcut and becomes a consistency tool, which is what supervisors and auditors care about.

### C. A team edition with one shared template library
Today the plan is a copy with an empty settings.ini. The stronger version: **templates.txt lives in one place** (a SharePoint/OneDrive folder the surveillance team shares, maintained by a supervisor), and each operator's script reads it from there, plus an optional personal `my-templates.txt` for their own extras. Wording changes once and every bay gets it on the next reload. With passwords in Credential Manager (item 2), the shared files contain nothing sensitive, which is the main thing IT will ask about. Compiling to a signed `.exe` with Ahk2Exe is the other thing that usually makes IT more comfortable.

### D. A searchable picker and training aid  (built in v2.9, Oct 16)
Ctrl+Alt+Space opens a box where you type "jack" or "medical" and see matching templates with a preview of the wording; Enter runs it. New operators don't need to memorize 30 triggers, and the preview doubles as a guide to the house wording. This is already on your ideas list and becomes more valuable the moment anyone else uses the tool.

### E. Reminders and timers
A small scheduler driven by settings.ini: hourly login, door checks and patrol logs that are expected at set times, the end of an audit window, "start of shift log not entered yet" 10 minutes after Ctrl+Alt+L. Tray pop-ups only, nothing automatic in iTrak.

### Things to stay away from
- Typing into iTrak automatically without you pressing a key. Inserting text you triggered is one thing; a script that writes logs on its own is a different conversation with IT and your manager.
- Reading data out of AlertGrid, SDS or CMP (they're Java apps and the window text isn't readable anyway). Copying a number and using `clip` is the safe way to bring values across.


---

# FILE 5: templates.txt

```text
# =====================================================================
#  WATCHLOG - template wording
#  Watchlog: Copyright (c) 2026 Jakob Blair Vanness. All rights reserved.
#  Used by permission only; see LICENCE.txt.
#  Edit this file freely and save it. The script reloads by itself.
#
#  TEAM COPY
#    When this file is the team's shared copy on SharePoint, every
#    operator's Watchlog reads it and reloads when it changes.
#    Change the wording version line whenever you change the wording,
#    so anyone can see which version they have (tray menu > Security
#    and status).
#    The program version line says which Watchlog everyone should
#    be running. When you hand out a new Watchlog.ahk, change it
#    here too: any PC on an older one gets told to update.
#
# Wording version: Oct 30, 2026 (5)
# Program version: 3.29.0
#
#  EASIER: the template editor (Ctrl+Alt+E, or click the tray icon >
#  Template editor) changes all of this for you, boxes included.
#
#  HOW A LINE WORKS
#    ;trigger (Name) = the text that gets pasted
#    - The trigger is what you type. Start it with ; so it never
#      fires by accident. Don't start one with ;t ;dd or ;dt
#      (those are the time/date stamps).
#    - It fires the moment you finish typing it - no space or Enter.
#      So no trigger can be the start of another one (;count would
#      fire before you finish ;counttables). The script tells you
#      if two clash.
#    - (Name) is optional. It shows on the form and the cheat sheet.
#    - Lines starting with # are notes like this one and are ignored.
#    - Type \n where you want a new line.
#
#  MAKING A FORM
#    Put a blank in curly brackets and the template becomes a form
#    automatically. Each blank becomes a box:
#      {Machine}                      plain box
#      {Who: employee | guest}        list you can pick from or type over
#      {Outcome: pick | A | B}        list you must pick from
#      {From: now}                    time box, filled with the time now
#      {To: now+20}                   time box, filled with now + 20 min
#      {Time paid: time}              time box (2130 becomes 21:30)
#      {Amount: money}                10000 becomes 10,000
#      {Buy-in: money | thousands}    3.3 becomes 3,300 (a decimal point
#                                     means thousands; 500 stays 500)
#      {Match: percent}               67 becomes 67%
#      {Employee #: clip}             fills in a copied employee #
#      {Bay: last}                    remembers what you typed last time
#      {Bay: saved}                   like last, but a bay entered in the last
#                                     14 hours (at the start of shift) is
#                                     used without asking
#      {Step: next | A | B | C}       opens on the step after the one
#                                     you used last time (C wraps to A)
#      {Machine: blank=AXXXX}         what to leave if the box is empty
#                                     (otherwise it leaves XX)
#      {Asset #: prefix=# | blank=}   adds # in front only if you fill it
#                                     in; blank= leaves nothing if empty
#      {Signs: prefix=( | suffix=) | blank=}
#                                     adds ( ) around it only if you fill it in
#      {Player #: numberprefix=#}    adds # only in front of a number
#                                     (12345 becomes #12345, RN stays RN)
#      {Player #: upper}              all capitals (rn becomes RN)
#      {Machine: caps}                capitals in machine numbers
#                                     (b1410 becomes B1410; in a Machine
#                                     or NRT box n3 becomes NRT3, a1 ATM1)
#      {Note: tidy}                   bvs becomes BVs, bvs divert
#                                     becomes BVs/Divert
#      {Table: @tables}               uses the @tables list below
#      {Amount: if ATM=100000}        fills in 100000 when another box
#                                     starts with ATM (you can change it)
#    In a box with a list, typing just the number picks the item that
#    ends in it: 202 becomes FB202.
#    Combine options with | like {Employee #: clip | blank=XXXXXXX}
#    Write a/an before a blank and it picks "a" or "an" for you.
#
#  SEVERAL IN ONE LOG
#    Put {repeat} at the end of a form line and the form gets an
#    "Add another" button (or press Ctrl+Enter). Fill in one, add
#    another, and Insert pastes them all as one log, one per line.
#    Add | several to a box to keep it all on one line instead: Add
#    another adds to that box's list ({Table: @tables | several}
#    gives "BJ205, BJ206 and RO204 Opened.").
#
#  SHARED LISTS
#    A line starting with @ is a list you can use in any blank. Change
#    it here and every template that uses it changes too.
# =====================================================================

@pit = 2=Pit 2 | 3=Pit 3
@slots = A=Alpha Slots | B=Bravo Slots | C=Charlie Slots | D=Delta Slots
@tables = UT201 | FB202 | UT203 | RO204 | BJ205 | BJ206 | RY301 | MP302 | BJ303 | BJ304 | BJ305 | RO306


# ----- FORMS ---------------------------------------------------------

;jack (Jackpot) = Operations Supervisor advised of a ${Amount: money} Supervisor Jackpot @{Machine: caps | blank=AXXXX}. Review confirmed winner. Patron requested to be paid all cash at window #{Window #: blank=X}. Slot Attendant was observed paying patron @{Time paid: time}. >> %slots% | Jackpot |

;audit (Audit) = Surveillance observed {Employee type: fromcopy | Dealer | Security Officer | Security Supervisor | Operations Supervisor | Operations Manager | Pit Supervisor | Pit Manager | Cage Cashier | F&B Server | F&B Bartender | F&B Dishwasher | F&B Commis Chef | F&B Sous Chef | F&B Chef de Partie | F&B Supervisor | F&B Manager | General Manager | Count Team Attendant | Count Team Supervisor | Audit Supervisor | Auditor | Slot Attendant | Slot Technician | Main Banker | EVS Attendant | General Maintenance | Facilities Manager} {Employee #: clip | prefix=# | blank=#XXXXXXX} from {From: now} - {To: now+20} on {Location: caps | blank=MX}. Nothing suspicious observed.

;medical (Medical) = Security Supervisor notified Surveillance of a/an {Who: employee | guest} medical at {Location: Kitchen | Main Entrance}. A review was conducted and observed {What the review showed}. Security administered first aid and contacted EMS. {Outcome: pick | EMS arrived on site and took the individual off-site via ambulance. | EMS arrived on site and the individual returned to the gaming floor, no further action taken.} Security Supervisor notified of the review results.

;evict (Trespass) = Report opened on behalf of Security. The Security Supervisor approached a guest at {Location: Main Entrance} for {Reason: showing signs of intoxication | being verbally abusive towards staff | being in violation of their trespass}. The guest was escorted off the gaming floor and given a/an {Length: 24 hour | indefinite} Trespass. The guest left without further incident.

;face (Facial recognition) = Facial Recognition Alert #{Alert #: alertcopy}\n{Result: Rejected} ({Match: matchcopy})


# ----- START / END OF SHIFT (asks which bay, remembers the last one) -

;start (Start of shift) = Start of Shift Bay {Bay: last} Operator >> Surveillance | Duty | NA | end
;end (End of shift) = End of Shift Bay {Bay: saved} Operator >> Surveillance | Duty | NA | end


# ----- QUICK TEMPLATES -----------------------------------------------

;interior (Interior door check) = Security {Rank: pick | Supervisor | Officer} performed interior door check >> Back of House - Non Sensitive | Call - Radio | NA
;exterior (Exterior door check) = Security {Rank: pick | Officer | Supervisor} performed exterior door check >> Parking Lot | Call - Radio | NA
;parking (Parking lot patrol) = Security {Rank: pick | Officer | Supervisor} performed parking lot patrol >> Parking Lot | Call - Radio | NA

;refuse (Refused entry) = Security Officer refused entry to {Patrons: one patron | 2 patrons | 3 patrons | 4 patrons | 5 patrons} due to {Reason: no ID | insufficient ID | expired ID | showing signs of intox} {Signs observed: prefix=( | suffix=) | blank=}.
;selfex (Self-exclusion) = Security Supervisor advised taking patron into PlaySmart to perform a self exclusion.

;inventory (Inventory transfer) = Security Officer performed inventory transfer from Delta Podium to Main Bank.
;account (Account under review) = Account #{Account #: blank=XXXXXX} reviewed, not banned player. Account cleared and Guest Services notified. >> Guest Services | Account under review | M6 (417)
;drop (Table drop) = Security Officers performed Table Drop >> Pit 2 | Table Drop | M3,6 (355,252,600,955,950,420,613,690)
;man (Garbage sweep) = Security Officer escorted EVS Attendant into Cage Mantrap for garbage sweep. >> Cage ManTrap | Security Escort | M6 (972,973)


# ----- FULL DAILY LOGS -----------------------------------------------
#  Logs that never change. Ctrl+Alt+F lists them; type the first letters,
#  Enter. Watchlog opens a new daily log in iTrak and fills in Location,
#  Topic, Reference and the Synopsis (End Time and Save are left to you).
#  One line each:   +Name = Location | Topic | Reference | Synopsis
#  Add  | end  at the end of a line to click End Time's Now button when the
#  log is filled; {Bay} in the synopsis is the bay entered at the start of shift,
#  and {Bay?} asks which bay (offering the last one) and keeps it for the shift.
#  (teach the spots once with Ctrl+Alt+Shift+F; see README section 10)
#
#  A code word can fill the whole daily log too: put  >> Location | Topic | Reference
#  at the end of its line. The wording (with its boxes) becomes the Synopsis, and
#  {boxes} work in Location, Topic and Reference too. Typing the code word fills the
#  daily log that is open in iTrak, or opens a new one. Press Shift+Enter on the form
#  (or hold Shift when a no-box code word fires) to paste just the wording instead.
#  Add  | end  last to click End Time's Now. Example:  the ;cards line below.

+Break = Surveillance | Duty | NA | Break
+Table Drop = Pit 2 | Table Drop | M3,6 (355,252,600,955,950,420,613,690) | Security Officers performed Table Drop
+Start = Surveillance | Duty | NA | Start of Shift Bay {Bay?} Operator | end
+End = Surveillance | Duty | NA | End of Shift Bay {Bay} Operator | end
+Garbage Sweep = Cage ManTrap | Security Escort | M6 (972,973) | Security Officer escorted EVS Attendant into Cage Mantrap for garbage sweep.
+Card Destruction = Card Destruction Room | Card Destruction | M6 (750,751,749) | Security Officers entered Card Destruction Room for Card Destruction.
+Interior Officer = Back of House - Non Sensitive | Call - Radio | NA | Security Officer performed interior door check
+Interior Supervisor = Back of House - Non Sensitive | Call - Radio | NA | Security Supervisor performed interior door check
+Exterior Officer = Parking Lot | Call - Radio | NA | Security Officer performed exterior door check
+Exterior Supervisor = Parking Lot | Call - Radio | NA | Security Supervisor performed exterior door check
+Parking Officer = Parking Lot | Call - Radio | NA | Security Officer performed parking lot patrol
+Parking Supervisor = Parking Lot | Call - Radio | NA | Security Supervisor performed parking lot patrol


# ----- TABLES --------------------------------------------------------

;close (Table closing) = Pit Manager advised checking table tray lids and Dealers collecting tokes.
;open (Table opening) = {Table: @tables | several | blank=XXXXX} Opened. {repeat} >> %pit% | Table Opening/Closing | NA
;auto (Auto-close) = {Table: @tables | several | blank=XXXXX} Closed and Auto-Close started. {repeat} >> %pit% | Table Opening/Closing | NA
;cards (Card change) = Card change on {Table: @tables}. >> Pit 2 | Card Change | NA
;break (Break) = Break >> Surveillance | Duty | NA
;fill (Table fill) = {Table: @tables} ${Amount: money} {repeat} >> %pit% | Table Fill |
;mfill (Machine fill) = {Machine: pick | NRT1 | NRT2 | NRT3 | NRT4 | ATM1 | ATM2 | ATM3 | ATM4 | ATM5} ${Amount: money | if ATM=100000} {Note: tidy | prefix=( | suffix=) | blank=} {repeat} >> ABM/NRT | ATM/NRT/CTR fill |
;player (Player log) = {Player #: numberprefix=Player # | upper | blank=Player #XXXXXX} playing Spot {Spot: blank=X}, {Table: @tables | blank=TableX}, In ${Buy-in: money | thousands}, {Down/Up: Down | Up} ${Amount: money | thousands}. {Reason (only if up): blank=}


# ----- SLOTS ---------------------------------------------------------

;bv (Emergency BV pull) = {Machine: caps | blank=XXXXX} {Asset #: prefix=# | blank=} ({Reason: Full | Defective}) {repeat} >> %slots% | Emergency Pull |
;abandon (Abandoned credits) = Operations Supervisor requested a review to determine the owner of abandoned credits found at {Found at: caps | blank=XXXXX}. A review was conducted and observed the last patron gaming there leave without appearing to cash out. Patron was found live gaming at {Patron found at: caps | blank=XXXXX}. Operations Supervisor advised, approach made and funds returned. TITO value (${TITO value: money})
;found (Abandoned credits - taken to Security) = Operations Supervisor advised printing off abandoned credits in the amount of ${Amount: money} from {Machine: caps | blank=XXXXX}. Funds taken to Security as found.
;aml (AML alert) = AML Alert #{Alert #: blank=XXX} populated at {Machine: caps | blank=XXXXX} ({Time: now}). Review showed nothing suspicious.
;maint (Maintenance) = {Machines: caps | NRT2 and NRT4} Maintenance.
;firm (NRT firmware check) = {Department/Title: Operations Supervisor | blank=XXXXX} notified Surveillance that they will be conducting an NRT Firmware check at {Location/NRT#: caps | blank=NRTX}.\nDUB#{DUB #: blank=XXXXX} (Should have fixed shot taken)


# ----- SOFT COUNT  (time fills in as now, step opens on the next one) -

;countstep (Soft count step) = {Time: now} - {Step: next | Count Team entered Count Room. Tables soft count started. | Main Banker entered Count Room for tables Buy. | Buy confirmed, Pod #1 Soft Count started. | Money secured, Count Team on break. | Pod 2 Soft Count started. | Main Banker entered for Buy. | Buy complete, totals confirmed. Calling Security for Sweep. | Security entered for Sweep. | Sweep complete.}
;counttables (Soft count - table totals) = {Time: now} - Tables totals: 1st; ${1st: money}, 2nd; ${2nd: money}, called Main banker for Table buy.
;countslots (Soft count - slots total) = {Time: now} - Pod 2 completed. Slots Total: ${Slots total: money}. Called Main Banker for Buy.
;countpull (Soft count - emergency pull) = {Time: now} - completed emergency pull for {Machine: caps | blank=XXXXX}.


# ----- OTHER ---------------------------------------------------------

;destroy (Card destruction) = Security Officers entered Card Destruction Room for Card Destruction. >> Card Destruction Room | Card Destruction | M6 (750,751,749)
;badge (Contractor pass) = Pass #17-0{Pass # (1-9): pick | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9} issued {Issued: to XXXXX employee | for interview}.
```


---

# FILE 6: QUICK START.txt

```text
=======================================================================
  WATCHLOG  v3.29.0  -  QUICK START  (one page)
  Shortcuts that type finished surveillance log entries for you
=======================================================================
Copyright (c) 2026 Jakob Blair Vanness. All rights reserved.
Watchlog is used only with the copyright holder's permission. No
copying, sharing, changing or redistributing it, in whole or in part,
without written permission. Provided "as is", without warranty. The
full licence is in LICENCE.txt (and tray menu > About Watchlog).


WHAT IT DOES
  Type a short code like ;jack in iTrak and it becomes the full log
  entry. Codes with blanks open a small form first: fill in the boxes,
  press Enter, and the finished entry goes where you were typing.
  It can also type your logins, open your work apps at the start of a
  shift, and keep a count of your logs for the End of Shift entry.


SET IT UP  (about 2 minutes, once per PC)
  1. Double-click  Watchlog.exe.  It asks "Install Watchlog on this
     PC?"  Press Yes. (It needs no administrator rights and no other
     software. It adds Watchlog to the Start menu and Settings > Apps,
     and starts it when Windows starts.)
  2. A short tutorial opens: it adds your logins (optional) and lets
     you try a quick entry and a form. Your settings and templates are
     kept in Documents\Watchlog.
  3. Later, click the tray icon (the white page with an eye, on teal) >
     Settings > Templates > Browse to pick the team's templates.txt in the
     SharePoint folder (your supervisor will say where). Then everyone
     uses the same wording and gets updates automatically.
  4. In File Explorer, right-click the synced SharePoint folder and
     choose "Always keep on this device", so the team templates are
     there even when the network is slow.
  To see the tutorial again: tray icon > Tutorial.  To remove Watchlog:
  Settings > Apps > Watchlog > Uninstall (your settings are kept).
  (IT can ask Jakob for the readable script version, Watchlog.ahk.
  It isn't in this folder.)


USE IT
  Click the Watchlog icon  The home window: every feature as a button,
  (or Ctrl+Alt+M)          each showing its shortcut.
  ;jack, ;audit, ;bv ...   Type a code anywhere. No Space or Enter
                           needed: it fires as soon as you finish it.
  Ctrl+Alt+Space           Can't remember a code? Type any word (like
                           jackpot or medical) and press Enter.
  Ctrl+Alt+H               Cheat sheet: every code, login and hotkey.
  Tab / Enter / Esc        In a form: next box / insert / cancel.
  Ctrl+Alt+J               This shift's log counts, with Copy summary.
  Ctrl+Alt+L               Start of shift: opens the work apps and
                           Edge (facial rec, Citrix).  Ctrl+Alt+Shift+L closes them.
  Ctrl+Alt+P               Pause all shortcuts (press again to resume).

  Ctrl+Alt+E               Template editor: change the wording, add
                           codes and boxes, change lists like @tables.
  Right-click the Watchlog icon for the menu: Settings, the template
  editor, and (under Advanced) Security and status and the Activity log.


WHAT IT KEEPS  (tray menu > Security and status shows it all, live)
  - Passwords: Windows Credential Manager on your PC only. Never in a
    file, never synced, never shown.
  - settings.ini: your login shortcuts and usernames. No passwords.
  - Shift journal: a copy of each log you insert, in Documents\Shift
    Journal, deleted after 30 days (Settings can change or turn it off).
  - Activity log: what the tool did and when (on this PC only). Never
    passwords or log text.
  It makes no internet connections and doesn't keep what you type.


IF SOMETHING'S WRONG
  - A code doesn't fire: check the tray shows the Watchlog icon. It
    changes while shortcuts are paused, and Ctrl+Alt+P turns them back
    on. Then press Ctrl+Alt+R to reload.
  - "Couldn't open the team templates": start OneDrive and let it sync.
    The last good copy is used meanwhile, so codes keep working.
  - Anything else: tray menu > Security and status > Copy report, and
    send it to whoever gave you this folder. (It's under right-click >
    Advanced, or the Security and status button in the home window.) README.txt has the details.
```


---

# FILE 7: settings.example.ini

```ini
; EXAMPLE COPY - shows what a settings.ini looks like. It has no real
; usernames or passwords. Your own settings.ini is made the first time
; Watchlog runs, and tray menu > Settings changes it for you.
; Keep your real settings.ini to yourself.
; =====================================================================
;  WATCHLOG - personal settings
;  Each operator has their own copy of this file.
;  Save it and the script reloads by itself in a couple of seconds.
;  No passwords are kept here: they're in Windows Credential Manager.
; =====================================================================

; ---------------------------------------------------------------------
;  TEAM TEMPLATES  -  the team's shared templates.txt on SharePoint,
;  synced to this PC by OneDrive. Blank = templates.txt in this folder.
;  Your own extra templates go in my-templates.txt in this folder.
;  If the shared file can't be read, the last good copy saved on this
;  PC is used, and it says so.
; ---------------------------------------------------------------------
[Templates]
Shared=C:\Users\your.name\Your Company\Surveillance - Documents\Watchlog\templates.txt

; ---------------------------------------------------------------------
;  LOGIN SHORTCUTS  -  type the trigger and it types the username,
;  presses Tab, types the password and presses Enter.
;  Tray menu > Settings adds, changes and removes these for you.
;  Up to [Login9].
;    Trigger  start it with ; so it never fires while you type normally
;    Window   optional: the login only works while this program is in
;             front. Several programs: separate them with |
;             (Settings > Pick window fills it in; Ctrl+Alt+I also
;             shows a window's title and program)
;    Remind   optional: minutes after using this login until a pop-up
;             reminds you to log in again, e.g. Remind=55 for an app
;             that signs you out every hour
;  Passwords are NOT kept in this file. They're in Windows Credential
;  Manager on each PC (typed in Settings, or asked for the first time
;  a login is used). Removing a login in Settings deletes its password.
; ---------------------------------------------------------------------
[Login1]
Trigger=;login
User=your.username

[Login2]
Trigger=;it
User=your.itrak.username
Window=iTrak
Remind=55

; What you type in front of code words and logins (default ;). 1 to 3 symbols,
; no letters, digits, spaces or colons. Settings > General changes it too.
[Triggers]
Prefix=;

[Paths]
; The most seconds Ctrl+Alt+L waits for the work programs' windows (at least 20)
LaunchWait=20
; Part of the Citrix page's window title, so Ctrl+Alt+L brings that Edge window to the front
CitrixTab=Citrix|apps.gcgaming.com
; The pages Ctrl+Alt+L opens in Edge: iTrak facial rec first (blank = not
; opened), the Citrix Receiver page last
FaceUrl=https://itrakappprod.olgnetwork.ca/iTrak/login.aspx
CitrixUrl=https://apps.gcgaming.com/Citrix/GCGCWeb/

; ---------------------------------------------------------------------
;  START OF SHIFT  -  programs Ctrl+Alt+L opens first (up to Run9),
;  before it opens the Edge pages.
;  A * means "any version", so a Bally upgrade doesn't break these.
;  Anything whose window is already open is skipped (WindowN= sets
;  how to spot it; the three Bally apps are recognised automatically).
; ---------------------------------------------------------------------
[StartOfShift]
Run1=C:\BallyTechnologies\AlertGridUI*\AlertGridUI\AlertGridUI.bat
Run2=C:\BallyTechnologies\SDSUI*\SDSUI\SDSUI.bat
Run3=C:\BallyTechnologies\CMPDesktop*\CMPDesktop\CMPDesktop.exe
;  SignIn=yes asks at the end of Ctrl+Alt+L whether to sign into the Bally
;  programs it just opened (each with the saved login locked to it). no = never ask.
SignIn=yes

; ---------------------------------------------------------------------
;  UPDATES  -  your own folder for new Watchlog.exe builds (tray >
;  Choose my own update folder). Leave out to use the team folder.
; ---------------------------------------------------------------------
;[Updates]
;Folder=C:\Users\you\Watchlog builds

; ---------------------------------------------------------------------
;  SHIFT JOURNAL  -  every log you insert is also saved, with the time,
;  in Documents\Shift Journal (one file per shift, named by the date it
;  started). Ctrl+Alt+J shows the shift summary with a Copy button.
;    Save=full     the time, template name and the log text (default)
;    Save=counts   only the time and template name
;    Save=off      nothing is saved
;    KeepDays=30   shift files older than this are deleted (0 = keep)
; ---------------------------------------------------------------------
[Journal]
Save=full
KeepDays=30

; ---------------------------------------------------------------------
;  END OF SHIFT  -  programs Ctrl+Alt+Shift+L closes
; ---------------------------------------------------------------------
[EndOfShift]
Close=outlook.exe, olk.exe, ms-teams.exe, Teams.exe, javaw.exe, CMPDesktop.exe, wfica32.exe, Spotify.exe, msedge.exe, explorer.exe

; ---------------------------------------------------------------------
;  WINDOW LAYOUT  -  Ctrl+Alt+Shift+S saves where your windows are,
;  Ctrl+Alt+W puts them back. AfterStart=yes also puts them back at the
;  end of Ctrl+Alt+L (only if a layout was saved). no = Ctrl+Alt+W only.
; ---------------------------------------------------------------------
[Layout]
AfterStart=yes

; ---------------------------------------------------------------------
;  CALL PAD  -  Numpad + (or Ctrl+Alt+N) opens a pad to jot a phone call
;  into. Key=off gives the + key back. Autocorrect=no turns off the
;  casino autocorrect (autocorrect.txt) in the pad and the log forms.
; ---------------------------------------------------------------------
[CallPad]
Key=NumpadAdd
Autocorrect=yes

; ---------------------------------------------------------------------
;  ALERT GRID  -  Ctrl+Alt+A (or plain Caps Lock with the guard on)
;  clears every alert. CapsLockClears=no stops Caps Lock doing it.
;  Pause = ms between the clicks. SelectWait = the longest (ms) it waits after Ctrl+A before
;  the right-click (it stops as soon as the list shows as selected).
; ---------------------------------------------------------------------
[AlertGrid]
CapsLockClears=yes
Pause=40
SelectWait=120

; ---------------------------------------------------------------------
;  LOGIN REMINDER  -  Beep=yes beeps with the reminder pop-up.
;  SDS: ResignMinutes = sign SDS back in this many minutes after an SDS
;  login (0 = off). UPDATES: Folder = your own folder for new builds
;  (empty = the team folder).
; ---------------------------------------------------------------------
[Reminder]
Beep=no

[SDS]
ResignMinutes=62

[Updates]
Folder=

; ---------------------------------------------------------------------
;  APP HOTKEYS  -  Ctrl+Alt + Key switches to the app, or opens it.
;  Add more as [App3], [App4] ... up to [App9].
;    Key     one letter (these are taken: Q O I H P X R L E J K W A M N)
;    Path    the program or .bat that opens it (* = any version),
;            or a link like msteams: for apps from the Microsoft Store
;    Window  how to find its window (Ctrl+Alt+I shows a window's info)
;  Built in, no section needed: T = Teams, U = Outlook, Y = Spotify,
;  G = Edge. To give one a different letter, add a section with the
;  same Name and a new Key. Key=none turns it off.
; ---------------------------------------------------------------------
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

; Filled in by the script: the last value typed in boxes that remember
; one (like the bay)
[LastUsed]
Bay=2
```


---

# FILE 8: LaunchWork.bat

```bat
@echo off
:: ============================================================
::  LaunchWork - opens iTrak facial rec and the Citrix page in Edge
::  NOTE: inside a .bat file every % in a link must be written %%
::
::  Watchlog's Ctrl+Alt+L opens these two pages itself now
::  (FaceUrl and CitrixUrl in settings.ini) and no longer runs this
::  file. It is only here for double-clicking.
::  The Bally / LNW apps (AlertGrid, SDS, CMP) are opened by
::  Watchlog from [StartOfShift] in settings.ini.
:: ============================================================

start "" msedge.exe "https://itrakappprod.olgnetwork.ca/iTrak/login.aspx" "https://apps.gcgaming.com/Citrix/GCGCWeb/"
```


---

# FILE 9: build/build.ahk

```autohotkey
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
```


---

# FILE 10: build/mk_resources.py

```python
"""Makes the icon and version resources Watchlog.exe needs.
Usage: python3 mk_resources.py Watchlog.ico 3.5.0.0 <out folder>
Writes icon101.bin..icon108.bin, group159.bin and version.bin."""
import struct, sys, os

ico, ver, out = sys.argv[1], sys.argv[2], sys.argv[3]
os.makedirs(out, exist_ok=True)

# --- icons: 8 images, replacing AutoHotkey's own icons 101-108 and group 159
d = open(ico, 'rb').read()
_, _, n = struct.unpack('<HHH', d[:6])
imgs = []
for i in range(n):
    w, h, c, _, pl, bpp, size, off = struct.unpack('<BBBBHHII', d[6 + 16 * i:22 + 16 * i])
    imgs.append((w or 256, h or 256, c, pl, bpp, d[off:off + size]))
want = [16, 20, 24, 32, 40, 48, 64, 256]
imgs = [next(x for x in imgs if x[0] == s) for s in want]
group = struct.pack('<HHH', 0, 1, len(imgs))
for k, (w, h, c, pl, bpp, data) in enumerate(imgs):
    open(os.path.join(out, 'icon%d.bin' % (101 + k)), 'wb').write(data)
    group += struct.pack('<BBBBHHIH', w % 256, h % 256, c, 0, pl, bpp, len(data), 101 + k)
open(os.path.join(out, 'group159.bin'), 'wb').write(group)

# --- version resource
def pad(b): return b + b'\0' * ((4 - len(b) % 4) % 4)
def node(key, value=b'', wtype=1, children=(), vlen=None):
    k = (key + '\0').encode('utf-16-le')
    if vlen is None:
        vlen = len(value) // 2 if wtype == 1 else len(value)
    d = bytearray(b'\0' * 6) + k
    d = bytearray(pad(bytes(d)))
    d += value
    for c in children:
        d = bytearray(pad(bytes(d)))
        d += c
    struct.pack_into('<HHH', d, 0, len(d), vlen, wtype)
    return bytes(d)
def s(key, val): return node(key, (val + '\0').encode('utf-16-le'), 1)
a, b, c, dd = [int(x) for x in ver.split('.')]
ms = (a << 16) | b; ls = (c << 16) | dd
fixed = struct.pack('<13I', 0xFEEF04BD, 0x00010000, ms, ls, ms, ls, 0x3F, 0, 0x40004, 1, 0, 0, 0)
strings = [s('FileDescription', 'Watchlog'), s('ProductName', 'Watchlog'), s('FileVersion', ver),
           s('ProductVersion', ver), s('InternalName', 'Watchlog'), s('OriginalFilename', 'Watchlog.exe'),
           s('Comments', 'Types standard log entries from short codes'),
           s('LegalCopyright', 'Copyright (c) 2026 Jakob Blair Vanness. All rights reserved.')]
st = node('040904B0', b'', 1, strings, vlen=0)
sfi = node('StringFileInfo', b'', 1, [st], vlen=0)
var = node('Translation', struct.pack('<HH', 0x0409, 0x04B0), 0)
vfi = node('VarFileInfo', b'', 1, [var], vlen=0)
root = node('VS_VERSION_INFO', fixed, 0, [sfi, vfi])
open(os.path.join(out, 'version.bin'), 'wb').write(root)
print('icons', len(imgs), 'version', len(root))
```


---

# FILE 11: docs/Watchlog - Overview.docx (text only)

```text
Watchlog

Oct 25, 2026 · Jakob

Summary

I’m asking for approval for Watchlog, a tool I built to speed up our log entries, so that anyone on the team who wants it can use it. I’d like IT to look it over first.

Every shift is typing the same entries: door checks, audits, jackpots, refusals, soft count steps, AML alerts. Each one has standard wording and a few details that change. Watchlog keeps the standard wording ready. You type a short code, fill in the details, and the finished entry goes into iTrak. You still read it over and save it yourself, same as now.

It also takes care of the repetitive clicking around the logging. One key clears the Alert Grid list, and the start of shift opens and signs into our programs.

By my count it saves about 2,000 keystrokes and around 14 minutes a shift on typing and opening programs, or roughly 42 hours a year per operator. Clearing Alert Grid alerts with one key should add another 5 to 10 minutes a shift. These are estimates. The tool now counts its own savings, and I plan to count one full shift by hand to check them. The time saved goes back into watching the floor.

  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  What I type                                                                 What ends up in the log
  --------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  ;interior (9 keystrokes)                                                    Security Supervisor performed interior door check

  ;evict, check the 3 boxes, Enter (9 keystrokes if the defaults are right)   Report opened on behalf of Security. The Security Supervisor approached a guest at Main Entrance for showing signs of intoxication. The guest was escorted off the gaming floor and given a 24 hour Trespass. The guest left without further incident.
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

What I’d need:

-   The supervisors, picked by management, to approve the template wording. The shared file would sit in a SharePoint folder that all of them have access to.
-   IT to look at how passwords are stored, the automatic logins, the Alert Grid clicks, running Watchlog.exe and starting it with Windows, and the shift journal (a copy of each entry kept for 30 days).

There’s no separate pilot. Our room has 3 operator bays and a supervisor bay, and if it’s approved, whoever wants to use it can.

Security has its own section further down. In short: passwords are kept in Windows Credential Manager and never in a file, the tool doesn’t connect to the internet or send anything anywhere, and a built-in report shows exactly what it has saved on any PC.

What it does

It’s a small Windows program. It’s written in AutoHotkey, a free automation tool that has been around for years, and comes as a single Watchlog.exe with everything built in, so nothing else needs installing. It sits by the clock as a small teal icon and starts with Windows. I’ve been building and testing it myself since October 13. Version 3.0 was the first one set up for the team, and it’s on 3.23.0 now.

Log entries

There are 35 templates so far. Every code starts with a semicolon so it never goes off in the middle of normal typing, and the entry appears as soon as the code is typed.

  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Area                                Codes
  ----------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Incidents and reviews               ;jack jackpot · ;audit employee audit · ;medical · ;evict trespass · ;face facial recognition alert

  Start and end of shift              ;start · ;end (remembers which bay you were on last)

  Security routines                   ;interior · ;exterior door checks · ;parking patrol · ;refuse refused entry (one or several patrons) · ;selfex self-exclusion · ;inventory · ;account review · ;drop table drop · ;man garbage sweep

  Tables                              ;open · ;close · ;auto auto-close · ;cards card change · ;fill table fill · ;player player log

  Slots                               ;bv emergency BV pull · ;abandon abandoned credits returned · ;found abandoned credits taken to Security · ;aml AML alert · ;maint maintenance · ;mfill ATM and NRT fill · ;firm NRT firmware check

  Soft count                          ;countstep step by step · ;counttables · ;countslots · ;countpull

  Other                               ;destroy card destruction · ;badge contractor pass or interview pass
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

If you can’t remember a code, Ctrl+Alt+Space opens a search. Type a word like trespass or ambulance, look at the wording, and press Enter. Ctrl+Alt+H brings up a cheat sheet with every code on it.

Forms for the details

When an entry has details that change, a small form pops up with a box for each one. Tab moves between boxes, Enter puts the entry in and Esc cancels. The form takes care of the fiddly parts:

-   Times fill themselves in (audits get the time plus 20 minutes), and typing 2130 gives 21:30.
-   Money and percentages come out formatted, so 10000 becomes $10,000 and 67 becomes 67%.
-   The medical outcome, trespass reason and length, employee job title and table number are picked from a list instead of typed. Typing 202 picks FB202, and typing the first letters of a choice finishes it.
-   Machine numbers come out in capitals, and an employee number you’ve just copied fills itself in.
-   For a facial recognition alert, I copy the alert number and the match percentage from the facial rec page in Edge, and ;face fills both in. It warns me if the alert number is the same as or lower than the last one I logged, since they always go up.
-   A BV pull, table fill or machine fill can list several machines or tables in one entry.
-   An empty box leaves XXXXX in the entry, so a missing detail is easy to spot. A preview at the bottom of the form shows the finished entry as you type.

Clearing Alert Grid

Most Alert Grid alerts need nothing from us, but each one still has to be acknowledged. By hand that’s Ctrl+A on the list, right-click, Acknowledge as received, Submit, then OK, and I do it about 50 to 80 times a shift.

With Watchlog I look over the list first, then press Caps Lock (or Ctrl+Alt+A). It brings Alert Grid to the front, does those same clicks, clears the acknowledged alerts, and puts me back in the window I was in. It works from any window. It clears everything in the list, so the operator still checks the alerts by eye before pressing the key, same as now.

The Acknowledge box already has the operator’s own Alert Grid login filled in by Alert Grid itself. Watchlog never reads or types that password, it only clicks Submit. Each PC is taught where to click once: the operator clears alerts by hand one time and presses F8 over each spot (Ctrl+Alt+Shift+A starts it). Only those screen positions are saved, on that PC.

Logging in

-   A short code types the username and password and presses Enter. Each login is locked to the programs it belongs to, so the code does nothing anywhere else.
-   When Ctrl+Alt+S or Ctrl+Alt+C brings SDS or CMP to the front, Watchlog asks “Log in to SDS as …?”. Enter types the login, Esc or waiting 6 seconds says no.
-   At the start of shift it asks once whether to sign into the programs it just opened. On yes, it brings each one to the front and types its login.
-   SDS logs me out an hour after I sign in, so Watchlog signs it back in by itself. 62 minutes after an SDS login it checks that SDS is really on its login screen, types the saved login, and puts me back in the window I was in. If SDS still says Welcome it tries again every minute, up to 6 times. It never types unless it sees the login screen, and Settings > Logins can turn it off. Other logins that expire still get a quiet pop-up reminder, with the beep off unless you turn it on in Settings.

Finding your way around

Clicking the Watchlog icon (or Ctrl+Alt+M) opens a home window with a button for every feature, grouped as Logs, Shift, Logins and Set up. Each button shows its shortcut, so new operators learn the keys as they go. A strip along the bottom shows the version, whether the templates are current, whether Alert Grid is taught on this PC and the time saved this shift. Right-clicking the icon gives the same things as a menu with small pictures, and the less-used items are tucked into Alert Grid, Windows and Advanced sub-menus.

Settings is now a window with tabs (Logins, Templates, Start / end of shift, Alert Grid, Updates, General), so nothing needs editing in settings.ini by hand. Ctrl+Alt+E opens a template editor for whoever looks after the wording. It lists the templates, shows the finished entry as you change it, flags clashes, and keeps a backup before saving. Saving the team’s file asks first, because it changes every bay. Editing in Notepad still works under Advanced.

Everything around the logging

-   ;t, ;dd and ;dt type the time, the date, or both.
-   Ctrl+Alt+L opens everything for the start of shift in about 20 seconds: SDS, Alert Grid and CMP first, then the iTrak facial recognition and the Citrix page in Edge, skipping anything that’s already open. It offers the sign-in above, puts the windows back where I like them, and ends with Edge on the Citrix page ready to start iTrak.
-   Ctrl+Alt+Shift+L closes it all at the end of the shift, after confirming. It logs out of SDS properly first instead of just closing it, and Ctrl+Alt+K does that SDS logout on its own.
-   Window layout: Ctrl+Alt+Shift+S saves where every window is and Ctrl+Alt+W puts them back. The start of shift does this by itself.
-   Caps Lock guard: plain Caps Lock can’t turn caps on by accident (Shift+Caps Lock does), and a red CAPS LOCK ON tag shows while it’s on. That’s what frees the Caps Lock key to clear Alert Grid. There are no beeps, so it doesn’t bother anyone nearby.
-   Ctrl+Alt and a letter switches to SDS, CMP, Teams, Outlook or Edge.
-   Ctrl+Alt+Q adds a quick note, with a tag like #todo if you want one. Ctrl+Alt+O shows all the notes in a window that always reads the latest copy, so an old Notepad tab can’t save over newer notes.
-   The shift journal saves a copy of every entry you put in, with the time. Ctrl+Alt+J shows how many of each log you’ve done and gives you a one-line summary for the End of Shift entry, like “Shift summary (18:20 - 05:47): 47 logs. 12 Audit, …”. If iTrak loses an entry, you can copy it back from the journal.

Using it as a team

Everyone reads the same template file from a SharePoint folder, so the whole team writes from the same approved wording. When the supervisors change something, every bay picks it up as SharePoint syncs, without restarting anything. If SharePoint can’t be reached, the tool keeps using the last copy it had and says so. Each PC also checks that it’s on the same version as the rest of the team, and says if it needs an update. When a new Watchlog.exe is put in the shared folder, each PC asks before updating itself, checks that the new file works, and keeps a backup of the old one. I can also point my own PC at a separate folder, so I can try a new version on my bay before anyone else gets it.

Setting up a new operator takes about 5 minutes. They run Watchlog.exe and say yes to installing it. That only puts it in their own Windows profile, with no administrator rights, adds it to the Start menu and starts it with Windows. It can be removed in Settings > Apps like any program. A short tutorial shows how codes, forms and the search work, with practice boxes, and a welcome window asks for their logins and where the team file is. After that, changes are made in a Settings window rather than by editing files, and there’s a one-page quick start guide. Operators can add a few codes of their own in a separate file, but those can’t override a team template.

Why it helps

-   It’s faster. A typical entry takes 5 to 25 keystrokes instead of 50 to 300 or more, and clearing Alert Grid is one key instead of five steps.
-   Entries are more consistent. When everyone works from the same file, entries read the same no matter who wrote them, which should make reviews and audits easier.
-   There are fewer mistakes. Times come from the PC clock, numbers are formatted the same way every time, and the standard wording can’t pick up typos. It won’t stop someone saving an incomplete entry, but the XXXXX makes it hard to miss.
-   Training is easier. New operators get a tutorial, can find a template by any word in it, and the templates show how each kind of entry should be worded.
-   It’s easier on the hands and on concentration over a long shift.
-   It’s easy to keep up to date. If a procedure changes, one edit to the shared file updates every bay.

It works in anything you can type into, including iTrak through Citrix, because all it does is paste text where the cursor is. Other departments that write repetitive reports, like security or the cage, could use it with their own template file.

Time saved (my estimates)

I worked these out by counting the keystrokes for each template, typed in full versus with the tool, over a typical shift. They haven’t been timed yet.

[Keystrokes for each template, typed in full and with the tool (counted on version 2.4).]

The longer the entry, the more it saves. The player log saves the least because most of it is details you still have to type.

A typical shift

  ----------------------------------------------------------------------------------------------------------------------------------------
  Task                                       Per shift           By hand                With the tool             Saved
  ------------------------------------------ ------------------- ---------------------- ------------------------- ------------------------
  Log entries (a mix of 18 templates)        30 entries          2,207 keystrokes       388 keystrokes            1,819

  Logins (one app every hour)                10 logins           about 240 keystrokes   about 50 keystrokes       about 190

  Time stamps                                10 stamps           60 keystrokes          20 keystrokes             40

  Total typing                                                   about 2,500            about 460                 about 2,050 (82% less)

  Opening apps and sites at start of shift   3 apps, 7 sites     about 3 minutes        1 key, about 20 seconds   about 3 min

  Closing everything at end of shift         about 11 programs   about 1 minute         1 key and a confirm       about 1 min
  ----------------------------------------------------------------------------------------------------------------------------------------

That’s about 14 minutes a shift: around 10 minutes of typing at 40 words a minute, plus about 4 minutes of opening and closing apps.

  ---------------------------------------------------------------------------------
  Period                            Keystrokes saved        Time saved
  --------------------------------- ----------------------- -----------------------
  Per shift                         about 2,050             about 14 minutes

  Per month (15 shifts)             about 31,000            about 3.5 hours

  Per year (180 shifts)             about 369,000           about 42 hours

  A team of 6 operators, per year   about 2.2 million       about 250 hours
  ---------------------------------------------------------------------------------

Alert Grid isn’t in those tables. I clear it about 50 to 80 times a shift, and each clear by hand is five steps that take me roughly 5 to 10 seconds. One key instead should save somewhere around 5 to 10 minutes a shift, which would nearly double the total. I haven’t timed this yet either.

How I got these numbers:

-   The shift I counted has 30 entries: start and end of shift, 2 each of door checks, patrols, jackpots, AML alerts, facial recognition alerts, no-ID refusals, account reviews and card changes, 4 audits, and 1 each of a table drop, table close, table fill, player log, medical and BV pull. A busier shift would save more.
-   “By hand” means typing the whole entry. “With the tool” means the code, only the details that change, and a Tab or Enter for each box.
-   I counted on an earlier version (2.4). Codes no longer need a space after them, and ;face now fills itself in from a copy, so the real numbers are a little better.
-   I didn’t count fixing typos, looking up wording, redoing entries that get sent back, or logging back in after a missed hourly login. Those would only add to it.
-   The team row assumes 6 operators doing the same mix of entries.

It could look better than it really is for anyone who already copies and pastes from old entries, and worse for anyone who looks up wording or fixes a lot of typos. I plan to spend one shift counting exactly how many times each thing is done, which will give better numbers than these.

Tracking it for real

The tool keeps its own count, so these estimates can be replaced with real numbers. For each entry it works out how much went in compared with how much I typed. An empty box counts as nothing saved, so the numbers aren’t inflated. Logins and time stamps are counted too, and each Alert Grid clear counts as 3 keystrokes, which is on the low side. The time comes from 40 words a minute. Tray menu > Time saved shows logs, logins, keystrokes and time saved for this shift, today, the last 7 days, the last 30 days and the total, and Copy report puts it on the clipboard. It only stores numbers, never the text of a log.

Security and saved information

Since security comes first here, this is everything the tool saves and where. It doesn’t save anything else.

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  What                                                                                                                        Where it’s kept                                                                      Who can see it                                                                     How long
  --------------------------------------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------------ ---------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------------------------------------------------
  Passwords                                                                                                                   Windows Credential Manager on that PC, where Windows keeps its own saved passwords   Only that Windows user. Never put in a file, synced or shown on screen             Until the login is removed in Settings, which deletes the password too

  Login codes, usernames and settings                                                                                         settings.ini in the operator’s Documents\Watchlog folder                             The operator                                                                       Until changed. There are no passwords in it. If someone types one in, the tool moves it into Credential Manager the next time it starts

  Shift journal (time, template and text of each entry, never logins)                                                         The operator’s Documents\Shift Journal folder, which syncs to their own OneDrive     The operator                                                                       30 days, then deleted automatically. It can be set anywhere from 7 days to a year, set to keep only times and template names, or turned off

  Quick notes                                                                                                                 Quick Notes.md in the operator’s Documents                                           The operator                                                                       Until they delete them

  Alert Grid click spots                                                                                                      That PC only                                                                         That Windows user                                                                  Screen positions only. Until the PC is taught again

  Window layout                                                                                                               That PC only                                                                         That Windows user                                                                  Program names, window positions and sizes only. Until saved again

  Time saved counts                                                                                                           That PC only                                                                         That Windows user                                                                  Numbers only, never log text

  The last value of a few boxes, like the bay and the last facial rec alert number logged                                     That PC only                                                                         That Windows user                                                                  Until the next one replaces it

  Activity log (when the tool started, settings changes, template updates, which login was used, Alert Grid clears, errors)   That PC only                                                                         That Windows user                                                                  Trimmed automatically. Never passwords or log text

  Last login time for each username                                                                                           The Windows registry, under the user’s own settings                                  That Windows user                                                                  Only used for the hourly reminder

  A facial rec alert number or match % just copied in Edge                                                                    Memory only, never saved                                                             Nobody                                                                             Forgotten after 2 minutes or once used

  Template wording                                                                                                            One file in a SharePoint folder, plus a backup copy on each PC                       Whoever the folder is shared with. Only the people management allows can edit it   SharePoint keeps earlier versions and who changed them
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

A few more things worth knowing:

-   It doesn’t connect to the internet or send anything anywhere. Its files only reach another PC through the operator’s own OneDrive and SharePoint, under our normal Microsoft 365 permissions. (Ctrl+Alt+L opens the work websites in the browser, the same as clicking a bookmark.)
-   It doesn’t record what you type. It only watches for its own codes.
-   It only types a password when that login’s code is typed, when the operator says yes to “Log in?” or to the start of shift sign-in, or when SDS comes back to its login screen after an SDS login the operator did. That last one can be turned off in Settings. Every time, it checks right before typing that the program in front is one that login is locked to. A login that isn’t locked to a program is never typed automatically.
-   In Alert Grid it only clicks and presses Ctrl+A, Enter or Esc. It never types into the Acknowledge box.
-   It only looks at the clipboard when a form opens with a box that takes a copy, and for ;face it notices copies made in Edge. Nothing it sees there is saved to a file.
-   It doesn’t change iTrak or any other system. It types or clicks what the operator would have, and the operator still saves the entry.
-   The copy it makes for sharing never includes anyone’s settings, passwords, journal or notes.

And how to check all of this:

-   Security and status, in the tray menu, shows everything above for the PC you’re on: which logins have a saved password and which program each one is locked to, whether a password has ended up in settings.ini, where the templates came from, the journal setting, and how many shift files there are. The Copy report button puts it on the clipboard so it can be sent to a supervisor or IT.
-   Each PC shows a short check code for its template wording, something like 1A2B-3C4D. Two PCs with the same code have exactly the same wording, so it’s easy to confirm every bay is on the approved version.
-   When the shared wording changes, each PC shows a notice and writes the old and new check codes to its activity log.

Setup and what IT would need to look at

Watchlog.exe installs per Windows user, with no administrator rights, into that user’s AppData. It adds a Start menu entry, a shortcut in the user’s Startup folder and an entry under Settings > Apps for removing it. Settings and templates go in the user’s Documents\Watchlog folder, which OneDrive syncs, so they follow the operator from bay to bay. The template wording comes from the shared file.

The exe isn’t signed, so Windows may show a SmartScreen warning the first time. For IT, I also have the plain script version (Watchlog.ahk), which is the same program as one text file anyone can read.

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  File                                What it is
  ----------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Watchlog.exe                        The program

  templates.txt                       The wording of every template, in plain English. The team copy lives on SharePoint and the supervisors look after it

  my-templates.txt                    Optional extra codes for one operator, kept separate from the approved wording

  settings.ini                        That operator’s login codes and usernames (no passwords), which program each login is locked to, app shortcuts and start and end of shift lists. Created by the welcome window

  LaunchWork.bat                      The websites that open at the start of shift

  QUICK START.txt and README.txt      A one-page setup guide and the full guide
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

What IT would need to approve:

-   Running Watchlog.exe from the user’s own profile and starting it with Windows
-   Storing passwords in Windows Credential Manager and having the tool type them into the programs they’re locked to
-   The tool clicking through the Alert Grid acknowledge steps for the operator
-   Signing back into SDS by itself about an hour after the operator’s own SDS login, only when SDS is on its login screen
-   The shift journal keeping a copy of log text for 30 days
-   Who gets edit access to the SharePoint template folder. A new Watchlog.exe put there updates every PC that says yes, so I’d keep it to the supervisors and me

Next steps

Version 3.23.0 is built and I’ve been using it on my own shifts. If it’s approved, this is how I’d see it going:

1.  Management and IT sign off.
2.  The supervisors go through and approve the wording of each template.
3.  The approved file goes in a SharePoint folder that all the supervisors have access to.
4.  I count one full shift by hand to check the time saved numbers.
5.  Anyone on the team who wants it installs it on their bays.

I’m happy to show it working to anyone who’d like to see it.
```


---

# FILE 12: docs/Watchlog - Summary.docx (text only)

```text
Watchlog summary

Oct 25, 2026 · Jakob

Watchlog is a small Windows program I built that types our standard log entries. You type a short code like ;interior or ;medical, fill in the details that change, and the finished entry goes into iTrak. You still read it over and save it yourself, same as now. It also clears the Alert Grid list with one key once you’ve looked it over, opens and signs into our programs at the start of shift, and signs SDS back in when it logs me out after an hour. A home window with a button for everything makes it easy for new people to find their way around.

Why it’s worth trying

-   About 2,000 keystrokes and 14 minutes saved per shift on typing and opening programs by my count, roughly 42 hours a year per operator. One-key Alert Grid clearing should add another 5 to 10 minutes a shift. These are estimates, and I plan to count a full shift to check them.
-   Everyone works from the same approved wording, so entries are consistent.
-   Fewer typos and missed details: times come from the clock, numbers are formatted for you, and a blank box shows up as XXXXX.
-   New operators get a short tutorial and can search templates by any word, so there’s nothing to memorize.

Security

-   Passwords are kept in Windows Credential Manager on each PC, never in a file and never synced. A login is only typed into the program it’s locked to.
-   It doesn’t connect to the internet, send anything anywhere, record what you type, or change anything in iTrak. In Alert Grid it only does the clicks you’d do, and never touches the password.
-   The only copy of log text it keeps is each operator’s own shift journal, which is deleted after 30 days.
-   The shared wording sits in a SharePoint folder that the supervisors have access to. Each PC shows a check code proving it has the approved version, and a Security and status report listing everything the tool has saved there.

What I’m asking for

Approval for anyone on the team who wants it to use it. I’d need the supervisors named by management to approve the wording, a SharePoint folder for the shared file, and IT to check the password storage, the automatic logins and Alert Grid clicks, and running Watchlog.exe with Windows. It installs per user with no administrator rights. The full overview has all the details.
```


---

# FILE 13: docs/Watchlog - IT Summary.docx (text only)

```text
Watchlog: information for IT

Oct 25, 2026 · Jakob

Watchlog is a small Windows program I built that types our standard surveillance log entries. I type a short code like ;interior and the full wording appears. It’s written in AutoHotkey v2 and comes as one Watchlog.exe with the AutoHotkey runtime built in, so nothing else is installed. The same program is also available as one plain text script for anyone to read. I’m on version 3.23.0 and have been using it on my own shifts since October 13. I’m asking for approval so other operators and supervisors can use it if they choose to, on our 3 operator bays and the supervisor bay.

What it does and doesn’t do

-   It types and pastes what the operator would have typed. The operator still saves the entry. It doesn’t change iTrak, SDS or any other system.
-   It clears the Alert Grid list when the operator presses Caps Lock or Ctrl+Alt+A. It clicks the same steps as by hand (Ctrl+A, right-click, Acknowledge as received, Submit, OK) using screen positions taught once per PC. The Acknowledge box is filled in by Alert Grid with the operator’s own login. Watchlog never reads or types into it.
-   SDS signs the operator out after an hour. Watchlog types the saved SDS login again about 62 minutes after an SDS login the operator did, only if SDS is on its login screen, and then puts the operator’s previous window back. It retries once a minute up to 6 times and can be turned off in Settings > Logins.
-   It doesn’t connect to the internet or send anything anywhere. Its files only travel through OneDrive and SharePoint under our normal Microsoft 365 permissions.
-   It doesn’t record what anyone types. It only watches for its own codes. It reads the clipboard only for a form box that takes a copy, and keeps a copied facial rec alert number or match % in memory for 2 minutes at most.

Passwords and saved information

-   Passwords are kept in Windows Credential Manager, on that PC, for that Windows user. They are never in a file, never synced and never shown.
-   A password is typed only when that login’s code is typed, when the operator answers Yes to “Log in to SDS?” or to the start of shift sign-in, or for the SDS sign-back-in above. Each time it first checks that the window in front is one that login is locked to. Logins with no lock are never typed automatically.
-   The shift journal keeps the time, template name and text of each entry for 30 days, then deletes it. It can be set to counts only, or off.
-   On the PC only: the activity log (never passwords or log text), Alert Grid click positions, window positions, time saved counts and a few last-used box values. The registry holds the last login time and the uninstall entry.
-   Tray menu > Security and status shows all of this for the PC in front of you, with a Copy report button.

Updates and shared files

The approved wording is one file in a SharePoint folder that the supervisors look after. Each PC shows a short check code, so it’s easy to confirm every bay matches. A new Watchlog.exe can go in the same folder. Each PC asks “Update now?”, checks the file, keeps a backup and refuses a broken one. That means whoever can edit the folder controls what the bays run, so I’d ask that edit access be limited to the supervisors and me. A user can also point their own PC at a folder of their own for testing, which only affects that PC.

What I’m asking IT to approve

1.  Watchlog.exe installed per user, with no admin rights, and starting with Windows. It isn’t signed, so SmartScreen may warn once.
2.  Passwords in Windows Credential Manager, typed into the programs they’re locked to.
3.  Watchlog clicking through the Alert Grid acknowledge steps for the operator.
4.  The automatic SDS sign-back-in (can be off).
5.  The 30 day shift journal (or counts only).
6.  Edit access to the SharePoint template folder.

Setting up and removing it

Setup per PC: run Watchlog.exe and say yes to installing (it goes in %LOCALAPPDATA%\Programs\Watchlog, with a Start menu entry and a Startup shortcut), go through the welcome window, then teach the Alert Grid clicks once with Ctrl+Alt+Shift+A. Settings live in Documents\Watchlog, so OneDrive needs to start with Windows.

To remove it, use Settings > Apps > Watchlog. It offers to delete the saved passwords and leaves the operator’s settings and journal in Documents. %LOCALAPPDATA%\Watchlog and HKCU\Software\Watchlog can then be deleted.

I’m happy to show it working to anyone who’d like to see it. The full overview has more detail.
```


---

# FILE 14: docs/Watchlog - Template Wording Review.docx (text only)

```text
Watchlog - Template Wording Review

Oct 21, 2026 · Jakob

This is every template in Watchlog, with the exact wording it writes. Please mark anything you'd change in the Notes column. Once the wording is approved, it goes in the shared file on SharePoint and every bay uses it.

Anything in [square brackets] is a box the operator fills in. Text after a colon, like [Location: Main Entrance], is what the box fills in unless it's changed. Boxes that pick from a long list are explained in the table at the end. A box left empty prints XXXXX, so a missing detail is easy to spot. Entries from ;fill, ;mfill and ;bv can list several tables or machines in one log.

Incidents and reviews

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Code              Template             What it writes                                                                                                                                                                                                                                                                                             Notes
  ----------------- -------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- -----------------
  ;jack             Jackpot              Operations Supervisor advised of a $[Amount] Supervisor Jackpot @[Machine]. Review confirmed winner. Patron requested to be paid all cash at window #[Window #]. Slot Attendant was observed paying patron @[Time paid].                                                                                   

  ;audit            Audit                Surveillance observed [Employee type] [Employee #] from [From] - [To] on [Location]. Nothing suspicious observed.                                                                                                                                                                                          

  ;medical          Medical              Security Supervisor notified Surveillance of a/an [Who: employee / guest] medical at [Location: Kitchen / Main Entrance]. A review was conducted and observed [What the review showed]. Security administered first aid and contacted EMS. [Outcome] Security Supervisor notified of the review results.   

  ;evict            Trespass             Report opened on behalf of Security. The Security Supervisor approached a guest at [Location: Main Entrance] for [Reason]. The guest was escorted off the gaming floor and given a/an [Length: 24 hour / indefinite] Trespass. The guest left without further incident.                                    

  ;face             Facial recognition   Facial Recognition Alert #[Alert #] ⏎ [Result: Rejected] ([Match])                                                                                                                                                                                                                                         
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Start and end of shift

  -----------------------------------------------------------------------------------------
  Code              Template          What it writes                      Notes
  ----------------- ----------------- ----------------------------------- -----------------
  ;start            Start of shift    Start of Shift Bay [Bay] Operator   

  ;end              End of shift      End of Shift Bay [Bay] Operator     
  -----------------------------------------------------------------------------------------

Security routines

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Code              Template              What it writes                                                                                                                     Notes
  ----------------- --------------------- ---------------------------------------------------------------------------------------------------------------------------------- -----------------
  ;interior         Interior door check   Security Supervisor performed interior door check                                                                                  

  ;exterior         Exterior door check   Security Officer performed exterior door check                                                                                     

  ;parking          Parking lot patrol    Security Officer performed parking lot patrol                                                                                      

  ;refuse           Refused entry         Security Officer refused entry to [Patrons: one patron] due to [Reason: no ID] [Signs observed, in brackets, only if filled in].   

  ;selfex           Self-exclusion        Security Supervisor advised taking patron into PlaySmart to perform a self exclusion.                                              

  ;inventory        Inventory transfer    Security Officer performed inventory transfer from Delta Podium to Main Bank.                                                      

  ;account          Account review        Account #[Account #] reviewed, not banned player, Guest Services notified                                                          

  ;drop             Table drop            Security Officers performed Table Drop                                                                                             
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Tables

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Code              Template          What it writes                                                                                                                                                Notes
  ----------------- ----------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------- -----------------
  ;open             Table opening     [Table: UT201 / FB202 / UT203 / RO204 / BJ205 / BJ206] Opened.                                                                                                

  ;close            Table closing     Pit Manager advised checking table tray lids and Dealers collecting tokes.                                                                                    

  ;auto             Auto-close        [Table: UT201 / FB202 / UT203 / RO204 / BJ205 / BJ206] Closed and Auto-Close started.                                                                         

  ;cards            Card change       Card change on [Table: UT201 / FB202 / UT203 / RO204 / BJ205 / BJ206].                                                                                        

  ;fill             Table fill        [Table: UT201 / FB202 / UT203 / RO204 / BJ205 / BJ206] $[Amount]                                                                                              

  ;player           Player log        [Player #] playing Spot [Spot], [Table: UT201 / FB202 / UT203 / RO204 / BJ205 / BJ206], In $[Buy-in], [Down/Up: Down / Up] $[Amount]. [Reason (only if up)]   
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Slots

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Code              Template                                What it writes                                                                                                                                                                                                                                                                                                                                                   Notes
  ----------------- --------------------------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- -----------------
  ;bv               Emergency BV pull                       [Machine] [Asset #] ([Reason: Full / Defective])                                                                                                                                                                                                                                                                                                                 

  ;abandon          Abandoned credits                       Operations Supervisor requested a review to determine the owner of abandoned credits found at [Found at]. A review was conducted and observed the last patron gaming there leave without appearing to cash out. Patron was found live gaming at [Patron found at]. Operations Supervisor advised, approach made and funds returned. TITO value ($[TITO value])   

  ;found            Abandoned credits - taken to Security   Operations Supervisor advised printing off abandoned credits in the amount of $[Amount] from [Machine]. Funds taken to Security as found.                                                                                                                                                                                                                        

  ;aml              AML alert                               AML Alert #[Alert #] populated at [Machine] ([Time]). Review showed nothing suspicious.                                                                                                                                                                                                                                                                          

  ;maint            Maintenance                             [Machines: NRT2 and NRT4] Maintenance.                                                                                                                                                                                                                                                                                                                           

  ;mfill            Machine fill                            [Machine] $[Amount]                                                                                                                                                                                                                                                                                                                                              
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Soft count

  -------------------------------------------------------------------------------------------------------------------------------------------------------
  Code              Template                      What it writes                                                                        Notes
  ----------------- ----------------------------- ------------------------------------------------------------------------------------- -----------------
  ;countstep        Soft count step               [Time] - [Step]                                                                       

  ;counttables      Soft count - table totals     [Time] - Tables totals: 1st; $[1st], 2nd; $[2nd], called Main banker for Table buy.   

  ;countslots       Soft count - slots total      [Time] - Pod 2 completed. Slots Total: $[Slots total]. Called Main Banker for Buy.    

  ;countpull        Soft count - emergency pull   [Time] - completed emergency pull for [Machine].                                      
  -------------------------------------------------------------------------------------------------------------------------------------------------------

Other

  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Code              Template           What it writes                                                                                                              Notes
  ----------------- ------------------ --------------------------------------------------------------------------------------------------------------------------- -----------------
  ;destroy          Card destruction   Security Officers entered Card Destruction Room for Card Destruction.                                                       

  ;badge            Contractor pass    Pass #17-0[Pass # (1-9)] issued [Issued: to XXXXX employee]. (The other choice writes: Pass #17-0X issued for interview.)   
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Lists the forms pick from

  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Box                                 Choices
  ----------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Employee type (;audit)              Dealer · Security Officer · Security Supervisor · Operations Supervisor · Operations Manager · Pit Supervisor · Pit Manager · Cage Cashier · F&B Server · F&B Bartender · F&B Dishwasher · F&B Commis Chef · F&B Sous Chef · F&B Chef de Partie · F&B Supervisor · F&B Manager · General Manager · Count Team Attendant · Count Team Supervisor · Audit Supervisor · Auditor · Slot Attendant · Slot Technician · Main Banker · EVS Attendant · General Maintenance · Facilities Manager

  Medical outcome (;medical)          EMS arrived on site and took the individual off-site via ambulance. · EMS arrived on site and the individual returned to the gaming floor, no further action taken.

  Trespass reason (;evict)            showing signs of intoxication · being verbally abusive towards staff · being in violation of their trespass

  Machine (;mfill)                    NRT1 · NRT2 · NRT3 · NRT4 · ATM1 · ATM2 · ATM3 · ATM4 · ATM5

  Step (;countstep)                   Count Team entered Count Room. Tables soft count started. · Main Banker entered Count Room for tables Buy. · Buy confirmed, Pod #1 Soft Count started. · Money secured, Count Team on break. · Pod 2 Soft Count started. · Main Banker entered for Buy. · Buy complete, totals confirmed. Calling Security for Sweep. · Security entered for Sweep. · Sweep complete.

  Pass number (;badge)                1 · 2 · 3 · 4 · 5 · 6 · 7 · 8 · 9

  Patrons (;refuse)                   one patron · 2 patrons · 3 patrons · 4 patrons · 5 patrons

  Reason (;refuse)                    no ID · insufficient ID · expired ID · showing signs of intox

  Issued (;badge)                     to XXXXX employee (type the company over XXXXX) · for interview
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
```


---

# FILE 15: docs/Watchlog - Demo Run Sheet.pdf (text only)

```text
Watchlog - Demo Run Sheet




  Watchlog - Demo Run Sheet
    Oct 21, 2026       · ​@Jakob

  This is a 10 to 15 minute walk-through for showing Watchlog working. Do it in Notepad, not
  in a real iTrak entry, and use made-up numbers like Dealer #123456 so nothing real ends up
  on screen. Each test shows what to type, what should appear, and one line to say.


  Before he arrives
         Watchlog is running (teal icon by the clock) and the tray menu shows the current
         version.
         Open a blank Notepad window to paste into.
         OneDrive is running, so the templates are the current ones.
         Close or cover any real iTrak entries, player numbers and employee numbers.
         Have the overview printed, with the one-page summary on top.
         Open Time saved and write down the numbers. The demo's entries count toward Time
         saved and go in the shift journal, so take them off your real tally afterwards.


  The demo

     #         Test                What to type or press   What should             What to say
                                                           appear

     1         A quick entry       ;interior               Security Supervisor     9 keystrokes
                                                           performed interior      instead of about
                                                           door check              50.
                                                           (straight away, no
                                                           form)

     2         A form with         ;evict , then Enter     The full trespass       Tab moves
               defaults                                    entry, with the         between boxes and
                                                           preview filling in as   Esc cancels. I still
                                                           the boxes change        read it over and
                                                                                   save it myself.

     3         Picking from        ;evict , drop down      Three reasons to        Wording stays the
               a list              the Reason box          pick from               approved wording.



                                                                                                      Page 1 of 4
Watchlog - Demo Run Sheet




     #         Test         What to type or press    What should             What to say
                                                     appear

     4         An audit     ;audit , pick Dealer,    Surveillance            The times fill
                            type 123456, type m3     observed Dealer         themselves in.
                            as the location, Enter   #123456 from (time
                                                     now) - (20 minutes
                                                     later) on M3 (it
                                                     capitalizes m3 for
                                                     you). Nothing
                                                     suspicious
                                                     observed.

     5         Several      ;refuse , pick 2         Security Officer        One template
               patrons      patrons and no ID,       refused entry to 2      covers every
               refused      Enter                    patrons due to no       refusal reason and
                                                     ID.                     any number of
                                                                             patrons.

     6         Signs        ;refuse , pick showing   ...due to showing       The brackets only
               observed     signs of intox, type     signs of intox          appear when
                            slurred speech in the    (slurred speech).       something is
                            third box, Enter                                 typed.

     7         Formatting   ;jack , type 10000 as    Operations              Money, capitals
               for you      the amount, b1410 as     Supervisor advised      and times come
                            the machine, 3 as the    of a $10,000            out formatted the
                            window, 2130 as the      Supervisor Jackpot      same way every
                            time paid                @B1410. ... window      time.
                                                     #3. ... paying patron
                                                     @21:30.

     8         A missing    ;aml , type b1410 as     AML Alert #XXX          A blank box shows
               detail       the machine and leave    populated at            as XXX or XXXXX,
                            the alert number         B1410...                so a missing detail
                            empty                                            is easy to spot.

     9         Several in   ;bv , type b1410 and     Two lines in one        Add another keeps
               one log      12345, press             entry, the first one    the earlier ones in
                            Ctrl+Enter, add a        B1410 #12345 (Full)     the preview.
                            second machine, Insert




                                                                                              Page 2 of 4
Watchlog - Demo Run Sheet




     #         Test            What to type or press     What should             What to say
                                                         appear

     10        A table         ;fill , type 202 in the   FB202 $5,000            Typing just the
               shortcut        table box, 5000 as the                            number picks the
                               amount                                            table.

     11        Can't           Ctrl+Alt+Space, type      ;evict listed, with     New operators can
               remember a      trespass                  the wording shown       search by any
               code                                      below                   word.

     12        Every code at   Ctrl+Alt+H                The cheat sheet         One list of every
               a glance                                                          code.

     13        Time stamps     ;t , ;dd , ;dt            @21:42, 2026-10-21,     Instant, no form.
                                                         or 2026-10-21
                                                         @21:42 (with the
                                                         real time and date)

     14        A quick note    Ctrl+Alt+Q, type a        "Note saved".           Handy for a
                               made-up note, OK          Ctrl+Alt+O opens        reminder in the
                                                         all the notes.          middle of a shift.

     15        The shift       Ctrl+Alt+J                How many of each        Copy summary
               journal                                   log this shift, and     gives the one-line
                                                         the time saved so       summary for the
                                                         far                     End of Shift entry.

     16        Time saved      Tray menu, Time saved     Logs, logins,           It only counts what
                                                         keystrokes and          I actually saved,
                                                         time for this shift,    and stores
                                                         today, the last 7       numbers, never log
                                                         days, the last 30       text.
                                                         days and in total

     17        Security        Tray menu, Security       Passwords saved in      This is everything it
                               and status                Credential Manager      saves, and it can be
                                                         only, none in a file,   sent to IT with
                                                         and which template      Copy report.
                                                         file is in use




                                                                                                     Page 3 of 4
Watchlog - Demo Run Sheet




     #         Test           What to type or press      What should            What to say
                                                         appear

     18        The            Click the version line     Up to date: the        The same check
               approved       at the top of the tray     team is on v3.4.2,     code on two PCs
               version        menu                       and program check      means exactly the
                                                         code 344E-9A72         same program.




  Describe, don't demonstrate
  These change the screen, so talk through them rather than running them on a real shift.

         Ctrl+Alt+L opens SDS, AlertGrid and CMP first, then the work websites, and ends on
         the Citrix page. The apps get up to 20 seconds to open before the websites start.
         Ctrl+Alt+Shift+L asks first. If you say yes it logs out of SDS properly, then closes the
         work apps. If you show it, answer No.
         Ctrl+Alt+K logs out of SDS properly on its own, so nobody gets locked out.
         The logins type a username and password from Windows Credential Manager. Never
         show a password on screen.


  If something goes wrong
         A form won't go away: press Esc.
         A code doesn't fire: check the cheat sheet (Ctrl+Alt+H) for the exact code. It needs
         the semicolon.
         Watchlog seems stuck: right-click the tray icon and choose Reload Script.
         Nothing pastes into iTrak through Citrix: the finished entry is still on the clipboard, so
         press Ctrl+V once more, or paste it into Notepad, copy it again and paste it into iTrak.




                                                                                                Page 4 of 4
```
