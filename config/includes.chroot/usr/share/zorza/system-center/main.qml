// Zorza OS – System Center
import QtQuick
import QtQuick.Window
import Zorza

Window {
    id: win
    width: 1060; height: 700
    minimumWidth: 900; minimumHeight: 600
    visible: true
    color: Style.bg
    title: "System Center"

    property int page: 0
    property var info: backend.systemInfo()

    Timer { interval: 5000; running: win.page === 0; repeat: true; onTriggered: win.info = backend.systemInfo() }

    // ---------------------------------------------------------------- nawigacja
    Rectangle {
        id: side
        width: 240; anchors.top: parent.top; anchors.bottom: parent.bottom
        color: Style.sidebar
        Column {
            anchors.fill: parent; anchors.margins: 22
            spacing: 22
            Row {
                spacing: 12
                Image { source: "file:///usr/share/zorza/branding/zorza-logo.png"; width: 40; height: 40; sourceSize.width: 80 }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "System Center"; color: Style.text; font.family: Style.font; font.pixelSize: 17; font.weight: Font.Bold }
                    Text { text: "Zorza OS"; color: Style.muted; font.family: Style.font; font.pixelSize: 12 }
                }
            }
            Column {
                spacing: 6
                Repeater {
                    model: [
                        { g: "◉", t: Style.tr("Przegląd", "Overview") },
                        { g: "◐", t: Style.tr("Wygląd", "Appearance") },
                        { g: "▦", t: Style.tr("Tapety", "Wallpapers") },
                        { g: "⟳", t: Style.tr("Aktualizacje", "Updates") }
                    ]
                    delegate: Rectangle {
                        width: 196; height: 42; radius: 12
                        color: win.page === index ? Style.accent : (ma.containsMouse ? Style.cardHover : "transparent")
                        Row {
                            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 14; spacing: 12
                            Text { text: modelData.g; color: win.page === index ? "white" : Style.muted; font.pixelSize: 16 }
                            Text { text: modelData.t; color: win.page === index ? "white" : Style.text
                                   font.family: Style.font; font.pixelSize: 14; font.weight: win.page === index ? Font.DemiBold : Font.Normal }
                        }
                        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: win.page = index }
                    }
                }
            }
        }
        Text {
            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.margins: 22
            visible: backend.busy
            text: Style.tr("Stosowanie zmian…", "Applying…"); color: Style.muted
            font.family: Style.font; font.pixelSize: 12
        }
    }

    Item {
        anchors.left: side.right; anchors.right: parent.right
        anchors.top: parent.top; anchors.bottom: parent.bottom
        anchors.margins: 32

        // ------------------------------------------------------------ Przegląd
        Flickable {
            visible: win.page === 0
            anchors.fill: parent; contentHeight: ov.height; clip: true
            Column {
                id: ov
                width: parent.width; spacing: 18
                Row {
                    spacing: 20
                    Image { source: "file:///usr/share/zorza/branding/zorza-logo.png"; width: 84; height: 84; sourceSize.width: 168 }
                    Heading {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 560
                        title: win.info.os
                        subtitle: win.info.base + " · " + win.info.desktop + " · " + win.info.session
                    }
                }
                Grid {
                    columns: 2; columnSpacing: 16; rowSpacing: 16
                    width: parent.width
                    Repeater {
                        model: [
                            { k: Style.tr("Komputer", "Computer"), v: win.info.machine },
                            { k: Style.tr("Procesor", "Processor"), v: win.info.cpu },
                            { k: Style.tr("Grafika", "Graphics"), v: win.info.gpu },
                            { k: Style.tr("Jądro", "Kernel"), v: win.info.kernel + " (" + win.info.arch + ")" },
                            { k: Style.tr("Wirtualizacja", "Virtualisation"), v: win.info.virt },
                            { k: Style.tr("Rozruch / czas pracy", "Boot / uptime"), v: win.info.boot + " · " + win.info.uptime }
                        ]
                        delegate: Card {
                            width: (ov.width - 16) / 2
                            Column {
                                width: parent.width; spacing: 4
                                Text { text: modelData.k; color: Style.muted; font.family: Style.font; font.pixelSize: 12 }
                                Text { text: modelData.v; color: Style.text; font.family: Style.font; font.pixelSize: 15
                                       width: parent.width; wrapMode: Text.WordWrap }
                            }
                        }
                    }
                }
                Repeater {
                    model: [
                        { k: Style.tr("Pamięć RAM", "Memory"), v: win.info.ram, p: win.info.ramPct },
                        { k: Style.tr("Dysk systemowy", "System disk"), v: win.info.disk, p: win.info.diskPct }
                    ]
                    delegate: Card {
                        width: ov.width
                        Column {
                            width: parent.width; spacing: 10
                            Row {
                                width: parent.width
                                Text { text: modelData.k; color: Style.text; font.family: Style.font; font.pixelSize: 15; font.weight: Font.DemiBold; width: parent.width / 2 }
                                Text { text: modelData.v; color: Style.muted; font.family: Style.font; font.pixelSize: 14; width: parent.width / 2; horizontalAlignment: Text.AlignRight }
                            }
                            Rectangle {
                                width: parent.width; height: 10; radius: 5; color: Style.border
                                Rectangle {
                                    height: parent.height; radius: 5; width: parent.width * Math.max(0.02, modelData.p)
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0; color: Style.accent }
                                        GradientStop { position: 1; color: "#FF6FA3" }
                                    }
                                }
                            }
                        }
                    }
                }
                Row {
                    spacing: 12
                    ZButton { text: Style.tr("Kopiuj informacje", "Copy details"); onClicked: backend.copySystemInfo() }
                    ZButton { text: Style.tr("Ustawienia systemowe", "System Settings"); onClicked: backend.launch("systemsettings.desktop") }
                    ZButton { text: Style.tr("Monitor systemu", "System Monitor"); onClicked: backend.launch("org.kde.plasma-systemmonitor.desktop") }
                    ZButton { visible: backend.isLive; primary: true; text: Style.tr("Zainstaluj na dysku", "Install to disk"); onClicked: backend.installSystem() }
                }
            }
        }

        // ------------------------------------------------------------ Wygląd
        Flickable {
            visible: win.page === 1
            anchors.fill: parent; contentHeight: ap.height; clip: true
            Column {
                id: ap
                width: parent.width; spacing: 22
                Heading { width: parent.width; title: Style.tr("Wygląd", "Appearance")
                          subtitle: Style.tr("Motyw, kolor akcentu i efekty pulpitu.", "Theme, accent colour and desktop effects.") }
                ThemePicker {}
                Text { text: Style.tr("Kolor akcentu", "Accent colour"); color: Style.text; font.family: Style.font; font.pixelSize: 16; font.weight: Font.DemiBold }
                AccentPicker { width: parent.width }
                Card {
                    width: parent.width
                    Row {
                        width: parent.width; spacing: 16
                        Column {
                            width: parent.width - 80; spacing: 4
                            Text { text: Style.tr("Efekty (rozmycie, animacje)", "Effects (blur, animations)"); color: Style.text; font.family: Style.font; font.pixelSize: 15; font.weight: Font.DemiBold }
                            Text { width: parent.width; wrapMode: Text.WordWrap; color: Style.muted; font.family: Style.font; font.pixelSize: 13
                                   text: Style.tr("Wyłącz, jeśli komputer lub maszyna wirtualna nie ma akceleracji 3D – pulpit będzie płynniejszy.",
                                                  "Turn off when the computer or VM has no 3D acceleration – the desktop will feel smoother.") }
                        }
                        ZSwitch { anchors.verticalCenter: parent.verticalCenter; checked: backend.effects; onToggled: (v) => backend.setEffects(v) }
                    }
                }
            }
        }

        // ------------------------------------------------------------ Tapety
        Flickable {
            visible: win.page === 2
            anchors.fill: parent; contentHeight: wp.height; clip: true
            Column {
                id: wp
                width: parent.width; spacing: 20
                Heading { width: parent.width; title: Style.tr("Tapety", "Wallpapers")
                          subtitle: Style.tr("Kliknij, aby ustawić. „Horyzont (dynamiczna)” zmienia się o świcie, w dzień, o zmierzchu i w nocy.",
                                             "Click to apply. “Horizon (dynamic)” changes at dawn, day, dusk and night.") }
                WallpaperGrid { width: parent.width; tileW: 230 }
            }
        }

        // ------------------------------------------------------------ Aktualizacje
        Column {
            visible: win.page === 3
            anchors.fill: parent; spacing: 18
            Heading {
                width: parent.width
                title: Style.tr("Aktualizacje", "Updates")
                subtitle: backend.updateState === "running" ? Style.tr("Trwa aktualizacja – nie wyłączaj komputera…", "Updating – please keep the computer on…")
                        : backend.updateState === "done" ? Style.tr("System jest aktualny ✔", "System is up to date ✔")
                        : backend.updateState === "error" ? Style.tr("Aktualizacja nie powiodła się – szczegóły poniżej.", "Update failed – see details below.")
                        : Style.tr("Pakiety systemowe (APT) i aplikacje Flatpak jednym kliknięciem.", "System packages (APT) and Flatpak apps in one click.")
            }
            Row {
                spacing: 12
                ZButton {
                    primary: true
                    enabledState: backend.updateState !== "running"
                    text: Style.tr("Zaktualizuj wszystko", "Update everything")
                    width: 220; height: 48
                    onClicked: backend.runUpdates()
                }
                ZButton { text: "Discover"; onClicked: backend.launch("org.kde.discover.desktop") }
            }
            Rectangle {
                width: parent.width; height: parent.height - 170
                radius: 14; color: "#0B0F22"; border.color: Style.border
                Flickable {
                    id: logView
                    anchors.fill: parent; anchors.margins: 14
                    contentHeight: logText.height; clip: true
                    Text {
                        id: logText
                        width: parent.width
                        text: backend.updateLog.length ? backend.updateLog : Style.tr("Dziennik pojawi się tutaj.", "The log will appear here.")
                        color: "#C8CCE8"; font.family: "JetBrains Mono"; font.pixelSize: 12
                        wrapMode: Text.WrapAnywhere
                        onTextChanged: logView.contentY = Math.max(0, logText.height - logView.height)
                    }
                }
            }
        }
    }

    // komunikat (toast)
    Rectangle {
        id: toast
        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 24
        width: toastText.implicitWidth + 40; height: 40; radius: 20
        color: Style.accent; opacity: 0
        Text { id: toastText; anchors.centerIn: parent; color: "white"; font.family: Style.font; font.pixelSize: 14 }
        NumberAnimation on opacity { id: fadeOut; to: 0; duration: 400; running: false }
        Timer { id: toastTimer; interval: 1800; onTriggered: fadeOut.start() }
    }
    Connections {
        target: backend
        function onToast(msg) { toastText.text = msg; toast.opacity = 1; toastTimer.restart() }
    }
}
