"""Makes the icon and version resources Watchlog.exe needs.
Usage: python3 mk_resources.py Watchlog.ico 3.5.0.0 <out folder>
Writes icon101.bin..icon108.bin, group159.bin and version.bin."""
import struct, sys, os

ico, ver, out = sys.argv[1], sys.argv[2], sys.argv[3]
os.makedirs(out, exist_ok=True)

# --- icons: 8 images, replacing AutoHotkey's own icons 101-108 and group 159
d = open(ico, 'rb').read()
_, _, n = struct.unpack('<HHH', d[:6])
imgs = []
for i in range(n):
    w, h, c, _, pl, bpp, size, off = struct.unpack('<BBBBHHII', d[6 + 16 * i:22 + 16 * i])
    imgs.append((w or 256, h or 256, c, pl, bpp, d[off:off + size]))
want = [16, 20, 24, 32, 40, 48, 64, 256]
imgs = [next(x for x in imgs if x[0] == s) for s in want]
group = struct.pack('<HHH', 0, 1, len(imgs))
for k, (w, h, c, pl, bpp, data) in enumerate(imgs):
    open(os.path.join(out, 'icon%d.bin' % (101 + k)), 'wb').write(data)
    group += struct.pack('<BBBBHHIH', w % 256, h % 256, c, 0, pl, bpp, len(data), 101 + k)
open(os.path.join(out, 'group159.bin'), 'wb').write(group)

# --- version resource
def pad(b): return b + b'\0' * ((4 - len(b) % 4) % 4)
def node(key, value=b'', wtype=1, children=(), vlen=None):
    k = (key + '\0').encode('utf-16-le')
    if vlen is None:
        vlen = len(value) // 2 if wtype == 1 else len(value)
    d = bytearray(b'\0' * 6) + k
    d = bytearray(pad(bytes(d)))
    d += value
    for c in children:
        d = bytearray(pad(bytes(d)))
        d += c
    struct.pack_into('<HHH', d, 0, len(d), vlen, wtype)
    return bytes(d)
def s(key, val): return node(key, (val + '\0').encode('utf-16-le'), 1)
a, b, c, dd = [int(x) for x in ver.split('.')]
ms = (a << 16) | b; ls = (c << 16) | dd
fixed = struct.pack('<13I', 0xFEEF04BD, 0x00010000, ms, ls, ms, ls, 0x3F, 0, 0x40004, 1, 0, 0, 0)
strings = [s('FileDescription', 'Watchlog'), s('ProductName', 'Watchlog'), s('FileVersion', ver),
           s('ProductVersion', ver), s('InternalName', 'Watchlog'), s('OriginalFilename', 'Watchlog.exe'),
           s('Comments', 'Types standard log entries from short codes')]
st = node('040904B0', b'', 1, strings, vlen=0)
sfi = node('StringFileInfo', b'', 1, [st], vlen=0)
var = node('Translation', struct.pack('<HH', 0x0409, 0x04B0), 0)
vfi = node('VarFileInfo', b'', 1, [var], vlen=0)
root = node('VS_VERSION_INFO', fixed, 0, [sfi, vfi])
open(os.path.join(out, 'version.bin'), 'wb').write(root)
print('icons', len(imgs), 'version', len(root))
