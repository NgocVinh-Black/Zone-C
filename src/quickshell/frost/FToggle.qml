import QtQuick

// `.tg` / `.tg.on`: 44x26 switch.
Rectangle {
    id: root
    property bool on: false
    signal toggled(bool value)

    implicitWidth: 44
    implicitHeight: 26
    radius: 13
    color: on ? Fz.acc : Fz.s1
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        width: 20; height: 20; radius: 10
        y: 3
        x: root.on ? 21 : 3
        color: root.on ? Fz.ink : Fz.knob
        Behavior on x { NumberAnimation { duration: 150 } }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { let v = !root.on; root.toggled(v); if (root.on !== v) root.on = v; } }
}
