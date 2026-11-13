"""Zorza OS – wspólny backend aplikacji Welcome i System Center.

Udostępnia do QML: stan wyglądu (motyw, akcent, tapeta, efekty),
informacje o sprzęcie oraz aktualizacje systemu jednym kliknięciem.
Zmiany wyglądu realizuje narzędzie /usr/bin/zorza-appearance.
"""
import json
import os
import platform
import re
import shutil
import subprocess
from pathlib import Path

from PySide6.QtCore import (Property, QObject, QProcess, QTimer, QUrl, Signal,
                            Slot)
from PySide6.QtGui import QDesktopServices

WALLPAPER_DIR = Path("/usr/share/wallpapers")
THUMBS = Path("/usr/share/zorza/thumbs")

ACCENTS = [
    {"id": "violet", "color": "#7C5CFF", "pl": "Fiolet zorzy", "en": "Aurora violet"},
    {"id": "pink", "color": "#FF6FA3", "pl": "Róż świtu", "en": "Dawn pink"},
    {"id": "gold", "color": "#FFB547", "pl": "Złoto", "en": "Gold"},
    {"id": "teal", "color": "#2FD4C4", "pl": "Turkus", "en": "Teal"},
    {"id": "blue", "color": "#4C8DFF", "pl": "Błękit", "en": "Blue"},
    {"id": "green", "color": "#3DDC84", "pl": "Zieleń", "en": "Green"},
]

WALLPAPER_ORDER = ["Zorza", "Horyzont", "Swit", "Fale", "Krysztal", "Glebia", "Zmierzch", "Wydmy", "Mgla"]


def _read_cfg(key, default, group="General", rc="zorzarc"):
    for tool in ("kreadconfig6", "kreadconfig5"):
        if shutil.which(tool):
            try:
                out = subprocess.run([tool, "--file", rc, "--group", group, "--key", key, "--default", default],
                                     capture_output=True, text=True, timeout=5).stdout.strip()
                return out or default
            except Exception:
                break
    return default


def _write_cfg(key, value, group="General", rc="zorzarc"):
    for tool in ("kwriteconfig6", "kwriteconfig5"):
        if shutil.which(tool):
            subprocess.run([tool, "--file", rc, "--group", group, "--key", key, value], timeout=5)
            return


def _sh(cmd, timeout=6):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, shell=isinstance(cmd, str)).stdout.strip()
    except Exception:
        return ""


def _human(n):
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if n < 1024 or unit == "TB":
            return f"{n:.1f} {unit}" if unit not in ("B", "KB") else f"{n:.0f} {unit}"
        n /= 1024.0
    return str(n)


