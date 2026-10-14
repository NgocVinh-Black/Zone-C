import QtQuick

// `.sel`: drop-down (36px, base background). options: strings; current: index.
Rectangle {
    id: root
    property var options: []
    property int current: 0
    signal picked(int index)
    implicitWidth: 190
    implicitHeight: 36
    radius: 11
    color: Fz.base
    border.width: 1
    border.color: Fz.line2

    FText { x: 10; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 34; elide: Text.ElideRight; text: root.options[root.current] || ""; px: 13.5 }
    FIcon { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; name: "chev"; size: 14; color: Fz.sub; rotation: 90 }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: list.visible = !list.visible }

    Rectangle {
        id: list
        visible: false
        z: 100
        y: parent.height + 4
        width: parent.width
        height: col.implicitHeight + 8
        radius: 11
        color: Fz.mantle
        border.width: 1; border.color: Fz.line2
        Column {
            id: col
            x: 4; y: 4
            width: parent.width - 8
            Repeater {
                model: root.options
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: col.width; height: 32; radius: 8
                    color: index === root.current ? Fz.acc : (optMouse.containsMouse ? Fz.fg(0.06) : "transparent")
                    FText { x: 8; anchors.verticalCenter: parent.verticalCenter; text: modelData; px: 13; color: index === root.current ? Fz.ink : Fz.tx }
                    MouseArea { id: optMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { root.current = index; root.picked(index); list.visible = false; } }
                }
            }
        }
    }
}
