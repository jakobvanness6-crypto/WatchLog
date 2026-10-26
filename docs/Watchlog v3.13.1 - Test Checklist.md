# Watchlog v3.13.1 - Call pad, shorthand, autocorrect: what to try on the work PC

Copy the new templates.txt (wording Oct 25, 2026 (3), in the zip) into Documents\Watchlog first. It adds the Note box to ;mfill. v3.11.0 (shift count) and v3.10.x items are still untested on a bay.

## Call pad
- [ ] **Numpad +** in another program opens the Call pad with the cursor ready; the time is stamped at your first key. **Shift+Numpad +** and **Ctrl+Numpad +** still type a plus. If plain + gets in your way in SDS or CMP, set `[CallPad] Key=off` in settings.ini (Ctrl+Alt+N still opens the pad).
- [ ] **Esc** hides the pad and returns you to your program; + brings it back with the text.
- [ ] **Make a log** (Ctrl+Enter) copies the call to the clipboard and hides the pad. Then type a trigger like ;jack: the form fills from the call, boxes marked "(from your call pad)". After that log is inserted the pad is empty and the call is under Earlier calls this shift. Cancelling the form keeps the call.
- [ ] Two different machines jotted: the Machine box stays empty (nothing is guessed).
- [ ] Copy all, Paste into window, New call, Earlier calls this shift work. End of shift wipes the pad.

## Shorthand
- [ ] `n3 190800 bvs` then ;mfill: `NRT3 $190,800 (BVs)`. `a1 100000`: `ATM1 $100,000`. `n1 5000 bvs/divert` or `bvs divert`: `(BVs/Divert)`.
- [ ] Three fill lines on the pad, type ;mfill: all three come out, one line each. Machines that don't exist (like n5) are ignored.
- [ ] `c2102 11421.11 win 3 cash` then ;jack: Machine C2102, Amount $11,421.11, Window #3. Time paid stays blank for now.

## Casino autocorrect
- [ ] In the pad type `tito `, `handpay `, `olg.`: they become TITO, hand pay, OLG. **Ctrl+Z** puts the old word back. The same fixes work in log form boxes.
- [ ] Tray > Advanced > **Edit the autocorrect list** opens autocorrect.txt. Add `surv = Surveillance`, save, reopen the pad: it works. # in front of a line switches it off.
- [ ] meal, ram, wan, gm become MEAL, RAM, WAN, GM. Tell me if any gets in your way. (WAP and R4 are off.)

## Time saved
- [ ] After a pad-based log, tray > Shift count shows its saving as the log's length minus the trigger, the keys typed on the pad, and 2 for + and Ctrl+Enter.

## Alert Grid
- [ ] Clear with the Caps Lock key several times, also while new alerts drop in: the whole list should clear each time. If it still sometimes clears only the top alert, raise `[AlertGrid] SelectWait=` in settings.ini (default 200) to 400 and tell me.
