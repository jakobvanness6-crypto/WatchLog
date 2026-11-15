# Watchlog v3.40.0 - Test Checklist (built, NOT run)

This zip also holds the count sheet (v3.39.0) and break seconds (v3.38.3), which are not tested on a bay yet. Their steps are at the bottom. Use the templates.txt from the zip.

## A. Boxes that remember (Reference, Asset #)
1. Type `;fill`. Expect a new last box: "Reference (remembered for each Table)". Pick BJ205, type an amount, type a Reference like `M3 (355)`, Enter. The daily log should get that Reference.
2. Type `;fill` again and pick BJ205. Expect the Reference filled in by itself as soon as the table is picked. Pick another table: it empties again.
3. Type over the remembered Reference and Enter. Next time BJ205 shows the new one.
4. Call pad: `fill 205 5.5`, Ctrl+Enter. Expect it to go straight in as before, now with BJ205's Reference. A table with nothing remembered goes in with Reference empty, as before.
5. `;bv`: type a machine and its asset #. Next `;bv` with the same machine fills the asset # (one `#`, not two).
6. Same check on `;jack` (Reference per machine) and `;medical` (daily log Location and Reference per place).
7. Tray > Advanced > Remembered boxes: Notepad opens remembered.ini with lines like `BJ205=M3 (355)` under `[Reference]`.

## B. The bay of this PC
8. Run the Start log (Ctrl+Alt+F, Start) or `;start`. The first time it asks "Which bay is this PC?" Answer it. Expect a tip that this PC is now that bay.
9. Run `;start`, `;end`, or the Start / End logs again: no bay question, the right bay in the text.
10. Tray > Advanced > This PC's bay...: change it, check the next `;end` uses the new one. Empty it and the question comes back.
11. On another bay: it asks once there too, and keeps a different bay for that PC.

## C. Open tables
12. `;open`, add BJ205 and RO204, Enter. Hover the tray icon: "Open tables: BJ205, RO204". Same line on the home window (Ctrl+Alt+M) and the dashboard.
13. `;cards` or `;fill`: BJ205 and RO204 are the first two in the Table list.
14. `;open` again: BJ205 and RO204 are now at the end of the list.
15. `;auto`: the list starts with "All open (BJ205, RO204)", then BJ205, RO204. Pick All open, Enter. Expect "BJ205 and RO204 Closed and Auto-Close started." and the tray text gone.
16. `;fill`, pick BJ205: the Table label says you logged it closed at that time. It still goes in.
17. Pad: `open 202 closing 204`, Ctrl+Enter: the list follows it too.
18. Typing `205` in a table box still picks BJ205.

## D. Still to check from v3.39.0 and v3.38.3
19. Count sheet: Ctrl+Alt+T asks the two questions, then stamps a line per press where the cursor is (see the v3.39.0 checklist in archive for all 20 steps).
20. Break: the tray text counts minutes and seconds; Change break time takes `45:30`.

If anything is off, send the line number from the error box or a photo.
