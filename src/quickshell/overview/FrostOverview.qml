import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"
import "../frost"

// Window overview and Alt+Tab switcher of the Frost design (Overview.dc.html).
// "overview": workspaces strip, filter field, live window previews of a workspace, app strip.
// "switch": only the app strip; Tab/Shift+Tab move, releasing Alt (or Enter) focuses.
PanelWindow {
    id: win
    property string mode: ""                 // "", "overview", "switch"
    visible: mode !== ""
    WlrLayershell.namespace: "zone-c-overview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    property int shownWs: 1
    property int selWin: 0
    property int selApp: 0
    property string filter: ""

    function show(m) {
        Hyprland.refreshToplevels();
        Hyprland.refreshWorkspaces();
        shownWs = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1;
        selWin = 0; filter = ""; field.text = "";
        selApp = m === "switch" && apps.length > 1 ? 1 : 0;
        mode = m;
        focusTimer.restart();
    }
    function hide() { mode = ""; }
    Timer { id: focusTimer; interval: 30; onTriggered: win.mode === "overview" ? field.forceActiveFocus() : keys.forceActiveFocus() }

    Connections {
        target: Fz
        function onOpenRequest(name, arg) {
            if (name === "overview") win.mode === "overview" ? win.hide() : win.show("overview");
            else if (name === "alttab") win.mode === "switch" ? win.cycle(1) : win.show("switch");
        }
    }
    IpcHandler {
        target: "overview"
        function toggle(): void { win.mode === "overview" ? win.hide() : win.show("overview"); }
        function alttab(): void { win.mode === "switch" ? win.cycle(1) : win.show("switch"); }
    }

    // ---------- data ----------
    readonly property var all: Hyprland.toplevels ? (Hyprland.toplevels.values || []) : []
    function cls(t) { return (t.lastIpcObject && t.lastIpcObject.class) ? t.lastIpcObject.class : ""; }
    function wsId(t) { return t.workspace ? t.workspace.id : (t.lastIpcObject && t.lastIpcObject.workspace ? t.lastIpcObject.workspace.id : 0); }
    function icon(t) {
        let c = (cls(t) + " " + (t.title || "")).toLowerCase();
        if (/foot|kitty|alacritty|wezterm|terminal|konsole/.test(c)) return "o-terminal";
        if (/chrome|chromium|firefox|brave|browser|zen/.test(c)) return "o-browser";
        if (/code|codium|zed|nvim|jetbrains|idea/.test(c)) return "o-code";
        if (/nautilus|thunar|dolphin|nemo|files|tệp/.test(c)) return "o-folder";
        if (/viber|telegram|discord|zalo|signal|slack/.test(c)) return "o-chat";
        if (/spotify|music|nhạc|rhythmbox/.test(c)) return "o-music";
        return "o-browser";
    }
    function appName(t) {
        let c = cls(t);
        let map = { "foot": "Foot", "kitty": "kitty", "google-chrome": "Chrome", "code": "VS Code", "code-oss": "VS Code", "org.gnome.Nautilus": Fz.tr("Tệp"), "ViberPC": "Viber", "Spotify": Fz.tr("Nhạc"), "spotify": Fz.tr("Nhạc") };
        return map[c] || (c ? c.charAt(0).toUpperCase() + c.slice(1) : (t.title || Fz.tr("Cửa sổ")));
    }
    readonly property var wsWindows: all.filter(t => wsId(t) === shownWs && (filter === "" || (t.title + " " + cls(t)).toLowerCase().indexOf(filter.toLowerCase()) !== -1))
    // most recently focused first, one entry per window
    readonly property var apps: all.filter(t => wsId(t) > 0).slice().sort((a, b) => {
        let fa = a.lastIpcObject ? a.lastIpcObject.focusHistoryID : 99, fb = b.lastIpcObject ? b.lastIpcObject.focusHistoryID : 99;
        return fa - fb;
    })
    function occupied(id) { return all.some(t => wsId(t) === id); }

    function focusWin(t) {
        if (!t) return;
        Hyprland.dispatch("hl.dsp.focus({ window = \"address:0x" + t.address + "\" })");
        hide();
    }
    function cycle(d) { if (apps.length) selApp = (selApp + d + apps.length) % apps.length; }

    // Card geometry: the artboard's layouts for one, two and three windows, a grid beyond that.
    function rect(i, n) {
        let W = win.width, sx = W / 1440, sy = win.height / 900;
        let r;
        if (n === 1) r = [320, 220, 800, 520];
        else if (n === 2) r = [[160, 230, 550, 480], [730, 230, 550, 480]][i];
        else if (n === 3) r = [[160, 220, 560, 520], [740, 220, 540, 250], [740, 490, 540, 250]][i];
        else {
            let cols = Math.ceil(Math.sqrt(n)), rows = Math.ceil(n / cols);
            let cw = (1120 - (cols - 1) * 20) / cols, ch = (520 - (rows - 1) * 20) / rows;
            r = [160 + (i % cols) * (cw + 20), 220 + Math.floor(i / cols) * (ch + 20), cw, ch];
        }
        return { x: r[0] * sx, y: r[1] * sy, w: r[2] * sx, h: r[3] * sy };
    }

    // ---------- backdrop: blurred wallpaper + `.scrim.deep` ----------
    Item {
        anchors.fill: parent
        visible: win.mode === "overview"
        Image {
            id: wall
            anchors.fill: parent; anchors.margins: -60
            source: Wallpaper.getWallpaperPath("") && !ZoneStyle.isVideo(Wallpaper.getWallpaperPath("")) ? "file://" + Wallpaper.getWallpaperPath("") : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 960
            layer.enabled: true
            // `.wall.blur`: blur(34px) saturate(110%)
            layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64; blurMultiplier: 1.6; saturation: 0.1 }
        }
        Rectangle { anchors.fill: parent; color: Fz.scrimDeep }
        MouseArea { anchors.fill: parent; onClicked: win.hide() }
    }
    Rectangle { anchors.fill: parent; visible: win.mode === "switch"; color: Qt.rgba(0, 0, 0, 0.001)
                MouseArea { anchors.fill: parent; onClicked: win.hide() } }

    Item {
        id: keys
        focus: true
        Keys.onPressed: (e) => {
            if (e.key === Qt.Key_Escape) { win.hide(); e.accepted = true; }
            else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Right) { win.cycle(1); e.accepted = true; }
            else if (e.key === Qt.Key_Backtab || e.key === Qt.Key_Left) { win.cycle(-1); e.accepted = true; }
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { win.focusWin(win.apps[win.selApp]); e.accepted = true; }
        }
        Keys.onReleased: (e) => { if (win.mode === "switch" && (e.key === Qt.Key_Alt || e.key === Qt.Key_Meta)) win.focusWin(win.apps[win.selApp]); }
    }

    // ---------- workspaces ----------
    Row {
        visible: win.mode === "overview"
        anchors.horizontalCenter: parent.horizontalCenter
        y: 24
        spacing: 12
        Repeater {
            model: 8
            delegate: Rectangle {
                id: wt
                required property int index
                readonly property int n: index + 1
                readonly property bool on: n === win.shownWs
                width: 150; height: 94; radius: 12
                color: Fz.crust
                border.width: on ? 2.5 : 1
                border.color: on ? Fz.acc : Fz.fg(0.1)
                clip: true
                RoundImage { anchors.fill: parent; anchors.margins: 1; radius: 11; source: wall.source; opacity: 0.7 }
                Repeater {
                    model: win.all.filter(t => win.wsId(t) === wt.n && t.lastIpcObject && t.lastIpcObject.at)
                    delegate: Rectangle {
                        required property var modelData
                        readonly property var o: modelData.lastIpcObject
                        readonly property real kx: 150 / Math.max(1, win.width)
                        readonly property real ky: 94 / Math.max(1, win.height)
                        x: o.at[0] * kx; y: o.at[1] * ky; width: Math.max(6, o.size[0] * kx); height: Math.max(6, o.size[1] * ky)
                        radius: 3; color: Fz.accA(0.55)
                    }
                }
                Rectangle {
                    x: 6; y: 6; width: nT.implicitWidth + 12; height: nT.implicitHeight + 2; radius: 6
                    color: Fz.surf(0.75)
                    FText { id: nT; anchors.centerIn: parent; text: wt.n; px: 11; weight: Font.Bold }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { win.shownWs = wt.n; win.selWin = 0; }
                    onDoubleClicked: { Hyprland.dispatch("hl.dsp.focus({ workspace = " + wt.n + " })"); win.hide(); } }
            }
        }
        Rectangle {
            width: 94; height: 94; radius: 12; color: Fz.crust; border.width: 1; border.color: Fz.fg(0.1)
            FIcon { anchors.centerIn: parent; name: "o-plus"; color: Fz.acc }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: { let id = 1; while (win.occupied(id) && id < 10) id++; Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })"); win.hide(); } }
        }
    }

    // ---------- filter ----------
    Glass {
        visible: win.mode === "overview"
        x: (parent.width - width) / 2
        y: 140
        width: 420; height: 44; radius: 14
        Row {
            x: 14; anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            FIcon { name: "o-search"; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
            Item {
                width: 420 - 28 - 17 - 20 - wsLabel.implicitWidth; height: 22; anchors.verticalCenter: parent.verticalCenter
                TextInput {
                    id: field; anchors.fill: parent; verticalAlignment: TextInput.AlignVCenter
                    color: Fz.tx; font.family: Fz.font; font.pointSize: 14 * 0.75; clip: true
                    onTextChanged: { win.filter = text; win.selWin = 0; }
                    Keys.onPressed: (e) => {
                        if (e.key === Qt.Key_Escape) { win.hide(); e.accepted = true; }
                        else if (e.key === Qt.Key_Right || e.key === Qt.Key_Down) { win.selWin = Math.min(win.selWin + 1, win.wsWindows.length - 1); e.accepted = true; }
                        else if (e.key === Qt.Key_Left || e.key === Qt.Key_Up) { win.selWin = Math.max(0, win.selWin - 1); e.accepted = true; }
                        else if (e.key === Qt.Key_Tab) { win.shownWs = win.shownWs % 8 + 1; e.accepted = true; }
                        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { win.focusWin(win.wsWindows[win.selWin]); e.accepted = true; }
                    }
                }
                FText { anchors.verticalCenter: parent.verticalCenter; visible: field.text === ""; text: Fz.tr("Gõ để lọc cửa sổ…"); color: Fz.dim; px: 14 }
            }
            FText { id: wsLabel; text: "Workspace " + win.shownWs; color: Fz.sub; px: 12; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // ---------- window cards `.wc` ----------
    Repeater {
        model: win.mode === "overview" ? win.wsWindows : []
        delegate: Item {
            id: wc
            required property var modelData
            required property int index
            readonly property var r: win.rect(index, win.wsWindows.length)
            readonly property bool on: index === win.selWin
            x: r.x; y: r.y; width: r.w; height: r.h
            Rectangle {
                anchors.fill: parent; anchors.margins: wc.on ? -2.5 : -1
                radius: 16 + (wc.on ? 2.5 : 1)
                color: wc.on ? Fz.acc : Fz.fg(0.1)
            }
            Rectangle {
                id: frame
                anchors.fill: parent; radius: 16; color: Fz.mantle; clip: true
                Rectangle {
                    width: parent.width; height: 38; color: Fz.crust; radius: 16
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 16; color: Fz.crust }
                    Row {
                        x: 12; anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        FIcon { name: win.icon(wc.modelData); size: 15; color: Fz.glow; anchors.verticalCenter: parent.verticalCenter }
                        FText { width: wc.width - 24 - 15 - 16 - 30; elide: Text.ElideRight; text: wc.modelData.title; px: 13; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                    }
                    FIconBtn { anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter; width: 26; height: 26; ghost: true; icon: "o-x"; iconSize: 14; label: Fz.tr("Đóng cửa sổ")
                               onClicked: Hyprland.dispatch("hl.dsp.window.close({ window = \"address:0x" + wc.modelData.address + "\" })") }
                }
                ScreencopyView {
                    y: 38; width: parent.width; height: parent.height - 38
                    captureSource: win.visible ? wc.modelData.wayland : null
                    live: false
                }
            }
            MouseArea { anchors.fill: parent; anchors.topMargin: 38; cursorShape: Qt.PointingHandCursor; onClicked: win.focusWin(wc.modelData); onEntered: win.selWin = wc.index; hoverEnabled: true }
        }
    }
    FText {
        visible: win.mode === "overview" && win.wsWindows.length === 0
        anchors.centerIn: parent
        text: win.filter ? Fz.tr("Không có cửa sổ nào khớp") : "Workspace " + win.shownWs + Fz.tr(" đang trống")
        color: Fz.sub2; px: 15
    }

    // ---------- app strip (Alt+Tab) `.at` ----------
    Glass {
        visible: win.mode !== "" && win.apps.length > 0
        radius: 24
        x: (parent.width - width) / 2
        y: win.mode === "switch" ? (parent.height - height) / 2 : parent.height - 36 - height
        width: strip.implicitWidth + 20
        height: 110 + 20
        Row {
            id: strip
            x: 10; y: 10
            spacing: 4
            Repeater {
                model: win.apps.slice(0, 10)
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool on: index === win.selApp
                    width: 110; height: 110; radius: 16
                    color: on ? Fz.accA(0.14) : "transparent"
                    border.width: on ? 1.5 : 0; border.color: Fz.acc
                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 52; height: 52; radius: 16; color: Fz.s0
                                    FIcon { anchors.centerIn: parent; name: win.icon(modelData); size: 24; color: Fz.acc } }
                        FText { anchors.horizontalCenter: parent.horizontalCenter; width: Math.min(implicitWidth, 100); elide: Text.ElideRight; text: win.appName(modelData); px: 12; color: on ? Fz.tx : Fz.sub2 }
                    }
                    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: win.selApp = index; onClicked: win.focusWin(modelData) }
                }
            }
        }
    }
    Row {
        visible: win.mode === "overview"
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - 12 - 24
        spacing: 6
        FKbd { text: "Super Tab" }
        FText { text: Fz.tr("tổng quan ·"); px: 12; color: Fz.sub2; anchors.verticalCenter: parent.verticalCenter }
        FKbd { text: "Alt Tab" }
        FText { text: Fz.tr("chuyển ứng dụng · kéo cửa sổ lên workspace khác để di chuyển"); px: 12; color: Fz.sub2; anchors.verticalCenter: parent.verticalCenter }
    }

}
