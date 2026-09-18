import QtQuick
import qs.core.bar
import qs.core.theme
import qs.features.launcher

IconBlockWidget {
    icon: String.fromCodePoint(0xF0349)
    iconSize: Tokens.font.size.weatherIcon
    hoverColour: Colours.blue
    onClicked: LauncherService.open()
}
