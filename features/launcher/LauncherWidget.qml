import QtQuick
import qs.core.bar
import qs.core.theme

IconBlockWidget {
    id: root

    icon: String.fromCodePoint(0xF0349)
    iconSize: Tokens.font.size.weatherIcon
    hoverColour: Colours.blue
    onClicked: root.openPopup()
}
