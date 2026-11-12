# Watchlog - Team readiness audit

Written Nov 11, 2026, on v3.36.0. Revised the same day after Jakob's answer: **each operator signs in to the bays with their own Windows account.** Planning only: nothing in the program has changed. Nothing gets built until Jakob says "build it".

**Confirmed by Jakob (Nov 11): everyone has their own Windows account and moves between the 3 operator bays (he is usually Bay 1 but sometimes 2 or 3); same for all operators. The supervisor bay is different.** So each person's OneDrive settings follow them to any bay, but passwords, taught spots, layout and time saved are per account per PC. That means each operator teaches every bay they sit at, and each bay needs its spots shared once for everyone (item 2). The supervisor bay is treated as its own bay with its own spots and, if the supervisor works differently, its own team-settings section.

**Answers from Jakob (Nov 12):** the team SharePoint folder is NOT set up yet (he doesn't know how to start it; see the steps in the reply and in Pending changes). The supervisor bay works the same for Watchlog except it has ONE monitor, so it needs its own bay spots and layout. Pilot: coworker Michael (techy, has seen the program, would use it). Still open: anyone on Chrome? OK for the safe new-operator defaults?

Jakob (Nov 11): "Many features I have designed are designed around my specific workflow but there are quite a few things that would break when I introduce it to the team. It needs to be more general and adaptive."

## The short version

Most of Watchlog is already general: the wording can live in one shared templates.txt, the Alert Grid and new daily log spots can be shared through the team folder, hotkeys and the code word prefix can be changed, and passwords never leave the PC.

Watchlog keeps its files in two places, and both belong to the Windows account:

- **The person's OneDrive** (Documents\Watchlog): settings.ini, logins, my-templates, pins, autocorrect, incidents.txt, Shift Journal.
- **This PC, this Windows account** (%LOCALAPPDATA%\Watchlog): taught spots, window layout, time saved, call pad, recent picks. Passwords are in Credential Manager, also per account and PC.

Because every operator has their own Windows account, the personal side is already separate: nobody gets Jakob's logins, passwords, Requested By route, pins, journal or time saved. That part is safe.

The real problem is the other way round. **Everything a bay needs is taught per person.** When a teammate signs in to a bay for the first time, Watchlog has no settings, no spots, no layout and no shared templates. They would have to:

- point it at the team templates by hand;
- teach Alert Grid, new log, daily log fields, audit and incident spots on every bay they ever sit at;
- save the window layout on every bay;
- set up start of shift, SDS sign-in and the browser.

On top of that they get Jakob's defaults (Edge only, Caps Lock clears alerts, Numpad + opens the call pad, autocorrect everywhere, clock on, previews hidden), which only make sense for Jakob.

The fix is three layers with a clear owner each:

| Layer | Where | Who sets it | What goes in it |
|---|---|---|---|
| **Team** | team-settings.ini beside the shared templates.txt | Supervisor, once | Site things: browser, web links, Bally app paths, start of shift programs, SDS sign-in minutes, break minutes, iTrak formats and waits, which features are on for a new operator |
| **Bay** | Team folder, one section per bay (by PC name and screen scale) | Taught once per bay, by anyone | Spots that depend on the bay's screens: Alert Grid, iTrak new log, daily log fields, audit and incident fields, window layout, clock monitor |
| **Person** | The operator's own settings.ini and %LOCALAPPDATA% (as now) | Each operator | Logins and passwords, prefix, hotkeys, switches, Requested By route, pins, recent, my-templates, journal, time saved, and any spot they teach for themselves |

Person beats bay beats team beats the built-in default. A brand new operator signs in, Watchlog finds the team folder, picks up the bay's spots and the team defaults, and works on day one.

## Everyone works differently (Jakob, Nov 12)
Jakob: operators arrange their windows differently, use different programs, tools and shortcuts, and some fill out logs and incidents in entirely different ways. So Watchlog can't assume one workflow. Changes to the plan:

1. **Everything is a switch, and a new operator starts with a small core.** Core on for everyone: shared wording (code words and forms), the finder, Alert Grid clear (if they use it), time saved. Opt-in modules, each with its own on/off in the first-run walk-through and tray: start of shift (and its program list), window layout, full-entry daily logs, code words that fill the whole daily log (>>), ;audit, incident reports, call pad, autocorrect everywhere, taskbar clock, Caps Lock clears alerts, Numpad +, SDS keep-in-spot. A module that is off never moves a window, grabs a key or types anything.
2. **Window layout is personal, never forced by the bay.** Item 6 changes: no bay layout. Each person may save their own layout per bay, or none. Spots must not depend on where windows sit.
3. **Shared bay spots only work if they are measured from inside the window.** Alert Grid and the new log button already are (since v3.18.0). The daily log field, audit and incident spots are not all, so bay sharing (item 2) has a prerequisite: measure them from inside the iTrak windows, or two people with different window sizes break each other. Until then bay sharing stays off for those spots.
4. **Start of shift and end of shift lists are personal** (team gives a default list; a person can change or turn them off). Today's built-in lists come from Jakob's programs.
5. **Different methods of filling logs and incidents:** shared wording stays optional. People can use only the parts that fit: their own my-templates, their own full-entry logs, their own incident wording file. Nothing in the team file is forced on anyone.
6. **Question for later:** which of these modules would Michael actually use? His answer decides the default set for new operators.

## Must fix before a pilot

Ordered by how badly it breaks for the second operator.

### 1. Finding the team folder on first run
**Today:** a new account gets a blank settings.ini with [Templates] Shared= empty, so Watchlog uses a local templates.txt (or none), no shared spots, no update check. Team sharing only starts once someone types the SharePoint path into settings.
**How it breaks:** a teammate who skips that step gets old wording, no spots and no updates, and nothing tells them.
**Fix:** first run (and tray > Advanced) shows "Pick the team folder" (rollout item 1). It sets shared templates, shared spots, team settings and the update check together, then shows a green/red checklist. Better still, the exe looks for a known SharePoint folder name in the person's OneDrive and offers it, so most people just click Yes.

### 2. Bay spots shared per bay, not per person
**Today:** daily log field spots, audit spots and incident spots are saved only in the teacher's own %LOCALAPPDATA%. Alert Grid and new log can be shared, but only keyed by screen scale (Clicks-<DPI>), not by bay. Jakob decided Oct 30 not to share the daily log spots because Bay 2/3 monitors differ.
**How it breaks:** every operator re-teaches every spot on every bay. With 3 bays plus the supervisor bay, that is a dozen teach sessions each. Untaught, Ctrl+Alt+F, ;audit, Ctrl+Alt+Shift+N and every code word ending in >> fail. Sharing by scale alone could hand Bay 2 the spots from Bay 1 at the same scale but a different monitor.
**Fix:**
- shared spots saved per bay: one section per PC name plus scale (e.g. [BAY2-PC @ 100%]) in a shared bays.ini in the team folder;
- teaching on a bay offers "Share with everyone on this bay"; the first person to teach a bay does it for all;
- lookup order: my own teach, then this bay's shared teach, then nothing (never another bay's);
- spots measured from inside the iTrak window (as Alert Grid is since v3.18.0) so they survive someone moving or resizing iTrak;
- a **bay checklist** (rollout item 2): green/red for each spot on this bay, a Teach button beside each red one;
- code words ending in >> paste just the wording on an untaught bay, with a one-line tip, instead of failing.

