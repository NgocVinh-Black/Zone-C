pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth shared by the bluetooth bar widget and the network popup.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false

    readonly property var devices: adapter ? adapter.devices.values : []
    readonly property var connected: devices.filter(d => d.connected)
    // Paired or recently seen devices that are not connected.
    readonly property var nearby: devices.filter(d => !d.connected)

    readonly property string connectedName: connected.length > 0 ? (connected[0].name || connected[0].address) : ""

    function setEnabled(on: bool): void {
        if (adapter)
            adapter.enabled = on;
    }

    function toggle(): void {
        setEnabled(!enabled);
    }

    function setDiscovering(on: bool): void {
        if (adapter && adapter.enabled)
            adapter.discovering = on;
    }

    function connect(device: var): void {
        if (!device)
            return;
        if (!device.paired)
            device.pair();
        device.connect();
    }

    function disconnect(device: var): void {
        device?.disconnect();
    }

    // Battery as 0–100, or -1 when the device doesn't report it.
    function battery(device: var): int {
        return device?.batteryAvailable ? Math.round(device.battery * 100) : -1;
    }
}
