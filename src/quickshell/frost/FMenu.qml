import QtQuick

// `.menu`: glass context menu, 6px padding, items stacked with 1px gaps.
Glass {
    id: root
    default property alias items: col.data
    radius: 16
    width: Math.max(240, col.implicitWidth + 12)
    height: col.implicitHeight + 12
    MouseArea { anchors.fill: parent }    // clicks between items stay in the menu
    Column {
        id: col
        x: 6; y: 6
        width: root.width - 12
        spacing: 1
    }
}
