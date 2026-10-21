=======================================================================
  WATCHLOG  v3.3.1  -  README
  Shortcuts for surveillance log entries, logins and shift start/end
=======================================================================

Watchlog (called Log Templates before v3.0.1) runs quietly in the
background: its icon, a white log page with an eye on a teal square,
sits in the tray near the clock. You type a short trigger like ;jack
and it turns into a finished log entry. It also types logins, opens your work apps at the
start of a shift, closes them at the end, and keeps quick notes.

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
 16. Setting it up on another PC, or for a new operator
 17. Troubleshooting
 18. Rules worth keeping


-----------------------------------------------------------------------
 1. FILES
-----------------------------------------------------------------------
These sit in the program folder (Documents\AutoHotkey on OneDrive):

  Watchlog.ahk        The program. You shouldn't need to edit it.
  Log Templates.ahk   Only starts Watchlog, so old shortcuts still
                      work (see MOVING FROM LOG TEMPLATES below).
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

Elsewhere:
  LaunchWork.bat      Opens the work websites at the start of a shift
                      (Documents, or the program folder).
  Quick Notes.md      Your quick notes (Documents). Made automatically.
  Shift Journal       A folder in Documents with every log you insert,
                      one file per shift. Made automatically.
  activity.log        What the tool did and when, on this PC only
                      (%LOCALAPPDATA%\Watchlog). See section 15.

