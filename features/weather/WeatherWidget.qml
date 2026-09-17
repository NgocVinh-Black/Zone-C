import QtQuick
import qs.core.bar
import qs.core.theme
import qs.core.ui
import qs.features.weather

BarWidget {
    id: root

    shown: WeatherService.available
    implicitWidth: row.implicitWidth + Tokens.clock.weatherGap + Tokens.clock.paddingX
    implicitHeight: row.implicitHeight

    Row {
        id: row

        anchors.right: parent.right
        anchors.rightMargin: Tokens.clock.paddingX
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.block.itemGap

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: WeatherService.icon
            font.pixelSize: Tokens.font.size.weatherIcon
            color: Qt.tint(Colours[WeatherService.tone], Colours.alpha(Colours.mauve, 0.4))
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: WeatherService.temperatureText
            font.pixelSize: Tokens.font.size.temperature
            font.weight: Font.Black
            color: Colours.peach
        }
    }
}
