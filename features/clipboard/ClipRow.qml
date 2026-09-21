import QtQuick
import qs.core.state
import qs.core.theme
import qs.core.ui

// One clipboard entry: a type glyph and the collapsed preview. Images show what
// cliphist knows about them (format, size) rather than a decoded thumbnail.
Item {
    id: root

    required property var entry
    property bool selected: false
    property color accent: Colours.mauve

    signal activated
    signal removed
    signal hovered

    implicitHeight: UiScale.s(56)

    Rectangle {
        anchors.fill: parent
        radius: UiScale.s(14)
        color: area.containsMouse ? Colours.alpha(Colours.surface1, 0.6) : Colours.alpha(Colours.surface0, 0.35)

        Behavior on color {
            ColorAnim {}
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: UiScale.s(14)
        opacity: root.selected ? 1 : 0

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
            Anim {
                duration: Tokens.anim.fast
            }
        }
    }

    // Declared before the trash button so that button's own area stays on top.
    HoverArea {
        id: area

        onClicked: root.activated()
        onContainsMouseChanged: {
            if (containsMouse)
                root.hovered();
        }
    }

    Icon {
        id: kind

        anchors.left: parent.left
        anchors.leftMargin: UiScale.s(18)
        anchors.verticalCenter: parent.verticalCenter
        text: root.entry.image ? String.fromCodePoint(0xF021F) : String.fromCodePoint(0xF0219)
        font.pixelSize: Tokens.font.size.iconLarge
        color: root.selected ? Colours.crust : Colours.subtext0

        Behavior on color {
            ColorAnim {}
        }
    }

    StyledText {
        anchors.left: kind.right
        anchors.leftMargin: UiScale.s(16)
        anchors.right: trash.left
        anchors.rightMargin: UiScale.s(12)
        anchors.verticalCenter: parent.verticalCenter
        text: root.entry.label
        elide: Text.ElideRight
        font.weight: root.entry.image ? Font.Normal : Font.Bold
        color: root.selected ? Colours.crust : Colours.text

        Behavior on color {
            ColorAnim {}
        }
    }

    IconButton {
        id: trash

        anchors.right: parent.right
        anchors.rightMargin: UiScale.s(12)
        anchors.verticalCenter: parent.verticalCenter
        opacity: area.containsMouse || root.selected ? 1 : 0
        icon: String.fromCodePoint(0xF0A7A)
        colour: root.selected ? Colours.alpha(Colours.crust, 0.7) : Colours.subtext0
        hoverColour: root.selected ? Colours.crust : Colours.red

        onClicked: root.removed()

        Behavior on opacity {
            Anim {
                duration: Tokens.anim.fast
            }
        }
    }
}
