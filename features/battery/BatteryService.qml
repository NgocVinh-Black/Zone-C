pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "BatteryLogic.js" as Logic

Singleton {
    readonly property var device: UPower.displayDevice
    readonly property bool available: (device?.ready ?? false) && device.isLaptopBattery
    readonly property int percent: Math.round((device?.percentage ?? 0) * 100)
    readonly property bool charging: device ? (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged) : false
    readonly property string icon: Logic.icon(percent, charging)
    readonly property string tone: Logic.tone(percent, charging)
}
