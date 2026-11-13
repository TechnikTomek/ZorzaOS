#!/usr/bin/env python3
"""Scala schemat kolorów z domyślnymi ustawieniami Zorzy w pliku kdeglobals.
Użycie: make-kdeglobals.py <schemat.colors> <plik-wyjściowy>
"""
import sys
from pathlib import Path

scheme, out = Path(sys.argv[1]), Path(sys.argv[2])
dark = "Dark" in scheme.name

extra = f"""
[KDE]
LookAndFeelPackage=org.zorza.{'dark' if dark else 'light'}
widgetStyle=Breeze
AnimationDurationFactor=0.7071

[Icons]
Theme=Zorza-{'Dark' if dark else 'Light'}

[General]
font=Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1
menuFont=Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1
toolBarFont=Inter,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1
smallestReadableFont=Inter,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1
fixed=JetBrains Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1
TerminalApplication=konsole
TerminalService=org.kde.konsole.desktop
BrowserApplication=firefox-esr.desktop

[WM]
activeFont=Inter,10,-1,5,600,0,0,0,0,0,0,0,0,0,0,1
"""

text = scheme.read_text()
# scal sekcję [General] schematu z naszą
lines, section, merged = [], None, {}
for raw in text.splitlines():
    l = raw.strip()
    if l.startswith("["):
        section = l
    if section == "[General]" and "=" in l and not l.startswith("Name"):
        merged[l.split("=", 1)[0]] = l
        continue
    if section == "[General]" and (l == "[General]" or l.startswith("Name")):
        continue
    lines.append(raw)

body = "\n".join(lines) + "\n" + extra
gen = "\n".join(merged.values())
body = body.replace("[General]\n", "[General]\n" + gen + "\n", 1)
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(body)
print(f"kdeglobals → {out}")
