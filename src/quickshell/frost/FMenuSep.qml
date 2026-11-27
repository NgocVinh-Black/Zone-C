import QtQuick

// `.ms`: hairline between menu groups.
Item {
    width: parent ? parent.width : 240
    implicitHeight: 9
    Rectangle { x: 6; y: 4; width: parent.width - 12; height: 1; color: Fz.fg(0.1) }
}
