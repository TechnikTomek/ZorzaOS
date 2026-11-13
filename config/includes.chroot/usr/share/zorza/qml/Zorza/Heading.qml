import QtQuick
import Zorza

Column {
    property alias title: t.text
    property alias subtitle: s.text
    spacing: 6
    Text { id: t; color: Style.text; font.family: Style.font; font.pixelSize: 28; font.weight: Font.Bold }
    Text { id: s; color: Style.muted; font.family: Style.font; font.pixelSize: 15; visible: text.length > 0; wrapMode: Text.WordWrap; width: parent.width }
}
