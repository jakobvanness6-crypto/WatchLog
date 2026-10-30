# Watchlog: Pending changes

Suggestions collected for the next version. Nothing here is built yet.
When Jakob says to build, all of these go into one new version and this list is cleared.

Current version: v3.28.0 (Oct 30, 2026): safeguards batch 2 (repeat last log Ctrl+Alt+Shift+R, daily backups, restore, go back to previous version) on top of v3.27.3 Alert Grid step-5 timing, v3.27.2 load fix and v3.27.1 SDS sign-in fix (built, NOT run: the sandbox blocked running AutoHotkey).

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

## Done in v3.28.0 (Oct 30)
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
