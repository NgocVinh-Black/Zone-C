import QtQuick
import qs.core.theme
import qs.core.ui

// A bar widget that is a single square block with a glyph, like v1's search and
// notification buttons. The block lightens and grows on hover.
BarWidget {
    id: root

    property string icon: ""
    property int iconSize: Tokens.font.size.weatherIcon
    property color hoverColour: Colours.blue

    signal clicked(var mouse)

    blockInteractive: true
    blockPadding: 0
    implicitWidth: Tokens.iconBlock.size
    implicitHeight: Tokens.iconBlock.size

    Icon {
        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: root.iconSize
        color: area.containsMouse ? root.hoverColour : Colours.text

        Behavior on color {
            ColorAnim {
                duration: 200
            }
        }
    }

    HoverArea {
        id: area

        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => root.clicked(mouse)
    }
}
