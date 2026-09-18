import QtQuick
import qs.core.bar
import qs.core.services
import qs.core.theme
import qs.core.ui
import "BluetoothLogic.js" as Logic

// Bluetooth power and connected device. Click opens the network popup on its
// Bluetooth tab; right click toggles power.
BarWidget {
    id: root

    shown: Bluetooth.available
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Pill {
        id: pill

        icon: Logic.icon(Bluetooth.enabled, Bluetooth.connected.length > 0)
        text: Bluetooth.enabled ? (Bluetooth.connectedName || "Disconnected") : "Off"
        active: Bluetooth.enabled
        accent: Colours.mauve
        startDelay: root.indexInGroup * Tokens.pill.enterStagger
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Bluetooth.toggle();
            else
                root.openPopup("network", "bt");
        }
    }
}
