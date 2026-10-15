import QtQuick
import QtQuick.Effects

// `.glass`: frosted surface, radius 24, hairline edge and a soft drop shadow.
// Real background blur comes from the compositor (Hyprland layerrule blur on the qs-* namespaces).
Item {
    id: root
    property real radius: 24
    property color color: Fz.glass
    property color borderColor: Fz.light ? Fz.glassEdge : Fz.line
    property bool shadow: true
    default property alias content: inner.data

    OuterShadow {
        visible: root.shadow
        radius: root.radius
        offsetY: Fz.light ? 20 : 30
        blur: Fz.light ? 50 : 70
        color: Fz.light ? Qt.rgba(31 / 255, 45 / 255, 53 / 255, 0.16) : Qt.rgba(0, 0, 0, 0.38)
    }
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root.radius
        color: root.color
        border.width: 1
        border.color: root.borderColor
        // inset 0 1px 0 rgba(255,255,255,0.05 | 0.7)
        Rectangle {
            x: root.radius * 0.6; y: 1
            width: parent.width - root.radius * 1.2; height: 1
            color: Qt.rgba(1, 1, 1, Fz.light ? 0.7 : 0.05)
        }
    }
    Item { id: inner; anchors.fill: parent }
}
