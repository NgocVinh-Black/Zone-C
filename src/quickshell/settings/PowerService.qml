import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../"

// Background half of Settings → Pin & nguồn: switch to the power-saver profile once the battery drops
// under 20% while discharging (and back to balanced when charging resumes, if we changed it).
Scope {
    readonly property bool enabled: Config.getSetting("power.autoSaver", true) !== false
    readonly property var dev: UPower.displayDevice
    readonly property bool low: dev.ready && dev.isLaptopBattery && dev.percentage < 0.2 && dev.state === UPowerDeviceState.Discharging
    property bool switched: false
    onLowChanged: {
        if (!enabled) return;
        if (low && PowerProfiles.profile !== PowerProfile.PowerSaver) { PowerProfiles.profile = PowerProfile.PowerSaver; switched = true; }
        else if (!low && switched && dev.state !== UPowerDeviceState.Discharging) { PowerProfiles.profile = PowerProfile.Balanced; switched = false; }
    }
}
