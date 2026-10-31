#!/usr/bin/env python3
# Static checks for Watchlog.ahk (AutoHotkey can't be run in the build sandbox):
#   python3 tools/check-ahk.py Watchlog.ahk
# Flags: unbalanced braces, duplicate functions, a local variable assigned with the
# name of a nested function (the v3.27.0 "joined" load error), a local that shadows a
# function it also calls, and functions assigning script globals without "global".
# "unterminated string" lines inside continuation sections are false alarms.
import re, sys, collections
src = open(sys.argv[1], encoding='utf-8').read().split('\n')

# strip comments and string contents; keep line structure
clean = []
in_block = False
in_cont = False
problems = []
for i, line in enumerate(src, 1):
    s = line
    st = s.strip()
    if in_block:
        if st.startswith('*/') or st.endswith('*/'):
            in_block = False
        clean.append(''); continue
    if st.startswith('/*'):
        in_block = not st.endswith('*/') or st == '/*'
        clean.append(''); continue
    if in_cont:
        if st.startswith(')'):
            in_cont = False
            s = s[s.index(')')+1:]
        else:
            clean.append(''); continue
    out = []
    q = None
    j = 0
    while j < len(s):
        c = s[j]
        if q:
            if c == '`':
                j += 2; continue
            if c == q:
                q = None; out.append('S')
                out.append(c)
            j += 1; continue
        if c in '"\'':
            q = c; out.append(c); j += 1; continue
        if c == ';' and (j == 0 or s[j-1] in ' \t'):
            break
        out.append(c); j += 1
    if q:
        problems.append((i, 'unterminated string (maybe " ;" inside a string)', line.strip()[:100]))
    o = ''.join(out)
    if o.strip() == '(' or re.match(r'^\s*\(\s*(Join|LTrim|RTrim|Comments|`)', o) :
        in_cont = True
        clean.append(''); continue
    clean.append(o)

KW = set('if else while for loop return try catch finally switch case until throw global local static class not and or is in contains isset super this new until goto break continue'.split())
# function definitions with nesting
defs = []  # (name, line, depth, parent_index)
stack = []  # entries: ('func', idx) or ('blk',)
depth_func = []
funcs_at = {}
line_owner = {}
pending_func = None
brace_issues = []
for i, l in enumerate(clean, 1):
    m = re.match(r'^\s*([A-Za-z_]\w*)\(([^()]|\([^()]*\))*\)\s*(\{)?\s*$', l)
    is_def = False
    if m and m.group(1).lower() not in KW:
        # definition if line ends with { or next nonblank line starts with {
        if m.group(3):
            is_def = True
        else:
            k = i
            while k < len(clean) and clean[k].strip() == '':
                k += 1
            if k < len(clean) and clean[k].strip().startswith('{'):
                is_def = True
    m2 = re.match(r'^\s*([A-Za-z_]\w*)\(([^()]|\([^()]*\))*\)\s*=>', l)
    parent = next((e[1] for e in reversed(stack) if e[0] == 'func'), None)
    if m2 and m2.group(1).lower() not in KW:
        defs.append((m2.group(1), i, parent, 'arrow'))
    if is_def:
        defs.append((m.group(1), i, parent, 'block'))
        pending_func = len(defs) - 1
    owner = next((e[1] for e in reversed(stack) if e[0] == 'func'), None)
    line_owner[i] = owner
    for c in l:
        if c == '{':
            if pending_func is not None:
                stack.append(('func', pending_func)); pending_func = None
            else:
                stack.append(('blk',))
        elif c == '}':
            if not stack:
                brace_issues.append(i)
            else:
                stack.pop()
    if pending_func is not None and line_owner.get(i) is None and is_def:
        line_owner[i] = pending_func
print('unclosed braces at end:', len(stack), 'extra closers:', brace_issues[:5])

names_global = collections.Counter(d[0].lower() for d in defs if d[2] is None)
dups = [n for n, c in names_global.items() if c > 1]
print('duplicate top-level functions:', dups)

# map each line to chain of function owners
def chain(idx):
    out = []
    while idx is not None:
        out.append(idx); idx = defs[idx][2]
    return out

children = collections.defaultdict(list)
for k, d in enumerate(defs):
    if d[2] is not None:
        children[d[2]].append(d[0].lower())

