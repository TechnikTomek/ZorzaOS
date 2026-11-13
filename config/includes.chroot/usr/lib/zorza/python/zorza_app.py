"""Wspólny start aplikacji QML Zorza OS."""
import os
import sys

os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")

from PySide6.QtGui import QFont, QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine

sys.path.insert(0, os.path.dirname(__file__))
from zorza_backend import Backend  # noqa: E402

QML_ROOT = "/usr/share/zorza"


def run(app_dir, app_name, desktop_id):
    app = QGuiApplication(sys.argv)
    app.setApplicationName(app_name)
    app.setOrganizationName("Zorza OS")
    app.setDesktopFileName(desktop_id)
    app.setWindowIcon(QIcon.fromTheme("zorza", QIcon("/usr/share/icons/hicolor/256x256/apps/zorza.png")))
    app.setFont(QFont("Inter", 10))
    engine = QQmlApplicationEngine()
    engine.addImportPath(os.path.join(QML_ROOT, "qml"))
    backend = Backend()
    engine.rootContext().setContextProperty("backend", backend)
    engine.load(os.path.join(QML_ROOT, app_dir, "main.qml"))
    if not engine.rootObjects():
        sys.exit(1)
    code = app.exec()
    # Najpierw niszczymy silnik QML, potem backend (bez ostrzeżeń przy zamykaniu)
    del engine
    del backend
    sys.exit(code)
