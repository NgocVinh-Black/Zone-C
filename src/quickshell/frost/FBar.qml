import QtQuick

// `.bar`: 6px progress track with accent fill.
Rectangle {
    property real value: 0      // 0..1
    property color fill: Fz.acc
    implicitHeight: 6
    radius: 3
    color: Fz.fg(0.1)
    clip: true
    Rectangle { width: parent.width * Math.max(0, Math.min(1, parent.value)); height: parent.height; radius: 3; color: parent.fill }
}
