import QtQuick

// `.grp`: rounded list group; children are rows separated by hairlines (`.row + .row`).
Rectangle {
    id: root
    default property alias rows: col.data
    implicitHeight: col.implicitHeight + 2
    radius: 16
    color: Fz.fg(0.04)
    border.width: 1
    border.color: Fz.line
    clip: true
    Column {
        id: col
        x: 1; y: 1
        width: root.width - 2
    }
    // hairlines between visible rows
    Repeater {
        model: col.children.length
        delegate: Rectangle {
            required property int index
            readonly property var it: col.children[index]
            visible: index > 0 && it && it.visible && it.height > 0
            x: 1; width: root.width - 2; height: 1
            y: it ? it.y + 1 : 0
            color: Fz.line
        }
    }
}
