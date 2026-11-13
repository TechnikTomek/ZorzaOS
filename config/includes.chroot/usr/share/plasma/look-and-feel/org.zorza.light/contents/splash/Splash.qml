// Zorza OS – ekran ładowania sesji (KSplash)
import QtQuick

Rectangle {
    id: root
    color: "#F4F5FB"
    property int stage

    onStageChanged: {
        if (stage == 2) { intro.running = true }
    }

    Gradient {
        id: grad
        GradientStop { position: 0.0; color: "#1B2350" }
        GradientStop { position: 1.0; color: "#0E1530" }
    }
    Rectangle { anchors.fill: parent; gradient: "light" === "dark" ? grad : null; color: "#F4F5FB" }

    Item {
        id: content
        anchors.centerIn: parent
        width: 360; height: 300
        opacity: 0

        Image {
            id: logo
            anchors.horizontalCenter: parent.horizontalCenter
            source: "file:///usr/share/zorza/branding/zorza-logo.png"
            width: 128; height: 128
            sourceSize.width: 256; sourceSize.height: 256
            smooth: true
        }
        Text {
            id: name
            anchors.top: logo.bottom; anchors.topMargin: 22
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Zorza OS"
            font.family: "Inter"; font.pixelSize: 30; font.weight: Font.DemiBold
            color: "#1E2140"
        }
        Row {
            anchors.top: name.bottom; anchors.topMargin: 28
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            Repeater {
                model: 6
                Rectangle {
                    width: 9; height: 9; radius: 4.5
                    color: index < root.stage ? "#7C5CFF" : "#3A3F72"
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }
        }
    }

    OpacityAnimator {
        id: intro
        target: content; from: 0; to: 1; duration: 600
        easing.type: Easing.OutCubic
    }
    Component.onCompleted: intro.running = true
}
