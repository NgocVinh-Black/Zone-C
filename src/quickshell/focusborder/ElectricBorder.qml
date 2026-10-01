import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../"

// Zone-C: vien dien (electric border) quanh cua so dang duoc chon.
// Lop phu trong suot, khong nhan chuot; vien duoc ve tren GPU bang shader
// electric.frag (turbulence lam lech vien, giong feTurbulence cua CSS).
// Sua electric.frag thi bien dich lai:
//   /usr/lib/qt6/bin/qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o electric.frag.qsb electric.frag
Scope {
    id: root

    // Hinh dang vien
    property real cornerRadius: 12
    property real outset: 2          // khoang cach tu mep cua so ra vien
    property real glowMargin: 40     // cho de ve quang sang
    property real amplitude: ZoneStyle.borderAmplitude // do rung cua tia dien (px), theo preset
    property real surgeSpeed: 0.45   // luong dien chay: vong / giay

    // Mau: quang sang -> tia -> loi
    // (theo preset: Zone Thunder / Zone Crystal, xem singletons/theme/ZoneStyle.qml)
    property color glowColor: ZoneStyle.borderGlow
    property color boltColor: ZoneStyle.borderBolt
    property color coreColor: ZoneStyle.borderCore

    // {x, y, w, h} theo toa do layout cua Hyprland, null neu khong co cua so
    property var win: null

    function refresh() {
        activeProc.running = false;
        activeProc.running = true;
    }

    Process {
        id: activeProc
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let j = JSON.parse(this.text);
                    if (!j || !j.address || !j.mapped || j.hidden || j.fullscreen > 0 || !j.size || j.size[0] <= 0) {
                        root.win = null;
                        return;
                    }
                    let w = { x: j.at[0], y: j.at[1], w: j.size[0], h: j.size[1] };
                    let o = root.win;
                    if (!o || o.x !== w.x || o.y !== w.y || o.w !== w.w || o.h !== w.h)
                        root.win = w;
                } catch (e) {
                    root.win = null;
                }
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            switch (event.name) {
            case "activewindowv2":
            case "openwindow":
            case "closewindow":
            case "movewindowv2":
            case "changefloatingmode":
            case "fullscreen":
            case "workspacev2":
            case "focusedmonv2":
                debounce.restart();
                break;
            }
        }
    }

    Timer {
        id: debounce
        interval: 30
        onTriggered: root.refresh()
    }

    // Hyprland khong phat su kien khi doi kich thuoc cua so -> hoi lai dinh ky
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overlay
            required property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-electric-border"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            mask: Region {}

            // Cua so dang chon co nam tren man hinh nay khong
            readonly property var local: {
                let w = root.win;
                if (!w) return null;
                let sx = modelData.x, sy = modelData.y;
                let cx = w.x + w.w / 2, cy = w.y + w.h / 2;
                if (cx < sx || cy < sy || cx > sx + modelData.width || cy > sy + modelData.height) return null;
                return { x: w.x - sx, y: w.y - sy, w: w.w, h: w.h };
            }

            // Preset co plainBorder (Zone Frost): chi la mot duong vien manh dung yen
            Rectangle {
                visible: overlay.local !== null && ZoneStyle.plainBorder
                x: overlay.local ? overlay.local.x - root.outset : 0
                y: overlay.local ? overlay.local.y - root.outset : 0
                width: overlay.local ? overlay.local.w + 2 * root.outset : 0
                height: overlay.local ? overlay.local.h + 2 * root.outset : 0
                radius: root.cornerRadius + root.outset
                color: "transparent"
                border.width: 2
                border.color: Qt.alpha(root.boltColor, 0.85)
            }

            ShaderEffect {
                id: bolt
                visible: overlay.local !== null && !ZoneStyle.plainBorder
                x: overlay.local ? overlay.local.x - root.outset - root.glowMargin : 0
                y: overlay.local ? overlay.local.y - root.outset - root.glowMargin : 0
                width: overlay.local ? overlay.local.w + 2 * (root.outset + root.glowMargin) : 0
                height: overlay.local ? overlay.local.h + 2 * (root.outset + root.glowMargin) : 0

                // Uniform cho electric.frag
                property size size: Qt.size(width, height)
                property rect rect: Qt.rect(root.glowMargin, root.glowMargin,
                                            Math.max(0, width - 2 * root.glowMargin),
                                            Math.max(0, height - 2 * root.glowMargin))
                property real radius: root.cornerRadius + root.outset
                property real time: 0
                property real amp: root.amplitude
                property real surgeSpeed: root.surgeSpeed
                property color glowColor: root.glowColor
                property color boltColor: root.boltColor
                property color coreColor: root.coreColor

                fragmentShader: Qt.resolvedUrl("electric.frag.qsb")

                // Preset tinh (Zone Crystal): vien dung yen, khong ve lai moi khung hinh
                FrameAnimation {
                    running: bolt.visible && ZoneStyle.animated
                    onTriggered: bolt.time += frameTime
                }
            }
        }
    }
}
