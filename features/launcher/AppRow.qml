import QtQuick
import Quickshell
import qs.core.state
import qs.core.theme
import qs.core.ui

// One result in the launcher list: themed icon, name and description. The selected
// row fills with the accent gradient the way v1's active pills do.
Item {
    id: root

    required property var item
    property bool selected: false
    property color accent: Colours.blue

    signal activated
    signal hovered

    implicitHeight: UiScale.s(64)

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

    Image {
        id: icon

        anchors.left: parent.left
        anchors.leftMargin: UiScale.s(16)
        anchors.verticalCenter: parent.verticalCenter
        width: UiScale.s(38)
        height: width
        sourceSize.width: width
        sourceSize.height: width
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        visible: status === Image.Ready
        source: Quickshell.iconPath(root.item.icon, "application-x-executable")
    }

    Icon {
        anchors.centerIn: icon
        visible: !icon.visible
        text: String.fromCodePoint(0xF0349)
        font.pixelSize: Tokens.font.size.iconLarge
        color: root.selected ? Colours.crust : Colours.subtext0
    }

    Column {
        anchors.left: icon.right
        anchors.leftMargin: UiScale.s(16)
        anchors.right: parent.right
        anchors.rightMargin: UiScale.s(16)
        anchors.verticalCenter: parent.verticalCenter
        spacing: UiScale.s(2)

        StyledText {
            width: parent.width
            text: root.item.name
            elide: Text.ElideRight
            font.weight: Font.Black
            color: root.selected ? Colours.crust : Colours.text

            Behavior on color {
                ColorAnim {}
            }
        }

        StyledText {
            width: parent.width
            visible: text !== ""
            text: root.item.comment ?? ""
            elide: Text.ElideRight
            font.pixelSize: Tokens.font.size.small
            font.weight: Font.Normal
            color: root.selected ? Colours.alpha(Colours.crust, 0.7) : Colours.subtext1

            Behavior on color {
                ColorAnim {}
            }
        }
    }

    HoverArea {
        id: area

        onClicked: root.activated()
        onContainsMouseChanged: {
            if (containsMouse)
                root.hovered();
        }
    }
}
