import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"
import "../frost"

// First-run setup of the Frost design (Welcome.dc.html): welcome, theme + light/dark, bar layout,
// done. Shown after the start animation on first launch, or with `zone-c ipc call welcome open`.
PanelWindow {
    id: win
    property bool open: false
    visible: open
    WlrLayershell.namespace: "zone-c-welcome"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    property int step: 0
    property string theme: (ZoneStyle.preset || "Zone Frost")
    property string bar: "pills"
    property var presets: []

    Connections { target: Fz; function onOpenRequest(name, arg) { if (name === "welcome") { win.step = 0; win.open = true; } } }
    IpcHandler { target: "welcome"; function open(): void { win.step = 0; win.open = true; } function step(n: int): void { win.step = Math.max(0, Math.min(3, n)); win.open = true; } function close(): void { win.finish(); } }

    Process {
        running: win.open
        command: ["python3", Caching.qsDir + "/settings/scripts/theme_sorter.py", Caching.zoneCDir + "/assets/themes", Caching.stateDir + "/themes", Caching.getCacheDir("themes") + "/theme_sort_cache.json"]
        stdout: StdioCollector { onStreamFinished: { try { win.presets = JSON.parse(this.text).filter(p => p.colors); } catch (e) {} } }
    }
    function applyTheme(name) {
        theme = name;
        let p = presets.find(x => x.name === name);
        if (!p) return;
        let cur = Config.getSetting("theme", {});
        cur.activePreset = name; cur.matugen = false;
        cur.colors = ZoneStyle.presetColors(name, p.colors);
        Config.setSetting("theme", cur);
        ThemeBackend.applyColorObject(cur.colors);
    }
    function applyBar(b) {
        bar = b;
        if (b === "side") Config.updateJsonBulk({ "bar.position": "left" });
        else Config.updateJsonBulk({ "bar.position": "top", "bar.style": b === "pills" ? "modular" : "solid", "bar.distinctPills": b === "pills" });
    }
    function finish() { open = false; }

    // `.wall.blur` + `.scrim.night`
    Image {
        anchors.fill: parent; anchors.margins: -60
        source: { let p = Wallpaper.getWallpaperPath(""); return p && !ZoneStyle.isVideo(p) ? "file://" + p : ""; }
        fillMode: Image.PreserveAspectCrop; sourceSize.width: 960
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64; blurMultiplier: 1.6; saturation: 0.1 }
    }
    Rectangle { anchors.fill: parent; color: Fz.scrimNight }
    MouseArea { anchors.fill: parent }
    Item {
        anchors.fill: parent; focus: true
        Keys.onReturnPressed: win.step < 3 ? win.step++ : win.finish()
        Keys.onEscapePressed: win.finish()
        Keys.onLeftPressed: win.step = Math.max(0, win.step - 1)
    }

    Glass {
        anchors.centerIn: parent
        width: 880; height: col.implicitHeight + 68
        radius: 32
        Column {
            id: col
            x: 34; y: 34
            width: parent.width - 68
            spacing: 24
            Row {
                width: parent.width; spacing: 6
                Repeater { model: 4; delegate: Rectangle { required property int index; width: (col.width - 18) / 4; height: 6; radius: 3; color: index <= win.step ? Fz.acc : Fz.fg(0.14) } }
            }

            // 0 · welcome
            Column {
                visible: win.step === 0
                width: parent.width; topPadding: 20; bottomPadding: 20
                spacing: 14
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 120; height: 120
                    FIcon { id: logo; anchors.fill: parent; name: "wl-zc"; size: 120; color: Fz.acc; layer.enabled: true
                            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Fz.glowA(0.45); shadowBlur: 1; blurMax: 30 } }
                }
                FText { anchors.horizontalCenter: parent.horizontalCenter; text: Fz.tr("Chào mừng đến với Zone-C"); px: 40; weight: Font.DemiBold; font.letterSpacing: -1 }
                FText { anchors.horizontalCenter: parent.horizontalCenter; width: 520; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; css: 1.5
                        text: Fz.tr("Desktop shell cho Hyprland, viết bằng Quickshell. Vài bước để chọn ngôn ngữ, giao diện và bố cục."); px: 16; color: Fz.sub2 }
                FText { anchors.horizontalCenter: parent.horizontalCenter; text: Fz.tr("bởi @NgocVinh-Black · v") + Updater.localVersion; px: 13; color: Fz.sub }
            }

            // 1 · theme
            Column {
                visible: win.step === 1
                width: parent.width
                spacing: 24
                FText { text: Fz.tr("Chọn theme"); px: 26; weight: Font.DemiBold }
                Row {
                    width: parent.width; spacing: 14
                    Repeater {
                        model: [["Zone Thunder", Fz.tr("Video sấm sét · viền điện chạy"), "#0A1633", "#3D9BFF", 0.25], ["Zone Crystal", Fz.tr("Ảnh tĩnh · pha lê xanh"), "#0B1C36", "#38B6FF", 0.35], ["Zone Frost", Fz.tr("Tuyết · panel kính mờ"), "", "", 0.85]]
                        delegate: Opt {
                            required property var modelData
                            width: (col.width - 28) / 3
                            on: win.theme === modelData[0]
                            title: modelData[0]; desc: modelData[1]
                            onClicked: win.applyTheme(modelData[0])
                            Rectangle { anchors.fill: parent; color: modelData[2] || Fz.crust }
                            Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 400; opacity: modelData[4]
                                    source: { let p = Wallpaper.getWallpaperPath(""); return p && !ZoneStyle.isVideo(p) ? "file://" + p : ""; } }
                            // Thunder / Crystal previews: the wallpaper under their deep-blue tint
                            Rectangle { anchors.fill: parent; visible: modelData[2] !== ""; color: modelData[2]; opacity: 1 - modelData[4] }
                            Rectangle { x: 10; y: 10; width: parent.width - 20; height: 12; radius: 6; color: Fz.well(0.45) }
                            Rectangle { anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 12; width: 28; height: 28; radius: 14; color: modelData[3] || Fz.acc }
                        }
                    }
                }
                Item {
                    width: parent.width; height: 36
                    FText { anchors.verticalCenter: parent.verticalCenter; text: Fz.tr("Chế độ"); px: 14 }
                    FSeg { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; options: [Fz.tr("Tối"), Fz.tr("Sáng")]; current: ZoneStyle.isLight ? 1 : 0; onPicked: (i) => ZoneStyle.setMode(i === 1 ? "light" : "dark") }
                }
            }

            // 2 · bar layout
            Column {
                visible: win.step === 2
                width: parent.width
                spacing: 24
                FText { text: Fz.tr("Bố cục bar"); px: 26; weight: Font.DemiBold }
                Row {
                    width: parent.width; spacing: 14
                    Repeater {
                        model: [["pills", Fz.tr("Pill tách rời"), Fz.tr("Mỗi mô-đun một viên")], ["solid", Fz.tr("Đặc"), Fz.tr("Một thanh liền")], ["side", Fz.tr("Bên trái"), Fz.tr("Thanh dọc")]]
                        delegate: Opt {
                            required property var modelData
                            width: (col.width - 28) / 3
                            on: win.bar === modelData[0]
                            title: modelData[1]; desc: modelData[2]
                            onClicked: win.applyBar(modelData[0])
                            Rectangle { anchors.fill: parent; color: Fz.crust }
                            Row {
                                visible: modelData[0] === "pills"
                                x: 12; y: 12; spacing: 6
                                Repeater { model: 8; delegate: Rectangle { width: 22; height: 14; radius: 7; color: Fz.acc } }
                            }
                            Rectangle { visible: modelData[0] === "solid"; width: parent.width; height: 20; color: Fz.s0 }
                            Rectangle { visible: modelData[0] === "side"; width: 20; height: parent.height; color: Fz.s0 }
                        }
                    }
                }
            }

            // 3 · done
            Column {
                visible: win.step === 3
                width: parent.width; topPadding: 24; bottomPadding: 24
                spacing: 14
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 80; height: 80; radius: 40; color: Fz.acc
                            FIcon { anchors.centerIn: parent; name: "wl-check"; size: 38; color: Fz.ink } }
                FText { anchors.horizontalCenter: parent.horizontalCenter; text: Fz.tr("Đã sẵn sàng"); px: 30; weight: Font.DemiBold }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 5
                    FText { text: Fz.tr("Nhấn"); px: 15; color: Fz.sub2; anchors.verticalCenter: parent.verticalCenter }
                    FKbd { text: "Super"; anchors.verticalCenter: parent.verticalCenter }
                    FText { text: Fz.tr("để mở launcher,"); px: 15; color: Fz.sub2; anchors.verticalCenter: parent.verticalCenter }
                    FKbd { text: "Super"; anchors.verticalCenter: parent.verticalCenter }
                    FKbd { text: "/"; anchors.verticalCenter: parent.verticalCenter }
                    FText { text: Fz.tr("để xem phím tắt."); px: 15; color: Fz.sub2; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            Item {
                width: parent.width; height: 44
                FSelect {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 160
                    options: [Fz.tr("Tiếng Việt"), "English", "Deutsch", Fz.tr("Русский")]
                    readonly property var values: ["vi", "en", "de", "ru"]
                    current: Math.max(0, values.indexOf(Config.getSetting("general.language", "vi")))
                    onPicked: (i) => Config.setSetting("general.language", values[i])
                }
                Row {
                    anchors.right: parent.right; spacing: 10
                    FBtn { visible: win.step > 0; height: 44; padX: 20; text: Fz.tr("Quay lại"); onClicked: win.step-- }
                    FBtn { height: 44; padX: 20; kind: "pri"; icon: "wl-r"; iconSize: 16; iconRight: true
                           text: win.step === 0 ? Fz.tr("Bắt đầu") : win.step === 3 ? Fz.tr("Vào desktop") : Fz.tr("Tiếp tục")
                           onClicked: win.step < 3 ? win.step++ : win.finish() }
                }
            }
        }
    }

    // `.opt` choice card with a 120px preview
    component Opt: Rectangle {
        id: opt
        property bool on: false
        property string title
        property string desc
        default property alias preview: pv.data
        signal clicked()
        height: 10 + 120 + 10 + 40 + 10
        radius: 20
        color: Fz.fg(optMouse.containsMouse ? 0.08 : 0.04)
        border.width: on ? 2 : 1; border.color: on ? Fz.acc : Fz.fg(0.1)
        Rectangle { id: pv; x: 10; y: 10; width: parent.width - 20; height: 120; radius: 14; clip: true; color: "transparent" }
        Column {
            x: 10; y: 140
            FText { text: opt.title; px: 14; weight: Font.DemiBold }
            FText { text: opt.desc; px: 12.5; color: Fz.sub }
        }
        MouseArea { id: optMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: opt.clicked() }
    }
}
