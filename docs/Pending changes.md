# Watchlog: Pending changes

Suggestions collected for the next version. Nothing here is built yet.
When Jakob says to build, all of these go into one new version and this list is cleared.

Current version: v3.10.0 (Oct 25, 2026).

## Waiting to be built

- Wording review sheet: swap the four old refusal rows for one `;refuse` row once Jakob has finished his own edits.

## Done Oct 21 (no version change)

- Overview: the Ctrl+Alt+L line is back, now saying apps first, then websites, ending on the Citrix page (v3.4.0 order). Done in both overview versions; later overview edits go in the plain version first, then the illustrated one is rebuilt. Overview easier to follow, screenshots version, time saved section, SDS logout line and Ctrl+Alt+K are all done too. Both say v3.4.1 now.
- settings.example.ini: the example login was `;me`, which clashes with `;medical` (it would fire first and the template got skipped); now `;login`. LaunchWait example is 20, matching the "at least 20" note.
- README: `suffix=` added to the box options list.

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
