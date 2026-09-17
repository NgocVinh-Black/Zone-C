pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "NetworkLogic.js" as Logic

// Network state from NetworkManager (nmcli). Refreshes on `nmcli monitor` events
// and periodically for wifi signal strength.
Singleton {
    id: root

    property bool available: false
    property string kind: "none" // "wifi" | "ethernet" | "none"
    property string name: ""
    property int strength: 0
    property bool wifiEnabled: false

    readonly property bool connected: kind !== "none"
    readonly property string icon: kind === "ethernet" ? Logic.ETHERNET_ICON : Logic.wifiIcon(wifiEnabled, strength)

    function refresh(): void {
        if (!status.running)
            status.running = true;
    }

    function setWifiEnabled(enabled: bool): void {
        Quickshell.execDetached(["nmcli", "radio", "wifi", enabled ? "on" : "off"]);
    }

    Process {
        id: status

        running: true
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION device status; echo '<<zone-c>>'; nmcli -t -f ACTIVE,SIGNAL,SSID device wifi list --rescan no; echo '<<zone-c>>'; nmcli radio wifi"]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("<<zone-c>>\n");
                if (parts.length < 3) {
                    root.available = false;
                    return;
                }
                const s = Logic.parseStatus(parts[0], parts[1], parts[2]);
                root.kind = s.kind;
                root.name = s.name;
                root.strength = s.strength;
                root.wifiEnabled = s.wifiEnabled;
                root.available = true;
            }
        }

        onExited: code => {
            if (code !== 0)
                console.warn("[zone-c network] nmcli exited with", code);
        }
    }

    Process {
        running: true
        command: ["nmcli", "monitor"]

        stdout: SplitParser {
            onRead: debounce.restart()
        }
    }

    Timer {
        id: debounce

        interval: 500
        onTriggered: root.refresh()
    }

    Timer {
        running: true
        repeat: true
        interval: 30 * 1000
        onTriggered: root.refresh()
    }
}
