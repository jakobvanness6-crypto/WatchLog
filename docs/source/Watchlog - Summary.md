# Watchlog summary

Oct 31, 2026 · Jakob

Watchlog is a small Windows program I built that types our standard log entries. You type a short code like `;interior` or `;medical`, fill in the details that change, and the finished entry goes into iTrak. Most codes can also open a new daily log and fill in its Location, Topic and Reference. You still read it over and save it yourself, same as now. It also clears the Alert Grid list with one key once you've looked it over, opens and signs into our programs at the start of shift, signs SDS back in when it logs me out after an hour, and keeps count of the 60 minutes of break. A home window with a button for everything makes it easy for new people to find their way around.

## Why it's worth trying

- About 2,000 keystrokes and 14 minutes saved per shift on typing and opening programs by my count, roughly 42 hours a year per operator. One-key Alert Grid clearing should add another 5 to 10 minutes a shift. These are estimates, and I plan to count a full shift to check them.
- Everyone works from the same approved wording, so entries are consistent.
- Fewer typos and missed details: times come from the clock, numbers are formatted for you, and a blank box shows up as XXXXX.
- New operators get a short tutorial and can search templates by any word, so there's nothing to memorize.

## Security

- Passwords are kept in Windows Credential Manager on each PC, never in a file and never synced. A login is only typed into the program it's locked to.
- It doesn't connect to the internet, send anything anywhere, record what you type, or change anything in iTrak. In Alert Grid it only does the clicks you'd do, and never touches the password.
- The only copy of log text it keeps is each operator's own shift journal, which is deleted after 30 days.
- The shared wording sits in a SharePoint folder that the supervisors have access to. Each PC shows a check code proving it has the approved version, and a Security and status report listing everything the tool has saved there.

## What I'm asking for

Approval for anyone on the team who wants it to use it. I'd need the supervisors named by management to approve the wording, a SharePoint folder for the shared file, and IT to check the password storage, the automatic logins and Alert Grid clicks, and running Watchlog.exe with Windows. It installs per user with no administrator rights. The full overview has all the details.
