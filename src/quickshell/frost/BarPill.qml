import QtQuick
import QtQuick.Effects

// `.zb` from TopBar.dc.html: 40px glass pill holding bar items.
Item {
    id: root
    default property alias items: row.data
    property real spacing: 2
    implicitWidth: row.implicitWidth + 8
    implicitHeight: 40

    OuterShadow {
        radius: 14
        offsetY: Fz.light ? 8 : 10
        blur: Fz.light ? 24 : 30
        color: Fz.light ? Qt.rgba(31 / 255, 45 / 255, 53 / 255, 0.14) : Qt.rgba(0, 0, 0, 0.28)
    }
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 14
        color: Fz.surf(Fz.light ? 0.82 : 0.72)
        border.width: 1
        border.color: Fz.light ? Qt.rgba(1, 1, 1, 0.75) : Fz.fg(0.09)
    }
    Row {
        id: row
        x: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.spacing
    }
}
