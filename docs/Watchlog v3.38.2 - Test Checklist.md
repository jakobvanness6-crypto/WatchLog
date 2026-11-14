# Watchlog v3.38.2 - Test Checklist (built, NOT run)

Machine fills on one call pad line. Use a test daily log you can delete, or just look at the form before it goes in.

1. Several machines on ONE line. Open the call pad (Numpad +), type
   `mfill n1 100000 n2 50000 bvs a1 20000` and press Ctrl+Enter.
   Expect three separate lines: `NRT1 $100,000`, `NRT2 $50,000 (BVs)`, `ATM1 $20,000`.
2. With commas and "and": `mfill n3 190800 bvs, n4 90k and a2 100000`.
   Expect `NRT3 $190,800 (BVs)`, `NRT4 $90,000`, `ATM2 $100,000`, one per line.
3. One machine per line (as before). Type on three lines:
   `mfill n1 50000` / `n2 60000 bvs/divert` / `a3 100000`.
   Expect three lines, the middle one with `(BVs/Divert)`.
4. Just one machine: `mfill n3 190800 bvs`. Expect one line `NRT3 $190,800 (BVs)`.
5. No code word: `n1 100000 a1 20000` then Ctrl+Enter. Expect two lines.

If anything is off, send the line number from the error box or a photo of the form.
