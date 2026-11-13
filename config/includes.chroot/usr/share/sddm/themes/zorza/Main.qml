// Zorza OS – ekran logowania SDDM (Qt 6)
import QtQuick
import QtQuick.Window

Rectangle {
    id: root
    width: Screen.width > 0 ? Screen.width : 1920
    height: Screen.height > 0 ? Screen.height : 1080
    color: "#0E1530"

    readonly property color accent: config.accent ? config.accent : "#7C5CFF"
    readonly property color fg: "#F4F5FB"
    readonly property color muted: "#A8ACD0"
    readonly property string fontName: config.font ? config.font : "Inter"
    readonly property bool pl: Qt.locale().name.indexOf("pl") === 0
    function tr(plText, enText) { return pl ? plText : enText }

    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0

    Image {
        id: bg
        anchors.fill: parent
        source: config.background ? config.background : "background.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#660E1530" }
            GradientStop { position: 0.6; color: "#330E1530" }
            GradientStop { position: 1.0; color: "#AA0E1530" }
        }
    }

    // ---------------------------------------------------------------- zegar
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.height * 0.11
        spacing: 4
        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.fontName; font.pixelSize: 96; font.weight: Font.Light
            color: root.fg
            text: Qt.formatTime(new Date(), "HH:mm")
        }
        Text {
            id: date
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.fontName; font.pixelSize: 20
            color: root.muted
            text: new Date().toLocaleDateString(Qt.locale(), "dddd, d MMMM")
        }
        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: {
                clock.text = Qt.formatTime(new Date(), "HH:mm")
                date.text = new Date().toLocaleDateString(Qt.locale(), "dddd, d MMMM")
            }
        }
    }

    // ---------------------------------------------------------------- karta logowania
    Rectangle {
        id: card
        width: 400; height: 400
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.height * 0.08
        radius: 28
        color: "#B3161B36"
        border.color: "#33FFFFFF"; border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 18

            // avatar
            Item {
                width: 112; height: 112
                anchors.horizontalCenter: parent.horizontalCenter
                Rectangle {
                    anchors.fill: parent; radius: width / 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "#2FD4C4" }
                        GradientStop { position: 0.5; color: root.accent }
                        GradientStop { position: 1; color: "#FF6FA3" }
                    }
                }
                Rectangle {
                    anchors.fill: parent; anchors.margins: 4; radius: width / 2
                    color: "#1B2350"; clip: true
                    Image {
                        id: avatar
                        anchors.fill: parent
                        source: userList.currentItem ? userList.currentItem.iconPath : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: !avatar.visible
                        text: (userList.currentItem ? userList.currentItem.display : "?").charAt(0).toUpperCase()
                        font.family: root.fontName; font.pixelSize: 46; font.weight: Font.DemiBold
                        color: root.fg
                    }
                }
            }

            // wybór użytkownika ‹ Imię ›
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14
                Text {
                    text: "‹"; color: userModel.count > 1 ? root.muted : "transparent"
                    font.pixelSize: 26
                    MouseArea { anchors.fill: parent; onClicked: userList.decrementCurrentIndex() }
                }
                Text {
                    text: userList.currentItem ? userList.currentItem.display : ""
                    color: root.fg
                    font.family: root.fontName; font.pixelSize: 22; font.weight: Font.DemiBold
                }
                Text {
                    text: "›"; color: userModel.count > 1 ? root.muted : "transparent"
                    font.pixelSize: 26
                    MouseArea { anchors.fill: parent; onClicked: userList.incrementCurrentIndex() }
                }
            }

            ListView {
                id: userList
                width: 0; height: 0; visible: false
                model: userModel
                currentIndex: root.userIndex
                delegate: Item {
                    property string display: model.realName ? model.realName : model.name
                    property string login: model.name
                    property string iconPath: model.icon ? model.icon : ""
                }
            }

            // hasło
            Rectangle {
                width: parent.width; height: 50; radius: 16
                color: "#26FFFFFF"
                border.color: password.activeFocus ? root.accent : "#33FFFFFF"
                border.width: password.activeFocus ? 2 : 1
                TextInput {
                    id: password
                    anchors.fill: parent; anchors.leftMargin: 18; anchors.rightMargin: 54
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    color: root.fg
                    font.family: root.fontName; font.pixelSize: 17
                    focus: true
                    clip: true
                    Keys.onReturnPressed: root.doLogin()
                    Keys.onEnterPressed: root.doLogin()
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: password.text.length === 0
                        text: root.tr("Hasło", "Password")
                        color: root.muted
                        font: password.font
                    }
                }
                Rectangle {
                    width: 38; height: 38; radius: 12
                    anchors.right: parent.right; anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: loginMouse.containsMouse ? Qt.lighter(root.accent, 1.15) : root.accent
                    Text { anchors.centerIn: parent; text: "→"; color: "white"; font.pixelSize: 20 }
                    MouseArea { id: loginMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.doLogin() }
                }
            }

            Text {
                id: message
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: "#FF8FA8"
                font.family: root.fontName; font.pixelSize: 14
                text: ""
            }

            // sesja
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.muted
                font.family: root.fontName; font.pixelSize: 13
                text: root.tr("Sesja: ", "Session: ") + (sessionList.currentItem ? sessionList.currentItem.sname : "") + "  ⌄"
                MouseArea {
                    anchors.fill: parent
                    onClicked: sessionList.currentIndex = (sessionList.currentIndex + 1) % Math.max(1, sessionModel.rowCount())
                }
            }
            ListView {
                id: sessionList
                width: 0; height: 0; visible: false
                model: sessionModel
                currentIndex: root.sessionIndex
                delegate: Item { property string sname: model.name }
            }
        }

        SequentialAnimation {
            id: shake
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -14; duration: 50 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 14; duration: 80 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -8; duration: 70 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 0; duration: 60 }
        }
    }

    function doLogin() {
        message.text = root.tr("Logowanie…", "Signing in…")
        sddm.login(userList.currentItem.login, password.text, sessionList.currentIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            password.text = ""
            message.text = root.tr("Nieprawidłowe hasło", "Wrong password")
            shake.start()
            password.forceActiveFocus()
        }
        function onLoginSucceeded() { message.text = "" }
    }

    // ---------------------------------------------------------------- przyciski zasilania
    Row {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 36
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16
        Repeater {
            model: [
                { label: root.tr("Uśpij", "Sleep"), glyph: "☾", act: "suspend", ok: sddm.canSuspend },
                { label: root.tr("Uruchom ponownie", "Restart"), glyph: "↻", act: "reboot", ok: sddm.canReboot },
                { label: root.tr("Wyłącz", "Shut down"), glyph: "⏻", act: "poweroff", ok: sddm.canPowerOff }
            ]
            delegate: Rectangle {
                visible: modelData.ok
                width: 150; height: 44; radius: 22
                color: pm.containsMouse ? "#40FFFFFF" : "#26FFFFFF"
                border.color: "#33FFFFFF"
                Row {
                    anchors.centerIn: parent; spacing: 8
                    Text { text: modelData.glyph; color: root.fg; font.pixelSize: 16 }
                    Text { text: modelData.label; color: root.fg; font.family: root.fontName; font.pixelSize: 14 }
                }
                MouseArea {
                    id: pm; anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        if (modelData.act === "suspend") sddm.suspend()
                        else if (modelData.act === "reboot") sddm.reboot()
                        else sddm.powerOff()
                    }
                }
            }
        }
    }

    // logo w rogu
    Row {
        anchors.left: parent.left; anchors.bottom: parent.bottom
        anchors.margins: 32
        spacing: 12
        Image { source: "logo.png"; width: 36; height: 36; sourceSize.width: 72; sourceSize.height: 72 }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Zorza OS"; color: root.fg
            font.family: root.fontName; font.pixelSize: 18; font.weight: Font.DemiBold
        }
    }

    // układ klawiatury
    Text {
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.margins: 36
        color: root.muted
        font.family: root.fontName; font.pixelSize: 14
        text: keyboard.layouts.length > 0 ? "⌨ " + keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : ""
        MouseArea {
            anchors.fill: parent
            onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
