import QtQuick
import qs.core.bar
import qs.core.theme
import qs.core.ui
import qs.features.battery
import "BatteryLogic.js" as Logic

// Tinted by level (blue, yellow, red); filled while charging (green) or low.
BarWidget {
    id: root

    shown: BatteryService.available
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Pill {
        id: pill

        icon: BatteryService.icon
        text: BatteryService.percent + "%"
        active: Logic.filled(BatteryService.percent, BatteryService.charging)
        accent: Colours[BatteryService.tone]
        contentColour: active ? Colours.base : Colours[BatteryService.tone]
        startDelay: root.indexInGroup * Tokens.pill.enterStagger
        onClicked: root.openPopup()
    }
}
