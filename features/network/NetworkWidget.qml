import QtQuick
import qs.core.bar
import qs.core.theme
import qs.core.ui
import qs.features.network

BarWidget {
    id: root

    shown: NetworkService.available
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Pill {
        id: pill

        icon: NetworkService.icon
        text: {
            if (NetworkService.kind === "ethernet")
                return "Ethernet";
            if (NetworkService.kind === "wifi")
                return NetworkService.name || "On";
            return NetworkService.wifiEnabled ? "On" : "Off";
        }
        active: NetworkService.connected
        accent: Colours.blue
        startDelay: root.indexInGroup * Tokens.pill.enterStagger
        onClicked: root.openPopup()
    }
}
