import QtQuick

// `.sep`: 1x18 divider with 4px side margins.
Item {
    implicitWidth: 9
    implicitHeight: 32
    Rectangle { x: 4; width: 1; height: 18; anchors.verticalCenter: parent.verticalCenter; color: Fz.fg(0.1) }
}
