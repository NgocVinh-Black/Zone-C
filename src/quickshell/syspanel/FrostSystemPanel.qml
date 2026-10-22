import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import "../"
import "../frost"

// System panel of the Frost design (QuickSettings.dc.html): account + light/dark switch, volume and
// brightness, ten quick tiles, notifications, power actions, battery and power profile.
Item {
    id: root
    focus: true

    // The panel is preloaded hidden; toasts are only held back while it is actually on screen.
    Component.onCompleted: NotificationManager.sysPanelOpen = visible
    Component.onDestruction: if (visible) NotificationManager.sysPanelOpen = false
    onVisibleChanged: { NotificationManager.sysPanelOpen = visible; if (visible) briRead.running = true; }

    // ---------- state ----------
    readonly property int vol: Audio.defaultSink && Audio.defaultSink.audio ? Math.round(Audio.defaultSink.audio.volume * 100) : 0
    property int bri: 78
    Process {
        id: briRead
        command: ["bash", Caching.zoneCDir + "/scripts/brightness.sh", "get"]
        stdout: StdioCollector { onStreamFinished: { let v = parseInt(this.text); if (!isNaN(v)) root.bri = v; } }
    }
    Timer { id: briWrite; interval: 60; property int v: 0; onTriggered: Quickshell.execDetached(["bash", Caching.zoneCDir + "/scripts/brightness.sh", "set", String(v)]) }

    readonly property var idleCfg: Config.getSetting("idle", {})
    readonly property bool caffeine: !!(idleCfg && idleCfg.manualInhibit)
    readonly property bool dnd: { let n = Config.getSetting("notifications", {}); return !!(n && n.dnd); }
    readonly property bool quickActions: { let g = Config.getSetting("general", {}); return g.quickactions !== false; }
    readonly property bool nightOn: typeof BlueLight !== "undefined" && typeof BlueLight.isAnyEnabled === "function" ? BlueLight.isAnyEnabled() : false
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property bool micOn: Audio.defaultSource && Audio.defaultSource.audio ? !Audio.defaultSource.audio.muted : false
    readonly property bool airplane: !Networking.wifiEnabled && !(bt && bt.enabled)

    function setCfg(section, key, value) {
        let s = Object.assign({}, Config.getSetting(section, {}));
        s[key] = value;
        Config.setSetting(section, s);
    }
    function closePanel() { Quickshell.execDetached(["bash", Caching.zoneCDir + "/scripts/qs_manager.sh", "close"]); }

    readonly property var tiles: [
        { k: "night", l: Fz.tr("Đèn ngủ"), i: "q-moon", on: nightOn, f: () => BlueLight.setEnabled("", !nightOn) },
        { k: "caffeine", l: "Caffeine", i: "q-coffee", on: caffeine, f: () => setCfg("idle", "manualInhibit", !caffeine) },
        { k: "wifi", l: "Wi-Fi", i: "q-wifi", on: Networking.wifiEnabled, f: () => Networking.wifiEnabled = !Networking.wifiEnabled },
        { k: "bt", l: "Bluetooth", i: "q-bt", on: bt ? bt.enabled : false, f: () => { if (bt) bt.enabled = !bt.enabled; } },
        { k: "plane", l: Fz.tr("Máy bay"), i: "q-plane", on: airplane, f: () => { let on = !airplane; Networking.wifiEnabled = !on; if (bt) bt.enabled = !on; } },
        { k: "dnd", l: Fz.tr("Im lặng"), i: "q-dnd", on: dnd, f: () => setCfg("notifications", "dnd", !dnd) },
        { k: "rec", l: Fz.tr("Quay MH"), i: "q-rec", on: Rec.active, f: () => { closePanel(); Quickshell.execDetached(["bash", Caching.zoneCDir + "/scripts/screenshot.sh", "--record"]); } },
        { k: "mic", l: Fz.tr("Micro"), i: "q-mic", on: micOn, f: () => { if (Audio.defaultSource) Audio.toggleMute(Audio.defaultSource); } },
        { k: "shot", l: Fz.tr("Chụp MH"), i: "q-shot", on: false, f: () => { closePanel(); Quickshell.execDetached(["bash", Caching.zoneCDir + "/scripts/screenshot.sh"]); } },
        { k: "qa", l: "Quick act.", i: "q-eye", on: quickActions, f: () => setCfg("general", "quickactions", !quickActions) }
    ]

    // ---------- notifications ----------
    readonly property var history: NotificationManager.globalNotificationHistory
    property bool muted: dnd
    function ago(ts) {
        let m = Math.floor((Date.now() - ts) / 60000);
        if (m < 1) return Fz.tr("vừa xong");
        if (m < 60) return m + Fz.tr(" phút");
        let h = Math.floor(m / 60);
        return h < 24 ? h + Fz.tr(" giờ") : Math.floor(h / 24) + Fz.tr(" ngày");
    }
    function appIcon(app) {
        let a = (app || "").toLowerCase();
        if (/update|pacman|yay|paru|zone-c updater/.test(a)) return "q-box";
        if (/screenshot|ảnh chụp|grim|flameshot|recorder/.test(a)) return "q-image";
        if (/weather|thời tiết/.test(a)) return "q-cloud";
        if (/viber|telegram|discord|zalo|messenger|signal|slack|whatsapp|chat|mail|thunderbird/.test(a)) return "q-chat";
        return "q-bell";
    }

    // ---------- power ----------
    readonly property var dev: UPower.displayDevice
    readonly property int pct: dev.ready ? Math.round(dev.percentage * 100) : 0
    readonly property bool hasBattery: dev.ready && dev.isLaptopBattery
    // uptime for the desktop-without-battery card (EmptyStates)
    property int uptimeSec: 0
    FileView { id: uptimeFile; path: "/proc/uptime"; onLoaded: root.uptimeSec = Math.floor(Number(text().split(" ")[0])) }
    Timer { interval: 60000; repeat: true; running: !root.hasBattery && root.visible; triggeredOnStart: true; onTriggered: uptimeFile.reload() }
    readonly property string batLeft: {
        if (!hasBattery) { let u = root.uptimeSec, h = Math.floor(u / 3600), m = Math.floor(u % 3600 / 60); return Fz.tr("Không có pin · bật ") + (h > 0 ? h + Fz.tr(" giờ ") : "") + m + Fz.tr(" phút"); }
        if (dev.state === UPowerDeviceState.FullyCharged) return Fz.tr("Đã sạc đầy");
        let charging = dev.state === UPowerDeviceState.Charging;
        let s = charging ? dev.timeToFull : dev.timeToEmpty;
        if (s <= 0) return charging ? Fz.tr("Đang sạc") : Fz.tr("Đang dùng pin");
        let h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60);
        return (charging ? Fz.tr("đầy sau ") : Fz.tr("còn ")) + (h > 0 ? h + Fz.tr(" giờ ") : "") + m + Fz.tr(" phút");
    }

    Glass {
        anchors.fill: parent
        radius: 24

        Column {
            id: col
            x: 14; y: 14
            width: parent.width - 28
            height: parent.height - 28
            spacing: 10

            // account + Tối/Sáng
            Card {
                id: account
                width: parent.width
                height: 70
                Row {
                    x: 13; anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    Rectangle {
                        width: 44; height: 44; radius: 22; color: Fz.acc
                        anchors.verticalCenter: parent.verticalCenter
                        FIcon { anchors.centerIn: parent; name: "q-zc"; size: 26; color: Fz.ink }
                    }
                    Column {
                        width: account.width - 24 - 44 - 24 - modeSeg.width
                        anchors.verticalCenter: parent.verticalCenter
                        FText { text: SystemInfo.username + "@" + (SystemInfo.hostname || "zone-c"); px: 15; weight: Font.DemiBold }
                        FText { text: (SystemInfo.osName || "Arch Linux") + " · " + (Fz.light ? "Frost Light" : "Frost Dark"); color: Fz.sub; px: 12 }
                    }
                    FSeg {
                        id: modeSeg
                        anchors.verticalCenter: parent.verticalCenter
                        options: [{ label: Fz.tr("Tối"), icon: "q-moon" }, { label: Fz.tr("Sáng"), icon: "q-sun" }]
                        current: Fz.light ? 1 : 0
                        onPicked: (i) => ZoneStyle.setMode(i === 1 ? "light" : "dark")
                    }
                }
            }

            // volume + brightness
            Card {
                width: parent.width
                height: 46 * 2 + 8 + 22
                Column {
                    x: 11; y: 11
                    width: parent.width - 22
                    spacing: 8
                    BigSlider {
                        width: parent.width; icon: "q-vol"; value: root.vol; label: Fz.tr("Âm lượng")
                        onMoved: (v) => { if (Audio.defaultSink) { if (Audio.defaultSink.audio.muted) Audio.toggleMute(Audio.defaultSink); Audio.setVolume(Audio.defaultSink, v / 100); } }
                    }
                    BigSlider {
                        width: parent.width; icon: "q-sun"; value: root.bri; label: Fz.tr("Độ sáng")
                        onMoved: (v) => { root.bri = v; briWrite.v = v; briWrite.restart(); }
                    }
                }
            }

            // quick tiles `.qt`
            Grid {
                width: parent.width
                columns: 5
                columnSpacing: 8; rowSpacing: 8
                Repeater {
                    model: root.tiles
                    delegate: Rectangle {
                        required property var modelData
                        width: (col.width - 32) / 5
                        height: 74
                        radius: 18
                        color: modelData.on ? Fz.acc : Fz.fg(tileMouse.containsMouse ? 0.11 : 0.06)
                        Accessible.role: Accessible.CheckBox
                        Accessible.name: modelData.l
                        Accessible.checked: modelData.on
                        Column {
                            anchors.centerIn: parent
                            spacing: 6
                            FIcon { anchors.horizontalCenter: parent.horizontalCenter; name: modelData.i; size: 20; color: modelData.on ? Fz.ink : Fz.sub2 }
                            FText { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.l; px: 11.5; weight: Font.Medium; color: modelData.on ? Fz.ink : Fz.sub2 }
                        }
                        MouseArea { id: tileMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.f() }
                    }
                }
            }

            // notifications
            Card {
                id: notifCard
                width: parent.width
                height: col.height - account.height - (46 * 2 + 30) - (74 * 2 + 8) - 52 - 64 - 10 * 5
                clip: true

                Item {
                    id: nhead
                    x: 14; y: 12
                    width: parent.width - 28; height: 34
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        FText { text: Fz.tr("Thông báo"); px: 14; weight: Font.DemiBold }
                        FText { text: " · " + (root.history ? root.history.count : 0); color: Fz.sub; px: 14 }
                    }
                    Row {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        FBtn { height: 30; padX: 10; fontSize: 12; text: Fz.tr("Xóa hết"); onClicked: nlist.clearAnimated() }
                        FBtn { height: 30; padX: 10; fontSize: 12; iconSize: 13; icon: "q-bell"; kind: root.dnd ? "pri" : ""
                            text: root.dnd ? Fz.tr("Đã tắt tiếng") : Fz.tr("Tắt tiếng"); onClicked: root.setCfg("notifications", "dnd", !root.dnd) }
                    }
                }

                ListView {
                    id: nlist
                    x: 12; y: 12 + 34 + 4
                    width: parent.width - 24
                    height: parent.height - y - 12
                    spacing: 8
                    clip: true
                    model: root.history
                    boundsBehavior: Flickable.StopAtBounds
                    // "Xóa hết": the cards sweep out to the right one after another, then the history is cleared
                    signal sweep()
                    property bool clearing: false
                    function clearAnimated() {
                        if (clearing || count === 0) return;
                        clearing = true;
                        sweep();
                        clearTimer.interval = Math.min(count, 8) * 40 + 260;
                        clearTimer.restart();
                    }
                    Timer { id: clearTimer; onTriggered: { NotificationManager.clearNotifications(); nlist.clearing = false; } }
                    add: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "outX"; from: 40; to: 0; duration: 260; easing.type: Easing.OutCubic }
                    }
                    remove: Transition {
                        NumberAnimation { property: "opacity"; to: 0; duration: 180; easing.type: Easing.InCubic }
                        NumberAnimation { property: "outX"; to: 120; duration: 180; easing.type: Easing.InCubic }
                    }
                    displaced: Transition { NumberAnimation { property: "y"; duration: 240; easing.type: Easing.OutCubic } }
                    delegate: Rectangle {
                        id: nt
                        required property var model
                        required property int index
                        property real outX: 0
                        transform: Translate { x: nt.outX }
                        Connections { target: nlist; function onSweep() { sweepAnim.start(); } }
                        SequentialAnimation {
                            id: sweepAnim
                            PauseAnimation { duration: Math.min(nt.index, 8) * 40 }
                            ParallelAnimation {
                                NumberAnimation { target: nt; property: "outX"; to: nlist.width; duration: 240; easing.type: Easing.InCubic }
                                NumberAnimation { target: nt; property: "opacity"; to: 0; duration: 220; easing.type: Easing.InCubic }
                            }
                        }
                        width: nlist.width
                        height: ntRow.implicitHeight + 24
                        radius: 18
                        color: Fz.fg(0.05)
                        border.width: 1; border.color: Fz.fg(0.07)
                        readonly property var actions: { try { return JSON.parse(model.actionsJson || "[]"); } catch (e) { return []; } }
                        readonly property string img: (model.image || "").toString()
                        readonly property bool showImg: img !== "" && img !== (model.iconPath || "") && !img.startsWith("image://icon")
                        Row {
                            id: ntRow
                            x: 12; y: 12
                            width: parent.width - 24
                            spacing: 12
                            Rectangle {
                                width: 38; height: 38; radius: 12; color: Fz.s0
                                FIcon { anchors.centerIn: parent; name: root.appIcon(nt.model.appName); color: Fz.acc }
                            }
                            Column {
                                width: parent.width - 38 - 26 - 24
                                spacing: 2
                                FText { width: parent.width; elide: Text.ElideRight; text: nt.model.appName + " · " + root.ago(nt.model.timestamp); color: Fz.sub; px: 11.5 }
                                FText { width: parent.width; elide: Text.ElideRight; text: nt.model.summary; px: 13.5; weight: Font.DemiBold }
                                FText { width: parent.width; visible: text !== ""; text: nt.model.body; textFormat: Text.PlainText; color: Fz.sub2; px: 12.5; wrapMode: Text.Wrap; maximumLineCount: 3; css: 1.15 }
                                Item {
                                    visible: nt.showImg
                                    width: parent.width; height: visible ? 76 : 0
                                    RoundImage { y: 6; width: parent.width; height: 70; radius: 10; source: nt.showImg ? nt.img : "" }
                                }
                                Row {
                                    visible: nt.actions.length > 0
                                    topPadding: 6
                                    spacing: 6
                                    Repeater {
                                        model: nt.actions.slice(0, 2)
                                        delegate: FBtn {
                                            required property var modelData
                                            required property int index
                                            height: 30; fontSize: 12; padX: 12
                                            kind: index === 0 ? "pri" : ""
                                            text: modelData.text || modelData.label || ""
                                            onClicked: {
                                                let n = NotificationManager.liveNotifs[nt.model.uid] || nt.model.notif;
                                                if (n && n.actions) { for (let a of n.actions) if (a.identifier === modelData.id || a.text === text) { a.invoke(); break; } }
                                                NotificationManager.dismissNotification(nt.model.uid);
                                            }
                                        }
                                    }
                                }
                            }
                            FIconBtn { width: 26; height: 26; ghost: true; icon: "q-x"; iconSize: 13; label: Fz.tr("Bỏ qua"); onClicked: NotificationManager.dismissNotification(nt.model.uid) }
                        }
                    }
                }

                Column {
                    anchors.centerIn: nlist
                    readonly property bool empty: !root.history || root.history.count === 0
                    visible: opacity > 0
                    opacity: empty ? 1 : 0
                    scale: empty ? 1 : 0.92
                    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                    spacing: 10
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 64; height: 64; radius: 32; color: Fz.accA(0.1)
                        FIcon { anchors.centerIn: parent; name: "q-check"; size: 28; color: Fz.acc }
                    }
                    FText { anchors.horizontalCenter: parent.horizontalCenter; text: Fz.tr("Bạn đã xem hết thông báo"); px: 16; weight: Font.DemiBold }
                    FText { anchors.horizontalCenter: parent.horizontalCenter; width: 300; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; css: 1.45
                            text: Fz.tr("Thông báo mới sẽ xuất hiện ở đây. Bật Không làm phiền để tạm ẩn."); color: Fz.sub; px: 13 }
                }
            }

            // power actions `.pw`
            Row {
                width: parent.width
                spacing: 8
                Repeater {
                    model: [
                        { i: "q-lock", l: Fz.tr("Khóa"), c: "lock" }, { i: "q-zzz", l: Fz.tr("Ngủ"), c: "suspend" }, { i: "q-moon", l: Fz.tr("Ngủ đông"), c: "hibernate" },
                        { i: "q-restart", l: Fz.tr("Khởi động lại"), c: "reboot" }, { i: "q-off", l: Fz.tr("Tắt máy"), c: "poweroff" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: (col.width - 32) / 5
                        height: 52
                        radius: 16
                        color: Fz.fg(pwMouse.containsMouse ? 0.12 : 0.06)
                        Accessible.role: Accessible.Button
                        Accessible.name: modelData.l
                        FIcon { anchors.centerIn: parent; name: modelData.i; size: 20; color: modelData.c === "poweroff" ? Fz.red : (pwMouse.containsMouse ? Fz.tx : Fz.sub2) }
                        MouseArea {
                            id: pwMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.c === "lock") { root.closePanel(); Quickshell.execDetached(["bash", Caching.zoneCDir + "/scripts/lock.sh"]); }
                                else Fz.open("power", modelData.c);
                            }
                        }
                    }
                }
            }

            // battery + power profile
            Row {
                width: parent.width
                height: 64
                spacing: 8
                Rectangle {
                    width: parent.width - 8 - profSeg.width
                    height: 64
                    radius: 18
                    color: Fz.acc
                    Row {
                        x: 16; anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        FIcon { name: root.hasBattery ? "q-bat" : "x-plug"; size: 26; color: Fz.ink; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            FText { text: root.hasBattery ? root.pct + "%" : "AC"; px: 20; weight: Font.Bold; color: Fz.ink; css: 1 }
                            FText { topPadding: 3; text: root.batLeft; px: 11.5; weight: Font.Medium; color: Fz.ink }
                        }
                    }
                }
                FSeg {
                    id: profSeg
                    height: 64
                    btnHeight: 58
                    btnWidth: 58
                    options: [{ icon: "q-gauge" }, { icon: "q-scale" }, { icon: "q-leaf" }]
                    current: PowerProfiles.profile === PowerProfile.Performance ? 0 : (PowerProfiles.profile === PowerProfile.PowerSaver ? 2 : 1)
                    onPicked: (i) => PowerProfiles.profile = [PowerProfile.Performance, PowerProfile.Balanced, PowerProfile.PowerSaver][i]
                }
            }
        }
    }

    // `.big`: 46px slider with the fill drawn to the value, icon on the fill, value at the right.
    component BigSlider: Rectangle {
        id: big
        property string icon
        property string label
        property int value: 0
        signal moved(int v)
        height: 46
        radius: 15
        color: Fz.well(0.25)
        clip: true
        Accessible.role: Accessible.Slider
        Accessible.name: label
        Rectangle { width: Math.max(big.value, 10) / 100 * big.width; height: parent.height; radius: 15; color: Fz.acc }
        FIcon { x: 15; anchors.verticalCenter: parent.verticalCenter; name: big.icon; size: 17; color: Fz.ink }
        // the canvas renders "{{vol}}%" with the number and the sign apart
        Row {
            anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
            spacing: 15
            FText { mono: true; text: big.value; px: 12.5 }
            FText { mono: true; text: "%"; px: 12.5 }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function set(mx) { let v = Math.round(Math.max(0, Math.min(1, mx / width)) * 100); big.moved(v); }
            onPressed: (e) => set(e.x)
            onPositionChanged: (e) => { if (pressed) set(e.x); }
            onWheel: (e) => big.moved(Math.max(0, Math.min(100, big.value + (e.angleDelta.y > 0 ? 5 : -5))))
        }
    }
}
