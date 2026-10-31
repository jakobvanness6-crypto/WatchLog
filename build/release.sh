#!/bin/bash
# Builds a Watchlog release:  bash build/release.sh NEW OLD   (e.g. 3.29.1 3.29.0)
# Run tools/bump-version.py NEW first. Needs the previous release zip
# ("Watchlog vOLD.zip") in the project folder: its exe is reused and only the
# script and text resources are swapped in (AutoHotkey can't run here).
# Makes "Watchlog vNEW.zip", the IT script zip, rebuilds the docs and the
# ChatGPT hand-off, and moves the old zips to archive/old-releases.
set -e
NEW=$1; OLD=$2
P="$(cd "$(dirname "$0")/.." && pwd)"
W=$(mktemp -d)
cd "$W" && mkdir rel res && (cd rel && unzip -q "$P/Watchlog v$OLD.zip")
python3 "$P/build/mk_resources.py" "$P/Watchlog.ico" "$NEW.0" res >/dev/null
python3 "$P/build/rebuild-resources.py" rel/Watchlog.exe rel/new.exe "10:1=$P/Watchlog.ahk" "10:TEMPLATES.TXT=$P/templates.txt" "10:README.TXT=$P/README.txt" "10:QUICK START.TXT=$P/QUICK START.txt" "16:1=res/version.bin"
mv rel/new.exe rel/Watchlog.exe; cp "$P/templates.txt" "$P/README.txt" "$P/QUICK START.txt" rel/
(cd rel && zip -q "$P/Watchlog v$NEW.zip" templates.txt LICENCE.txt README.txt "QUICK START.txt" Watchlog.exe)
mv "$P/Watchlog v$OLD.zip" "$P/archive/old-releases/"
mv "$P/for IT (on request)/Watchlog v$OLD script for IT.zip" "$P/archive/old-releases/"
mkdir it && cd it && unzip -q "$P/archive/old-releases/Watchlog v$OLD script for IT.zip"
sed -i "s/Watchlog v$OLD/Watchlog v$NEW/g" "READ ME FIRST.txt"; cp "$P/Watchlog.ahk" "$P/settings.example.ini" .
zip -qr "$P/for IT (on request)/Watchlog v$NEW script for IT.zip" .
cd "$P/docs/source" && python3 build-docs.py 2>&1 | tail -1
cd "$P" && python3 tools/make-chatgpt-handoff.py "$NEW" | tail -1 && rm -f "ChatGPT hand-off.zip" && zip -qr "ChatGPT hand-off.zip" "ChatGPT hand-off"
rm -rf "$W"
