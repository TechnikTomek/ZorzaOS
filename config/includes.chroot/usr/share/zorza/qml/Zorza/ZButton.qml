import QtQuick
import Zorza

Rectangle {
    id: b
    property string text: ""
    property bool primary: false
    property bool enabledState: true
    signal clicked()
    implicitWidth: Math.max(120, label.implicitWidth + 40)
    implicitHeight: 42
    radius: 14
    opacity: enabledState ? 1.0 : 0.45
    color: primary ? (ma.pressed ? Qt.darker(Style.accent, 1.15) : ma.containsMouse ? Qt.lighter(Style.accent, 1.1) : Style.accent)
                   : (ma.containsMouse ? Style.cardHover : Style.card)
    border.color: primary ? "transparent" : Style.border
    Behavior on color { ColorAnimation { duration: 120 } }
    Text {
        id: label
        anchors.centerIn: parent
        text: b.text
        color: b.primary ? "white" : Style.text
        font.family: Style.font; font.pixelSize: 14; font.weight: Font.DemiBold
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (b.enabledState) b.clicked()
    }
}
