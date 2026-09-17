import QtQuick
import qs.core.bar
import qs.core.theme
import qs.core.ui
import qs.features.bluetooth

BarWidget {
    id: root

    shown: BluetoothService.available
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Pill {
        id: pill

        icon: BluetoothService.icon
        text: BluetoothService.deviceName
        active: BluetoothService.enabled
        accent: Colours.mauve
        startDelay: root.indexInGroup * Tokens.pill.enterStagger
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                BluetoothService.toggle();
            else
                root.openPopup();
        }
    }
}
