import QtQuick
import qs.core.bar
import qs.core.theme
import qs.core.ui
import qs.features.battery

// Always filled; green while charging, red at 20% or less.
BarWidget {
    id: root

    shown: BatteryService.available
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Pill {
        id: pill

        icon: BatteryService.icon
        text: BatteryService.percent + "%"
        active: true
        accent: Colours[BatteryService.tone]
        startDelay: root.indexInGroup * Tokens.pill.enterStagger
        onClicked: root.openPopup()
    }
}
