import QtQuick
import qs.core.theme

// A glyph that highlights and grows on hover, like the v1 media controls.
Item {
    id: root

    property alias icon: glyph.text
    property int iconSize: Tokens.font.size.icon
    property color colour: Colours.overlay2
    property color hoverColour: Colours.text
    property real hoverScale: 1.1

    signal clicked

    readonly property bool hovered: area.containsMouse

    implicitWidth: Tokens.media.control
    implicitHeight: Tokens.media.control

    Icon {
        id: glyph

        anchors.centerIn: parent
        font.pixelSize: root.iconSize
        color: root.hovered ? root.hoverColour : root.colour
        scale: root.hovered ? root.hoverScale : 1

        Behavior on color {
            ColorAnim {
                duration: Tokens.anim.fast
            }
        }

        Behavior on scale {
            Anim {
                duration: Tokens.anim.normal
                easing.type: Easing.OutBack
            }
        }
    }

    HoverArea {
        id: area

        onClicked: root.clicked()
    }
}