class Backend(QObject):
    darkChanged = Signal()
    accentChanged = Signal()
    wallpaperChanged = Signal()
    effectsChanged = Signal()
    updateChanged = Signal()
    busyChanged = Signal()
    toast = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._dark = _read_cfg("Dark", "true") == "true"
        self._accent = _read_cfg("Accent", "violet")
        self._wallpaper = _read_cfg("Wallpaper", "auto")
        self._effects = _read_cfg("Effects", "true") == "true"
        self._busy = False
        self._update_log = ""
        self._update_state = "idle"  # idle | running | done | error
        self._proc = None
        self._pl = os.environ.get("LANG", "pl").startswith("pl") or os.environ.get("LANGUAGE", "").startswith("pl")

    # ------------------------------------------------------------------ helpers
    def _appearance(self, *args):
        """Uruchamia zorza-appearance asynchronicznie (UI się nie blokuje)."""
        self._set_busy(True)
        p = QProcess(self)
        p.finished.connect(lambda *_: (self._set_busy(False), p.deleteLater()))
        p.start("/usr/bin/zorza-appearance", list(args))

    def _set_busy(self, v):
        if self._busy != v:
            self._busy = v
            self.busyChanged.emit()

    # ------------------------------------------------------------------ properties
    @Property(bool, notify=busyChanged)
    def busy(self):
        return self._busy

    @Property(bool, constant=True)
    def polish(self):
        return self._pl

    @Property(bool, constant=True)
    def isLive(self):
        return os.path.exists("/run/zorza/live-session") or os.path.isdir("/run/live/medium")

    @Property(bool, notify=darkChanged)
    def dark(self):
        return self._dark

    @Property(str, notify=accentChanged)
    def accent(self):
        return self._accent

    @Property(str, notify=accentChanged)
    def accentColor(self):
        for a in ACCENTS:
            if a["id"] == self._accent:
                return a["color"]
        return ACCENTS[0]["color"]

    @Property("QVariantList", constant=True)
    def accents(self):
        return [{"id": a["id"], "color": a["color"], "label": a["pl"] if self._pl else a["en"]} for a in ACCENTS]

    @Property(str, notify=wallpaperChanged)
    def wallpaper(self):
        return self._wallpaper

    @Property("QVariantList", constant=True)
    def wallpapers(self):
        out = []
        names = sorted([d.name for d in WALLPAPER_DIR.iterdir() if (d / "metadata.json").exists()],
                       key=lambda n: WALLPAPER_ORDER.index(n) if n in WALLPAPER_ORDER else 99) if WALLPAPER_DIR.is_dir() else []
        for n in names:
            if n not in WALLPAPER_ORDER:
                continue
            try:
                meta = json.loads((WALLPAPER_DIR / n / "metadata.json").read_text())
                label = meta["KPlugin"].get("Name[pl]" if self._pl else "Name", n)
            except Exception:
                label = n
            thumb = THUMBS / f"{n}.jpg"
            if not thumb.exists():
                thumb = WALLPAPER_DIR / n / "contents/screenshot.png"
            wid = "dynamic" if n == "Horyzont" else n
            if n == "Horyzont":
                label = "Horyzont (dynamiczna)" if self._pl else "Horizon (dynamic)"
            out.append({"id": wid, "label": label, "thumb": QUrl.fromLocalFile(str(thumb)).toString()})
        return out

    @Property(bool, notify=effectsChanged)
    def effects(self):
        return self._effects

    @Property(str, notify=updateChanged)
    def updateLog(self):
        return self._update_log

    @Property(str, notify=updateChanged)
    def updateState(self):
        return self._update_state

    # ------------------------------------------------------------------ appearance slots
    @Slot(bool)
    def setDark(self, v):
        self._dark = v
        self.darkChanged.emit()
        self._appearance("theme", "dark" if v else "light")

    @Slot(str)
    def setAccent(self, a):
        self._accent = a
        self.accentChanged.emit()
        self._appearance("accent", a)

    @Slot(str)
    def setWallpaper(self, w):
        self._wallpaper = w
        self.wallpaperChanged.emit()
        self._appearance("wallpaper", w)

    @Slot(bool)
    def setEffects(self, v):
        self._effects = v
        self.effectsChanged.emit()
        self._appearance("effects", "on" if v else "off")

    # ------------------------------------------------------------------ actions
    @Slot(str)
    def launch(self, desktop_id):
        """Uruchamia aplikację po identyfikatorze pliku .desktop."""
        if shutil.which("gtk-launch") and desktop_id.endswith(".desktop"):
            QProcess.startDetached("gtk-launch", [desktop_id[:-8]])
        elif shutil.which("kioclient"):
            QProcess.startDetached("kioclient", ["exec", f"/usr/share/applications/{desktop_id}"])
        else:
            QProcess.startDetached("xdg-open", [f"/usr/share/applications/{desktop_id}"])

    @Slot(str)
    def run(self, cmd):
        QProcess.startDetached("/bin/sh", ["-c", cmd])

    @Slot(str)
    def openUrl(self, url):
        QDesktopServices.openUrl(QUrl(url))

    @Slot()
    def installSystem(self):
        QProcess.startDetached("/usr/bin/zorza-install", [])

    @Slot(bool)
    def finishWelcome(self, show_again):
        state = Path.home() / ".config/zorza"
        state.mkdir(parents=True, exist_ok=True)
        f = state / "welcome-done"
        if show_again:
            f.unlink(missing_ok=True)
        else:
            f.touch()

    @Property(bool, constant=True)
    def welcomeAutostart(self):
        return not (Path.home() / ".config/zorza/welcome-done").exists()

    # ------------------------------------------------------------------ updates
    @Slot()
    def runUpdates(self):
        if self._proc is not None:
            return
        self._update_log = ""
        self._update_state = "running"
        self.updateChanged.emit()
        script = (
            "set -e; export DEBIAN_FRONTEND=noninteractive; "
            "echo '▶ apt update'; apt-get update; "
            "echo '▶ apt full-upgrade'; apt-get -y -o Dpkg::Options::=--force-confold full-upgrade; "
            "apt-get -y autoremove --purge; "
            "if command -v flatpak >/dev/null; then echo '▶ flatpak update'; flatpak update -y --noninteractive --system || true; fi; "
            "echo '✔ OK'"
        )
        self._proc = QProcess(self)
        self._proc.setProcessChannelMode(QProcess.MergedChannels)
        self._proc.readyReadStandardOutput.connect(self._on_update_output)
        self._proc.finished.connect(self._on_update_finished)
        self._proc.start("pkexec", ["/bin/sh", "-c", script])

    def _on_update_output(self):
        data = bytes(self._proc.readAllStandardOutput()).decode(errors="replace")
        self._update_log += data
        if len(self._update_log) > 60000:
            self._update_log = self._update_log[-60000:]
        self.updateChanged.emit()

    def _on_update_finished(self, code, _status):
        self._update_state = "done" if code == 0 else "error"
        if code in (126, 127):
            self._update_log += "\n" + ("Anulowano uwierzytelnianie." if self._pl else "Authentication cancelled.")
        self._proc.deleteLater()
        self._proc = None
        self.updateChanged.emit()

    @Slot(result=int)
    def pendingUpdates(self):
        out = _sh("apt list --upgradable 2>/dev/null | tail -n +2 | wc -l", timeout=20)
        try:
            return int(out)
        except ValueError:
            return -1

    # ------------------------------------------------------------------ system info
    @Slot(result="QVariantMap")
    def systemInfo(self):
        info = {}
        osr = {}
        try:
            for line in Path("/etc/os-release").read_text().splitlines():
                if "=" in line:
                    k, v = line.split("=", 1)
                    osr[k] = v.strip('"')
        except Exception:
            pass
        info["os"] = osr.get("PRETTY_NAME", "Zorza OS")
        info["base"] = "Debian " + (_sh("cat /etc/debian_version") or "13")
        info["kernel"] = platform.release()
        info["arch"] = platform.machine()
        info["hostname"] = platform.node()
        info["desktop"] = "KDE Plasma " + (_sh("plasmashell --version").replace("plasmashell", "").strip() or "6")
        info["session"] = os.environ.get("XDG_SESSION_TYPE", "?").capitalize()

        cpu = ""
        try:
            txt = Path("/proc/cpuinfo").read_text()
            m = re.search(r"model name\s*:\s*(.+)", txt) or re.search(r"Hardware\s*:\s*(.+)", txt)
            cpu = m.group(1).strip() if m else ""
        except Exception:
            pass
        if not cpu:
            cpu = _sh("lscpu | sed -n 's/^Model name:\\s*//p' | head -n1") or platform.processor() or platform.machine()
        info["cpu"] = f"{cpu} · {os.cpu_count()} " + ("wątków" if self._pl else "threads")

        try:
            import psutil
            vm = psutil.virtual_memory()
            info["ram"] = f"{_human(vm.used)} / {_human(vm.total)}"
            info["ramPct"] = vm.percent / 100.0
            du = psutil.disk_usage("/")
            info["disk"] = f"{_human(du.used)} / {_human(du.total)}"
            info["diskPct"] = du.percent / 100.0
            up = int(psutil.boot_time())
            import time
            secs = int(time.time()) - up
            info["uptime"] = f"{secs // 3600} h {secs % 3600 // 60} min"
        except Exception:
            info["ram"] = info["disk"] = info["uptime"] = "?"
            info["ramPct"] = info["diskPct"] = 0.0

        gpu = _sh("lspci 2>/dev/null | grep -Ei 'vga|3d|display' | sed 's/^[^:]*: //' | head -n2")
        info["gpu"] = gpu.replace("\n", "; ") or ("nieznana" if self._pl else "unknown")

        vendor = _sh("cat /sys/class/dmi/id/sys_vendor 2>/dev/null")
        product = _sh("cat /sys/class/dmi/id/product_name 2>/dev/null")
        info["machine"] = (f"{vendor} {product}".strip()) or _sh("cat /proc/device-tree/model 2>/dev/null | tr -d '\\0'") or "?"
        virt = _sh("systemd-detect-virt 2>/dev/null")
        info["virt"] = virt if virt and virt != "none" else ("brak (sprzęt fizyczny)" if self._pl else "none (bare metal)")
        info["boot"] = "UEFI" if os.path.isdir("/sys/firmware/efi") else "BIOS"
        return info

    @Slot()
    def copySystemInfo(self):
        from PySide6.QtGui import QGuiApplication
        i = self.systemInfo()
        text = "\n".join(f"{k}: {v}" for k, v in i.items() if not k.endswith("Pct"))
        QGuiApplication.clipboard().setText(text)
        self.toast.emit("Skopiowano do schowka" if self._pl else "Copied to clipboard")
