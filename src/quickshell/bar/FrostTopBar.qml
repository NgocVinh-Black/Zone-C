import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import "../"
import "../frost"

// Horizontal bar of the Frost design (TopBar.dc.html): three glass pills,
// launcher + workspaces + media on the left, clock + weather centred, system status on the right.
Item {
    id: root
    property var barWindow
    anchors.fill: parent

    // Bar.qml reads these to size its input mask.
    readonly property real dynamicMinX: 0
    readonly property real dynamicMaxX: width

    // Which panel is open, so its bar item lights up (`.it.on`).
    property string openWidget: ""
    property bool launcherOpen: LauncherController.isVisible === true
    property bool clipboardOpen: ClipboardController.isVisible === true
    FileView {
        path: Caching.runDir ? Caching.runDir + "/current_widget" : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.openWidget = JSON.parse(text().trim()).widget || ""; } catch (e) { root.openWidget = ""; }
            if (root.openWidget === "hidden") root.openWidget = "";
        }
    }

    function getWidget(name) {
        let map = { left: launcherIt, workspaces: wsIt, media: mediaIt, timedate: clockIt, weather: weatherIt,
                    kb: kbIt, wifi: wifiIt, bt: btIt, vol: volIt, bat: batIt, info: notifIt };
        return map[name] || null;
    }

    // ---------- data ----------
    readonly property var player: MprisController.activePlayer
    readonly property bool hasMedia: player !== null && player.trackTitle !== ""
    readonly property string mediaText: hasMedia ? (player.trackTitle + (player.trackArtist ? " · " + player.trackArtist : "")) : "Không phát nhạc"

    readonly property string ssid: {
        let devs = Networking.devices ? (Networking.devices.values || []) : [];
        for (let i = 0; i < devs.length; i++) {
            let d = devs[i];
            if (d && d.type === DeviceType.Wifi && d.networks) {
                let nets = d.networks.values || [];
                for (let j = 0; j < nets.length; j++) if (nets[j].connected) return nets[j].name;
            }
        }
        return "";
    }
    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btOn: btAdapter ? btAdapter.enabled : false
    readonly property int btConnected: {
        if (!btAdapter || !btAdapter.devices) return 0;
        let n = 0, ds = btAdapter.devices.values || [];
        for (let i = 0; i < ds.length; i++) if (ds[i].connected) n++;
        return n;
    }
    readonly property int volume: Audio.defaultSink && Audio.defaultSink.audio ? Math.round(Audio.defaultSink.audio.volume * 100) : 0
    readonly property bool muted: Audio.defaultSink && Audio.defaultSink.audio ? Audio.defaultSink.audio.muted : false
    readonly property bool hasBattery: UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery
    readonly property int battery: UPower.displayDevice.ready ? Math.round(UPower.displayDevice.percentage * 100) : 0
    readonly property int notifCount: NotificationManager.globalNotificationHistory ? NotificationManager.globalNotificationHistory.count : 0
    property string kbLayout: "VI"
    Process {
        id: kbPoll
        running: true
        command: ["bash", "-c", "if [[ \"$(fcitx5-remote -n 2>/dev/null)\" == \"unikey\" ]]; then echo VI; else l=$(LC_ALL=C hyprctl devices -j 2>/dev/null | jq -r '(.keyboards[] | select(.main == true) | .active_keymap) // empty' | head -n1); echo \"${l:0:2}\" | tr '[:lower:]' '[:upper:]'; fi"]
        stdout: StdioCollector { onStreamFinished: { let t = this.text.trim(); root.kbLayout = (t === "" ? "US" : t); } }
    }
    Timer { interval: 1500; running: true; repeat: true; onTriggered: kbPoll.running = true }

    readonly property int activeWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    function wsOccupied(id) {
        let ws = Hyprland.workspaces.values.find(w => w.id === id);
        return ws !== undefined && ws.toplevels && ws.toplevels.values && ws.toplevels.values.length > 0;
    }

    readonly property bool recording: Rec.active
    // Settings → Thanh bar: modules dropped from every column of bar.modules are hidden
    readonly property var modulesOn: { let m = Config.getSetting("bar.modules", null); if (!m) return null; let out = []; for (const c of ["left", "center", "right"]) (m[c] || []).forEach(x => out = out.concat(Array.isArray(x) ? x : [x])); return out; }
    function shown(k) { return modulesOn === null || modulesOn.indexOf(k) !== -1; }
    readonly property int wsCount: Math.max(1, Math.min(10, Number(Config.getSetting("bar.workspaceCount", 8)) || 8))
    readonly property bool showDate: Config.getSetting("bar.showDate", true) !== false

    // ---------- left: launcher · workspaces · media ----------
    BarPill {
        id: leftPill
        x: 4
        anchors.verticalCenter: parent.verticalCenter

        BarItem {
            id: launcherIt
            visible: root.shown("left")
            padX: 9
            label: "Zone-C: mở launcher"
            on: root.launcherOpen
            onClicked: Fz.open("launcher")
            FIcon { name: "b-zc"; size: 19; color: launcherIt.on ? Fz.ink : Fz.acc; anchors.verticalCenter: parent.verticalCenter }
        }
        BarSep {}
        BarItem {
            id: wsIt
            visible: root.shown("workspaces")
            padX: 8
            label: "Không gian làm việc " + root.activeWs + " trên " + root.wsCount
            onClicked: Fz.open("overview")
            onWheel: (steps) => Hyprland.dispatch("hl.dsp.focus({ workspace = \"" + (steps > 0 ? "e-1" : "e+1") + "\" })")
            Row {
                spacing: 4
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: root.wsCount
                    delegate: Rectangle {
                        required property int index
                        readonly property bool cur: index + 1 === root.activeWs
                        width: cur ? 26 : 8
                        height: 8
                        radius: 4
                        color: cur ? Fz.acc : (root.wsOccupied(index + 1) ? Fz.fg(0.55) : Fz.fg(0.18))
                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (index + 1) + " })") }
                    }
                }
            }
        }
        BarSep {}
        BarItem {
            id: mediaIt
            visible: root.shown("media")
            label: root.mediaText
            on: root.openWidget === "music"
            onClicked: Fz.open("music")
            Row {
                spacing: 2
                height: 14
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: [0.4, 0.9, 0.6, 1.0, 0.5]
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: 2.5
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: mediaIt.on ? Fz.ink : Fz.glow
                        property real level: MprisController.isPlaying ? modelData : 0.25
                        height: 14 * level
                        SequentialAnimation on level {
                            running: MprisController.isPlaying
                            loops: Animation.Infinite
                            NumberAnimation { to: Math.min(1, modelData + 0.35); duration: 260 + index * 70; easing.type: Easing.InOutSine }
                            NumberAnimation { to: Math.max(0.25, modelData - 0.3); duration: 300 + index * 60; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }
            FText {
                text: root.mediaText
                color: mediaIt.fgColor
                px: 13
                weight: Font.Medium
                width: Math.min(implicitWidth, 230 - 20 - 20)
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // ---------- centre: clock · weather ----------
    BarPill {
        id: centerPill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        BarItem {
            visible: root.recording
            label: "Đang quay màn hình"
            onClicked: Fz.open("screenshot")
            FIcon { name: "b-rec"; size: 11; color: "#ff9b9b"; anchors.verticalCenter: parent.verticalCenter }
            FText { mono: true; text: Rec.elapsed; color: "#ff9b9b"; px: 13; weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
        }
        BarSep { visible: root.recording }
        BarItem {
            id: clockIt
            visible: root.shown("timedate")
            on: root.openWidget === "calendar"
            label: "Mở lịch"
            onClicked: Fz.open("calendar")
            FText { mono: true; text: DateTime.timeShort; color: clockIt.fgColor; px: 14; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
            FText { visible: root.showDate; text: Fz.dateShort(DateTime.now); color: clockIt.fgColor; opacity: 0.75; px: 13; weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
        }
        BarSep {}
        BarItem {
            id: weatherIt
            visible: root.shown("weather")
            on: root.openWidget === "calendar"
            label: "Thời tiết"
            onClicked: Fz.open("calendar")
            FIcon { name: Fz.weatherIcon(Weather.currentIcon); size: 15; color: weatherIt.fgColor; anchors.verticalCenter: parent.verticalCenter }
            FText { text: Weather.currentTemp !== "" ? Math.round(Number(Weather.currentTemp)) + "°" : "--°"; color: weatherIt.fgColor; px: 13; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // ---------- right: clipboard · input method | wifi · bt · volume · battery | notifications · settings ----------
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        BarPill {
            BarItem {
                id: clipIt
                visible: root.shown("tray")
                padX: 9
                label: "Clipboard"
                on: root.clipboardOpen
                onClicked: Fz.open("clipboard")
                onRightClicked: Fz.open("tray")
                FIcon { name: "b-clip"; size: 15; color: clipIt.fgColor; anchors.verticalCenter: parent.verticalCenter }
            }
            BarItem {
                id: kbIt
                visible: root.shown("kb")
                padX: 9
                label: root.kbLayout === "VI" ? "Bộ gõ Tiếng Việt" : "Bàn phím " + root.kbLayout
                onClicked: { Quickshell.execDetached(["fcitx5-remote", "-t"]); kbPoll.running = true; }
                FText { text: root.kbLayout; color: kbIt.fgColor; px: 12; weight: Font.Bold; font.letterSpacing: 0.5; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        BarPill {
            BarItem {
                id: wifiIt
                visible: root.shown("wifi")
                on: root.openWidget === "network"
                label: root.ssid !== "" ? "Wi-Fi " + root.ssid : "Wi-Fi"
                onClicked: Fz.open("network", "wifi")
                // EmptyStates: no network → red "Ngoại tuyến"
                readonly property bool offline: root.wifiOn && root.ssid === ""
                readonly property color tint: offline && !on ? Fz.redTx : fgColor
                FIcon { name: root.wifiOn && root.ssid !== "" ? "b-wifi" : "x-wifioff"; size: 15; color: wifiIt.tint; anchors.verticalCenter: parent.verticalCenter }
                FText { text: !root.wifiOn ? "Tắt" : (root.ssid !== "" ? root.ssid : "Ngoại tuyến"); color: wifiIt.tint; px: 13; weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
            }
            BarItem {
                id: btIt
                visible: root.shown("bt")
                label: "Bluetooth, " + root.btConnected + " thiết bị đã kết nối"
                onClicked: Fz.open("network", "bt")
                FIcon { name: root.btOn ? "b-bt" : "x-btoff"; size: 15; color: btIt.fgColor; opacity: root.btOn || btIt.on ? 1 : 0.55; anchors.verticalCenter: parent.verticalCenter }
                FText { text: root.btOn ? "Bluetooth" : "Tắt"; opacity: root.btOn || btIt.on ? 1 : 0.55; color: btIt.fgColor; px: 13; weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                    visible: root.btConnected > 0
                    width: Math.max(16, btBadge.implicitWidth + 8); height: 16; radius: 8
                    color: btIt.on ? Fz.ink : Fz.acc
                    anchors.verticalCenter: parent.verticalCenter
                    FText { id: btBadge; anchors.centerIn: parent; text: root.btConnected; color: btIt.on ? Fz.acc : Fz.ink; px: 10.5; weight: Font.Bold }
                }
            }
            BarItem {
                id: volIt
                visible: root.shown("vol")
                padX: 9
                on: root.openWidget === "volume"
                label: "Âm lượng " + root.volume + " phần trăm"
                onClicked: Fz.open("volume")
                onRightClicked: if (Audio.defaultSink) Audio.toggleMute(Audio.defaultSink)
                onWheel: (steps) => { if (Audio.defaultSink) Audio.setVolume(Audio.defaultSink, Math.max(0, Math.min(1.5, Audio.defaultSink.audio.volume + steps * 0.05))); }
                FIcon { name: root.muted ? "mute" : "b-vol"; size: 15; color: volIt.fgColor; anchors.verticalCenter: parent.verticalCenter }
            }
            BarItem {
                id: batIt
                visible: root.shown("bat") && (root.hasBattery)
                on: root.openWidget === "system"
                label: "Pin " + root.battery + " phần trăm, mở bảng hệ thống"
                onClicked: Fz.open("system")
                Item {
                    width: 24; height: 12
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        anchors.fill: parent; radius: 4; color: "transparent"
                        border.width: 1.5; border.color: batIt.fgColor
                        Rectangle { x: 3; y: 3; height: parent.height - 6; width: (parent.width - 6) * root.battery / 100; radius: 1.5; color: batIt.fgColor }
                    }
                    Rectangle { x: parent.width + 2; y: 4; width: 2; height: 4; radius: 1; color: batIt.fgColor }
                }
                FText { mono: true; text: root.battery; color: batIt.fgColor; px: 12; anchors.verticalCenter: parent.verticalCenter }
            }
            BarItem {
                // desktop without a battery (EmptyStates): plug + AC
                id: acIt
                visible: root.shown("bat") && !root.hasBattery
                on: root.openWidget === "system"
                label: "Nguồn điện AC, mở bảng hệ thống"
                onClicked: Fz.open("system")
                FIcon { name: "x-plug"; size: 15; color: acIt.fgColor; anchors.verticalCenter: parent.verticalCenter }
                FText { text: "AC"; color: acIt.fgColor; px: 13; weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
            }
            BarSep {}
            BarItem {
                id: notifIt
                on: root.openWidget === "system"
                label: root.notifCount + " thông báo"
                onClicked: Fz.open("system")
                FIcon { name: "b-bell"; size: 15; color: notifIt.fgColor; anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                    visible: root.notifCount > 0
                    width: Math.max(16, notifBadge.implicitWidth + 8); height: 16; radius: 8
                    color: notifIt.on ? Fz.ink : Fz.acc
                    anchors.verticalCenter: parent.verticalCenter
                    FText { id: notifBadge; anchors.centerIn: parent; text: root.notifCount; color: notifIt.on ? Fz.acc : Fz.ink; px: 10.5; weight: Font.Bold }
                }
            }
            BarItem {
                id: gearIt
                padX: 9
                on: root.openWidget === "guide"
                label: "Cài đặt"
                onClicked: Fz.open("guide")
                FIcon { name: "b-gear"; size: 15; color: gearIt.fgColor; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
