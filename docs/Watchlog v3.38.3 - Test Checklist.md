# Watchlog v3.38.3 - Test Checklist (built, NOT run)

Break tracker now shows minutes and seconds.

1. Start a break (`;break` or Ctrl+Alt+F > Break). Hover the tray icon: expect `On break 0 m 12 s, 59 m 48 s left` style text, counting up every couple of seconds.
2. Save & Close the break log after about a minute. Expect the pop-up `Break 1 m 05 s. Break: 58 m 55 s left (1 m 05 s of 60 m used)` and the same wording in the activity journal.
3. Open the shift dashboard: the break line reads `Break: ... left (... of 60 m used)` with seconds.
4. Tray > Change break time... The box opens with the used time as `m:ss` (like `1:05`). Try each: `45` (45 m 00 s used), `45:30` (45 m 30 s), `15 left` (45 m 00 s used), `14:55 left` (45 m 05 s used), `0` (fresh).
5. Type nonsense like `abc`: expect the friendly "Type minutes..." box, nothing changes.
6. While a break log is open, Change break time: it keeps counting on from the new number.
7. Go past 60 minutes (set `61`): expect `over by 1 m 00 s`, and the dashboard line in red.
8. Reload Watchlog (Ctrl+Alt+R) mid-break and after a break: the used time is kept.

If anything is off, send the line number from the error box or a photo.
