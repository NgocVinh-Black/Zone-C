import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"
import "../frost"

// Floating quick actions of the Frost design (QuickActions.dc.html): a small glass rail on the right edge
// with a timer (pomodoro, countdown, stopwatch), system usage and screen drawing.
Scope {
    id: qa
    property bool timerOpen: false
    property bool usageOpen: false
    property bool drawOpen: false

    Connections {
        target: FloatingController
        function onSetIndexRequested(screen, index) {
            if (index === "timer" || index === "0") qa.timerOpen = !qa.timerOpen;
            else if (index === "usage" || index === "systemusage" || index === "1") qa.usageOpen = !qa.usageOpen;
            else if (index === "draw" || index === "2") qa.drawOpen = !qa.drawOpen;
        }
        function onShowSystemUsageRequested(screen) { qa.usageOpen = true; }
        function onHideRequested() { qa.timerOpen = false; qa.usageOpen = false; qa.drawOpen = false; }
    }

    // ---------------- timer state ----------------
    QtObject {
        id: tm
        property int mode: 0                 // 0 pomodoro, 1 countdown, 2 stopwatch
        property bool running: false
        property int total: 25 * 60
        property int left: 25 * 60
        property int elapsed: 0
        property int session: 1              // pomodoro focus session 1..4
        property bool onBreak: false
        readonly property int shown: mode === 2 ? elapsed : left
        readonly property string text: { let s = shown; let h = Math.floor(s / 3600); let m = Math.floor((s % 3600) / 60), x = s % 60;
                                         return (h > 0 ? h + ":" + String(m).padStart(2, "0") : String(m).padStart(2, "0")) + ":" + String(x).padStart(2, "0"); }
        readonly property real frac: mode === 2 ? (elapsed % 3600) / 3600 : (total > 0 ? 1 - left / total : 0)
        function reset() {
            running = false; elapsed = 0; onBreak = false;
            total = mode === 0 ? 25 * 60 : (mode === 1 ? total : 0);
            left = total;
        }
    }
    Timer {
        interval: 1000; repeat: true; running: tm.running
        onTriggered: {
            if (tm.mode === 2) { tm.elapsed++; return; }
            tm.left = Math.max(0, tm.left - 1);
            if (tm.left > 0) return;
            if (tm.mode === 0) {
                Quickshell.execDetached(["notify-send", "-a", Fz.tr("Hẹn giờ"), tm.onBreak ? Fz.tr("Hết giờ nghỉ") : Fz.tr("Xong phiên tập trung ") + tm.session + "/4", tm.onBreak ? Fz.tr("Bắt đầu phiên tiếp theo.") : Fz.tr("Nghỉ 5 phút nhé.")]);
                if (tm.onBreak) { tm.onBreak = false; tm.session = tm.session % 4 + 1; tm.total = 25 * 60; }
                else { tm.onBreak = true; tm.total = (tm.session === 4 ? 15 : 5) * 60; }
                tm.left = tm.total;
            } else {
                tm.running = false;
                Quickshell.execDetached(["notify-send", "-a", Fz.tr("Hẹn giờ"), Fz.tr("Hết giờ"), Fz.tr("Đếm ngược đã xong.")]);
            }
        }
    }
    // the bar shows the running timer through TimerState
    Binding { target: TimerState; property: "isActive"; value: tm.running }
    Binding { target: TimerState; property: "timeFormatted"; value: tm.text }

    // ---------------- usage samples ----------------
    property var cpuHist: []
    property real rx: 0
    property real tx: 0
    property string gpu: ""
    property var last: null
    Process {
        id: netSample
        command: ["bash", "-c", "awk 'NR>2 && $1 !~ /lo:/ {r+=$2; t+=$10} END {print r, t}' /proc/net/dev; g=$(cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1); echo \"${g:-}\"; for f in /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input; do [ -f \"$f\" ] && { echo $(( $(cat $f) / 1000 )); break; }; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                let l = this.text.trim().split("\n"), p = l[0].split(" ").map(Number), t = Date.now();
                if (qa.last) { let dt = (t - qa.last.t) / 1000; qa.rx = (p[0] - qa.last.r) / dt; qa.tx = (p[1] - qa.last.x) / dt; }
                qa.last = { r: p[0], x: p[1], t: t };
                qa.gpu = l[1] ? l[1] + "%" + (l[2] ? " · " + l[2] + "°" : "") : "";
            }
        }
    }
    Timer {
        interval: 2000; repeat: true; running: qa.usageOpen; triggeredOnStart: true
        onTriggered: { qa.cpuHist = qa.cpuHist.concat([SysData.cpu]).slice(-30); netSample.running = true; }
    }
    onUsageOpenChanged: usageOpen ? SysData.subscribe() : SysData.unsubscribe()
    function rate(b) { return b > 1048576 ? (b / 1048576).toFixed(1) + " MB/s" : Math.round(b / 1024) + " KB/s"; }

    // ---------------- the rail + panels ----------------
    PanelWindow {
        id: rail
        WlrLayershell.namespace: "qs-floating-overlay"
        WlrLayershell.layer: WlrLayer.Top
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; right: true }
        implicitWidth: 540   // panels plus room for their shadow
        color: "transparent"
        mask: Region {
            Region { item: railBox }
            Region { item: edgeStrip }
            Region { item: timerBox.visible ? timerBox : null }
            Region { item: usageBox.visible ? usageBox : null }
        }

        property real railY: 300
        // The rail tucks into the screen edge (a slim tab stays visible) and slides out on hover or
        // while one of its panels is open, so it never sits on top of an app or a desktop widget.
        // Fullscreen windows hide it completely.
        readonly property var ws: Hyprland.focusedWorkspace
        readonly property bool busy: ws !== null && ws.toplevels && (ws.toplevels.values || []).length > 0
        readonly property bool fullscreen: Hyprland.activeToplevel !== null && Hyprland.activeToplevel.lastIpcObject && Hyprland.activeToplevel.lastIpcObject.fullscreen > 0
        // Hover covers the rail *and* the strip between it and the screen edge: the pointer that slid it
        // out sits at the edge, so without the strip the rail would tuck back under it and bounce. Leaving
        // waits a moment so a pointer passing by doesn't flicker it.
        property bool hovering: false
        readonly property bool pointerIn: railHover.hovered || edgeHover.hovered
        onPointerInChanged: { if (pointerIn) { tuckDelay.stop(); hovering = true; } else tuckDelay.restart(); }
        Timer { id: tuckDelay; interval: 350; onTriggered: rail.hovering = false }
        readonly property bool tucked: !hovering && !qa.timerOpen && !qa.usageOpen && !qa.drawOpen
        visible: !fullscreen
        // the gap between the slid-out rail and the screen edge
        Item {
            id: edgeStrip
            x: railBox.x + railBox.width; y: railBox.y
            width: Math.max(0, rail.width - x); height: railBox.height
            HoverHandler { id: edgeHover }
        }
        Glass {
            id: railBox
            x: rail.tucked ? rail.width - 10 : rail.width - 18 - width
            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            HoverHandler { id: railHover }
            opacity: rail.tucked ? 0.85 : 1
            y: rail.railY
            radius: 26
            width: 52 + 16
            height: railCol.implicitHeight + 16
            Column {
                id: railCol
                x: 8; y: 8
                spacing: 6
                Item {
                    width: 52; height: 18
                    FIcon { anchors.centerIn: parent; name: "a-grip"; size: 16; color: Fz.dim }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.SizeVerCursor
                        property real y0
                        onPressed: (e) => y0 = e.y
                        onPositionChanged: (e) => rail.railY = Math.max(60, Math.min(rail.height - railBox.height - 10, rail.railY + e.y - y0))
                    }
                }
                Repeater {
                    model: [["timer", Fz.tr("Hẹn giờ"), "a-timer"], ["usage", Fz.tr("Tài nguyên"), "a-pulse"], ["draw", Fz.tr("Vẽ"), "a-pen"]]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool on: modelData[0] === "timer" ? qa.timerOpen : modelData[0] === "usage" ? qa.usageOpen : qa.drawOpen
                        width: 52; height: 52; radius: 18
                        color: on ? Fz.acc : (qaMouse.containsMouse ? Fz.fg(0.08) : "transparent")
                        FIcon { anchors.centerIn: parent; name: modelData[2]; size: 22; color: parent.on ? Fz.ink : Fz.sub2 }
                        MouseArea {
                            id: qaMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { if (modelData[0] === "timer") qa.timerOpen = !qa.timerOpen; else if (modelData[0] === "usage") qa.usageOpen = !qa.usageOpen; else qa.drawOpen = !qa.drawOpen; }
                        }
                        Accessible.role: Accessible.Button
                        Accessible.name: modelData[1]
                        Accessible.checked: on
                    }
                }
            }
        }

        // timer panel (right 100, top 90 in the artboard)
        Glass {
            id: timerBox
            visible: qa.timerOpen
            x: rail.width - 100 - width
            y: 90
            width: 300
            height: tcol.implicitHeight + 40
            Column {
                id: tcol
                x: 20; y: 20
                width: parent.width - 40
                spacing: 14
                FSeg {
                    width: parent.width; btnWidth: (parent.width - 6 - 4) / 3; fontSize: 12.5
                    options: ["Pomodoro", Fz.tr("Đếm ngược"), Fz.tr("Bấm giờ")]
                    current: tm.mode
                    onPicked: (i) => { tm.mode = i; if (i === 1 && tm.total === 0) tm.total = 10 * 60; tm.reset(); }
                }
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 190; height: 190
                    Ring { anchors.fill: parent; size: 190; thickness: 1.6 * 190 / 36; value: tm.frac * 100; label: "" }
                    Column {
                        anchors.centerIn: parent
                        FText { anchors.horizontalCenter: parent.horizontalCenter; mono: true; text: tm.text; px: 40; weight: Font.Medium }
                        FText {
                            anchors.horizontalCenter: parent.horizontalCenter; px: 12; color: Fz.sub
                            text: tm.mode === 0 ? (tm.onBreak ? Fz.tr("Giờ nghỉ") : Fz.tr("Phiên tập trung ") + tm.session + "/4") : tm.mode === 1 ? Fz.tr("Đếm ngược") : Fz.tr("Bấm giờ")
                        }
                    }
                }
                Row {
                    visible: tm.mode === 1 && !tm.running
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6
                    Repeater {
                        model: [5, 10, 15, 30]
                        delegate: FBtn { required property var modelData; height: 30; padX: 10; fontSize: 12; kind: tm.total === modelData * 60 ? "pri" : ""
                                         text: modelData + Fz.tr(" phút"); onClicked: { tm.total = modelData * 60; tm.left = tm.total; } }
                    }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    FIconBtn { width: 46; height: 46; radius: 23; icon: "a-reset"; label: Fz.tr("Đặt lại"); onClicked: tm.reset() }
                    FIconBtn { width: 64; height: 46; radius: 23; on: true; icon: tm.running ? "a-pause" : "a-play"; label: tm.running ? Fz.tr("Tạm dừng") : Fz.tr("Bắt đầu"); onClicked: tm.running = !tm.running }
                }
            }
        }

        // usage panel (right 100, top 470)
        Glass {
            id: usageBox
            visible: qa.usageOpen
            x: rail.width - 100 - width
            y: 470
            width: 340
            height: ucol.implicitHeight + 36
            Column {
                id: ucol
                x: 18; y: 18
                width: parent.width - 36
                spacing: 12
                Item {
                    width: parent.width; height: 24
                    FText { anchors.bottom: parent.bottom; text: "CPU"; px: 15; weight: Font.DemiBold }
                    FText { anchors.right: parent.right; anchors.bottom: parent.bottom; mono: true; text: SysData.cpu + "%"; px: 20 }
                }
                Canvas {
                    id: spark
                    width: parent.width; height: 70
                    property var data: qa.cpuHist
                    onDataChanged: requestPaint()
                    onPaint: {
                        let c = getContext("2d"); c.reset();
                        let d = data; if (d.length < 2) return;
                        // samples spread over the full width; the scale follows the load (at least 25%) so an idle CPU isn't a flat floor
                        let top = Math.min(100, Math.max(25, Math.max.apply(null, d) * 1.25));
                        let X = i => i * width / (d.length - 1), Y = v => height - 4 - (height - 8) * Math.min(top, v) / top;
                        c.beginPath(); c.moveTo(0, height);
                        for (let i = 0; i < d.length; i++) c.lineTo(X(i), Y(d[i]));
                        c.lineTo(width, height); c.closePath(); c.fillStyle = Fz.accA(0.12); c.fill();
                        c.beginPath(); for (let i = 0; i < d.length; i++) i ? c.lineTo(X(i), Y(d[i])) : c.moveTo(0, Y(d[0]));
                        c.strokeStyle = Fz.acc; c.lineWidth = 2; c.stroke();
                    }
                }
                Column {
                    width: parent.width
                    spacing: 8
                    UsageRow { label: "RAM"; value: SysData.ramPercent / 100; text: SysData.ramGb.toFixed(1) + " / " + Math.round(SystemInfo.totalRamGb || 0) + " GB" }
                    UsageRow { visible: qa.gpu !== ""; label: "GPU"; value: parseInt(qa.gpu) / 100; text: qa.gpu }
                    UsageRow { label: Fz.tr("Ổ đĩa"); value: SysData.diskPercent / 100; text: Math.round(SysData.diskGb) + " / " + Math.round(SysData.diskTotalGb) + " GB" }
                    Row {
                        FText { width: 80; text: Fz.tr("Mạng"); px: 12.5; color: Fz.sub }
                        FText { mono: true; px: 12.5; text: "↓ " + qa.rate(qa.rx) + " · ↑ " + qa.rate(qa.tx) }
                    }
                }
            }
        }
    }

    // ---------------- drawing overlay ----------------
    PanelWindow {
        id: draw
        visible: qa.drawOpen
        WlrLayershell.namespace: "zone-c-draw"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        property var strokes: []
        property var cur: null
        property string pen: Fz.glow
        property bool eraser: false
        onVisibleChanged: if (!visible) { strokes = []; board.requestPaint(); }

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: qa.drawOpen = false
            Keys.onPressed: (e) => { if (e.key === Qt.Key_Z && (e.modifiers & Qt.ControlModifier)) { draw.strokes = draw.strokes.slice(0, -1); board.requestPaint(); } }
        }
        Canvas {
            id: board
            anchors.fill: parent
            onPaint: {
                let c = getContext("2d"); c.reset();
                c.lineCap = "round"; c.lineJoin = "round";
                for (const s of draw.strokes.concat(draw.cur ? [draw.cur] : [])) {
                    if (s.p.length < 1) continue;
                    c.globalCompositeOperation = s.erase ? "destination-out" : "source-over";
                    c.strokeStyle = s.c; c.lineWidth = s.erase ? 28 : 5;
                    c.beginPath(); c.moveTo(s.p[0].x, s.p[0].y);
                    for (let i = 1; i < s.p.length; i++) c.lineTo(s.p[i].x, s.p[i].y);
                    c.stroke();
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.CrossCursor
                onPressed: (e) => { draw.cur = { c: draw.pen, erase: draw.eraser, p: [{ x: e.x, y: e.y }] }; }
                onPositionChanged: (e) => { if (draw.cur) { draw.cur.p.push({ x: e.x, y: e.y }); board.requestPaint(); } }
                onReleased: { if (draw.cur) { draw.strokes = draw.strokes.concat([draw.cur]); draw.cur = null; board.requestPaint(); } }
            }
        }
        Glass {
            x: 60; y: parent.height - 140 + 0
            radius: 20
            width: drow.implicitWidth + 24
            height: 52
            MouseArea { anchors.fill: parent }
            Row {
                id: drow
                x: 12; anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                FText { text: Fz.tr("Vẽ trên màn hình"); px: 13; weight: Font.DemiBold; rightPadding: 4; anchors.verticalCenter: parent.verticalCenter }
                Repeater {
                    model: [[Fz.tr("Xanh băng"), Fz.glow], [Fz.tr("Trắng"), Fz.tx], [Fz.tr("Đỏ"), Fz.red], [Fz.tr("Vàng"), Fz.yellow], [Fz.tr("Xanh lá"), Fz.green]]
                    delegate: Item {
                        required property var modelData
                        width: 28; height: 28
                        anchors.verticalCenter: parent.verticalCenter
                        readonly property bool on: !draw.eraser && Qt.colorEqual(draw.pen, modelData[1])
                        Rectangle { visible: parent.on; anchors.fill: parent; anchors.margins: -4; radius: 18; color: Fz.acc
                                    Rectangle { anchors.fill: parent; anchors.margins: 2; radius: 16; color: Fz.ink } }
                        Rectangle { anchors.fill: parent; radius: 14; color: modelData[1] }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { draw.pen = modelData[1]; draw.eraser = false; } }
                        Accessible.name: modelData[0]
                    }
                }
                Rectangle { width: 1; height: 26; color: Fz.line2; anchors.verticalCenter: parent.verticalCenter }
                FIconBtn { icon: "a-eraser"; label: Fz.tr("Tẩy"); on: draw.eraser; onClicked: draw.eraser = !draw.eraser; anchors.verticalCenter: parent.verticalCenter }
                FIconBtn { icon: "a-trash"; label: Fz.tr("Xóa hết"); onClicked: { draw.strokes = []; board.requestPaint(); }
                           anchors.verticalCenter: parent.verticalCenter }
                FKbd { text: "Esc"; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }

    component UsageRow: Item {
        property string label
        property real value
        property string text
        width: parent ? parent.width : 0
        height: 17
        FText { width: 80; text: parent.label; px: 12.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
        FBar { x: 80; width: 122; value: parent.value; anchors.verticalCenter: parent.verticalCenter }
        FText { anchors.right: parent.right; text: parent.text; mono: true; px: 12.5; anchors.verticalCenter: parent.verticalCenter }
    }
}
