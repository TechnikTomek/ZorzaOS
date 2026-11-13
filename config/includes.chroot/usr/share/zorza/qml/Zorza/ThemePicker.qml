import QtQuick
import Zorza

Row {
    spacing: 18
    Repeater {
        model: [
            { dark: true,  label: Style.tr("Ciemny", "Dark"),  img: "file:///usr/share/zorza/branding/theme-dark.png" },
            { dark: false, label: Style.tr("Jasny", "Light"), img: "file:///usr/share/zorza/branding/theme-light.png" }
        ]
        delegate: Column {
            spacing: 8
            Rectangle {
                width: 240; height: 135; radius: 16
                color: "transparent"
                border.width: backend.dark === modelData.dark ? 3 : 1
                border.color: backend.dark === modelData.dark ? Style.accent : Style.border
                Image {
                    anchors.fill: parent; anchors.margins: 4
                    source: modelData.img
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 480
                    layer.enabled: false
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: backend.setDark(modelData.dark)
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.label; color: Style.text
                font.family: Style.font; font.pixelSize: 14; font.weight: Font.DemiBold
            }
        }
    }
}
