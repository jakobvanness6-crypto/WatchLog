# Watchlog v3.10.1 - what to try on the work PC

Nothing from v3.10.0 or v3.10.1 has been tried on a real bay yet (only under Wine). Tick each box, and write down anything odd with what you pressed and what you saw.

Install: unzip Watchlog v3.10.1.zip and run the installer as before. The tray tooltip and the top tray item should say v3.10.1.

## 1. Home window
- [ ] **Left-click the tray icon once.** The Watchlog home window opens with big buttons in four groups: Logs, Shift, Logins, Set up.
- [ ] **Press Ctrl+Alt+M.** Same window. (Ctrl+Alt+H is still the cheat sheet.)
- [ ] Click **Find a template** from the home window while Notepad or iTrak is in front. The window closes and the finder opens, and anything it types goes into the window you were in before.
- [ ] Check there is one button per saved login. Click one that is locked to a program (SDS, CMP). That program comes to the front. Click one that isn't locked. It should ask "Type the ... login into this window?"
- [ ] The strip along the bottom shows version, templates/wording version, Alert Grid taught or not, and this shift's time saved. The Caps guard and pause ticks work.

## 2. Tray menu and icons
- [ ] **Right-click the tray icon.** Items have small pictures. **Look for black squares or empty gaps instead of pictures** (the pictures come from Windows icon fonts, so this is the most likely thing to look wrong). Same check on the home window buttons.
- [ ] Sub-menus open: **Alert Grid** (clear all, teach), **Windows** (save layout, put back, Caps Lock guard tick), **Advanced** (Security, Activity log, make a copy to share, Edit in Notepad, Open folder, update folder, Pause, Reload).
- [ ] The normal AutoHotkey items (Open, Help, Window Spy and so on) are gone, and Exit Watchlog is at the bottom.

## 3. Settings in tabs
- [ ] Tray > Settings opens with tabs: Logins, Templates, Start / end of shift, Alert Grid, Updates, General.
- [ ] **Text is readable on every tab** (no black boxes or missing labels).
- [ ] Change one harmless thing (for example the beep tick), Save. Watchlog reloads and the change stuck. Open settings.ini: only the changed line was added.
- [ ] Cancel changes nothing.

## 4. Template editor (Ctrl+Alt+E)
- [ ] Ctrl+Alt+E opens the editor (not Notepad). Pick the file at the top. Search finds a template, and picking one shows its shortcut, name, section and wording.
- [ ] "How it will look" shows the finished log. Break something on purpose (delete a closing }) and it shows red. Fix it again.
- [ ] **Change one box** (double-click it), and **Add a box** at the cursor. Both work and the preview updates.
- [ ] **Make a test template** with New (for example `;zztest`), Save. Close the editor. Type `;zztest` in Notepad. The form or text comes out right.
- [ ] Saving **backs up** the old file: look in %LOCALAPPDATA%\Watchlog\template backups for a new copy, and check "# Wording version" moved on in the file.
- [ ] If you pick the **team file**, Save asks once before writing. (Use your own my-templates.txt first if you'd rather not touch the team file.)
- [ ] Type `;jack` inside the editor. It must not fire a template.
- [ ] Delete the `;zztest` template, Save again.
- [ ] **Notepad fallback:** tray > Advanced > Edit templates in Notepad still opens the file, and saving it reloads Watchlog by itself.

## 5. SDS signs itself back in (v3.10.1)
- [ ] In Settings > Logins, the SDS tick box and minutes box (62) are there. Make sure the SDS login is locked to SDS (the Window= box).
- [ ] Sign into SDS with its login (shortcut, or the Yes/No question, or Ctrl+Alt+L). A 62-minute countdown starts.
- [ ] **The 55-minute "log in again" pop-up should not show for SDS** any more. (Other logins with a Remind time still show it.)
- [ ] About 62 minutes later, once SDS has logged you out: SDS comes to the front, the login is typed, and the window you were in is put back. If you were typing, it waits until you stop for a moment.
- [ ] If SDS still says Welcome it tries again each minute, up to 6 times, and types nothing while SDS isn't on its login screen.
- [ ] For a quick check without waiting an hour: set minutes to 2, sign in, let SDS sit on its login screen, and watch. Set it back to 62 after.
- [ ] Untick it (or set 0): the old 55-minute pop-up comes back for SDS.

## 6. Quick re-check of older things (v3.9.x, already confirmed once)
- [ ] Ctrl+Alt+L start of shift still opens the apps and asks the sign-in question.
- [ ] Caps Lock clears Alert Grid alerts (guard on, Alert Grid taught).
- [ ] On a second bay: the Alert Grid teach step (tray > Alert Grid > Teach) hasn't been done there yet.

## What to send back
Anything that looked wrong: which section number, what you pressed, what you saw, and any error with its line number.
