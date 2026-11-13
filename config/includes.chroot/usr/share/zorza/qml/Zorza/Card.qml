import QtQuick
import Zorza

Rectangle {
    id: card
    default property alias content: inner.data
    property int padding: 22
    radius: Style.radius
    color: Style.card
    border.color: Style.border
    border.width: 1
    implicitHeight: inner.childrenRect.height + padding * 2
    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: card.padding
    }
}
