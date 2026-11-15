# Watchlog: more automation from context (Nov 15, 2026)

Written after reading all of Watchlog.ahk (v3.39.0), templates.txt and incidents.txt. **Built so far: ideas 1, 2 and 3, in v3.40.0 (Nov 15). Idea 5 is on hold.** Nothing else here is built. Each idea says what Watchlog already knows at that moment, what it would fill in from it, and what I'd need from you.

**The rule I kept to:** everything comes from what you type into Watchlog, what it has already logged this shift, the clock, or the PC it is running on. Nothing reads people's names or numbers out of iTrak, CMP or the Alert Grid, and nothing about a person is kept between shifts.

How Watchlog fills boxes today, so the gaps are clear:

- `now`, `now+20`: the time.
- `last`, `saved`, `next`: what you typed last time (only Bay uses it).
- `clip`, `alertcopy`, `matchcopy`, `fromcopy`: something you copied.
- `if X=Y`: one box filled from another (only the ATM amount and the audit Area use it).
- `%pit%`, `%slots%`: the daily log Location worked out from the table or machine.
- The call pad: a table, machine, amount or alert # typed on the pad fills the matching box.

Most boxes use none of these. That is where the ideas below come from.

---

## Part 1. Can be built now, nothing needed from you

### 1. The bay from the PC it's running on
Watchlog knows the PC's name. You rotate across three bays, and the bay is still asked at every start of shift. A one-time list (PC name = bay, kept in the team settings so every operator gets it) means `;start`, `;end`, `+Start` and `+End` never ask again. The first time on a PC it asks once and remembers it for that PC.

### 2. A box that remembers its partner ("recall")
A new box option: remember the last answer **per value of another box**. No lists to write, it learns as you work.

- `;bv`: Asset # is remembered per Machine. Type C2102 once with its asset #, and next time C2102 fills the asset # itself.
- `;jack`, `;fill`, `;mfill`, `;bv`, `;aml`, `;abandon`, `;found`: the daily log **Reference** (monitor and cameras) is remembered per table or machine. You type it into the form once per table; after that the Reference is filled every time. Today you type Reference by hand on all of these.
- `;audit`: Location (the monitor, `MX`) remembered per Employee type or Area.
- `;medical`: the daily log Location and Reference remembered per place (Kitchen, Main Entrance).

These are machines, tables and cameras, not people. Kept on the PC, or shared in the team folder so one operator's teaching helps all three bays.

### 3. Open tables are known for the rest of the shift
`;open`, `;oc`, `;auto` and `;close` already say which tables opened and closed. Keeping that list for the shift gives:

- `;auto` and the Closed box of `;oc` offer only the tables that are open, with "all open tables" as the first choice.
- `;cards`, `;fill` and `;player` list open tables first.
- A quiet note on the form if you fill or change cards on a table Watchlog thinks is closed (not a block).
- The dashboard shows "Open now: BJ205, RO204".

### 4. "The usual" for table openings
Table openings follow a schedule. With an empty `;open`, the first choice would be the same set you opened in that hour on the same weekday last week ("UT201, FB202 and BJ205"), one Enter. Tables only, learned on the PC.

### 5. Daily log to incident: boxes carried across, report picked for you
Today the incident key (Ctrl+Alt+Shift+N) shows the full list and asks its boxes again. Watchlog already knows which log you just made and what you picked in it:

- After `;refuse` with "showing signs of intox": the incident list opens on **Refusal - signs of intox**.
- After `;evict` with "24 hour": opens on **Trespass - 24 hours**, with Where and Reason already filled from the log. "indefinite" and "in violation of their trespass" pick their reports the same way.
- Optional switch: offer the incident straight after such a log is filled ("Make the incident too? Enter = yes"), so the pair is one flow.

### 6. Boxes that only matter sometimes are hidden until they do
- `;refuse`: "Signs observed" only shows when Reason is "showing signs of intox".
- `;player`: "Reason (only if up)" only shows when Down/Up is Up.

Fewer boxes to Tab past, and no stray text in the wrong case.

### 7. `next` on machine fills
The `next` option exists but only the old count step used it. On `;mfill`, each "Add another" would open on the following machine (NRT1, NRT2, NRT3 ...), so a full fill run is amounts only. Templates change only.

### 8. `last` on small repeat boxes
One-word change per box in templates.txt, so the form opens on what you picked last time:
`;jack` Window # and Paid, the Rank in `;interior` / `;exterior` / `;parking`, `;medical` Who and Location, `;refuse` Patrons and Reason, `;bv` Reason, `;firm` Department.

### 9. Time boxes take the call's time, not the time you finish typing
The call pad stamps the minute of your first key. A log made from the pad would use that time in its `now` boxes (`;aml` Time, `;audit` From), since the call is closer to when it happened. `now+20` follows it.

### 10. Recently used values first
Any machine, table or NRT box opens with this shift's values at the top of its list (from the shift journal Watchlog already keeps). A follow-up log on the same machine is one arrow key.

### 11. "Already logged" check
Before a log goes in, Watchlog compares it with this shift's journal and notes on the form when it is the same thing twice: the same table fill and amount, the same machine and alert #, the same jackpot. The facial rec alert # already has this; it would cover everything. A note only, never a block.

### 12. Sanity notes on what was typed
- A machine whose letter isn't in `@slots` ("Couldn't tell which slots area" happens after the fact today; this says so on the form).
- A table that isn't in `@tables`.
- An amount far outside what that log normally sees (a $500,000 table fill), using the range of your own past logs.