MOVING FROM LOG TEMPLATES
  Watchlog was called Log Templates before v3.0.1. Put Watchlog.ahk,
  Watchlog.ico and the new Log Templates.ahk in the folder (replacing
  the old Log Templates.ahk), then double-click Watchlog.ahk. The first
  time it runs on each PC it moves everything over by itself:
    - closes the old Log Templates if it's still running
    - saved passwords: each one moves to the new name ("Watchlog:
      <username>") the first time it's used, so nobody types them again
    - %LOCALAPPDATA%\Log Templates becomes %LOCALAPPDATA%\Watchlog
    - the Startup shortcut now starts Watchlog
  settings.ini, templates.txt, my-templates.txt, Quick Notes.md and the
  Shift Journal keep their names. Tray menu > Activity log lists what
  was moved. The small Log Templates.ahk only starts Watchlog, so a PC
  whose shortcut still points at it keeps working; delete it once every
  PC has run Watchlog.

Save templates.txt, my-templates.txt or settings.ini (or have the team
file change on SharePoint) and the script reloads by itself within a
couple of seconds. No need to press anything.


-----------------------------------------------------------------------
 2. HOTKEYS  (hold Ctrl+Alt and press the key)
-----------------------------------------------------------------------
  Ctrl+Alt+Space    Find a template: type part of its name or any word
                    in it, then Enter. See section 3.
  Ctrl+Alt+H        Cheat sheet: every template, login, app and hotkey
                    on this PC.

  Ctrl+Alt+L        Start of shift. Opens the websites and the Bally
                    apps (AlertGrid, SDS, CMP), skips any already open,
                    then switches Chrome to the Citrix tab. See section 8.
  Ctrl+Alt+Shift+L  End of shift. Asks first (default No), logs you out
                    of SDS properly, then closes all work apps. See
                    section 9.
  Ctrl+Alt+K        Log out of SDS properly (the lock button, then Yes),
                    so the account doesn't get locked. SDS stays open at
                    its login screen.
  Ctrl+Alt+J        Shift journal: how many of each log you've done this
                    shift, with a Copy summary button. See section 10.

  Ctrl+Alt+S        SDS: switch to it, minimise it if it's already in
                    front, or open it if it isn't running.
  Ctrl+Alt+C        CMP: same as above.
  Ctrl+Alt+T        Teams         (same: switch, minimise or open)
  Ctrl+Alt+U        Outlook
  Ctrl+Alt+Y        Spotify
  Ctrl+Alt+G        Chrome
                    (SDS and CMP come from [App1]/[App2] in settings.ini.
                    Teams, Outlook, Spotify and Chrome are built in. You
                    can change their letters or add more, see section 14.)

  Ctrl+Alt+Q        Quick note. Type a note starting with a tag like
                    #todo, #incident or #idea. It's saved with the date
                    and time in Documents\Quick Notes.md.
  Ctrl+Alt+O        Open all your quick notes in Notepad.
                    (Ctrl+Alt+T used to find notes by tag. It was
                    removed in v2.7 and T is now Teams.)

  Ctrl+Alt+E        Edit templates.txt in Notepad (or my-templates.txt,
                    when the team's shared file is in use).
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
                      it's already filled in
      list boxes      pick from the list, or type over it, depending
                      on the template. Typing just the number picks the
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
  ;open         Table opened: table
  ;auto         Table closed and auto-close started: table
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
  ;maint        Machine maintenance
  ;countstep    Soft count step (time now, opens on the next step)
  ;counttables  Soft count: table totals
  ;countslots   Soft count: slots total
  ;countpull    Soft count: emergency pull
  ;badge        Visitor badge 17-01 to 17-09: who, reason, location
  ;account      Account review: account # (the # stays if left empty)
  ;intox        Refused one patron entry due to signs of intox:
                signs observed (in brackets)

Quick (paste straight away):
  ;interior     Interior door check
  ;exterior     Exterior door check
  ;parking      Parking lot patrol
  ;noid         Refused one patron entry due to no ID
  ;insuf        Refused one patron entry due to insufficient ID
  ;expired      Refused one patron entry due to expired ID
  ;selfex       Self-exclusion: patron taken into PlaySmart
  ;inventory    Inventory transfer, Delta Podium to Main Bank
  ;drop         Table drop
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

The window lock ("only works in a window whose title has...", like
iTrak) keeps a login from firing anywhere else. Logins without one work
in any program, so the ; at the start is their only protection. The
Settings window won't save a shortcut without a ; unless it has a
window lock.

Login shortcuts never fire in the template finder or the Settings
window, so typing one there can't type a password. Each time a login is
used, the activity log notes the username and the program it went into
(never the password). See section 15.

If an old settings.ini still has a Password= line, the script moves it
into Credential Manager, deletes it from the file and tells you.


-----------------------------------------------------------------------
 7. HOURLY LOGIN REMINDER
-----------------------------------------------------------------------
For an app that signs you out every hour. In tray menu > Settings, edit
that login and put 55 in "remind me to log in again after this many
minutes". (In settings.ini it's a Remind=55 line under that login.)

Each time you use that login, a 55-minute countdown starts. When it runs
out you get a short beep and a small pop-up in the bottom-right corner
saying it's time to log in again, with the trigger to use. It doesn't
take the keyboard away from the window you're typing in, and it only
beeps once, so it's easy to miss if you're away from the screen. Press
Esc (from any window) or click OK to close it, or just log in again:
using the login closes the pop-up and restarts the countdown.

The countdown survives a reload (the last login time is kept on the PC),
so saving templates.txt doesn't reset it.


-----------------------------------------------------------------------
 8. START OF SHIFT  (Ctrl+Alt+L)
-----------------------------------------------------------------------
What happens, in order (about 5 seconds):
  1. A "Opening work apps..." message shows in the middle of the screen.
  2. LaunchWork.bat runs in the background and opens the websites
     (if Chrome or Edge is already open, it asks first whether to open
     them again; No is the default, so you don't get every tab twice):
     facial rec (OLG iTrak) in Edge, then the Citrix Receiver page,
     scheduling, Names & Photos, GIO, the training folder and Oracle
     learning in Chrome.
     Chrome opens them in the profile signed in to ChromeAccount from
     settings.ini, whichever profile that is on this PC.
  3. The programs in [StartOfShift] open one second apart (AlertGrid,
     SDS, CMP). Any it can see are already open are skipped, so pressing
     it twice normally won't give you two copies. (It spots them by
     window title, so an app still starting up can be missed.)
  4. It waits until those programs have their windows up (LaunchWait
     seconds at most, 5 by default), then switches Chrome to the
     Citrix Receiver tab, so you can launch iTrak from there.
  5. If anything couldn't be found, a message lists it.

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
     iTrak (Citrix), Spotify, Chrome, Edge, and File Explorer windows.
  4. Waits 5 seconds. If anything is still open, it lists it and offers
     to force it closed (default No; unsaved work in it would be lost).

File Explorer is special: only its folder windows are closed. It's
never force-closed, because the same program runs the taskbar.


-----------------------------------------------------------------------
 10. SHIFT JOURNAL  (Ctrl+Alt+J)
-----------------------------------------------------------------------
Every log you insert, quick or form, is also saved with the time it
went in. Logins and passwords are never saved.

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
  Watchlog v3.3.1 (date)        Which version is running, whether
                                it's up to date, the program check
                                code, and where the templates come from
  Find a template               Same as Ctrl+Alt+Space
  Cheat sheet                   Same as Ctrl+Alt+H
  Shift journal                 Same as Ctrl+Alt+J
  Time saved                    How much typing Watchlog has saved
                                (see TIME SAVED in section 10)
  Settings (logins, templates, journal)   Section 14
  Security and status           What's kept where, checked live (15)
  Activity log                  Opens the activity log (section 15)
  Make a copy to share          A clean copy for a new operator (16)
  Edit my templates             Opens my-templates.txt (makes it the
                                first time)
  Edit templates                Opens templates.txt ("Edit team
                                templates" when the shared file is set)
  Edit settings file (advanced) Opens settings.ini in Notepad
  Open script folder            Opens the program folder
  End of shift (close apps)     Same as Ctrl+Alt+Shift+L

The tray menu is the backup if another program ever grabs a Ctrl+Alt
hotkey. "Change a login password" moved into Settings in v3.0.

WHICH VERSION AM I RUNNING?  AM I UP TO DATE?
  Hover over the icon, or look at the top of the tray menu. Every time
  the script loads it also shows "Watchlog v3.3.1 running" in the
  bottom-right corner for a few seconds.

  The templates file has a line near the top, "# Program version:
  3.3.1", saying which version everyone should be on. With a team
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
Ctrl+Alt+E (or tray menu > Edit templates) opens it. Save and the
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
  {Bay: last}                  remembers what you typed last time
  {Step: next | A | B | C}     opens on the step after last time's
  {Machine: blank=AXXXX}       what to leave if the box is empty
                               (otherwise it leaves XX)
  {Asset #: prefix=# | blank=} adds # in front only if you fill it in;
                               blank= leaves nothing if empty
  {Machine: caps}              capitals in machine numbers
                               (b1410 becomes B1410)
  {Table: @tables}             uses the @tables list (see below)
  {repeat}                     at the end of a form: adds an "Add
                               another" button (several in one log,
                               one per line)
  Combine options with |, e.g. {Employee #: clip | blank=XXXXXXX}
  The same blank used twice in one template is one box that fills both.

Shared lists: a line starting with @ near the top of the file is a list
any blank can use. The table list is written once:
  @tables = UT201 | FB202 | UT203 | RO204 | BJ205 | BJ206
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
  - Ctrl+Alt+E opens your my-templates.txt instead, so nobody edits the
    team file by accident. Tray menu > Edit team templates opens it, and
    SharePoint's permissions decide whether you can save it.
  Tip: right-click the synced folder > "Always keep on this device".

YOUR OWN TEMPLATES (my-templates.txt)
  Tray menu > Edit my templates makes my-templates.txt in the program
  folder the first time. Same format as templates.txt. These are added
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
a PC.
  Logins          add, edit, remove, change password (section 6)
  Templates       the team's shared file: Browse / Clear (section 13)
  Shift journal   what's saved, and when old shift files are deleted
                  (section 10)
  Windows         "Start Watchlog when I sign in to Windows" adds
                  or removes a shortcut in your Startup folder
Save writes settings.ini and reloads. Cancel changes nothing.

Everything else is in settings.ini (tray menu > Edit settings file).
Save it and it reloads itself.

[Templates]
  Shared=    the team's shared templates file. Blank = templates.txt
             in the program folder.

[Login1] ... [Login9]
  Trigger=   what you type, starting with ;
  User=      the username it types
  Window=    optional: only works while this program is in front
  Remind=    optional: minutes until the login reminder pops up
  (No password here. See section 6.)

[Paths]
  LaunchWork=     full path to LaunchWork.bat (if it isn't there, a
                  LaunchWork.bat in the program folder is used)
  LaunchWait=     the most seconds Ctrl+Alt+L waits for the programs'
                  windows before switching to Chrome (default 5)
  CitrixTab=      part of the Citrix Receiver tab's title, so Ctrl+Alt+L
                  can switch Chrome to it (default: Citrix; blank = off)
  ChromeAccount=  optional: the Google account the websites open in.
                  Blank = Chrome's last used profile.

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
  Built in: T Teams, U Outlook, Y Spotify, G Chrome. To give one a
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
checked live, with a Copy report button (to paste into an email to IT
or a supervisor). It never shows a password.

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
  Activity log     See below. On that PC only.
  Registry         The time of the last login per username, for the
                   log-in-again reminder (HKCU\Software\Watchlog).

WHAT IT NEVER DOES
  - It makes no internet connections and sends nothing anywhere itself.
    Files reach other PCs only through your own OneDrive and SharePoint
    sync, under your Microsoft 365 permissions. (Ctrl+Alt+L opens your
    work websites in the browser, the same as clicking their links.)
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
YOUR OWN OTHER BAY PCs
  1. AutoHotkey v2 must be installed on that PC.
  2. Make sure OneDrive has synced the AutoHotkey folder (and
     LaunchWork.bat).
  3. Double-click Watchlog.ahk. Then tray menu > Settings: tick
     "Start Watchlog when I sign in to Windows" and Save. (The
     Startup folder doesn't sync, so each PC needs this once.)
  4. If you use ChromeAccount, sign in to it in Chrome once on that PC.
  5. The first time you use each login there, type its password once.

A NEW OPERATOR
  1. Tray menu > Make a copy to share. Pick a folder (a SharePoint or
     Teams folder works). It makes a "Watchlog v3.3.1" folder with
     only: the program, the icon, the templates (the team's, if that's in use),
     QUICK START.txt, README.txt, settings.example.ini and
     LaunchWork.bat. It never copies your settings.ini, my-templates.txt,
     shift journal, notes, activity log or passwords, and it lists what
     it left out. The activity log records the copy.
  2. The new operator copies that folder to their own Documents and
     double-clicks Watchlog.ahk. The Welcome window asks only for
     their logins and where the team templates are. QUICK START.txt
     walks them through it.


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

Ctrl+Alt+L says the Chrome profile wasn't found
  Sign in to the ChromeAccount in Chrome on that PC once.

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
    menu > Make a copy to share.
  - Never put passwords in templates.txt, settings.ini or a note.
  - Before sharing the tool with the team, get the surveillance
    manager's and IT's OK.