### 3. ;audit Requested By
**Today:** the Requested By route is a list of clicks that ends on the teacher's own name, stored per account and PC.
**How it breaks:** nothing crosses between people (own accounts), but every operator has to teach it on every bay, and it must never be shared.
**Fix:** stays personal and is never put in the bay file. With no route taught, ;audit fills everything else and stops at Requested By with a tip ("Pick yourself, or tray > iTrak > Teach my Requested By"). Try measuring the route from the Audit window so one teach works on every bay with the same scale.

### 4. Team settings file (team-settings.ini)
Rollout item 4. Today these are built-in defaults that fit Jakob's bay and site:
- **Browser:** Ctrl+Alt+L opens msedge.exe only (v3.23.0, Jakob's choice) and looks for the Citrix and facial rec tabs only in Edge. Fix: Browser=edge|chrome, and the tab search looks in that browser. The Ctrl+Alt+G key follows it.
- **Web links:** the FaceUrl and CitrixUrl defaults are the OLG and GCGaming links. Right for this site, but they belong in team settings.
- **Start of shift programs and Bally app paths:** the default list (Alert Grid, SDS, CMP with * paths). Team default; a person can change it.
- **End of shift close list:** includes Spotify.exe and explorer.exe. Team default without Spotify; a person can add.
- **SDS ResignMinutes (62), Break Minutes (60), Alert Grid and iTrak waits:** site and network facts, so team values.
- **iTrak date formats** (AuditEndFormat, AuditTimeParts, AuditPitText "Pit #{n}"): set by the Citrix server, same for everyone.
- **Features on for a new operator** (next item).

### 5. Safer defaults for someone who isn't Jakob
These are on by default because Jakob wanted them. Each new account gets them without being asked.
- **Caps Lock clears the Alert Grid** (on). Someone who types capitals with Caps Lock clears alerts by accident. New operator default off, offered in the first-run walk-through.
- **Numpad + opens the call pad** (on). Takes away the + key when typing amounts. Default off; Ctrl+Alt+N always works.
- **Autocorrect in every program** (on). Retypes words in emails and Teams. Default: call pad and forms only.
- **Taskbar previews hidden and the taskbar clock** (on). Changes Windows itself. Default off.
- The supervisor can flip any of these in team-settings.ini; each person's own switch wins.

### 6. Window layout and start of shift
**Today:** layout.ini is per account and PC, saved from how Jakob arranges his screens. SdsSpot and the Alert Grid spot come from it, and SdsKeepInSpot moves SDS back for 2 minutes after start of shift.
**How it breaks:** each person saves a layout on each bay. If someone's layout puts the Alert Grid somewhere other than where the bay's shared spots expect it, Alert Grid clearing still works (it follows the window), but the SDS guard and start of shift can fight their arrangement.
**Fix:** the bay's layout is shared like its spots (item 2) and used when the person hasn't saved one. [Layout] AfterStart stays a person switch. Keep the display-scale warning.

### 7. New-operator walk-through
Rollout item 2, now more important: name stays out of it (Windows already knows who they are). Steps: team folder, logins (passwords asked masked, saved in their Credential Manager), the switches from item 5, then the bay checklist. Each step skippable, all of it re-runnable from the tray.

## Later (after the pilot starts)

### 8. Template wording that is really Jakob's habits
templates.txt should stay one shared file, but some lines carry choices only Jakob made. A supervisor pass before rollout, not a code change:
- `@pit` (2 and 3) and `@slots` (A-D, D = Delta Slots assumed): confirm.
- `@tables`, `;mfill` machines (NRT1-4, ATM1-5), `;badge` passes 17-01 to 17-09, `;medical` locations, `;evict` reasons, camera numbers in `;drop`, `;man`, `;destroy`, `;account`.
- `;face` Result fixed to Rejected and Reference NA (Jakob's Nov 9 call); others may log accepted alerts.
- Interior/Exterior/Parking split Officer vs Supervisor (Jakob's Oct 30 choice).
- Full-entry logs (Ctrl+Alt+F): Jakob's "never changes" list. Good start; people can add their own in my-templates.
- **Shared files that are personal today:** picker pins, autocorrect.txt and incidents.txt sit in each person's own OneDrive folder. Pins can stay personal; a team autocorrect list and the incident report wording should sit beside the shared templates.txt, with each person's file adding to it.

### 9. Hotkey clashes per person
Ctrl+Alt+T, U, Y, G open Jakob's apps (Teams, Outlook, Spotify, Edge). Already per person and changeable in Customize. Later: a clash check on first run.

### 10. Supervisor tools
Rollout items 3 and 5: "is everyone on the same version" status line per PC, operator guide, supervisor guide. Add: which bays have which spots shared (bay + green/red, no names).

### 11. One shared exe and update path
Self-update from the team folder exists. Each operator installs the exe once in their own account (%LOCALAPPDATA%\Programs). Later: code signing (Jakob's step with IT).

### Not a problem (checked)
- Logins, passwords, journal, time saved, pins, call pad: already separate per person because of separate Windows accounts.
- Window titles (iTrak, Daily Log Entry, Incident File, Audit, Alert Grid, SDS "Welcome") come from the shared software.
- SDS logged-in check reads "Welcome", not Jakob's name.
- Display scale: spots carry their DPI and Watchlog warns on a mismatch.

## Recommended order (folds in the TEAM ROLLOUT plan)

1. **v3.37.0 Team folder + team settings + safe defaults** (items 1, 4, 5): first-run "Pick the team folder", team-settings.ini, new-operator defaults off, browser choice. Jakob's own settings keep winning, so nothing changes for him.
2. **v3.38.0 Bay sharing** (items 2, 3, 6): bays.ini per PC name, "share with everyone on this bay", bay checklist with Teach buttons, untaught bays paste instead of fail, Requested By stays personal with a clean stop.
3. **v3.39.0 New-operator walk-through** (item 7) and the supervisor version check (rollout item 3).
4. **Supervisor wording pass and guides** (item 8, rollout item 5): no program change.
5. **Pilot with one other operator** on one bay Jakob has already shared, then the rest.
6. **v4.0**: signed exe, team version, after the manager's OK.

Each step is one version, built only on "build it", with all docs bumped together.

## Questions for Jakob
1. ~~Shared Windows account?~~ Answered Nov 11: each operator has their own Windows account.
2. Besides the supervisor bay, does anyone work differently from you (someone who does audits all shift, someone who uses Chrome)? And what does the supervisor bay do differently?
3. Who would pilot it with you first, and on which bay?
4. Is the team SharePoint folder already set up, and does it sync to everyone's OneDrive?