assign_re = re.compile(r'(?<![\w.%])([A-Za-z_]\w*)\s*(?::=|\.=|\+=|-=|\*=|/=|//=|\|=|&=)')
ref_re = re.compile(r'&([A-Za-z_]\w*)')
for_re = re.compile(r'^\s*for\s+([A-Za-z_]\w*)\s*(?:,\s*([A-Za-z_]\w*))?\s+in\b', re.I)
catch_re = re.compile(r'\bcatch\b.*\bas\s+([A-Za-z_]\w*)', re.I)
topfuncs = {d[0].lower() for d in defs if d[2] is None}
calls_in = collections.defaultdict(set)
assigned_in = collections.defaultdict(dict)
for i, l in enumerate(clean, 1):
    o = line_owner.get(i)
    if o is None: continue
    if re.match(r'^\s*(global|static)\b', l, re.I):
        continue
    found = [m.group(1) for m in assign_re.finditer(l)] + [m.group(1) for m in ref_re.finditer(l)]
    m = for_re.match(l)
    if m: found += [g for g in m.groups() if g]
    m = catch_re.search(l)
    if m: found.append(m.group(1))
    for n in found:
        assigned_in[o].setdefault(n.lower(), i)
    for m in re.finditer(r'(?<![\w.])([A-Za-z_]\w*)\(', l):
        calls_in[o].add(m.group(1).lower())

# globals declared per function
glob_decl = collections.defaultdict(set)
for i, l in enumerate(clean, 1):
    o = line_owner.get(i)
    m = re.match(r'^\s*global\s+(.*)', l, re.I)
    if m and o is not None:
        for n in re.findall(r'([A-Za-z_]\w*)', m.group(1)):
            glob_decl[o].add(n.lower())

# A: assignment to a nested function name of an enclosing function
for o, names in assigned_in.items():
    for anc in chain(o):
        for n, ln in names.items():
            if n in children[anc]:
                problems.append((ln, 'assigns to "%s", a nested function of %s()' % (n, defs[anc][0]), src[ln-1].strip()[:100]))
# B: local shadows a top-level function that the same function also calls
for o, names in assigned_in.items():
    for n, ln in names.items():
        if n in topfuncs and n not in glob_decl[o]:
            if n in calls_in[o]:
                problems.append((ln, 'local "%s" shadows function %s() which this function also calls' % (n, n), src[ln-1].strip()[:100]))
            else:
                problems.append((ln, 'note: local "%s" has the same name as a function (harmless unless called here)' % n, src[ln-1].strip()[:100]))
for p in sorted(problems):
    print(p)
# undefined calls
alldefs = {d[0].lower() for d in defs}
allcalls = set()
for s in calls_in.values(): allcalls |= s
for i, l in enumerate(clean, 1):
    if line_owner.get(i) is None:
        for m in re.finditer(r'(?<![\w.])([A-Za-z_]\w*)\(', l):
            allcalls.add(m.group(1).lower())
print('called but not defined here:', sorted(allcalls - alldefs - KW))
print('defs:', len(defs))

# C: function assigns to a script-level global without declaring it global
top_assigned = set()
for i, l in enumerate(clean, 1):
    if line_owner.get(i) is None:
        for m in assign_re.finditer(l):
            top_assigned.add(m.group(1).lower())
def declared(o, n):
    for anc in chain(o):
        if n in glob_decl[anc] or 'global' in [x for x in glob_decl[anc] if x=='global']:
            return True
    return False
# functions with bare "global" (assume-global)
bare_global = set()
for i, l in enumerate(clean, 1):
    if re.match(r'^\s*global\s*$', l, re.I) and line_owner.get(i) is not None:
        bare_global.add(line_owner[i])
print('\nC: assigns to a script global without "global":')
for o, names in assigned_in.items():
    if any(a in bare_global for a in chain(o)): continue
    for n, ln in names.items():
        if n in top_assigned and not any(n in glob_decl[a] for a in chain(o)):
            # params are fine
            print(ln, defs[o][0], n, '|', src[ln-1].strip()[:90])

# D: a space or tab then ; INSIDE a quoted string. AutoHotkey treats it as the
# start of a comment even there, so the line fails to load ("Missing quote").
# Write `; instead. (This is what broke v3.25.0 and v3.30.0.)
print("\nD: space/tab + ; inside a string (must be `;):")
in_cont2 = False
for i, line in enumerate(src, 1):
    st = line.strip()
    if in_cont2:
        if st.startswith(')'):
            in_cont2 = False
        continue
    if st.startswith(';') or st.startswith('/*'):
        continue
    q = None
    j = 0
    while j < len(line):
        c = line[j]
        if c == '`':
            j += 2; continue
        if q:
            if c == q:
                q = None
            elif c == ';' and j > 0 and line[j-1] in ' \t':
                print(i, '|', st[:110]); break
        else:
            if c in '"\'':
                q = c
            elif c == ';' and j > 0 and line[j-1] in ' \t':
                break
        j += 1
    if q and st in ('text := "', 'return "') or (q and st.endswith('"') and st.count('"') == 1):
        in_cont2 = True
