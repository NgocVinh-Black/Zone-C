import QtQuick
import qs.core.state
import qs.core.theme

// Horizontal 0–100 slider drawn as a rounded track with a gradient fill (v1 style).
// `value` follows the outside until the user drags; `moved` reports new values.
Item {
    id: root

    property real value: 0
    property color colorStart: Colours.blue
    property color colorEnd: Qt.lighter(colorStart, 1.15)
    property color trackColor: Colours.alpha(Colours.white, 0.05)
    property color trackBorder: Colours.alpha(Colours.white, 0.1)
    property bool dimmed: false
    property int radius: height / 2

    readonly property bool dragging: area.pressed
    readonly property bool hovered: area.containsMouse

    signal moved(int value)

    implicitHeight: Scale.s(18)

    property real shownValue: value

    onValueChanged: {
        if (!area.pressed && !settle.running)
            shownValue = value;
    }

    // After a drag, hold the dragged value briefly so a stale poll can't snap it back.
    Timer {
        id: settle

        interval: 800
        onTriggered: root.shownValue = root.value
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.trackColor
        border.color: root.trackBorder
        border.width: 1
        clip: true

        Rectangle {
            height: parent.height
            width: parent.width * Math.max(0, Math.min(100, root.shownValue)) / 100
            radius: root.radius
            opacity: root.dimmed ? 0.5 : (area.containsMouse ? 1 : 0.85)

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: root.colorStart

                    Behavior on color {
                        ColorAnimation { duration: 300 }
                    }
                }

                GradientStop {
                    position: 1
                    color: root.colorEnd

                    Behavior on color {
                        ColorAnimation { duration: 300 }
                    }
                }
            }

            Behavior on width {
                enabled: !area.pressed
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuint
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function update(mx: real): void {
            const pct = Math.max(0, Math.min(100, Math.round(mx / width * 100)));
            root.shownValue = pct;
            root.moved(pct);
        }

        onPressed: mouse => {
            settle.stop();
            update(mouse.x);
        }
        onPositionChanged: mouse => {
            if (pressed)
                update(mouse.x);
        }
        onReleased: settle.restart()
    }
}
