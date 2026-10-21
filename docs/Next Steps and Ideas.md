# Watchlog (formerly Log Templates): Next Steps and Ideas

Written 2026-10-14 against v2.1 (`Log Templates.ahk`, `templates.txt`, `settings.example.ini`, `LaunchWork.bat`).
Line numbers refer to v2.1 of `Log Templates.ahk`. **Items 1–4 were built in v2.2 (Oct 14).**

---

## Part 1: Improvements worth making now (ranked by value)

### 1. Make the logins safe to fire by accident
**What's there now.** Logins are instant hotstrings (`:*C:`, line 64) that type the username, Tab, the password, then **Enter** (lines 69-74) into whatever window has focus. They fire in any app.

**The risk.** `prd` has no `;` in front of it, so typing "prd" as a word in a Teams chat, an email, or an iTrak narrative sends `prd-jvanness`, Tab, your password, Enter. In a chat, Enter posts it. Every other trigger got a `;` for exactly this reason; this one slipped through.

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
