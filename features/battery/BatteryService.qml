pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.core.config
import "BatteryLogic.js" as Logic
import "schema.js" as Schema

// Battery (UPower), power profile (powerprofilesctl), screen brightness (brightnessctl),
// uptime and session actions.
Singleton {
    id: root

    readonly property var settings: Config.feature("battery", Schema.fields)

    readonly property var device: UPower.displayDevice
    readonly property bool available: (device?.ready ?? false) && device.isLaptopBattery
    readonly property int percent: Math.round((device?.percentage ?? 0) * 100)
    readonly property bool charging: device ? (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged) : false
    readonly property string stateText: {
        if (!device)
            return "Unknown";
        switch (device.state) {
        case UPowerDeviceState.Charging:
            return "Charging";
        case UPowerDeviceState.FullyCharged:
            return "Full";
        case UPowerDeviceState.Discharging:
            return "Discharging";
        default:
            return "Not Charging";
        }
    }
    readonly property string icon: Logic.icon(percent, charging)
    readonly property string tone: Logic.tone(percent, charging)

    property string profile: "balanced"
    property int brightness: 0
    property int uptimeHours: 0
    property int uptimeMinutes: 0
    readonly property string userName: Quickshell.env("USER") ?? ""

    function setProfile(name: string): void {
        profile = name;
        Quickshell.execDetached(["powerprofilesctl", "set", name]);
        profileReader.running = true;
    }

    function setBrightness(value: int): void {
        brightness = value;
        brightnessWriter.pending = value;
        if (!brightnessWriter.running)
            brightnessWriter.running = true;
    }

    function run(action: string): void {
        const command = settings[action + "Command"];
        if (command)
            Quickshell.execDetached(command);
    }

    Process {
        id: profileReader

        running: true
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim();
                if (value !== "")
                    root.profile = value;
            }
        }
    }

    Process {
        id: brightnessReader

        running: true
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Format: device,class,current,percent%,max
                const fields = text.trim().split(",");
                const value = parseInt(fields[3], 10);
                if (!isNaN(value) && !brightnessWriter.running)
                    root.brightness = value;
            }
        }
    }

    // Coalesces drag updates: sets the latest value, then catches up if it changed meanwhile.
    Process {
        id: brightnessWriter

        property int pending: -1
        property int sent: -1

        command: ["brightnessctl", "-q", "set", pending + "%"]
        onStarted: sent = pending
        onExited: {
            if (pending !== sent)
                running = true;
        }
    }

    FileView {
        id: uptimeFile

        path: "/proc/uptime"
        onLoaded: {
            const up = Logic.parseUptime(text());
            root.uptimeHours = up.hours;
            root.uptimeMinutes = up.minutes;
        }
    }

    Timer {
        running: true
        repeat: true
        interval: 30000
        onTriggered: {
            uptimeFile.reload();
            profileReader.running = true;
            brightnessReader.running = true;
        }
    }
}
