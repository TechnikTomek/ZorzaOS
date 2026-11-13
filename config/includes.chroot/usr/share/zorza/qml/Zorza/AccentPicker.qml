import QtQuick
import Zorza

Flow {
    spacing: 14
    Repeater {
        model: backend.accents
        delegate: Column {
            spacing: 6
            width: 70
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 48; height: 48; radius: 24
                color: modelData.color
                border.width: backend.accent === modelData.id ? 3 : 0
                border.color: Style.text
                scale: ma.containsMouse ? 1.08 : 1.0
                Behavior on scale { NumberAnimation { duration: 120 } }
                Text {
                    anchors.centerIn: parent; text: "✓"; color: "white"
                    font.pixelSize: 20; font.weight: Font.Bold
                    visible: backend.accent === modelData.id
                }
                MouseArea {
                    id: ma; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backend.setAccent(modelData.id)
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.label; color: Style.muted
                font.family: Style.font; font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                width: parent.width; wrapMode: Text.WordWrap
            }
        }
    }
}
