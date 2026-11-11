# Watchlog - Team readiness audit

Written Nov 11, 2026, on v3.36.0. Planning only: nothing in the program has changed. Nothing gets built until Jakob says "build it".

Jakob (Nov 11): "Many features I have designed are designed around my specific workflow but there are quite a few things that would break when I introduce it to the team. It needs to be more general and adaptive."

## The short version

Most of Watchlog is already general: the wording lives in one shared templates.txt, the Alert Grid and new daily log spots can be shared through the team folder, hotkeys and the code word prefix can be changed, and passwords never leave the PC.

The real problem is **where settings live**, not any single feature. Today Watchlog knows two places:

- **"Personal"** = the Watchlog folder in the Windows account's OneDrive (settings.ini, logins, my-templates, pins, autocorrect, incidents.txt, Shift Journal).
- **"This PC"** = %LOCALAPPDATA%\Watchlog (taught spots, window layout, passwords in Credential Manager, time saved, call pad, recent picks).

Because every bay signs in to the **same Windows account**, "personal" really means "everyone", and "this PC" means "whoever sits at this bay". So a teammate on Jakob's bay would get Jakob's logins (and Jakob's saved passwords behind them), Jakob's Requested By route in ;audit, Jakob's pins and time saved, and Jakob's journal.

The fix is three layers instead of two, each with a clear owner:

| Layer | Where | Who sets it | What goes in it |
|---|---|---|---|
| **Team** | team-settings.ini beside the shared templates.txt | Supervisor, once | Site things: browser, web addresses, Bally app paths, SDS sign-in minutes, break minutes, which features are on by default, iTrak date formats, pit/slots lists |
| **Bay** | %LOCALAPPDATA%\Watchlog (as now) | Taught once per bay | Spots that depend on the screen: Alert Grid, iTrak new log, daily log fields, audit and incident fields, window layout, clock monitor |
| **Person** | A profile per operator, picked at start of shift | Each operator | Logins and their passwords, prefix, hotkeys, Caps Lock / Numpad + / autocorrect / clock / previews switches, Requested By route, pins, recent, my-templates, journal, time saved |

Each layer only fills what the one above leaves blank: person beats bay beats team beats the built-in default. A brand new operator with an empty profile gets the team defaults and the bay's spots, and Watchlog works on day one.

## Must fix before a pilot

Ordered by how badly it breaks for the second operator.

### 1. Operator profiles (who is on this bay)
**What's Jakob-specific:** settings.ini holds Jakob's logins (;prd, ;jakob, ;jv), the SDS start-of-shift sign-in ([User] LoginTrigger) and his switches. Passwords in Credential Manager are stored as "Watchlog: <username>" per PC and Windows account, so they are shared by anyone using that account on that bay.
**How it breaks:** a teammate types ;jakob and signs in as Jakob. Start of shift signs SDS in as Jakob. If the teammate saves their own login, it overwrites the shared settings.ini on every bay through OneDrive.
**Fix:** a "Who's on?" pick at start of shift (Ctrl+Alt+L) and in the tray, remembered for the shift (cleared at end of shift or after 14 hours, like the bay). Each person gets a profile file (people\<name>.ini beside templates.txt), holding only their own logins, switches and hotkeys. Passwords saved as "Watchlog: <person>: <username>" so they never cross between people. A name is display only; nothing is sent anywhere. Jakob's current settings become his profile automatically.
**Open question:** do teammates share one Windows account like the bays do (see Questions).

### 2. Per-person taught routes: ;audit Requested By
**What's Jakob-specific:** the Requested By route is a list of clicks that ends on Jakob's own name in iTrak. It's stored per PC in itrak.ini.
**How it breaks:** anyone else running ;audit on that bay gets Jakob put in Requested By. That's a wrong record, which is worse than a missing one.
**Fix:** the route moves into the person's profile. If the operator has no route of their own, ;audit fills everything else and stops at Requested By with a tip ("Pick yourself in Requested By, or tray > iTrak > Teach my Requested By"). Never fall back to someone else's route.

### 3. Team settings file (team-settings.ini)
Already item 4 in the TEAM ROLLOUT plan; this audit fills in what goes in it. Today these are built-in defaults that fit Jakob's bay and site:
- **Browser:** Ctrl+Alt+L opens msedge.exe only (v3.23.0, Jakob's choice), and finds the Citrix and facial rec tabs only in Edge windows. Fix: [Team] Browser=edge|chrome, with the tab search looking in that browser. The Ctrl+Alt+G app key follows it.
- **Web addresses:** FaceUrl and CitrixUrl defaults are the OLG and GCGaming links. Fine for this site, but they belong in team settings, not the program.
- **Bally app paths:** C:\BallyTechnologies\...15_9 style paths with * already cope with upgrades. Move the default list to team settings.
- **End of shift close list:** includes Spotify.exe and explorer.exe. A teammate with other programs open loses them. Team default without Spotify; person can add.
- **SDS ResignMinutes (62), Break Minutes (60), Alert Grid pause/wait, iTrak waits:** site or network facts, so team values.
- **iTrak date formats** (AuditEndFormat, AuditTimeParts, AuditPitText "Pit #{n}"): depend on the Citrix server, same for everyone; team values.
- **Which features are on by default for a new operator** (see item 4).

### 4. Safer defaults for someone who isn't Jakob
These are on by default because Jakob wanted them. Each is stored per PC today (last used.ini or settings.ini), so whoever sits down inherits the last person's choice.
- **Caps Lock clears the Alert Grid** (on). Someone who uses Caps Lock to type capitals clears alerts by accident. New operator default: off, offered in the first-run walk-through.
- **Numpad + opens the call pad** (on). Takes away the + key, which people use when typing amounts or in Excel. Default off for new operators; Ctrl+Alt+N always works.
- **Autocorrect in every program** (on). Retypes words in emails and Teams too. Default: call pad and forms only; everywhere is opt-in.
- **Taskbar previews hidden and the taskbar clock** (on). Changes Windows for everyone at the bay. Default off; per person.
- **Code word prefix ;**, hotkeys: already settings, but they need to move to the person layer so one person's change doesn't change every bay.

### 5. Bay spots: teach once per bay, share where the screens match
**What's Jakob-specific:** the daily log field spots (full-entry logs, code words that fill the daily log), the audit spots and the incident report spots are taught on Jakob's bay only. Alert Grid and the new log button can already be shared (Clicks-<DPI> in the team folder); the others can't. Jakob decided Oct 30 not to share the daily log spots to Bay 2/3 because the monitors differ.
**How it breaks:** on an untaught bay, Ctrl+Alt+F, ;audit, Ctrl+Alt+Shift+N and every code word ending in >> do nothing useful until someone finds the right teach item in the tray.
**Fix:** keep spots per bay (right call), but:
- a **Bay setup checklist** (item 2 of the rollout plan): green/red for each taught spot on this bay, a Teach button beside each red one, one after another;
- spots measured from the inside of the iTrak window (like Alert Grid since v3.18.0) so the same bay keeps working when someone moves or resizes iTrak;
- code words that end in >> fall back to pasting just the wording when the bay isn't taught, with a one-line tip, instead of failing.

### 6. Window layout and start of shift
**What's Jakob-specific:** layout.ini is per PC, saved from how Jakob arranges his screens; SdsSpot and the Alert Grid spot come from it. Start of shift opens Jakob's list of programs.
**How it breaks:** a teammate who likes their windows elsewhere gets them moved back every start of shift and for 2 minutes after (SdsKeepInSpot). If a bay was never saved, nothing moves (fine).
**Fix:** a saved layout belongs to the bay by default (the Alert Grid has to be where the bay's spots are), with an optional person layout on top. [Layout] AfterStart becomes a person switch. The display-scale warning stays.

### 7. Shared files that should be personal
- **Shift Journal** (Documents\Shift Journal) and **call pad history**: one person's logs visible to the next. With profiles, the journal goes under the person's name; call pad is already wiped at end of shift.
- **Time saved** (per PC): mixes everyone on that bay into one tally, which matters for the manager pitch. Count per person (and keep a bay total).
- **Picker pins and recent** (pins shared on OneDrive, recent per PC): person layer.
- **my-templates.txt and autocorrect.txt**: today one file for everyone on the Windows account. Person layer; team autocorrect list stays beside templates.txt.

## Later (after the pilot starts)

### 8. Template wording that is really Jakob's habits
templates.txt is the team's wording and should stay one shared file, but some lines carry choices only Jakob made. Worth a supervisor pass before rollout, not a code change:
- `@pit` (2 and 3) and `@slots` (A-D, D = Delta Slots assumed). Correct for this casino as far as we know; just confirm.
- `@tables` list, `;mfill` machine list (NRT1-4, ATM1-5), `;badge` passes 17-01 to 17-09, `;medical` locations (Kitchen, Main Entrance), `;evict` reasons, camera numbers in `;drop`, `;man`, `;destroy`, `;account`.
- `;face` Result fixed to Rejected and Reference NA (Jakob's Nov 9 call); others may log accepted alerts.
- Interior/Exterior/Parking split Officer vs Supervisor (Jakob's Oct 30 choice).
- Full-entry logs (Ctrl+Alt+F): Jakob's list of "never changes" logs. Good starting set; let people add their own in my-templates.
- The template editor already lets a supervisor change all of this. Add a "Team wording review" checklist for the supervisor (one page).

### 9. Hotkey clashes per person
Ctrl+Alt+letters can clash with software a teammate uses (Ctrl+Alt+T, U, Y, G for Teams, Outlook, Spotify, Edge are Jakob's apps). Person layer handles it; the Customize screen already exists. Later: a clash check on first run.

### 10. Supervisor tools
Already in the rollout plan (items 3 and 5): "is everyone on the same version" status line per PC, operator guide, supervisor guide. Add: who has which features taught on which bay (no names, just bay + green/red).

### 11. One shared exe and update path
Self-update from the team folder exists. Later: code signing (Jakob's step with IT), and the team folder path set once in team-settings.ini so new PCs find it.

### Not a problem (checked)
- Window titles (iTrak, Daily Log Entry, Incident File, Audit, Alert Grid, SDS "Welcome") come from the shared software, so they match for everyone.
- SDS logged-in check reads "Welcome", not Jakob's name.
- Display scale: spots are stored with their DPI and Watchlog warns on a mismatch. Keep the rule "check Display scale matches across bays".
- Passwords never in files, never typed outside their program: stays as is, just keyed per person.

## Recommended order (folds in the TEAM ROLLOUT plan)

1. **v3.37.0 Profiles** (items 1, 2, 7): "Who's on?" at start of shift, people\<name>.ini, passwords per person, Requested By per person, journal/time saved/pins per person. Jakob's current setup becomes the "Jakob" profile with no re-teaching. This is the one that must exist before anyone else touches a bay.
2. **v3.38.0 Team settings + safe defaults** (items 3, 4): team-settings.ini (rollout item 4), new-operator defaults off, browser choice.
3. **v3.39.0 Setup screens** (items 5, 6; rollout items 1 and 2): Pick the team folder, bay checklist with Teach buttons, new-operator walk-through, untaught bays fall back to paste.
4. **Supervisor pass on wording** (item 8) and **guides** (rollout item 5): no program change.
5. **Pilot with one other operator** on one bay, then the rest. Version check for the supervisor (rollout item 3) before more than two people use it.
6. **v4.0**: signed exe, team version, after the manager's OK.

Each step is one version, built only on "build it", with all docs bumped together.

## Questions for Jakob
1. Do your teammates sign in to Windows with the same shared account you use on the bays, or each with their own? (If their own, profiles come for free from Windows and step 1 gets much smaller.)
2. Do the other operators work the same way as you (same iTrak screens, Edge, same logs), or are there people who mostly do something different, like a supervisor bay or someone who does audits all shift?
3. Who would pilot it with you first, and on which bay? That bay gets taught and checked first.
