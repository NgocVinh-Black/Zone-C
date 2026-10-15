import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import "../"
import "../frost"

// Horizontal bar of the Frost design (TopBar.dc.html): three glass pills,
// launcher + workspaces + media on the left, clock + weather centred, system status on the right.
Item {
    id: root
    property var barWindow
    // the bar window is taller than the bar (shadow room): the bar keeps to its edge
    x: 0
    width: parent ? parent.width : 0
    height: barWindow ? barWindow.barHeight : 40
    y: barWindow && barWindow.barPosition === "bottom" ? parent.height - height : 0

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
    readonly property string mediaText: hasMedia ? (player.trackTitle + (player.trackArtist ? " · " + player.trackArtist : "")) : Fz.tr("Không phát nhạc")

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
    readonly property bool charging: UPower.displayDevice.state === UPowerDeviceState.Charging
    readonly property bool onAc: charging || UPower.displayDevice.state === UPowerDeviceState.FullyCharged || UPower.displayDevice.state === UPowerDeviceState.PendingCharge || !UPower.onBattery
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
    readonly property var trayItems: SystemTray.items ? (SystemTray.items.values || []).filter(i => i.status !== Status.Passive) : []
    readonly property string focusTitle: Hyprland.activeToplevel ? (Hyprland.activeToplevel.title || "") : ""
    Component.onCompleted: SysData.subscribe()
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
            label: Fz.tr("Zone-C: mở launcher")
            on: root.launcherOpen
            onClicked: Fz.open("launcher")
            FIcon { name: "b-zc"; size: 19; color: launcherIt.on ? Fz.ink : Fz.acc; anchors.verticalCenter: parent.verticalCenter }
        }
        BarSep {}
        BarItem {
            id: wsIt
            visible: root.shown("workspaces")
            padX: 8
            label: Fz.tr("Không gian làm việc ") + root.activeWs + Fz.tr(" trên ") + root.wsCount
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
        BarSep { visible: focusIt.visible }
        BarItem {
            // active window (Settings → Thanh bar → Tiêu điểm)
            id: focusIt
            visible: root.shown("focus") && root.focusTitle !== ""
            label: root.focusTitle
            onClicked: Fz.open("overview")
            FText { text: root.focusTitle; color: focusIt.fgColor; px: 13; width: Math.min(implicitWidth, 220); elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
        }
        BarSep { visible: actIt.visible }
        BarItem {
            // quick actions (Settings → Thanh bar → Thao tác): screenshot, screen recording
            id: actIt
            visible: root.shown("actions")
            padX: 9
            label: Fz.tr("Chụp màn hình")
            onClicked: Fz.open("screenshot")
            onRightClicked: Quickshell.execDetached(["zone-c", "screenshot", "--record"])
            FIcon { name: "t-shot"; size: 15; color: actIt.fgColor; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // ---------- centre: clock · weather ----------
    BarPill {
        id: centerPill
        // centred, but pushed aside (and the date dropped) rather than drawn over the side groups
        readonly property real leftEnd: leftPill.x + leftPill.width + 8
        readonly property real rightStart: rightRow.x - 8
        x: Math.max(leftEnd, Math.min((root.width - width) / 2, rightStart - width))
        anchors.verticalCenter: parent.verticalCenter

        BarItem {
            visible: root.recording
            label: Fz.tr("Đang quay màn hình")
            onClicked: Fz.open("screenshot")
            FIcon { name: "b-rec"; size: 11; color: "#ff9b9b"; anchors.verticalCenter: parent.verticalCenter }
            FText { mono: true; text: Rec.elapsed; color: "#ff9b9b"; px: 13; weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
        }
        BarSep { visible: root.recording }
        BarItem {
            // running timer from Quick actions (Settings → Thanh bar → Ghi hình/Hẹn giờ)
            id: timerIt
            visible: TimerState.isActive && root.shown("info")
            label: Fz.tr("Hẹn giờ ") + TimerState.timeFormatted
            onClicked: FloatingController.setIndex("timer", null)
            FIcon { name: "a-timer"; size: 15; color: timerIt.fgColor; anchors.verticalCenter: parent.verticalCenter }
            FText { mono: true; text: TimerState.timeFormatted; color: timerIt.fgColor; px: 13; weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
        }
        BarSep { visible: timerIt.visible }
        BarItem {
            id: clockIt
            visible: root.shown("timedate")
            on: root.openWidget === "calendar"
            label: Fz.tr("Mở lịch")
            onClicked: Fz.open("calendar")
            FText { mono: true; text: DateTime.timeShort; color: clockIt.fgColor; px: 14; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
            FText { id: dateTxt; visible: root.showDate && !root.tight; text: Fz.dateShort(DateTime.now); color: clockIt.fgColor; opacity: 0.75; px: 13; weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
        }
        BarSep {}
        BarItem {
            id: weatherIt
            visible: root.shown("weather")
            on: root.openWidget === "calendar"
            label: Fz.tr("Thời tiết")
            onClicked: Fz.open("calendar")
            FIcon { name: Fz.weatherIcon(Weather.currentIcon); size: 15; color: weatherIt.fgColor; anchors.verticalCenter: parent.verticalCenter }
            FText { text: Weather.currentTemp !== "" ? Math.round(Number(Weather.currentTemp)) + "°" : "--°"; color: weatherIt.fgColor; px: 13; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // not enough room for the full centre group between the sides → drop the date
    // (assigned, not bound: the full width is the same whether or not the date is showing, so no loop)
    property bool tight: false
    function recheck() {
        let full = centerPill.width + (dateTxt.visible || !root.showDate ? 0 : dateTxt.implicitWidth + 8);
        root.tight = rightRow.x - (leftPill.x + leftPill.width) - 16 < full;
    }
    Connections { target: rightRow; function onXChanged() { root.recheck(); } }
    Connections { target: leftPill; function onWidthChanged() { root.recheck(); } }
    Connections { target: centerPill; function onWidthChanged() { root.recheck(); } }
    onWidthChanged: recheck()

    // ---------- right: clipboard · input method | wifi · bt · volume · battery | notifications · settings ----------
    Row {
        id: rightRow
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        BarPill {
            visible: root.shown("sysmon")
            BarItem {
                id: sysIt
                on: root.openWidget === "taskmanager"
                label: "CPU " + SysData.cpu + "% · RAM " + SysData.ramPercent + "%" + (SysData.temp > 0 ? " · " + SysData.temp + "°C" : "")
                onClicked: Fz.open("taskmanager")
                // icon + value pairs, as compact as the rest of the bar
                Row { spacing: 4; anchors.verticalCenter: parent.verticalCenter
                      FIcon { name: "x-cpu"; size: 14; color: sysIt.fgColor; anchors.verticalCenter: parent.verticalCenter }
                      FText { mono: true; text: SysData.cpu + "%"; color: sysIt.fgColor; px: 12; anchors.verticalCenter: parent.verticalCenter } }
                Row { spacing: 4; anchors.verticalCenter: parent.verticalCenter
                      FIcon { name: "x-ram"; size: 14; color: sysIt.fgColor; anchors.verticalCenter: parent.verticalCenter }
                      FText { mono: true; text: SysData.ramPercent + "%"; color: sysIt.fgColor; px: 12; anchors.verticalCenter: parent.verticalCenter } }
                Row { visible: SysData.temp > 0; spacing: 2; anchors.verticalCenter: parent.verticalCenter
                      FIcon { name: "x-temp"; size: 14; color: SysData.temp >= 85 ? Fz.yellow : sysIt.fgColor; anchors.verticalCenter: parent.verticalCenter }
                      FText { mono: true; text: SysData.temp + "°"; color: SysData.temp >= 85 ? Fz.yellow : sysIt.fgColor; px: 12; anchors.verticalCenter: parent.verticalCenter } }
            }
        }

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
            // system tray icons (Settings → Thanh bar → Khay); left click activates, right click opens the tray menu
            Repeater {
                model: root.shown("tray") ? root.trayItems.slice(0, 6) : []
                delegate: BarItem {
                    required property var modelData
                    padX: 7
                    label: modelData.tooltipTitle || modelData.title || modelData.id
                    onClicked: modelData.onlyMenu ? Fz.open("tray") : modelData.activate()
                    onRightClicked: Fz.open("tray")
                    Item {
                        width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter
                        Image { id: trayImg; anchors.fill: parent; source: modelData.icon; sourceSize: Qt.size(32, 32); visible: status === Image.Ready }
                        // apps whose icon can't be loaded get a neutral glyph instead of an empty box
                        FIcon { anchors.centerIn: parent; visible: trayImg.status !== Image.Ready; name: "t-open"; size: 15; color: Fz.sub2 }
                    }
                }
            }
            BarItem {
                id: kbIt
                visible: root.shown("kb")
                padX: 9
                label: root.kbLayout === "VI" ? Fz.tr("Bộ gõ Tiếng Việt") : Fz.tr("Bàn phím ") + root.kbLayout
                onClicked: { Quickshell.execDetached(["fcitx5-remote", "-t"]); kbPoll.running = true; }
                FText { text: root.kbLayout; color: kbIt.fgColor; px: 12; weight: Font.Bold; font.letterSpacing: 0.5; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        BarPill {
            BarItem {
                id: wifiIt
                visible: root.shown("wifi")
                on: root.openWidget === "network"
                padX: 9
                label: !root.wifiOn ? "Wi-Fi · " + Fz.tr("Tắt") : (root.ssid !== "" ? "Wi-Fi · " + root.ssid : "Wi-Fi · " + Fz.tr("Ngoại tuyến"))
                onClicked: Fz.open("network", "wifi")
                // EmptyStates: no network → red "Ngoại tuyến"
                readonly property bool offline: root.wifiOn && root.ssid === ""
                readonly property color tint: offline && !on ? Fz.redTx : fgColor
                FIcon { name: root.wifiOn && root.ssid !== "" ? "b-wifi" : "x-wifioff"; size: 15; color: wifiIt.tint; anchors.verticalCenter: parent.verticalCenter }

            }
            BarItem {
                id: btIt
                visible: root.shown("bt")
                padX: 9
                label: root.btOn ? "Bluetooth · " + root.btConnected + Fz.tr(" thiết bị đã kết nối") : "Bluetooth · " + Fz.tr("Tắt")
                onClicked: Fz.open("network", "bt")
                FIcon { name: root.btOn ? "b-bt" : "x-btoff"; size: 15; color: btIt.fgColor; opacity: root.btOn || btIt.on ? 1 : 0.55; anchors.verticalCenter: parent.verticalCenter }

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
                label: Fz.tr("Âm lượng ") + root.volume + Fz.tr(" phần trăm")
                onClicked: Fz.open("volume")
                onRightClicked: if (Audio.defaultSink) Audio.toggleMute(Audio.defaultSink)
                onWheel: (steps) => { if (Audio.defaultSink) Audio.setVolume(Audio.defaultSink, Math.max(0, Math.min(150, root.volume + steps * 5))); }
                FIcon { name: root.muted ? "mute" : "b-vol"; size: 15; color: volIt.fgColor; anchors.verticalCenter: parent.verticalCenter }
                FText { mono: true; text: root.muted ? "–" : root.volume; color: volIt.fgColor; px: 12; anchors.verticalCenter: parent.verticalCenter }
            }
            BarItem {
                id: batIt
                visible: root.shown("bat") && (root.hasBattery)
                on: root.openWidget === "system"
                label: Fz.trAs("Pin ", "Battery ") + root.battery + "%" + (root.charging ? " · " + Fz.tr("Đang sạc") : root.onAc ? " · " + Fz.trAs("Đã cắm sạc", "Plugged in") : "")
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
                // plugged in: a bolt before the level (green while charging)
                FIcon { visible: root.onAc; name: "x-bolt"; size: 13; color: root.charging && !batIt.on ? Fz.green : batIt.fgColor; anchors.verticalCenter: parent.verticalCenter }
                FText { mono: true; text: root.battery; color: batIt.fgColor; px: 12; anchors.verticalCenter: parent.verticalCenter }
            }
            BarItem {
                // desktop without a battery (EmptyStates): plug + AC
                id: acIt
                visible: root.shown("bat") && !root.hasBattery
                on: root.openWidget === "system"
                label: Fz.tr("Nguồn điện AC, mở bảng hệ thống")
                onClicked: Fz.open("system")
                FIcon { name: "x-plug"; size: 15; color: acIt.fgColor; anchors.verticalCenter: parent.verticalCenter }
                FText { text: "AC"; color: acIt.fgColor; px: 13; weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
            }
            BarSep {}
            BarItem {
                id: notifIt
                on: root.openWidget === "system"
                label: root.notifCount + Fz.tr(" thông báo")
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
                label: Fz.tr("Cài đặt")
                onClicked: Fz.open("guide")
                FIcon { name: "b-gear"; size: 15; color: gearIt.fgColor; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
