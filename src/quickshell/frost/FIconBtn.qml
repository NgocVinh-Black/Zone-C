import QtQuick

// `.ib`, `.ib.on`, `.ib.ghost`: square icon button.
Rectangle {
    id: root
    property string icon: ""
    property real iconSize: 17
    property bool on: false
    property bool ghost: false
    property string label: ""
    property color iconColor: on ? Fz.ink : Fz.tx
    property bool hovered: mouse.containsMouse
    signal clicked()

    implicitWidth: 36
    implicitHeight: 36
    radius: 11
    color: on ? Fz.acc : ghost ? (hovered ? Fz.fg(0.14) : "transparent") : Fz.fg(hovered ? 0.14 : 0.06)
    Accessible.role: Accessible.Button
    Accessible.name: label

    FIcon { anchors.centerIn: parent; name: root.icon; size: root.iconSize; color: root.iconColor }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
