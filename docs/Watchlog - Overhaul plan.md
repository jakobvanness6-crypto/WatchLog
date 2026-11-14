# Watchlog - Overhaul plan

Written Nov 14, 2026, against v3.37.0 (built, NOT run). Planning only: nothing in the program has changed. Nothing gets built until Jakob says "build it".

Jakob (Nov 14): "go over everything we've done with this program and bring it to its maximum potential. I need it to save as much time as possible throughout a shift and make the workflow effortless."

## The short version

The goal is time saved per shift, so the plan has two parts and the first one comes first:

- **Part A: save more time in a shift.** Where the shift still costs keystrokes, clicks and decisions, and the builds that take them away. Batch 1 is the recommended first build.
- **Part B: foundation.** Code and docs cleanup that makes Part A safer and faster to build, done in small behaviour-neutral versions, never all at once.

The big constraint: Jakob can only test on his work PC, and every build since v3.28.0 is "built, NOT run". So each step is one version he can check in a shift, risky steps are opt-in switches (off until he turns them on), and Go back a version stays the safety net.

## Part A: save more time in a shift

### Where the time still goes

Looked at every feature from v2.1 to v3.37.0, the templates file and the README. What a log costs today, best case:

| Step in a log | Today | Still costs |
|---|---|---|
| The call | Numpad + opens the pad, jot while talking | Nothing to save; the pad is the notepad |
| Turning the call into a log | 8 code words have shorthand lines (fill, open, auto, jack, bv, mfill, account, oc): one line + Ctrl+Enter = finished log, no form. The other 29 code words open their form prefilled with what the pad found (machine, table, amount, alert #) | A form per log for 29 of 37 code words: read it, fill the rest, Enter |
| Opening the daily log | 32 of 37 code words (>>) open a new daily log, fill Location, Topic, Reference, paste the wording, click End Time Now where the template says `end` | Nothing, when the spots are taught on that bay |
| Saving the log | Jakob clicks Save in iTrak himself, every log | One click plus a wait per log, every log |
| Fixed logs | Ctrl+Alt+F list, Ctrl+Alt+Space picker with pins/recent/first letters, Ctrl+Alt+Shift+R repeats the last one | Nothing much |
| Soft count | ;countstep remembers the next step, counttables / countslots / countpull are separate code words; none of them fill the daily log (no >>) | Location/Topic/Reference typed by hand for every count log, 9+ logs per count |
| Audits | ;audit fills Console, Area, Start/End, Remarks, Requested By. Jakob opens the audit, picks the employee, saves | Open + employee + Save stay by hand (employee is personal data: stays by hand on purpose) |
| Alerts | Caps Lock clears the Alert Grid; ;face logs a facial alert | Nothing much |
| Incidents | Ctrl+Alt+Shift+N fills from the open daily log; stops at Secondary Operator | Checklist and Custom Forms tabs (Jakob still to show what goes in them) |
| Start / end of shift | Ctrl+Alt+L / Ctrl+Alt+Shift+L, SDS signs in hourly, layout put back, SDS kept out of the Alert Grid's spot | Nothing much |
| Knowing where the time goes | Time saved counts keys, clicks and autocorrect; Shift count per item | Nothing measures what is slow (how long from code word to pasted log) |

Time saved today is about 6 minutes and 1,200 keystrokes on a slow 12-log shift (Jakob's own count, Oct 25). The typing is mostly gone; what is left is **forms, Save clicks, soft count, and the waits**.

### The builds, ranked by time saved per shift

1. **Shorthand for every code word** (the ask since Oct 30, "shorthand for more logs"; waiting on Jakob's lines per log). Instead of designing each log's shorthand by hand: one rule for all 37. The first word is the code word (or an alias), the rest of the words fill the form's boxes in order, lists match by first letters, money and tables and machines are recognised wherever they sit, and anything the line doesn't have opens the form with the rest filled in. Examples: `cards 205`, `close 2`, `break`, `medical guest buffet`, `refuse 2`, `interior sup`, `destroy`, `aml 123 b1410`, `badge 3 jsmith`. Aliases in templates.txt (`;cards | cc`) so his own abbreviations work. Result: one line + Ctrl+Enter for every log. Safe: nothing changes until a line starts with a code word, and the form still opens when something is missing.
2. **Save after fill (opt-in switch, off by default).** After a >> log is filled and pasted, Watchlog clicks iTrak's Save (taught spot or key), only when every box was filled and nothing was skipped. One click and one glance saved per log, about 30 clicks a shift. Risky: a wrong Save is a saved wrong log. So: off by default, a 2-second "Saving..." tip with Esc to stop, never on an untaught bay, counted as a click in Time saved.
3. **Soft count as one guided run.** `count` on the pad (or ;count) steps through the 9 steps, each with the time filled and the daily log opened and filled (>> added to the four count code words), Enter per step, Esc out. Tables and slots totals asked when their step comes. Cuts a whole soft count from 9 forms to one run.
4. **One-hand numpad mode while on the phone.** Numpad + already opens the pad. Add: while the pad or the picker is open, Numpad 1-9 run the 9 pinned templates (shown with their number), Numpad Enter = Ctrl+Enter, Numpad . = New call. Nothing changes outside those windows.
5. **Measure what is slow.** Time each log from code word to pasted (no content, just the milliseconds and which step) and show the slowest steps in Shift count. That tells us which waits to tune on his bay instead of guessing. Also: `Activity()` lines on the silent `try` around saves, so a lost setting is visible.
6. **Waits tuned from the measurements** (after 5): the 39 Sleeps of 100 ms or more around iTrak/Citrix, most already settings, shortened only where the timing shows room. Risky: Citrix. One setting at a time, his bay only.
7. **Reminders with a Log it button** (Oct 14 idea E, still open): patrol and door checks expected at set times, audit end at +20 min, "start of shift log not entered" at 10 min. Tray pop-up with a button that runs the matching full-entry log; nothing automatic. Value depends on how many of these he does by the clock: ask.
8. **Incidents, the rest:** Checklist and Custom Forms tabs, when Jakob shows them; trespass Specific.

Not proposed (decided before): copying from CMP/Alert Grid, Info From people search, anything that writes into iTrak on its own, storing people names, a rewrite in another language.

### Batch 1 (recommended first build, v3.38.0)

Items 1, 3, 4 and 5, plus item 2 as a switch that starts off. One version, one shift to check: a dozen calls as shorthand lines, one soft count, the numpad keys, and Save after fill turned on for a few logs once the rest is proven.

What Jakob can send to sharpen it (no log text, counts only): the Shift count list from two or three shifts (which code words he runs most), and three things in a shift that still feel slow.

## Part B: foundation

### What the audit found (Watchlog.ahk, v3.37.0)

The program is one file of 13,630 lines, 451 functions, 70 sections. It is in better shape than that sounds:

| Looked at | Found | Verdict |
|---|---|---|
| Dead code | Only 3 functions are never called: `FindTemplates` (replaced by the quick picker, v3.36.0), `AuditEndText` (replaced by `AuditEndFormat`, v3.35.0), `NoteOwnWrite` (singular; `NoteOwnWrites` is live). | Tiny. Remove (safe). |
| Duplicated logic | Two small repeats: the "Which bay are you on?" box (around lines 5121 and 5136) and the insertion sort in Shift count. | Fold into a helper when nearby code is touched. |
| Naming clashes | None: no variable shares a function's name (the v3.27.0 `joined`/`Joined` problem does not recur). 77 distinct globals. check-ahk.py passes (sections A-E clean). | OK. Keep running check-ahk.py before every build. |
| Giant functions | `ShowEditor` 627 lines, `ShowSettings` 449, `FormPaste` 434, `ClearAlerts` 205, `ShowEntryEditor` 192, `ShowPicker` 167, `AuditFill` 166, `ParseFields` 164, `RunEntry` 156, `ShowJournal` 155. Ten functions are 2,700 lines, a fifth of the file. | Where bugs hide. Split one at a time, each when its feature is next touched (FormPaste and RunEntry first: Part A item 1 lives there). |
| Error handling | `OnError` logs "Error on line N" and shows a plain box; Watchlog keeps running. 226 one-line `try X` swallow errors silently, some around file writes. | Fine for a desk tool. Add `Activity()` to the ones around saving (settings, layout, spots, time saved). |
| Settings sprawl | 10 data files (settings.ini, team-settings.ini, last used.ini, time saved.ini, layout.ini, itrak.ini, alertgrid.ini, picker.ini, call pad files) plus templates/my-templates/autocorrect/pins/incidents. 152 raw `IniRead` calls on 57 section/key pairs; only 32 keys go through the three-layer `CfgRead` from v3.37.0, so a team-settings.ini default is ignored for 40 reads of settings.ini. | The real problem for the team rollout. Every setting through `CfgRead`, one complete settings.example.ini. |
| Start-up | Load does about 20 steps (logged) and is fast. Two 150 ms timers run forever (Caps Lock check, taskbar preview poll), a 2 s file watcher, a 5 s autocorrect sync. | Stop the two 150 ms timers when their module is off. Low value, low risk. |
| Comments and history | 1,584 comment lines (12%), a banner per feature, "(vX.Y.Z)" notes inline. | Good. Keep the history notes. |

### Fragile for the team (feeds docs/Team readiness audit.md)

1. Daily log field, audit and incident spots are measured from the screen, not from inside the iTrak window (Alert Grid and the new log button already are, v3.18.0). This is the prerequisite for sharing bay spots (Team readiness step 2) and the most fragile thing in the program.
2. Jakob's defaults live in code (Edge, Spotify, Caps Lock clears, Numpad +, autocorrect everywhere, clock, previews). v3.37.0 turns them off for new operators; the values should move into the built-in default table and team-settings.ini.
3. >> code words, Ctrl+Alt+F, ;audit and incidents fail on an untaught bay instead of pasting the wording with a tip.
4. Log Templates migration code (around 70 lines) still runs at every start. Harmless; remove in v4.0.

### Docs

- Current version is consistent (v3.37.0) everywhere it should be; older numbers in README and Pending changes are history, which is right.
- The same information lives in six places: README.txt (1,928 lines, manual plus changelog), QUICK START.txt, PROJECT-NOTES.md (one 85 KB paragraph per version), docs/Pending changes.md (80 KB; waiting, built, dropped and history all mixed), the three manager docs in docs/source, and the cheat sheet and tutorial inside the program. Every release touches all of them by hand.
- docs/Next Steps and Ideas.md (Oct 14, v2.1) is mostly built or superseded; mark it historical, keep the open ideas (E reminders, B guided procedures: both now in Part A).
- Repo vs /mnt/project-files differ only by CRLF line endings; a .gitattributes line stops whole-file diffs.

### Split into #Include parts?

AutoHotkey v2 `#Include` works and the compiled exe is identical. About 12 parts by the existing banners (core/settings, templates+forms, call pad, journal+time saved, Alert Grid, iTrak logs, audits, incidents, windows, team+updates+install, screens, look). Line numbers in the error box become file + line; release.sh, check-ahk.py, bump-version.py, build.ahk and the IT zip must learn the parts. Behaviour-neutral but one-shot and touches every line. Recommendation: yes, as its own version with nothing else in it, after v3.37.0 and batch 1 are confirmed on his bay.

## The order

| Step | Version | What | Safe or risky | Jakob checks |
|---|---|---|---|---|
| 0 | - | Confirm v3.37.0 on his bay (team setup screen; nothing else changed for him). | - | One normal shift. |
| 1 | v3.37.1 | Part B cleanup: 3 dead functions out, `Activity()` on silent saves, timers stop when module off, .gitattributes, Next Steps marked historical. | Safe | Loads; tray; one code word; one form. |
| 2 | v3.38.0 | **Batch 1**: shorthand for every code word, soft count run, numpad mode, log timing, Save after fill (switch, off). FormPaste/RunEntry split on the way. | Items 1, 3, 4, 5 safe; item 2 opt-in | A dozen shorthand calls, one soft count, numpad keys; then Save after fill on for a few logs. |
| 3 | v3.38.1 | All settings through `CfgRead`; Jakob's defaults into the default table and team-settings.ini; complete settings.example.ini. | Safe (same values, different lookup) | Start/end of shift, SDS sign-in, break, clock, previews: same as before. |
| 4 | v3.38.2 | Waits tuned from the timing (step 2), one setting at a time. | Risky (Citrix) | Each log type once. |
| 5 | v3.39.0 | Spots measured from inside the iTrak window + paste-with-tip when untaught (Team readiness step 2's prerequisite). | Risky (every >> log, Ctrl+Alt+F, ;audit, incidents) | Re-teach once, then one of each. Go back a version is the net. |
| 6 | v3.39.1 | Split into #Include parts; error box says file + line. | Safe in intent, big | Loads; error box test; IT zip opens. |
| 7 | v3.40.0 | Docs: CHANGELOG out of README, PROJECT-NOTES trimmed to a table, Pending changes split Waiting / Built / Dropped, manager docs rebuilt. | Docs only | Read-through. |
| 8 | v3.40.x | Reminders with Log it (if wanted), incidents tabs, Team readiness steps 2-3, pilot with Michael. | New features | Pilot. |

Jakob (Nov 14) picked **Foundation cleanup first**, so Part B goes before Part A. Done so far:

- **v3.37.1 (Nov 14, built NOT run):** step 1 plus the settings half of step 3. Three dead functions out; failed saves logged (TryIniWrite/TryAppend); Caps Lock and preview timers only while on; 17 more settings keys through CfgRead and the team [AppN] list; starter team-settings.ini and settings.example.ini list them; Next Steps and Ideas marked historical. Logins, team folder pointer, update folder and hotkeys stay personal-only on purpose.
- Next, each its own version after the previous one is confirmed on his bay: #Include split (step 6), window-relative iTrak spots (step 5), giant-function breakup, docs split; then Part A batch 1.
