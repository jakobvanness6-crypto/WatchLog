#!/usr/bin/env python3
"""Changes Watchlog's version number in the places that show the CURRENT version.

    python3 tools/bump-version.py 3.29.1 [Oct 31, 2026]

Only these spots change, so the "(v3.24.0)" style notes that say when a
feature arrived are left alone (a blanket find-and-replace used to bump
those too and made the history wrong):
  Watchlog.ahk         VERSION := "..." and VERSION_DATE := "..."
  templates.txt        # Program version: ...
  README.txt           the title line  WATCHLOG  v...  -  README
  QUICK START.txt      the title line  WATCHLOG  v...  -  QUICK START
  docs/source/*.md     "it's on X now", "Version X is built", "I'm on version X"
  docs/Pending changes.md   "Current version: vX"
PROJECT-NOTES.md "Current version" is a written summary: update it by hand.
Then run build/release.sh NEW OLD (builds the zip, the IT zip, the docs and
the ChatGPT hand-off).
"""
import re, sys, datetime, os
PF = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) + os.sep
new = sys.argv[1]
date = sys.argv[2] if len(sys.argv) > 2 else datetime.date.today().strftime("%b %-d, %Y")
V = r'\d+\.\d+\.\d+'
spots = [
    ("Watchlog.ahk", r'(?m)^VERSION := "' + V + '"', f'VERSION := "{new}"'),
    ("Watchlog.ahk", r'(?m)^VERSION_DATE := "[^"]*"', f'VERSION_DATE := "{date}"'),
    ("templates.txt", r'(?m)^# Program version: ' + V, f'# Program version: {new}'),
    ("README.txt", r'(?m)^(  WATCHLOG  )v' + V + r'(  -  README)', r'\g<1>v' + new + r'\g<2>'),
    ("QUICK START.txt", r'(?m)^(  WATCHLOG  )v' + V + r'(  -  QUICK START)', r'\g<1>v' + new + r'\g<2>'),
    ("docs/source/Watchlog - Overview.md", r"(it's on )" + V + r"( now)", r'\g<1>' + new + r'\g<2>'),
    ("docs/source/Watchlog - Overview.md", r"(Version )" + V + r"( is built)", r'\g<1>' + new + r'\g<2>'),
    ("docs/source/Watchlog - IT Summary.md", r"(I'm on version )" + V, r'\g<1>' + new),
    ("docs/Pending changes.md", r'(Current version: v)' + V, r'\g<1>' + new),
]
for f, pat, rep in spots:
    p = PF + f
    s = open(p, encoding="utf-8").read()
    s2, n = re.subn(pat, rep, s, count=1)
    print(("ok      " if n else "MISSING ") + f + "  " + pat[:50])
    if n:
        open(p, "w", encoding="utf-8", newline="").write(s2)
print("Now update PROJECT-NOTES.md 'Current version' by hand.")
