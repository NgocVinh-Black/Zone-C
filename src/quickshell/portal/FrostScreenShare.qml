import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"
import "../frost"

// Screen-share picker of the Frost design (ScreenShare.dc.html), driven by zone-c-screenshare (the
// custom picker of xdg-desktop-portal-hyprland): screens, windows or a region, live previews,
// "remember" for a restore token. The answer goes to <request>.out.
PanelWindow {
    id: win
    property bool open: false
    property string reqFile: ""
    property var windows: []
    property int tab: 0
    property int sel: 0
    property bool remember: false
    visible: open
    WlrLayershell.namespace: "zone-c-screenshare"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    readonly property var screens: Quickshell.screens
    readonly property var tops: Hyprland.toplevels ? (Hyprland.toplevels.values || []) : []
    function topFor(w) {
        let a = String(w.addr || "").replace(/^0x/, "").toLowerCase();
        return tops.find(t => String(t.address).toLowerCase() === a) || null;
    }
    readonly property var sources: tab === 0 ? screens.map(s => ({ kind: "screen", value: s.name, name: s.name + (s.model ? " · " + s.model : ""), desc: s.width + "×" + s.height, icon: "s-display", screen: s }))
                                  : tab === 1 ? windows.map(w => ({ kind: "window", value: w.id, name: w.title || w.cls, desc: w.cls, icon: /code/i.test(w.cls) ? "s-code" : /foot|kitty|term/i.test(w.cls) ? "s-terminal" : /nautilus|files|thunar/i.test(w.cls) ? "s-folder" : "s-browser", top: topFor(w) }))
                                  : [{ kind: "region", value: "", name: "Chọn vùng…", desc: "Kéo trên màn hình để chọn", icon: "s-region" }]

    function answer(obj) {
        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$2\" > \"$1.tmp\" && mv \"$1.tmp\" \"$1\"", "_", reqFile + ".out", JSON.stringify(obj)]);
        open = false;
    }
    function share() { let s = sources[sel]; if (s) answer({ kind: s.kind, value: s.value, remember: remember }); }
    Process {
        id: reader
        stdout: StdioCollector { onStreamFinished: { try { win.windows = JSON.parse(this.text).windows || []; } catch (e) { win.windows = []; } win.tab = 0; win.sel = 0; win.open = true; Hyprland.refreshToplevels(); } }
    }
    IpcHandler { target: "screenshare"; function pick(file: string): void { win.reqFile = file; reader.command = ["cat", file]; reader.running = true; } }
    Connections { target: Fz; function onOpenRequest(name, arg) { if (name === "screenshare" && arg) { win.reqFile = arg; reader.command = ["cat", arg]; reader.running = true; } } }

    // `.wall.blur` + `.scrim.night`
    Image {
        anchors.fill: parent; anchors.margins: -60
        source: { let p = Wallpaper.getWallpaperPath(""); return p && !ZoneStyle.isVideo(p) ? "file://" + p : ""; }
        fillMode: Image.PreserveAspectCrop; sourceSize.width: 960
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64; blurMultiplier: 1.6; saturation: 0.1 }
    }
    Rectangle { anchors.fill: parent; color: Fz.scrimNight; MouseArea { anchors.fill: parent; onClicked: win.answer({ kind: "cancel" }) } }
    Item {
        anchors.fill: parent; focus: true
        Keys.onEscapePressed: win.answer({ kind: "cancel" })
        Keys.onReturnPressed: win.share()
        Keys.onLeftPressed: win.sel = Math.max(0, win.sel - 1)
        Keys.onRightPressed: win.sel = Math.min(win.sources.length - 1, win.sel + 1)
    }

    Solid {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 96
        width: 900; height: col.implicitHeight + 48
        radius: 26
        MouseArea { anchors.fill: parent }
        Column {
            id: col
            x: 24; y: 24
            width: parent.width - 48
            spacing: 18
            Row {
                spacing: 14
                Rectangle { width: 48; height: 48; radius: 15; color: Fz.acc
                            FIcon { anchors.centerIn: parent; name: "s-cast"; size: 22; color: Fz.ink } }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    FText { text: "Chia sẻ màn hình"; px: 19; weight: Font.DemiBold }
                    FText { text: "Một ứng dụng muốn ghi hình nội dung bạn chọn · xdg-desktop-portal-hyprland"; px: 13; color: Fz.sub2 }
                }
            }
            FSeg {
                options: [{ label: "Màn hình", icon: "s-display" }, { label: "Cửa sổ", icon: "s-browser" }, { label: "Vùng", icon: "s-region" }]
                current: win.tab
                onPicked: (i) => { win.tab = i; win.sel = 0; }
            }
            Grid {
                width: parent.width
                columns: 3; spacing: 12
                Repeater {
                    model: win.sources
                    delegate: Rectangle {
                        id: src
                        required property var modelData
                        required property int index
                        readonly property bool on: win.sel === index
                        width: (col.width - 24) / 3; height: 10 + 150 + 10 + 36 + 10
                        radius: 16
                        color: on ? Fz.accA(0.08) : Fz.fg(srcMouse.containsMouse ? 0.07 : 0.035)
                        border.width: on ? 2 : 1; border.color: on ? Fz.acc : Fz.fg(0.08)
                        Rectangle {
                            x: 10; y: 10; width: parent.width - 20; height: 150; radius: 11; clip: true; color: Fz.crust
                            ScreencopyView {
                                anchors.fill: parent
                                captureSource: !win.open ? null : src.modelData.kind === "screen" ? src.modelData.screen : src.modelData.kind === "window" && src.modelData.top ? src.modelData.top.wayland : null
                                live: src.modelData.kind === "screen"
                            }
                            Image {
                                visible: src.modelData.kind === "region"
                                anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 600
                                source: { let p = Wallpaper.getWallpaperPath(""); return p && !ZoneStyle.isVideo(p) ? "file://" + p : ""; }
                            }
                            Rectangle { width: parent.width; height: 12; color: Fz.surf(0.7) }
                            Rectangle {
                                visible: src.on
                                anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8
                                width: 24; height: 24; radius: 12; color: Fz.acc
                                FIcon { anchors.centerIn: parent; name: "s-check"; size: 14; color: Fz.ink }
                            }
                        }
                        Row {
                            x: 10; y: 10 + 150 + 10
                            spacing: 8
                            FIcon { name: src.modelData.icon; size: 15; color: Fz.acc; anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                width: src.width - 20 - 23
                                FText { width: parent.width; elide: Text.ElideRight; text: src.modelData.name; px: 13.5; weight: Font.DemiBold }
                                FText { width: parent.width; elide: Text.ElideRight; text: src.modelData.desc; mono: true; px: 11.5; color: Fz.sub }
                            }
                        }
                        MouseArea { id: srcMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.sel = src.index; onDoubleClicked: win.share() }
                    }
                }
            }
            FText { visible: win.tab === 1 && win.windows.length === 0; text: "Không có cửa sổ nào để chia sẻ."; px: 13; color: Fz.sub }
            Grp {
                width: parent.width
                GRow { Lbl { width: col.width - 32 - 14 - 44; title: "Chia sẻ cả âm thanh"; sub: "Ứng dụng tự xử lý âm thanh khi chia sẻ qua portal" } FToggle { enabled: false; opacity: 0.5; anchors.verticalCenter: parent.verticalCenter } }
                GRow { Lbl { width: col.width - 32 - 14 - 44; title: "Ghi nhớ lựa chọn cho trang này"; sub: "Không hỏi lại lần sau" } FToggle { on: win.remember; onToggled: (v) => win.remember = v; anchors.verticalCenter: parent.verticalCenter } }
            }
            Item {
                width: parent.width; height: 42
                FText { anchors.verticalCenter: parent.verticalCenter; text: "Khi đang chia sẻ, thanh bar hiện chấm đỏ và nút dừng"; px: 12.5; color: Fz.sub }
                Row {
                    anchors.right: parent.right
                    spacing: 8
                    FBtn { height: 42; text: "Hủy"; onClicked: win.answer({ kind: "cancel" }) }
                    FBtn { height: 42; width: Math.max(130, implicitWidth); kind: "pri"; text: "Chia sẻ"; onClicked: win.share() }
                }
            }
        }
    }
}
