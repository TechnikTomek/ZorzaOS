#!/usr/bin/env python3
"""Tworzy motywy ikon Zorza-Dark / Zorza-Light (+ warianty akcentu).

Każdy motyw dziedziczy po Papirus(-Dark), ale ma własne ikony folderów
przekolorowane z fioletowego zestawu Papirusa na kolory akcentu Zorzy.
"""
import os
import re
from pathlib import Path

PAPIRUS = Path("/usr/share/icons/Papirus")
SHARED = Path("/usr/share/zorza/folders")
ICONS = Path("/usr/share/icons")

# Papirus violet: główny #7e57c2, tylna ścianka #5d399b
ACCENTS = {
    "violet": ("#7C5CFF", "#5A3FD0"),
    "pink":   ("#FF6FA3", "#C8467A"),
    "gold":   ("#FFB547", "#C98418"),
    "teal":   ("#2FD4C4", "#1C9C90"),
    "blue":   ("#4C8DFF", "#2F62C8"),
    "green":  ("#3DDC84", "#23A35C"),
}
SRC_MAIN, SRC_BACK = "#7e57c2", "#5d399b"


def sizes():
    out = []
    for d in sorted(PAPIRUS.iterdir()):
        if d.is_symlink() or "@" in d.name:
            continue
        if (d / "places").is_dir() and any((d / "places").glob("folder-violet*.svg")):
            out.append(d.name)
    return out


def build_shared():
    for acc, (main, back) in ACCENTS.items():
        for size in sizes():
            dst = SHARED / acc / size / "places"
            dst.mkdir(parents=True, exist_ok=True)
            for f in (PAPIRUS / size / "places").glob("folder-violet*.svg"):
                svg = f.resolve().read_text()
                svg = re.sub(SRC_MAIN, main, svg, flags=re.I)
                svg = re.sub(SRC_BACK, back, svg, flags=re.I)
                name = f.name.replace("folder-violet", "folder")
                (dst / name).write_text(svg)
                # Ikony "user-*" (katalog domowy, pulpit) też w akcencie
                if name == "folder-home.svg":
                    (dst / "user-home.svg").write_text(svg)
                if name == "folder-desktop.svg":
                    (dst / "user-desktop.svg").write_text(svg)


def write_theme(name, display, inherits, acc):
    root = ICONS / name
    root.mkdir(exist_ok=True)
    dirs = []
    for size in sizes():
        sdir = root / size
        sdir.mkdir(exist_ok=True)
        link = sdir / "places"
        if link.is_symlink() or link.exists():
            link.unlink()
        link.symlink_to(SHARED / acc / size / "places")
        dirs.append(size)
    lines = [
        "[Icon Theme]",
        f"Name={display}",
        f"Comment=Papirus z folderami w kolorze akcentu Zorza OS ({acc})",
        f"Inherits={inherits},breeze,hicolor",
        "Example=folder",
        "DesktopDefault=48",
        "ToolbarDefault=22",
        "PanelDefault=48",
        "Directories=" + ",".join(f"{s}/places" for s in dirs),
        "",
    ]
    for s in dirs:
        px = int(s.split("x")[0].split("@")[0]) if s[0].isdigit() else 48
        scale = 2 if "@2x" in s else 1
        lines += [f"[{s}/places]", "Context=Places", f"Size={px}", f"Scale={scale}",
                  "Type=Scalable" if s == "scalable" else "Type=Fixed", ""]
    (root / "index.theme").write_text("\n".join(lines))


def main():
    if not PAPIRUS.is_dir():
        print("Brak Papirusa – pomijam motywy ikon")
        return
    build_shared()
    for acc in ACCENTS:
        suffix = "" if acc == "violet" else f"-{acc}"
        write_theme(f"Zorza-Dark{suffix}", f"Zorza Dark ({acc})" if suffix else "Zorza Dark", "Papirus-Dark", acc)
        write_theme(f"Zorza-Light{suffix}", f"Zorza Light ({acc})" if suffix else "Zorza Light", "Papirus", acc)
    os.system("for d in /usr/share/icons/Zorza-*; do gtk-update-icon-cache -q -f \"$d\" 2>/dev/null; done")
    print("Motywy ikon Zorza gotowe")


if __name__ == "__main__":
    main()
