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
    property string ssid: ""
    property int strength: 0
    property string security: ""
    property string freq: ""
    property string ip: ""
    property bool wifiEnabled: false
    property string wifiDevice: ""
    // [{ ssid, signal, security, freq, active }]
    property var networks: []
    // SSIDs with a connection attempt in progress.
    property var connecting: ({})

    readonly property bool connected: kind !== "none"
    readonly property string icon: kind === "ethernet" ? Logic.ETHERNET_ICON : Logic.wifiIcon(wifiEnabled, strength)

    function wifiIcon(signal: int): string {
        return Logic.wifiIcon(true, signal);
    }

    function refresh(): void {
        if (!status.running)
            status.running = true;
        else
            status.again = true;
    }

    function rescan(): void {
        Quickshell.execDetached(["nmcli", "device", "wifi", "rescan"]);
        debounce.restart();
    }

    function setWifiEnabled(on: bool): void {
        wifiEnabled = on;
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]);
        debounce.restart();
    }

    function toggleWifi(): void {
        setWifiEnabled(!wifiEnabled);
    }

    // Connects using a saved profile, or an open network. Secured networks without
    // a saved profile need a password, which this popup does not ask for.
    function connectTo(name: string): void {
        const next = Object.assign({}, connecting);
        next[name] = true;
        connecting = next;
        connectProcess.target = name;
        connectProcess.running = true;
    }

    function disconnectWifi(): void {
        if (wifiDevice !== "")
            Quickshell.execDetached(["nmcli", "device", "disconnect", wifiDevice]);
        debounce.restart();
    }

    Process {
        id: status

        property bool again: false

        running: true
        command: ["sh", "-c", "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status; echo '<<zone-c>>'; nmcli -t -f IN-USE,SIGNAL,SECURITY,FREQ,SSID device wifi list --rescan no; echo '<<zone-c>>'; nmcli radio wifi; echo '<<zone-c>>'; dev=$(nmcli -t -f DEVICE,TYPE device status | awk -F: '$2==\"wifi\"{print $1; exit}'); [ -n \"$dev\" ] && nmcli -g IP4.ADDRESS device show \"$dev\""]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("<<zone-c>>\n");
                // Unexpected output: keep the last known state.
                if (parts.length < 4) {
                    console.warn("[zone-c network] unexpected nmcli output, keeping last state");
                    return;
                }
                const s = Logic.parseStatus(parts[0], parts[1], parts[2], parts[3]);
                root.kind = s.kind;
                root.ssid = s.kind === "wifi" ? s.name : "";
                root.strength = s.strength;
                root.security = s.security;
                root.freq = s.freq;
                root.ip = s.ip;
                root.wifiEnabled = s.wifiEnabled;
                root.wifiDevice = s.wifiDevice;
                root.networks = s.networks;
                root.available = true;
            }
        }

        onExited: code => {
            if (code !== 0)
                console.warn("[zone-c network] nmcli exited with", code);
            if (again) {
                again = false;
                running = true;
            }
        }
    }

    Process {
        id: connectProcess

        property string target: ""

        command: ["nmcli", "device", "wifi", "connect", target]
        onExited: code => {
            if (code !== 0)
                console.warn("[zone-c network] could not connect to", target, "- a saved profile or open network is required");
            const next = Object.assign({}, root.connecting);
            delete next[target];
            root.connecting = next;
            root.refresh();
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
