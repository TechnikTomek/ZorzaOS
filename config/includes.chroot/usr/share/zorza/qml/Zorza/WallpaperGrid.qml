import QtQuick
import Zorza

Flow {
    id: grid
    spacing: 14
    property int tileW: 200
    Repeater {
        model: backend.wallpapers
        delegate: Column {
            spacing: 6
            Rectangle {
                width: grid.tileW; height: grid.tileW * 9 / 16; radius: 14
                color: Style.card
                border.width: backend.wallpaper === modelData.id ? 3 : 1
                border.color: backend.wallpaper === modelData.id ? Style.accent : Style.border
                Image {
                    anchors.fill: parent; anchors.margins: 3
                    source: modelData.thumb
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 400
                    asynchronous: true
                }
                Rectangle {
                    anchors.fill: parent; radius: parent.radius; color: "white"
                    opacity: ma.containsMouse ? 0.08 : 0
                }
                MouseArea {
                    id: ma; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backend.setWallpaper(modelData.id)
                }
            }
            Text {
                text: modelData.label; color: Style.muted
                font.family: Style.font; font.pixelSize: 12
            }
        }
    }
}
