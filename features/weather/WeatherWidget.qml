import QtQuick
import qs.core.bar
import qs.core.services
import qs.core.theme
import qs.core.ui

// Weather icon and temperature. Shares the clock's block, so a click opens the calendar.
BarWidget {
    id: root

    shown: Weather.available
    blockInteractive: true
    blockHoverScale: Tokens.clock.hoverScale
    implicitWidth: row.implicitWidth + Tokens.clock.paddingX * 2
    implicitHeight: Tokens.bar.height

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.block.itemGap

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: Weather.icon
            font.pixelSize: Tokens.font.size.weatherIcon
            color: Qt.tint(Colours[Weather.tone], Colours.alpha(Colours.mauve, 0.4))
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Weather.temperatureText
            font.pixelSize: Tokens.font.size.temperature
            font.weight: Font.Black
            color: Colours.peach
        }
    }

    HoverArea {
        onClicked: root.openPopup("clock")
    }
}
