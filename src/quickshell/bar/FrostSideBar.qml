import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import "../"
import "../frost"

// Vertical bar of the Frost design (SideBar.dc.html), used when the bar sits on the left or right:
// launcher, workspace dots and music on top, a two-line clock with weather in the middle, status
// items at the bottom. The music button opens a compact player next to the bar.
Item {
    id: root
    property var barWindow
    // window is wider than the bar (shadow room); keep the 52px bar on its edge
    height: parent ? parent.height : 0
    width: 60
    x: onRight && parent ? parent.width - width : 0
    visible: barWindow ? barWindow.isVertical : false
    readonly property bool onRight: barWindow ? barWindow.barPosition === "right" : false
    function getWidget(name) { return null; }

    property string openWidget: ""
    FileView {
        path: Caching.runDir ? Caching.runDir + "/current_widget" : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { root.openWidget = JSON.parse(text().trim()).widget || ""; } catch (e) { root.openWidget = ""; } }
    }

    // ---------- data ----------
    readonly property int wsCount: Math.max(1, Math.min(10, Number(Config.getSetting("bar.workspaceCount", 8)) || 8))
    readonly property int activeWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    function wsOccupied(id) { let ws = Hyprland.workspaces.values.find(w => w.id === id); return ws !== undefined && ws.toplevels && ws.toplevels.values && ws.toplevels.values.length > 0; }
    readonly property string ssid: {
        let devs = Networking.devices ? (Networking.devices.values || []) : [];
        for (const d of devs) if (d && d.type === DeviceType.Wifi && d.networks) for (const n of (d.networks.values || [])) if (n.connected) return n.name;
        return "";
    }
    // the band of the connected network (5G / 2.4) as the short label of the design
    readonly property string wifiShort: ssid === "" ? "" : (/5g|5ghz/i.test(ssid) ? "5G" : ssid.length <= 4 ? ssid : ssid.slice(0, 3))
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property int btConnected: bt && bt.devices ? (bt.devices.values || []).filter(d => d.connected).length : 0
    readonly property int volume: Audio.defaultSink && Audio.defaultSink.audio ? Math.round(Audio.defaultSink.audio.volume * 100) : 0
    readonly property bool muted: Audio.defaultSink && Audio.defaultSink.audio ? Audio.defaultSink.audio.muted : false
    readonly property bool hasBattery: UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery
    readonly property int battery: UPower.displayDevice.ready ? Math.round(UPower.displayDevice.percentage * 100) : 0
    readonly property int notifCount: NotificationManager.globalNotificationHistory ? NotificationManager.globalNotificationHistory.count : 0
    property string kbLayout: "VI"
    Process {
        id: kbPoll
        running: root.visible
        command: ["bash", "-c", "if [[ \"$(fcitx5-remote -n 2>/dev/null)\" == \"unikey\" ]]; then echo VI; else l=$(LC_ALL=C hyprctl devices -j 2>/dev/null | jq -r '(.keyboards[] | select(.main == true) | .active_keymap) // empty' | head -n1); echo \"${l:0:2}\" | tr '[:lower:]' '[:upper:]'; fi"]
        stdout: StdioCollector { onStreamFinished: { let t = this.text.trim(); root.kbLayout = t === "" ? "US" : t; } }
    }
    Timer { interval: 1500; running: root.visible; repeat: true; onTriggered: kbPoll.running = true }
    property bool musicOpen: false

    Column {
        id: top
        x: root.onRight ? root.width - width - 4 : 4; y: 4
        Sb {
            Si { onClicked: Fz.open("launcher"); FIcon { name: "v-zc"; size: 20; color: Fz.acc; anchors.horizontalCenter: parent.horizontalCenter } }
            Hs {}
            Item {
                width: 40; height: wsCol.implicitHeight + 12
                Column {
                    id: wsCol
                    anchors.centerIn: parent
                    spacing: 5
                    Repeater {
                        model: root.wsCount
                        delegate: Rectangle {
                            required property int index
                            readonly property bool cur: index + 1 === root.activeWs
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 8; height: cur ? 24 : 8; radius: 4
                            color: cur ? Fz.acc : (root.wsOccupied(index + 1) ? Fz.fg(0.55) : Fz.fg(0.18))
                            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (index + 1) + " })") }
                        }
                    }
                }
                MouseArea { anchors.fill: parent; z: -1; onClicked: Fz.open("overview")
                            onWheel: (w) => Hyprland.dispatch("hl.dsp.focus({ workspace = \"" + (w.angleDelta.y > 0 ? "e-1" : "e+1") + "\" })") }
            }
            Hs {}
            Si { on: root.musicOpen; onClicked: root.musicOpen = !root.musicOpen; FIcon { name: "v-music"; size: 16; color: parent.parent.fg; anchors.horizontalCenter: parent.horizontalCenter } }
        }
    }

    Sb {
        x: root.onRight ? root.width - width - 4 : 4
        anchors.verticalCenter: parent.verticalCenter
        padY: 10; gap: 0
        MouseArea { width: 40; height: clockCol.implicitHeight; cursorShape: Qt.PointingHandCursor; onClicked: Fz.open("calendar")
            Column {
                id: clockCol
                anchors.horizontalCenter: parent.horizontalCenter
                FText { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(DateTime.now, DateTime.is12Hour ? "hh" : "HH"); mono: true; px: 17; weight: Font.DemiBold; css: 1.1 }
                FText { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(DateTime.now, "mm"); mono: true; px: 17; weight: Font.DemiBold; css: 1.1 }
                FText { anchors.horizontalCenter: parent.horizontalCenter; topPadding: 4; text: Fz.dayShort(DateTime.now) + " " + DateTime.now.getDate(); px: 10; color: Fz.sub }
                Item { width: 1; height: 8 }
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 20; height: 1; color: Fz.fg(0.1) }
                Item { width: 1; height: 8 }
                FIcon { anchors.horizontalCenter: parent.horizontalCenter; name: Fz.weatherIcon(Weather.currentIcon); size: 16; color: Fz.acc }
                FText { anchors.horizontalCenter: parent.horizontalCenter; topPadding: 2; text: Weather.currentTemp !== "" ? Math.round(Number(Weather.currentTemp)) + "°" : "--°"; px: 11; weight: Font.DemiBold }
            }
        }
    }

    Column {
        x: root.onRight ? root.width - width - 4 : 4
        anchors.bottom: parent.bottom; anchors.bottomMargin: 4
        Sb {
            Si { onClicked: { Quickshell.execDetached(["fcitx5-remote", "-t"]); kbPoll.running = true; }
                 FText { anchors.horizontalCenter: parent.horizontalCenter; text: root.kbLayout; px: 11; weight: Font.DemiBold; color: parent.parent.fg } }
            Si { on: root.openWidget === "network"; onClicked: Fz.open("network", "wifi")
                 FIcon { anchors.horizontalCenter: parent.horizontalCenter; name: Networking.wifiEnabled && root.ssid !== "" ? "v-wifi" : "x-wifioff"; size: 16; color: root.ssid === "" && Networking.wifiEnabled && !parent.parent.on ? Fz.redTx : parent.parent.fg }
                 FText { visible: root.wifiShort !== ""; anchors.horizontalCenter: parent.horizontalCenter; text: root.wifiShort; px: 10.5; weight: Font.DemiBold; color: parent.parent.fg } }
            Si { onClicked: Fz.open("network", "bt"); opacity: root.bt && root.bt.enabled ? 1 : 0.55
                 FIcon { anchors.horizontalCenter: parent.horizontalCenter; name: root.bt && root.bt.enabled ? "v-bt" : "x-btoff"; size: 16; color: parent.parent.fg }
                 FText { visible: root.btConnected > 0; anchors.horizontalCenter: parent.horizontalCenter; text: root.btConnected; px: 10.5; weight: Font.DemiBold; color: parent.parent.fg } }
            Si { on: root.openWidget === "volume"; onClicked: Fz.open("volume")
                 onWheelSteps: (s) => { if (Audio.defaultSink) Audio.setVolume(Audio.defaultSink, Math.max(0, Math.min(150, root.volume + s * 5))); }
                 FIcon { anchors.horizontalCenter: parent.horizontalCenter; name: root.muted ? "v-mute" : "v-vol"; size: 16; color: parent.parent.fg }
                 FText { anchors.horizontalCenter: parent.horizontalCenter; text: root.volume; px: 10.5; weight: Font.DemiBold; color: parent.parent.fg } }
            Si { on: root.openWidget === "system"; onClicked: Fz.open("system"); padY: 6
                 Rectangle { visible: root.hasBattery; anchors.horizontalCenter: parent.horizontalCenter; width: 12; height: 22; radius: 4; color: "transparent"; border.width: 1.5; border.color: parent.parent.fg
                             Rectangle { anchors.bottom: parent.bottom; anchors.bottomMargin: 3; anchors.horizontalCenter: parent.horizontalCenter; width: 6; height: (parent.height - 6) * root.battery / 100; radius: 1.5; color: parent.border.color } }
                 FIcon { visible: !root.hasBattery; anchors.horizontalCenter: parent.horizontalCenter; name: "x-plug"; size: 16; color: parent.parent.fg }
                 FText { anchors.horizontalCenter: parent.horizontalCenter; text: root.hasBattery ? root.battery : "AC"; px: 10.5; weight: Font.DemiBold; color: parent.parent.fg } }
            Hs {}
            Si { onClicked: Fz.open("system")
                 FIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "v-bell"; size: 16; color: parent.parent.fg }
                 FText { visible: root.notifCount > 0; anchors.horizontalCenter: parent.horizontalCenter; text: root.notifCount; px: 10.5; weight: Font.DemiBold; color: parent.parent.fg } }
            Si { onClicked: Fz.open("settings")
                 FIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "v-gear"; size: 16; color: parent.parent.fg } }
        }
    }

    // ---------- compact music player next to the bar ----------
    PanelWindow {
        visible: root.visible && root.musicOpen
        screen: root.barWindow ? root.barWindow.screen : null
        WlrLayershell.namespace: "qs-sidemusic"
        WlrLayershell.layer: WlrLayer.Top
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; left: !root.onRight; right: root.onRight }
        margins { top: 150 - 52 - 60; left: 72 - 60 - 60; right: 72 - 60 - 60 }
        implicitWidth: 380 + 160; implicitHeight: mcard.height + 180
        color: "transparent"
        mask: Region { item: mcard }
        Glass {
            id: mcard
            x: 80; y: 80
            width: 380; height: mcol.implicitHeight + 36
            readonly property var player: MprisController.activePlayer
            readonly property bool has: player !== null && MprisController.trackTitle !== ""
            readonly property real len: player && player.length > 0 ? player.length : 0
            function mmss(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0"); }
            Column {
                id: mcol
                x: 18; y: 18
                width: parent.width - 36
                spacing: 14
                Row {
                    width: parent.width; spacing: 16
                    MusicDisc { size: 84; width: 84; height: 84; art: MprisController.activePlayer ? (MprisController.activePlayer.trackArtUrl || "") : ""; anchors.verticalCenter: parent.verticalCenter }
                    Column {
                        width: parent.width - 84 - 16 - 36 - 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Caps { px: 11; text: mcard.has ? (MprisController.isPlaying ? Fz.tr("Đang phát") : Fz.tr("Tạm dừng")) + (mcard.player.identity ? " · " + mcard.player.identity : "") : Fz.tr("Trình phát nhạc") }
                        FText { width: parent.width; elide: Text.ElideRight; text: mcard.has ? MprisController.trackTitle : Fz.tr("Không có gì đang phát"); px: 17; weight: Font.DemiBold }
                        FText { width: parent.width; elide: Text.ElideRight; text: mcard.has ? MprisController.trackArtist : Fz.tr("Mở một ứng dụng nghe nhạc"); px: 13; color: Fz.sub }
                    }
                    FIconBtn { ghost: true; icon: "v-heart"; label: Fz.tr("Yêu thích"); anchors.verticalCenter: parent.verticalCenter }
                }
                Row {
                    width: parent.width; height: 28; spacing: 3
                    Repeater {
                        model: 40
                        delegate: Item {
                            required property int index
                            width: (parent.width - 39 * 3) / 40; height: 28
                            readonly property real lv: { let b = Cava.barLevels; let v = (b && b.length) ? b[Math.floor(index * b.length / 40)] : 0; return MprisController.isPlaying ? Math.max(0.08, Math.min(1, v)) : 0.08; }
                            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: Math.max(2, 28 * parent.lv); radius: 2; color: Fz.accA(0.35 + parent.lv / 2) }
                        }
                    }
                }
                Column {
                    width: parent.width; spacing: 6
                    FBar { width: parent.width; value: mcard.len > 0 && mcard.player ? mcard.player.position / mcard.len : 0 }
                    Item {
                        width: parent.width; height: 14
                        FText { text: mcard.mmss(mcard.player ? mcard.player.position : 0); mono: true; px: 11.5; color: Fz.sub }
                        FText { anchors.right: parent.right; text: mcard.mmss(mcard.len); mono: true; px: 11.5; color: Fz.sub }
                    }
                    Timer { interval: 1000; repeat: true; running: mcard.visible && MprisController.isPlaying; onTriggered: if (mcard.player) mcard.player.positionChanged() }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    FIconBtn { ghost: !(mcard.player && mcard.player.shuffle); on: mcard.player ? mcard.player.shuffle === true : false; icon: "v-shuffle"; label: Fz.tr("Trộn bài"); onClicked: if (mcard.player) mcard.player.shuffle = !mcard.player.shuffle }
                    FIconBtn { icon: "v-prev"; label: Fz.tr("Bài trước"); onClicked: if (mcard.player) mcard.player.previous() }
                    FIconBtn { width: 56; height: 42; on: true; icon: MprisController.isPlaying ? "v-pause" : "v-play"; label: MprisController.isPlaying ? Fz.tr("Tạm dừng") : Fz.tr("Phát"); onClicked: if (mcard.player) mcard.player.togglePlaying() }
                    FIconBtn { icon: "v-next"; label: Fz.tr("Bài tiếp"); onClicked: if (mcard.player) mcard.player.next() }
                    FIconBtn { ghost: true; icon: "v-repeat"; label: Fz.tr("Lặp lại"); onClicked: if (mcard.player) mcard.player.loopState = mcard.player.loopState === MprisLoopState.None ? MprisLoopState.Playlist : MprisLoopState.None }
                }
            }
        }
    }

    // `.sb`: glass column of items
    component Sb: Rectangle {
        default property alias items: sbCol.data
        property real padY: 6
        property real gap: 2
        width: 52; height: sbCol.implicitHeight + padY * 2
        radius: 16
        color: Fz.glass
        border.width: 1; border.color: Fz.fg(0.09)
        Column { id: sbCol; anchors.horizontalCenter: parent.horizontalCenter; y: parent.padY; spacing: parent.gap }
    }
    // `.si`: 40px item, icon above a small label
    component Si: Rectangle {
        id: si
        default property alias content: siCol.data
        property bool on: false
        property real padY: 0
        signal clicked()
        signal wheelSteps(int steps)
        readonly property color fg: on ? Fz.ink : (siMouse.containsMouse ? Fz.tx : Fz.sub2)
        width: 40; height: Math.max(36, siCol.implicitHeight + 8 + padY * 2)
        radius: 11
        color: on ? Fz.acc : (siMouse.containsMouse ? Fz.fg(0.08) : "transparent")
        Column { id: siCol; anchors.centerIn: parent; width: parent.width; spacing: 2 }
        MouseArea { id: siMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: si.clicked()
                    onWheel: (w) => si.wheelSteps(w.angleDelta.y > 0 ? 1 : -1) }
    }
    component Hs: Rectangle { anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined; width: 20; height: 9; color: "transparent"
                              Rectangle { anchors.centerIn: parent; width: 20; height: 1; color: Fz.fg(0.1) } }
}
