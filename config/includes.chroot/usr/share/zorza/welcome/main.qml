// Zorza OS – Witaj (ekran powitalny po pierwszym uruchomieniu)
import QtQuick
import QtQuick.Window
import Zorza

Window {
    id: win
    width: 980; height: 660
    minimumWidth: 860; minimumHeight: 600
    visible: true
    color: Style.bg
    title: Style.tr("Witaj w Zorza OS", "Welcome to Zorza OS")

    property int page: 0
    readonly property int pages: 5

    // ---------------------------------------------------------------- pasek boczny
    Rectangle {
        id: side
        width: 250; anchors.top: parent.top; anchors.bottom: parent.bottom
        color: Style.sidebar
        Image {
            anchors.fill: parent
            source: "file:///usr/share/zorza/thumbs/Zorza.jpg"
            fillMode: Image.PreserveAspectCrop
            opacity: Style.dark ? 0.35 : 0.18
        }
        Column {
            anchors.left: parent.left; anchors.right: parent.right
            anchors.top: parent.top; anchors.margins: 26
            spacing: 26
            Row {
                spacing: 12
                Image { source: "file:///usr/share/zorza/branding/zorza-logo.png"; width: 44; height: 44; sourceSize.width: 88 }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Zorza OS"; color: Style.text
                    font.family: Style.font; font.pixelSize: 21; font.weight: Font.Bold
                }
            }
            Column {
                spacing: 6
                Repeater {
                    model: [Style.tr("Powitanie", "Welcome"), Style.tr("Wygląd", "Appearance"), Style.tr("Tapeta", "Wallpaper"),
                            Style.tr("Efekty i aplikacje", "Effects & apps"), Style.tr("Gotowe", "Done")]
                    delegate: Rectangle {
                        width: 198; height: 40; radius: 12
                        color: win.page === index ? Style.accent : (ma.containsMouse ? Style.cardHover : "transparent")
                        Row {
                            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 14
                            spacing: 12
                            Rectangle {
                                width: 22; height: 22; radius: 11
                                color: win.page === index ? "white" : "transparent"
                                border.color: win.page === index ? "white" : Style.muted
                                Text {
                                    anchors.centerIn: parent; text: index < win.page ? "✓" : (index + 1)
                                    color: win.page === index ? Style.accent : Style.muted
                                    font.pixelSize: 11; font.weight: Font.Bold
                                }
                            }
                            Text {
                                text: modelData
                                color: win.page === index ? "white" : Style.text
                                font.family: Style.font; font.pixelSize: 14
                                font.weight: win.page === index ? Font.DemiBold : Font.Normal
                            }
                        }
                        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: win.page = index }
                    }
                }
            }
        }
        Text {
            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.margins: 26
            text: "1.0 · Świt"; color: Style.muted
            font.family: Style.font; font.pixelSize: 12
        }
    }

    // ---------------------------------------------------------------- treść
    Item {
        id: content
        anchors.left: side.right; anchors.right: parent.right
        anchors.top: parent.top; anchors.bottom: nav.top
        anchors.margins: 36
        clip: true

        // 1. Powitanie
        Column {
            visible: win.page === 0
            anchors.fill: parent
            spacing: 22
            Item { width: 1; height: 10 }
            Image {
                source: "file:///usr/share/zorza/branding/zorza-wordmark.png"
                width: 360; fillMode: Image.PreserveAspectFit; sourceSize.width: 720
            }
            Heading {
                width: parent.width
                title: Style.tr("Cześć! Miło Cię widzieć.", "Hi! Great to see you.")
                subtitle: Style.tr("Zorza OS to szybki i piękny system oparty na Debianie 13 i KDE Plasma 6. W kilku krokach dopasujesz go do siebie – wszystko możesz później zmienić w System Center.",
                                   "Zorza OS is a fast and beautiful system built on Debian 13 and KDE Plasma 6. In a few steps you can make it yours – everything can be changed later in System Center.")
            }
            Row {
                spacing: 12
                visible: backend.isLive
                Rectangle {
                    width: 10; height: 10; radius: 5; color: "#FFB547"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: Style.tr("Pracujesz w trybie live – zmiany nie zostaną zapisane po restarcie.",
                                   "You are in live mode – changes are lost after a reboot.")
                    color: Style.muted; font.family: Style.font; font.pixelSize: 14
                }
            }
        }

        // 2. Wygląd
        Column {
            visible: win.page === 1
            anchors.fill: parent
            spacing: 26
            Heading { width: parent.width; title: Style.tr("Wybierz styl", "Pick your style")
                      subtitle: Style.tr("Motyw jasny lub ciemny oraz kolor akcentu dla przycisków, folderów i zaznaczeń.",
                                         "Light or dark theme and an accent colour for buttons, folders and selections.") }
            ThemePicker {}
            Text { text: Style.tr("Kolor akcentu", "Accent colour"); color: Style.text; font.family: Style.font; font.pixelSize: 16; font.weight: Font.DemiBold }
            AccentPicker { width: parent.width }
        }

        // 3. Tapeta
        Flickable {
            visible: win.page === 2
            anchors.fill: parent
            contentHeight: wpCol.height
            clip: true
            Column {
                id: wpCol
                width: parent.width
                spacing: 20
                Heading { width: parent.width; title: Style.tr("Tapeta", "Wallpaper")
                          subtitle: Style.tr("Wszystkie tapety powstały proceduralnie dla Zorza OS. „Horyzont” zmienia się z porą dnia.",
                                             "All wallpapers were generated procedurally for Zorza OS. “Horizon” follows the time of day.") }
                WallpaperGrid { width: parent.width; tileW: 196 }
            }
        }

        // 4. Efekty i aplikacje
        Column {
            visible: win.page === 3
            anchors.fill: parent
            spacing: 20
            Heading { width: parent.width; title: Style.tr("Efekty i aplikacje", "Effects & apps") }
            Card {
                width: parent.width
                Row {
                    width: parent.width
                    spacing: 16
                    Column {
                        width: parent.width - 80
                        spacing: 4
                        Text { text: Style.tr("Efekty pulpitu", "Desktop effects"); color: Style.text; font.family: Style.font; font.pixelSize: 16; font.weight: Font.DemiBold }
                        Text {
                            width: parent.width; wrapMode: Text.WordWrap
                            text: Style.tr("Rozmycie paneli i płynne animacje. Bez akceleracji 3D (np. VirtualBox) lepiej je wyłączyć – Zorza zrobiła to automatycznie, jeśli trzeba.",
                                           "Panel blur and smooth animations. Without 3D acceleration (e.g. VirtualBox) it's better to turn them off – Zorza did it automatically if needed.")
                            color: Style.muted; font.family: Style.font; font.pixelSize: 13
                        }
                    }
                    ZSwitch {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: backend.effects
                        onToggled: (v) => backend.setEffects(v)
                    }
                }
            }
            Text { text: Style.tr("Na dobry początek", "Get started"); color: Style.text; font.family: Style.font; font.pixelSize: 16; font.weight: Font.DemiBold }
            Flow {
                width: parent.width; spacing: 12
                Repeater {
                    model: [
                        { t: Style.tr("Sklep z aplikacjami", "App store"), d: "org.kde.discover.desktop" },
                        { t: "System Center", d: "org.zorza.SystemCenter.desktop" },
                        { t: "Firefox", d: "firefox-esr.desktop" },
                        { t: Style.tr("Ustawienia systemowe", "System Settings"), d: "systemsettings.desktop" },
                        { t: Style.tr("Pliki", "Files"), d: "org.kde.dolphin.desktop" }
                    ]
                    delegate: ZButton { text: modelData.t; onClicked: backend.launch(modelData.d) }
                }
            }
        }

        // 5. Gotowe
        Column {
            visible: win.page === 4
            anchors.fill: parent
            spacing: 22
            Heading {
                width: parent.width
                title: backend.isLive ? Style.tr("Spodobało Ci się?", "Do you like it?") : Style.tr("Wszystko gotowe!", "All set!")
                subtitle: backend.isLive
                    ? Style.tr("Zainstaluj Zorza OS na dysku, aby zachować ustawienia i pliki. Instalator przeprowadzi Cię przez to w kilka minut.",
                               "Install Zorza OS to disk to keep your settings and files. The installer will guide you in a few minutes.")
                    : Style.tr("Miłej pracy! Aktualizacje i ustawienia wyglądu znajdziesz w System Center.",
                               "Enjoy! Updates and appearance settings live in System Center.")
            }
            ZButton {
                visible: backend.isLive
                primary: true
                text: Style.tr("Zainstaluj na dysku", "Install to disk")
                width: 240; height: 50
                onClicked: backend.installSystem()
            }
            Row {
                spacing: 14
                ZSwitch { id: again; checked: false }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Style.tr("Pokazuj to okno przy każdym logowaniu", "Show this window at every login")
                    color: Style.text; font.family: Style.font; font.pixelSize: 14
                }
            }
        }
    }

    // ---------------------------------------------------------------- nawigacja
    Item {
        id: nav
        anchors.left: side.right; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 84
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Style.border }
        Row {
            anchors.left: parent.left; anchors.leftMargin: 36; anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Repeater {
                model: win.pages
                Rectangle {
                    width: index === win.page ? 26 : 8; height: 8; radius: 4
                    color: index === win.page ? Style.accent : Style.border
                    Behavior on width { NumberAnimation { duration: 180 } }
                }
            }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 36; anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: backend.busy
                text: Style.tr("Stosowanie…", "Applying…"); color: Style.muted
                font.family: Style.font; font.pixelSize: 13
            }
            ZButton {
                visible: win.page > 0
                text: Style.tr("Wstecz", "Back")
                onClicked: win.page--
            }
            ZButton {
                primary: true
                text: win.page < win.pages - 1 ? Style.tr("Dalej", "Next") : Style.tr("Zakończ", "Finish")
                onClicked: {
                    if (win.page < win.pages - 1) win.page++
                    else { backend.finishWelcome(again.checked); Qt.quit() }
                }
            }
        }
    }

    onClosing: backend.finishWelcome(again.checked)
}
