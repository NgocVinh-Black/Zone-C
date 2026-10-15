import QtQuick
import QtQuick.Effects

// `.solid`: opaque dialog surface (mantle, hairline, radius 24, drop shadow).
Item {
    id: root
    property real radius: 24
    property color color: Fz.mantle
    default property alias content: inner.data
    RectangularShadow {
        anchors.fill: bg; radius: root.radius
        offset.y: Fz.light ? 20 : 30; blur: Fz.light ? 25 : 35   // CSS blur 50 / 70, halved for Qt
        color: Fz.light ? Qt.rgba(31 / 255, 45 / 255, 53 / 255, 0.16) : Qt.rgba(0, 0, 0, 0.38)
    }
    Rectangle { id: bg; anchors.fill: parent; radius: root.radius; color: root.color; border.width: 1; border.color: Fz.line }
    Item { id: inner; anchors.fill: parent }
}
