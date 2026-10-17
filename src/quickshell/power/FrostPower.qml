import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"
import "../frost"

// Power menu of the Frost design (Power.dc.html): lock, log out, sleep, hibernate, restart, power off,
// a confirm button and a 60 s countdown that names the apps still open.
PanelWindow {
    id: win
    property bool open: false
    visible: open
    WlrLayershell.namespace: "zone-c-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    readonly property var defs: [
        { k: "logout", l: Fz.tr("Đăng xuất"), i: "p-logout", h: Fz.tr("Đăng xuất khỏi Hyprland?"), s: Fz.tr("Mọi ứng dụng sẽ được đóng."), c: Fz.tr("Đăng xuất"), run: "exit.sh" },
        { k: "suspend", l: Fz.tr("Ngủ"), i: "p-zzz", h: Fz.tr("Đưa máy vào chế độ ngủ?"), s: Fz.tr("Phiên làm việc giữ nguyên trong RAM."), c: Fz.tr("Ngủ ngay"), run: "suspend.sh" },
        { k: "hibernate", l: Fz.tr("Ngủ đông"), i: "p-moon", h: Fz.tr("Ngủ đông?"), s: Fz.tr("Lưu phiên ra ổ đĩa rồi tắt nguồn."), c: Fz.tr("Ngủ đông"), run: "hibernate.sh" },
        { k: "reboot", l: Fz.tr("Khởi động lại"), i: "p-restart", h: Fz.tr("Khởi động lại máy?"), s: Fz.tr("Hệ thống sẽ khởi động lại."), c: Fz.tr("Khởi động lại"), run: "reboot.sh" },
        { k: "poweroff", l: Fz.tr("Tắt máy"), i: "p-off", h: Fz.tr("Tắt máy?"), s: Fz.tr("Hãy lưu công việc trước khi tắt."), c: Fz.tr("Tắt ngay"), run: "poweroff.sh" }
    ]
    property string pick: "poweroff"
    property bool canHibernate: true
    readonly property var options: defs.filter(d => d.k !== "hibernate" || canHibernate)
    readonly property var cur: defs.find(d => d.k === pick) || defs[4]
    property int secsLeft: 60
    readonly property var openApps: {
        let tl = Hyprland.toplevels ? (Hyprland.toplevels.values || []) : [], seen = {}, out = [];
        for (const t of tl) {
            let c = t.lastIpcObject && t.lastIpcObject.class ? t.lastIpcObject.class : "";
            if (c === "org.quickshell") continue;   // Zone-C's own windows close with the session anyway
            let n = c ? Fz.appName(c, t.title) : "";
            if (n && !seen[n]) { seen[n] = true; out.push(n); }
        }
        return out;
    }

    function show(k) {
        pick = (k === "sleep" ? "suspend" : k) || "poweroff";
        if (defs.every(d => d.k !== pick)) pick = "poweroff";
        secsLeft = 60;
        Hyprland.refreshToplevels();
        hib.running = true;
        open = true;
    }
    function run() {
        let d = cur;
        open = false;
        Quickshell.execDetached(["bash", Caching.zoneCDir + "/scripts/system/" + d.run]);
    }
    Process { id: hib; command: ["bash", Caching.zoneCDir + "/scripts/system/can_hibernate.sh"]; onExited: (code) => win.canHibernate = code === 0 }
    Timer { interval: 1000; repeat: true; running: win.open; onTriggered: { win.secsLeft--; if (win.secsLeft <= 0) win.run(); } }
    Connections { target: Fz; function onOpenRequest(name, arg) { if (name === "power") win.open ? (win.open = false) : win.show(arg); } }
    IpcHandler { target: "power"; function toggle(): void { win.open ? (win.open = false) : win.show(""); } function open(action: string): void { win.show(action); } }

    // `.wall.blur` + `.scrim.night`
    Image {
        anchors.fill: parent; anchors.margins: -60
        source: { let p = Wallpaper.getWallpaperPath(""); return p && !ZoneStyle.isVideo(p) ? "file://" + p : ""; }
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: 960
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64; blurMultiplier: 1.6; saturation: 0.1 }
    }
    Rectangle { anchors.fill: parent; color: Fz.scrimNight }
    MouseArea { anchors.fill: parent; onClicked: win.open = false }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: win.open = false
        Keys.onReturnPressed: win.run()
        Keys.onLeftPressed: { let i = win.options.findIndex(d => d.k === win.pick); win.pick = win.options[Math.max(0, i - 1)].k; win.secsLeft = 60; }
        Keys.onRightPressed: { let i = win.options.findIndex(d => d.k === win.pick); win.pick = win.options[Math.min(win.options.length - 1, i + 1)].k; win.secsLeft = 60; }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 190 * win.height / 900
        spacing: 10
        FText { anchors.horizontalCenter: parent.horizontalCenter; text: win.cur.h; px: 32; weight: Font.Medium; font.letterSpacing: -0.5 }
        FText { anchors.horizontalCenter: parent.horizontalCenter; text: win.cur.s; px: 15; color: Fz.sub2 }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 320 * win.height / 900
        spacing: 18
        PowerTile { label: Fz.tr("Khóa"); icon: "p-lock"; on: false; onClicked: { win.open = false; Quickshell.execDetached(["bash", Caching.zoneCDir + "/scripts/lock.sh"]); } }
        Repeater {
            model: win.options
            delegate: PowerTile {
                required property var modelData
                label: modelData.l; icon: modelData.i
                on: win.pick === modelData.k
                onClicked: { if (win.pick === modelData.k) win.run(); else { win.pick = modelData.k; win.secsLeft = 60; } }
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 504 * win.height / 900
        spacing: 10
        FBtn { height: 44; radius: 22; padX: 22; text: Fz.tr("Hủy · Esc"); onClicked: win.open = false }
        FBtn { height: 44; radius: 22; padX: 22; kind: "pri"; text: win.cur.c; onClicked: win.run() }
    }
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 570 * win.height / 900
        width: 320
        spacing: 8
        FBar { width: parent.width; value: win.secsLeft / 60 }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            FText { text: Fz.tr("Tự thực hiện sau "); px: 12.5; color: Fz.sub }
            FText { text: win.secsLeft; mono: true; px: 12.5; color: Fz.sub }
            FText { text: Fz.tr(" giây") + (win.openApps.length ? " · " + win.openApps.slice(0, 3).join(", ") + Fz.tr(" đang mở") : ""); px: 12.5; color: Fz.sub }
        }
    }

    // `.po` / `.po.on`
    component PowerTile: Rectangle {
        id: po
        property string label
        property string icon
        property bool on: false
        signal clicked()
        width: 136; height: 136; radius: 32
        color: on ? Fz.acc : Fz.surf(poMouse.containsMouse ? 0.85 : 0.7)
        border.width: on ? 0 : 1; border.color: Fz.fg(0.08)
        layer.enabled: on
        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Fz.glowA(0.35); shadowBlur: 1; blurMax: 40 }
        Column {
            anchors.centerIn: parent
            spacing: 12
            FIcon { anchors.horizontalCenter: parent.horizontalCenter; name: po.icon; size: 32; color: po.on ? Fz.ink : Fz.tx }
            FText { anchors.horizontalCenter: parent.horizontalCenter; text: po.label; px: 14; weight: Font.Medium; color: po.on ? Fz.ink : Fz.tx }
        }
        MouseArea { id: poMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: po.clicked() }
        Accessible.role: Accessible.Button
        Accessible.name: label
    }
}
