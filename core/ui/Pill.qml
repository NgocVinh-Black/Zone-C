import QtQuick
import qs.core.theme

// Status pill from the v1 bar: icon + label on a translucent surface.
// When `active`, a horizontal accent gradient fills it and content turns dark.
Item {
    id: root

    property string icon: ""
    property string text: ""
    property bool active: false
    property color accent: Colours.blue
    property int startDelay: 0

    signal clicked(var mouse)
    signal scrolled(var wheel)

    readonly property bool hovered: area.containsMouse
    property real enterOffset: Tokens.pill.enterOffset

    implicitWidth: row.implicitWidth + Tokens.pill.paddingX * 2
    implicitHeight: Tokens.pill.height
    scale: hovered ? Tokens.pill.hoverScale : 1
    opacity: 0

    transform: Translate {
        y: root.enterOffset
    }

    Behavior on implicitWidth {
        Anim {
            duration: Tokens.anim.slow
            easing.type: Easing.OutQuint
        }
    }

    Behavior on scale {
        Anim {}
    }

    Behavior on opacity {
        Anim {
            duration: Tokens.anim.slow
        }
    }

    Behavior on enterOffset {
        Anim {
            duration: Tokens.anim.slow
            easing.type: Easing.OutBack
        }
    }

    Timer {
        running: true
        interval: root.startDelay
        onTriggered: {
            root.opacity = 1;
            root.enterOffset = 0;
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Tokens.pill.radius
        color: root.hovered ? Colours.alpha(Colours.surface1, Tokens.pill.hoverAlpha) : Colours.alpha(Colours.surface0, Tokens.pill.alpha)

        Behavior on color {
            ColorAnim {}
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Tokens.pill.radius
        opacity: root.active ? 1 : 0

        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: root.accent
            }

            GradientStop {
                position: 1
                color: Qt.lighter(root.accent, Tokens.pill.accentLighter)
            }
        }

        Behavior on opacity {
            Anim {}
        }
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.pill.spacing

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.active ? Colours.base : (root.hovered ? Colours.text : Colours.subtext0)

            Behavior on color {
                ColorAnim {}
            }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.text !== ""
            width: Math.min(implicitWidth, Tokens.pill.maxTextWidth)
            text: root.text
            elide: Text.ElideRight
            font.pixelSize: Tokens.font.size.pill
            font.weight: Font.Black
            color: root.active ? Colours.base : Colours.text

            Behavior on color {
                ColorAnim {}
            }
        }
    }

    HoverArea {
        id: area

        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.scrolled(wheel)
    }
}
