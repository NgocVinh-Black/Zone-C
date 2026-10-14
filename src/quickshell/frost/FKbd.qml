import QtQuick

// `.kbd`: key cap.
Rectangle {
    property string text: ""
    implicitWidth: label.implicitWidth + 16
    implicitHeight: 24
    radius: 7
    color: Fz.base
    border.width: 1
    border.color: Fz.line2
    Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 1; height: 1; color: Fz.line2 }
    FText { id: label; anchors.centerIn: parent; anchors.verticalCenterOffset: -0.5; text: parent.text; mono: true; px: 12 }
}
