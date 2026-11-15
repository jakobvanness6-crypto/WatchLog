# Watchlog v3.39.0 - Test Checklist (built, NOT run)

The count sheet. Try it in Notepad first, then in a test daily log in iTrak. Replace templates.txt with the one in the zip (the four old count code words are gone).

**Start a count**
1. Press Ctrl+Alt+T. Expect a small "new count" window: Tables and slots / Slots only, Pod 1 first / Pod 2 first. Pick Tables and slots, Pod 2 first, Enter.
2. Expect the sheet with 12 lines, the first marked NEXT, and line 3 reading like `Nov, 15th; $___. Starting Pod 2 Soft Count.`

**Stamp lines**
3. Click in Notepad, press Ctrl+Alt+T. Expect `10:00 - Count Team entered Count Room for Soft Count start.` typed there with the time now.
4. Press it again. Expect the second line on a NEW line.
5. Press it again. Expect a box asking for the amount. Type `70385`, Enter. Expect `Nov, 15th; $70,385. Starting Pod 2 Soft Count.`
6. Next line, type `1144.005k`. Expect `Pod 2 Total; $1,144,005. Calling Main Banker for Partial Buy.`
7. Next amount line, press Esc in the box. Expect nothing typed and the line still NEXT.
8. In iTrak: reopen a test daily log, click at the end of the Synopsis, press Ctrl+Alt+T. Check the line lands on its own line.

**The sheet (Ctrl+Alt+Shift+T)**
9. Undo last: the last line goes back to NEXT.
10. Skip / unskip on a line: it says skipped and Ctrl+Alt+T goes past it. Press again to bring it back.
11. Edit... on a done line: change `10:03` to `10:05`, OK. The sheet shows the new time.
12. Pick a later line and press Stamp: it is stamped, copied, and moves up behind the last done line.
13. Tables Buy: three lines appear as the next ones.
14. Emergency pull: type a machine, expect `Completed emergency pull for C2102.` stamped and copied.
15. Note...: type anything, expect it stamped and copied.
16. Copy whole log, paste in Notepad: every stamped line, in order.

**Other ways in**
17. Type `count` on the call pad, Ctrl+Enter: the next line is typed where you were.
18. Type `;count` anywhere: the sheet opens. Tray menu > Count sheet does the same.

**Slots-only day and keeping it**
19. New count, Slots only, Pod 1 first: expect 8 lines, a break line after Pod 1, and one `Pod 1 and 2 Total; $___` line.
20. Reload (Ctrl+Alt+R) mid-count: the sheet and its times are still there.

If anything is off, send the line number from the error box or a photo.
