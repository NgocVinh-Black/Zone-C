import QtQuick

// `.ico` / `.ico.on`: 36px rounded icon tile.
Rectangle {
    property string icon: ""
    property bool on: false
    property real iconSize: 17
    implicitWidth: 36
    implicitHeight: 36
    radius: 11
    color: on ? Fz.acc : Fz.fg(0.07)
    FIcon { anchors.centerIn: parent; name: parent.icon; size: parent.iconSize; color: parent.on ? Fz.ink : Fz.acc }
}