### 13. The count sheet finds the log itself
Now that the count sheet exists: if a Daily Log Entry window is open, Ctrl+Alt+T could click into the Synopsis and jump to the end by itself (that spot is already taught for full-entry logs), so you reopen the log and press one key without clicking first. The first stamp of the day could also open and fill the count log (Location, Topic, Reference) like any full-entry log.

### 14. Count sheet totals
The sheet has every amount. The Buy line could carry the day's total by itself (tables + both pods), and the dashboard could show the count's start, finish and length.

### 15. Back from break in one key
The break log is known (Watchlog watches its window). One key: bring it to the front, click End Time Now, click Save (the taught Save spot from v3.38.0). The break clock stops as it does today.

### 16. Start and end of shift as one flow
Ctrl+Alt+L opens the apps and signs in; the Start log is a separate step. With the bay known (idea 1), start of shift could finish by making the Start log itself, and end of shift could make the End log before closing the apps. A switch, off until you want it.

### 17. End of shift check
Before the End log, a small list from what Watchlog already knows: tables still open (idea 3), a count sheet not finished, a break log still open, break time left, a call still on the pad, forms left on Esc. One glance instead of remembering.

### 18. The finder knows the time of the shift
Ctrl+Alt+Space already ranks by pins, recent and most used. Adding "what you usually run in this hour of the shift" puts the door checks, table drop or count on top when they are due, without any reminder pop-up.

### 19. The pad guesses the log from the shape of the line
The pad already knows `n3 190800` is a machine fill and `c2102 12 win 3` is a jackpot without a code word. Extending the same idea:

- a table and an amount (`205 5.5`) = table fill
- a table alone with "cards" or just `cc 205` = card change (already works through the alias)
- a machine, "#" number and full/def (`c2102 #4471 full`) = BV pull
- an 8-digit number and a percent = facial rec
- a three-digit number and a machine = AML alert

When two logs fit, the finder opens on those two only.

### 20. Any order on the pad
Shorthand for most code words fills boxes strictly in order. Matching by shape instead (the amount goes to the money box, the table to the table box, 2130 to the time box, a percent to the percent box) means the words can be typed in the order the caller says them.

---

## Part 2. Needs a short list from you (then mostly templates.txt changes)

### 21. Reference for logs that always happen in the same place
These leave Reference empty today although the place never changes. With the monitor and camera text for each, they are filled for good:
`;selfex` (Security Office), `;inventory` (Cash Cage), `;evict` (Security Desk - Main Lobby), `;maint`, `;firm`, and `;mfill` per machine (nine machines: NRT1-4, ATM1-5).

### 22. Location and Reference for `;medical`
Its daily log Location is empty. A small list (Kitchen = which iTrak Location and cameras, Main Entrance = ...) fills both from the Location box you already pick.

### 23. A camera list for tables
Twelve tables. A `@cams` list (BJ205 = M3 (355) ...) fills Reference on `;fill`, `;cards`, `;open`, `;player` from day one, instead of learning it one table at a time (idea 2).

### 24. Standard amounts
`if ATM=100000` exists. If NRT fills, table fills per game, or the partial buy have usual amounts, the same rule fills them and you only type the exceptions.

### 25. `;jack` rules
If there is a rule for cash or cheque by amount, or a usual window, the form can pick it from the amount. Time paid could open on the time now if you normally log right after the pay.

### 26. Incident dates from the log
The audit fill already types iTrak's segmented date boxes part by part. The same code could fill an incident's Reported and Occurred times from the daily log's time. I need to see those boxes once (a screenshot with made-up details).

### 27. More incident kinds
Only the five "on behalf of Security" reports exist. Medicals and self-exclusion violations were left for later; each needs its Type, Specific, Risk and brief wording.

---

## Part 3. Bigger, worth it later

### 28. Player updates that remember the player for the shift
`;player` asks player #, spot, table and buy-in every time. Kept in memory for the shift only (never written to a file), a second update on the same player would need just the new amount, and Down or Up could be worked out from the last one. This touches a patron account number, so it is your call and your manager's.

### 29. Your supervisor for the shift
The incident fill stops at Secondary Operator for you to type your supervisor. Asked once at start of shift and kept in memory until end of shift, it would be typed for you. A person's name, so the same caution as 28.

### 30. Forms that never open
"Skip forms already filled in" exists and is off. With ideas 2, 8 and 9 in place, many logs would have every box filled from context, so with that switch on they go straight in. Worth turning on only after those are proven on a bay.

### 31. Audits you haven't done yet
`;audit` could order the Employee type list by what you have not audited this shift (it counts job titles only, which the Shift count already does).

### 32. Supplemental builder for incidents
Parked from Nov 1: camera and time per line, built like the count sheet.

---

## What I'd build first

1. **Idea 2 (recall)** with **21 and 23** as its head start: Reference is the box you still type by hand on the most logs.
2. **Idea 1 (bay from the PC)**: small, and it matters more once Michael and the others rotate through.
3. **Idea 5 (log to incident)**: removes the double entry on the reports you do most.
4. **Idea 3 (open tables)** with **6, 7 and 8**: small changes that make the everyday table and slot forms shorter.
5. **Idea 13 (count sheet finds the log)**: once v3.39.0 is confirmed on a bay.

Say which numbers you want and "build it". For Part 2 ideas, send the lists and I'll add them.
