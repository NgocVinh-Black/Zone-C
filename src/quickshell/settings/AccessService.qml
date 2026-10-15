import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"
import "../frost"

// Background half of Settings → Trợ năng: screen flash on notifications, the on-screen keyboard and
// the screen reader (started while their toggles are on), mono audio, and zoom in/out via IPC.
Scope {
    id: svc
    readonly property bool flash: Config.getSetting("access.flash", false) === true
    readonly property bool osk: Config.getSetting("access.osk", false) === true
    readonly property bool orca: Config.getSetting("access.orca", false) === true
    readonly property bool mono: Config.getSetting("access.mono", false) === true

    // visual bell
    property bool flashing: false
    Connections { target: NotificationManager; function onPopupAdded(uid, n) { if (svc.flash) { svc.flashing = true; flashTimer.restart(); } } }
    Timer { id: flashTimer; interval: 260; onTriggered: svc.flashing = false }
    Variants {
        model: svc.flashing ? Quickshell.screens : []
        PanelWindow {
            required property var modelData
            screen: modelData
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "zone-c-flash"
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            mask: Region {}
            color: Qt.rgba(1, 1, 1, 0.28)
        }
    }

    Process { running: svc.osk; command: ["bash", "-c", "exec wvkbd-mobintl -L 280"] }
    Process { running: svc.orca; command: ["orca", "--replace"] }

    onMonoChanged: {
        if (!Config.dataReady) return;
        Quickshell.execDetached(["bash", "-c", svc.mono
            ? "m=$(pactl get-default-sink); pactl list short modules | grep -q zone_c_mono || pactl load-module module-remap-sink sink_name=zone_c_mono sink_properties=device.description=Mono master=\"$m\" channels=1 channel_map=mono >/dev/null; pactl set-default-sink zone_c_mono"
            : "for i in $(pactl list short modules | awk '/zone_c_mono/{print $1}'); do pactl unload-module $i; done"]);
    }

    IpcHandler {
        target: "access"
        function zoom(dir: string): void {
            let cur = Number(Config.getSetting("access.zoomLevel", 200)) || 200;
            let on = Config.getSetting("access.zoom", false) === true;
            let lvl = dir === "out" ? Math.max(100, cur - 25) : Math.min(400, (on ? cur : 100) + 25);
            Config.setSetting("access.zoomLevel", lvl);
            Config.setSetting("access.zoom", lvl > 100);
            HyprConf.set("cursor.zoom_factor", lvl / 100);
        }
    }
}
