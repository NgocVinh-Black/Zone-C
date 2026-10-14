import QtQuick

// `.radio` / `.radio.on`
Rectangle {
    property bool on: false
    implicitWidth: 18
    implicitHeight: 18
    radius: 9
    color: "transparent"
    border.width: on ? 5 : 2
    border.color: on ? Fz.acc : Fz.s2
}
