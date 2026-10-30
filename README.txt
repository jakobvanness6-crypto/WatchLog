=======================================================================
  WATCHLOG  v3.20.2  -  README
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
  LaunchWork.bat      Opens the work websites at the start of a shift
                      (Documents, or the program folder).
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
                    SDS, CMP) first, skips any already open, then the
                    websites, then brings the Citrix tab to the front.
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
  Ctrl+Alt+G        Chrome
                    (SDS and CMP come from [App1]/[App2] in settings.ini.
                    Teams, Outlook, Spotify and Chrome are built in. You
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
                    Four come ready-made: Break, Table Drop, End (end of shift) and
                    Card Destruction. A line that ends with | end also clicks End Time's
                    Now button once the log is filled (the End log does); {Bay} in a
                    synopsis is the bay entered at the start of shift (v3.20.2).
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
  4. LaunchWork.bat runs in the background and opens the websites
     (if Chrome or Edge is already open, it asks first whether to open
     them again; No is the default, so you don't get every tab twice):
     facial rec (OLG iTrak) in Edge, then the Citrix Receiver page,
     scheduling, Names & Photos, GIO, the training folder and Oracle
     learning in Chrome.
     Chrome opens them in the profile signed in to ChromeAccount from
     settings.ini, whichever profile that is on this PC.
  5. It switches Chrome to the Citrix Receiver tab, so you can launch
     iTrak from there, and keeps Chrome on top for 25 seconds if an
     app jumps to the front.
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

WATCHLOG HOME  (click the icon, or Ctrl+Alt+M)
  Big buttons in three groups: Logs (call pad, find a template, cheat
  sheet, journal, quick notes, time saved, shift count, dashboard), Logins
  (one button per saved login) and Set up (template editor, settings,
  tutorial, security and status, about, save window layout). The Shift
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
                  waits for the programs (LaunchWait), LaunchWork.bat,
                  the Google account (ChromeAccount), and what end of
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
  LaunchWork=     full path to LaunchWork.bat (if it isn't there, a
                  LaunchWork.bat in the program folder is used)
  LaunchWait=     the most seconds Ctrl+Alt+L waits for the programs'
                  windows before opening the websites (default 20, never less)
  CitrixTab=      words from the Citrix Receiver tab's title, split with |,
                  so Ctrl+Alt+L can switch Chrome to it. A tab still opening
                  is named after its address, so apps.gcgaming.com is
                  always tried too (default: Citrix|apps.gcgaming.com;
                  blank = off)
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
    two Chrome windows go back to the first and second spots saved.
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
  2. Make sure OneDrive has synced the AutoHotkey folder (and
     LaunchWork.bat).
  3. Double-click Watchlog.ahk. Then tray menu > Settings: tick
     "Start Watchlog when I sign in to Windows" and Save. (The
     Startup folder doesn't sync, so each PC needs this once.)
  4. If you use ChromeAccount, sign in to it in Chrome once on that PC.
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
    menu > Advanced > Make a copy to share.
  - Never put passwords in templates.txt, settings.ini or a note.
  - Before sharing the tool with the team, get the surveillance
    manager's and IT's OK.
