# Watchlog: information for IT

Oct 31, 2026 · Jakob

Watchlog is a small Windows program I built that types our standard surveillance log entries. I type a short code like `;interior` and the full wording appears. It's written in AutoHotkey v2 and comes as one Watchlog.exe with the AutoHotkey runtime built in, so nothing else is installed. The same program is also available as one plain text script for anyone to read. I'm on version 3.29.2 and have been using it on my own shifts since October 13. I'm asking for approval so other operators and supervisors can use it if they choose to, on our 3 operator bays and the supervisor bay.

## What it does and doesn't do

- It types and pastes what the operator would have typed. The operator still saves the entry. It doesn't change iTrak, SDS or any other system.
- It clears the Alert Grid list when the operator presses Caps Lock or Ctrl+Alt+A. It clicks the same steps as by hand (Ctrl+A, right-click, Acknowledge as received, Submit, OK) using screen positions taught once per PC. The Acknowledge box is filled in by Alert Grid with the operator's own login. Watchlog never reads or types into it.
- It can open a new iTrak daily log and fill in Location, Topic, Reference and Synopsis by clicking spots taught once per PC. It never clicks Save: the operator reads the entry and saves it.
- SDS signs the operator out after an hour. Watchlog types the saved SDS login again about 62 minutes after an SDS login the operator did, only if SDS is on its login screen, and then puts the operator's previous window back. It retries once a minute up to 6 times and can be turned off in Settings > Logins.
- It doesn't connect to the internet or send anything anywhere. Its files only travel through OneDrive and SharePoint under our normal Microsoft 365 permissions.
- It doesn't record what anyone types. It only watches for its own codes. It reads the clipboard only for a form box that takes a copy, and keeps a copied facial rec alert number or match % in memory for 2 minutes at most.

## Passwords and saved information

- Passwords are kept in Windows Credential Manager, on that PC, for that Windows user. They are never in a file, never synced and never shown.
- A password is typed only when that login's code is typed, when the operator answers Yes to "Log in to SDS?" or to the start of shift sign-in, or for the SDS sign-back-in above. Each time it first checks that the window in front is one that login is locked to. Logins with no lock are never typed automatically.
- The shift journal keeps the time, template name and text of each entry for 30 days, then deletes it. It can be set to counts only, or off.
- On the PC only: the activity log (never passwords or log text), Alert Grid and iTrak click positions, window positions, time saved counts, break minutes used this shift and a few last-used box values. Once a day it backs up the operator's templates, settings and click positions (never passwords) to `%LOCALAPPDATA%\Watchlog\Backups` and keeps 14 days. The registry holds the last login time and the uninstall entry.
- Tray menu > Security and status shows all of this for the PC in front of you, with a Copy report button.

## Updates and shared files

The approved wording is one file in a SharePoint folder that the supervisors look after. Each PC shows a short check code, so it's easy to confirm every bay matches. A new Watchlog.exe can go in the same folder. Each PC asks "Update now?", checks the file, keeps a backup and refuses a broken one. The tray menu can put the previous version back. That means whoever can edit the folder controls what the bays run, so I'd ask that edit access be limited to the supervisors and me. A user can also point their own PC at a folder of their own for testing, which only affects that PC.

## What I'm asking IT to approve

1. Watchlog.exe installed per user, with no admin rights, and starting with Windows. It isn't signed, so SmartScreen may warn once.
2. Passwords in Windows Credential Manager, typed into the programs they're locked to.
3. Watchlog clicking through the Alert Grid acknowledge steps, and opening and filling in a new iTrak daily log, for the operator.
4. The automatic SDS sign-back-in (can be off).
5. The 30 day shift journal (or counts only).
6. Edit access to the SharePoint template folder.

## Setting up and removing it

Setup per PC: run Watchlog.exe and say yes to installing (it goes in `%LOCALAPPDATA%\Programs\Watchlog`, with a Start menu entry and a Startup shortcut), go through the welcome window, then teach the Alert Grid clicks once with Ctrl+Alt+Shift+A and the iTrak daily log spots with Ctrl+Alt+Shift+I and Ctrl+Alt+Shift+F. Settings live in `Documents\Watchlog`, so OneDrive needs to start with Windows.

To remove it, use Settings > Apps > Watchlog. It offers to delete the saved passwords and leaves the operator's settings and journal in Documents. `%LOCALAPPDATA%\Watchlog` and `HKCU\Software\Watchlog` can then be deleted.

I'm happy to show it working to anyone who'd like to see it. The full overview has more detail.
