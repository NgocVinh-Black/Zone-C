import QtQuick

// `.row`: 56px min-height list row, 10/16 padding, items centred with a 14px gap.
Item {
    id: root
    default property alias content: row.data
    property real padY: 10
    width: parent ? parent.width : 0
    implicitHeight: Math.max(56, row.implicitHeight + padY * 2)
    Row {
        id: row
        x: 16
        width: root.width - 32
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14
    }
}
