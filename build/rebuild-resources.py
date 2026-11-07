"""Rebuilds the .rsrc section of a PE (last section, no overlay) with replaced/added resources.
Usage: rsrc_build.py in.exe out.exe TYPE:NAME=file ...   (NAME is an int id or a string)"""
import sys, struct, pefile

src, out = sys.argv[1], sys.argv[2]
pe = pefile.PE(src)
data = bytearray(pe.__data__)
# tree: {type: {name: {lang: bytes}}}
tree = {}
for t in pe.DIRECTORY_ENTRY_RESOURCE.entries:
    tk = str(t.name) if t.name is not None else t.id
    for n in t.directory.entries:
        nk = str(n.name) if n.name is not None else n.id
        for l in n.directory.entries:
            d = l.data.struct
            tree.setdefault(tk, {}).setdefault(nk, {})[l.id] = pe.get_data(d.OffsetToData, d.Size)
for arg in sys.argv[3:]:
    key, f = arg.split('=', 1)
    tk, nk = key.split(':', 1)
    tk = int(tk); nk = int(nk) if nk.isdigit() else nk
    langs = tree.setdefault(tk, {}).setdefault(nk, {})
    lang = next(iter(langs)) if langs else 0x409
    langs.clear(); langs[lang] = open(f, 'rb').read()

sec = pe.sections[-1]
assert sec.Name.rstrip(b'\0') == b'.rsrc'
base = sec.VirtualAddress

def order(d):
    names = sorted([k for k in d if isinstance(k, str)], key=lambda s: s.upper())
    ids = sorted([k for k in d if isinstance(k, int)])
    return names, ids

# layout pass: directories, then data entries, then strings, then data
dirs = []      # (node dict, level)
def collect(node, level):
    dirs.append((node, level))
    if level < 2:
        n, i = order(node)
        for k in n + i:
            collect(node[k], level + 1)
collect(tree, 0)
off = 0; dir_off = {}
for node, level in dirs:
    dir_off[id(node)] = off
    off += 16 + 8 * len(node)
entries = []
for node, level in dirs:
    if level == 2:
        for k in sorted(node):
            entries.append((node, k))
ent_off = {}
for e in entries:
    ent_off[(id(e[0]), e[1])] = off; off += 16
strings = {}
for node, level in dirs:
    for k in node:
        if isinstance(k, str) and k not in strings:
            strings[k] = off; off += 2 + 2 * len(k)
off = (off + 7) & ~7
data_off = {}
for node, k in entries:
    data_off[(id(node), k)] = off
    off += len(node[k]); off = (off + 7) & ~7
buf = bytearray(off)
for node, level in dirs:
    o = dir_off[id(node)]
    n, i = order(node)
    struct.pack_into('<IIHHHH', buf, o, 0, 0, 0, 0, len(n), len(i))
    o += 16
    for k in n + i:
        nm = (0x80000000 | strings[k]) if isinstance(k, str) else k
        if level < 2:
            tgt = 0x80000000 | dir_off[id(node[k])]
        else:
            tgt = ent_off[(id(node), k)]
        struct.pack_into('<II', buf, o, nm, tgt); o += 8
for s, o in strings.items():
    struct.pack_into('<H', buf, o, len(s)); buf[o + 2:o + 2 + 2 * len(s)] = s.encode('utf-16-le')
for node, k in entries:
    do = data_off[(id(node), k)]
    struct.pack_into('<IIII', buf, ent_off[(id(node), k)], base + do, len(node[k]), 0, 0)
    buf[do:do + len(node[k])] = node[k]

fa = pe.OPTIONAL_HEADER.FileAlignment; sa = pe.OPTIONAL_HEADER.SectionAlignment
raw = len(buf) + (-len(buf)) % fa
assert sec.PointerToRawData + sec.SizeOfRawData == len(data), 'overlay present'
data = data[:sec.PointerToRawData] + buf + b'\0' * (raw - len(buf))
pe2 = pefile.PE(data=bytes(data), fast_load=True)
s2 = pe2.sections[-1]
s2.SizeOfRawData = raw
s2.Misc_VirtualSize = len(buf)
pe2.OPTIONAL_HEADER.SizeOfImage = base + ((len(buf) + sa - 1) // sa) * sa
pe2.OPTIONAL_HEADER.DATA_DIRECTORY[2].Size = len(buf)
pe2.OPTIONAL_HEADER.CheckSum = 0
pe2.OPTIONAL_HEADER.CheckSum = pe2.generate_checksum()
pe2.write(out)
print('rsrc', len(buf), 'file', len(data))
