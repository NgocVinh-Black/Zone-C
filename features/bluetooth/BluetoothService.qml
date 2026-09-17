pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "BluetoothLogic.js" as Logic

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var connectedDevice: enabled ? (adapter.devices.values.find(d => d.connected) ?? null) : null
    readonly property string deviceName: connectedDevice?.name ?? ""
    readonly property string icon: Logic.icon(enabled, connectedDevice !== null)

    function toggle(): void {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }
}
