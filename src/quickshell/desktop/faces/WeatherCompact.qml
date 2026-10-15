import QtQuick
import "../../"
import "../../frost"

// "Thời tiết · gọn" (Widgets artboard): icon, temperature, place and sky.
Glass {
    implicitWidth: 300
    implicitHeight: 150
    radius: 22
    readonly property string city: (Weather.activeLocation && Weather.activeLocation.city) ? Weather.activeLocation.city : ""
    Row {
        x: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16
        FIcon { anchors.verticalCenter: parent.verticalCenter; name: Fz.weatherIcon(Weather.currentIcon); size: 54; strokeWidth: 1.2; color: Fz.acc }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            FText { text: Fz.deg(Weather.currentTemp); px: 48; weight: Font.Light; css: 1 }
            FText { text: (city ? city + " · " : "") + Fz.weatherDesc(Weather.currentIcon); color: Fz.sub2; px: 13 }
        }
    }
}
