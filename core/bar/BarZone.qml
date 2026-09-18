import QtQuick
import qs.core.theme

// A horizontal run of bar groups (left, center or right).
// Slides in from (enterX, enterY) after `enterDelay`, like the v1 bar at startup.
Row {
    id: root

    required property var groups
    required property var screen
    required property var barWindow

    property real enterX: 0
    property real enterY: 0
    property int enterDelay: 0
    property bool entered: false

    spacing: Tokens.block.gap
    opacity: entered ? 1 : 0

    transform: Translate {
        x: root.entered ? 0 : root.enterX
        y: root.entered ? 0 : root.enterY

        Behavior on x {
            NumberAnimation {
                duration: Tokens.bar.enterDuration
                easing.type: Easing.OutBack
                easing.overshoot: Tokens.bar.enterOvershoot
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: Tokens.bar.enterDuration
                easing.type: Easing.OutBack
                easing.overshoot: Tokens.bar.enterOvershoot
            }
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 600
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        running: true
        interval: root.enterDelay
        onTriggered: root.entered = true
    }

    Repeater {
        model: root.groups

        delegate: BarGroup {
            required property var modelData

            anchors.verticalCenter: parent.verticalCenter
            names: modelData
            screen: root.screen
            barWindow: root.barWindow
        }
    }
}
