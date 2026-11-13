import QtQuick
import Zorza

Item {
    id: sw
    property bool checked: false
    signal toggled(bool value)
    implicitWidth: 52; implicitHeight: 30
    Rectangle {
        anchors.fill: parent; radius: height / 2
        color: sw.checked ? Style.accent : (Style.dark ? "#2A3166" : "#D5D7E8")
        Behavior on color { ColorAnimation { duration: 150 } }
        Rectangle {
            width: 24; height: 24; radius: 12; color: "white"
            anchors.verticalCenter: parent.verticalCenter
            x: sw.checked ? parent.width - width - 3 : 3
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
    }
    MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        onClicked: { sw.checked = !sw.checked; sw.toggled(sw.checked) }
    }
}
