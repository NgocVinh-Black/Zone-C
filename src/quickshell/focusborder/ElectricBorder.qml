import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

// Zone-C: vien dien (electric border) quanh cua so dang duoc chon.
// Lop phu trong suot, khong nhan chuot; vien duoc ve bang Canvas voi duong
// rang cua rung lien tuc (lay cam hung tu hieu ung "electric border" CSS).
Scope {
    id: root

    // Hinh dang vien
    property real cornerRadius: 12
    property real outset: 2          // khoang cach tu mep cua so ra vien
    property real glowMargin: 24     // cho de ve quang sang
    property real amplitude: 3.2     // do rung cua tia dien (px)

    // Mau: quang sang -> tia -> loi
    property color glowColor: "#1e8fff"
    property color boltColor: "#4cc3ff"
    property color coreColor: "#e8fbff"

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

            Canvas {
                id: bolt
                visible: overlay.local !== null
                x: overlay.local ? overlay.local.x - root.outset - root.glowMargin : 0
                y: overlay.local ? overlay.local.y - root.outset - root.glowMargin : 0
                width: overlay.local ? overlay.local.w + 2 * (root.outset + root.glowMargin) : 0
                height: overlay.local ? overlay.local.h + 2 * (root.outset + root.glowMargin) : 0
                renderStrategy: Canvas.Threaded

                property real time: 0
                property var phases: [0, 0, 0, 0]

                Timer {
                    interval: 33
                    running: bolt.visible
                    repeat: true
                    onTriggered: {
                        bolt.time += 0.033;
                        // doi pha ngau nhien thinh thoang de tia dien "giat"
                        if (Math.random() < 0.35)
                            bolt.phases = [Math.random() * 6.28, Math.random() * 6.28, Math.random() * 6.28, Math.random() * 6.28];
                        bolt.requestPaint();
                    }
                }

                // Diem tren vien hinh chu nhat bo goc theo do dai cung s, kem vector phap tuyen
                function perimeterPoints(x0, y0, w, h, r, step) {
                    let pts = [];
                    let straightW = w - 2 * r, straightH = h - 2 * r;
                    let arc = Math.PI * r / 2;
                    let segs = [
                        { len: straightW, f: t => ({ x: x0 + r + t, y: y0, nx: 0, ny: -1 }) },
                        { len: arc, f: t => { let a = -Math.PI / 2 + t / r; return { x: x0 + w - r + r * Math.cos(a), y: y0 + r + r * Math.sin(a), nx: Math.cos(a), ny: Math.sin(a) }; } },
                        { len: straightH, f: t => ({ x: x0 + w, y: y0 + r + t, nx: 1, ny: 0 }) },
                        { len: arc, f: t => { let a = t / r; return { x: x0 + w - r + r * Math.cos(a), y: y0 + h - r + r * Math.sin(a), nx: Math.cos(a), ny: Math.sin(a) }; } },
                        { len: straightW, f: t => ({ x: x0 + w - r - t, y: y0 + h, nx: 0, ny: 1 }) },
                        { len: arc, f: t => { let a = Math.PI / 2 + t / r; return { x: x0 + r + r * Math.cos(a), y: y0 + h - r + r * Math.sin(a), nx: Math.cos(a), ny: Math.sin(a) }; } },
                        { len: straightH, f: t => ({ x: x0, y: y0 + h - r - t, nx: -1, ny: 0 }) },
                        { len: arc, f: t => { let a = Math.PI + t / r; return { x: x0 + r + r * Math.cos(a), y: y0 + r + r * Math.sin(a), nx: Math.cos(a), ny: Math.sin(a) }; } }
                    ];
                    let total = 0;
                    for (let s of segs) total += s.len;
                    for (let s of segs) {
                        let n = Math.max(1, Math.round(s.len / step));
                        for (let i = 0; i < n; i++) {
                            let p = s.f(s.len * i / n);
                            p.u = pts.length ? pts[pts.length - 1].u + s.len / n / total : 0;
                            pts.push(p);
                        }
                    }
                    return pts;
                }

                function strokeBolt(ctx, pts, amp, seed) {
                    let t = bolt.time, ph = bolt.phases;
                    ctx.beginPath();
                    for (let i = 0; i <= pts.length; i++) {
                        let p = pts[i % pts.length];
                        let u = p.u * Math.PI * 2;
                        let d = Math.sin(u * 23 + t * 9 + ph[0] + seed) * 0.45
                              + Math.sin(u * 61 - t * 14 + ph[1] + seed * 2) * 0.3
                              + Math.sin(u * 131 + t * 23 + ph[2]) * 0.15
                              + (Math.random() - 0.5) * 0.5;
                        let px = p.x + p.nx * d * amp, py = p.y + p.ny * d * amp;
                        if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
                    }
                    ctx.closePath();
                    ctx.stroke();
                }

                onPaint: {
                    let ctx = getContext("2d");
                    ctx.reset();
                    if (!overlay.local) return;

                    let m = root.glowMargin;
                    let pts = perimeterPoints(m, m, width - 2 * m, height - 2 * m, root.cornerRadius + root.outset, 5);
                    ctx.lineJoin = "round";
                    ctx.lineCap = "round";

                    // 1. quang sang rong
                    ctx.shadowColor = root.glowColor;
                    ctx.shadowBlur = 18;
                    ctx.globalAlpha = 0.55;
                    ctx.strokeStyle = root.glowColor;
                    ctx.lineWidth = 5;
                    strokeBolt(ctx, pts, root.amplitude * 0.6, 0);

                    // 2. tia dien chinh
                    ctx.shadowBlur = 10;
                    ctx.globalAlpha = 0.95;
                    ctx.strokeStyle = root.boltColor;
                    ctx.lineWidth = 2.2;
                    strokeBolt(ctx, pts, root.amplitude, 1.7);

                    // 3. tia phu mong, lech pha
                    ctx.shadowBlur = 6;
                    ctx.globalAlpha = 0.6;
                    ctx.lineWidth = 1.2;
                    strokeBolt(ctx, pts, root.amplitude * 1.4, 4.1);

                    // 4. loi sang trang
                    ctx.shadowBlur = 4;
                    ctx.shadowColor = root.coreColor;
                    ctx.globalAlpha = 0.9;
                    ctx.strokeStyle = root.coreColor;
                    ctx.lineWidth = 1;
                    strokeBolt(ctx, pts, root.amplitude * 0.8, 1.7);
                }
            }
        }
    }
}
