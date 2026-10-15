import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../frost"

// System monitor of the Frost design (TaskManager.dc.html): processes, performance graphs, systemd
// services and boot timing. taskmon.py samples /proc once a second while the window is open.
Scope {
    id: app
    property bool open: false
    property string startTab: "proc"

    function show(tab) { startTab = tab || "proc"; open = true; }
    Connections { target: Fz; function onOpenRequest(name, arg) { if (name === "taskmanager") app.open ? (app.open = false) : app.show(arg); } }
    IpcHandler {
        target: "taskmanager"
        function toggle(): void { app.open ? (app.open = false) : app.show(""); }
        function open(tab: string): void { app.show(tab); }
    }

    LazyLoader {
        active: app.open
        FloatingWindow {
            id: win
            title: "Zone-C · Giám sát hệ thống"
            implicitWidth: 1320
            implicitHeight: 810
            minimumSize: Qt.size(980, 600)
            color: Fz.mantle
            visible: true
            onVisibleChanged: if (!visible) app.open = false

            readonly property var tabKeys: ["proc", "perf", "svc", "boot"]
            property int tab: Math.max(0, tabKeys.indexOf(app.startTab))

            // ---------------- samples ----------------
            property var info: ({ cpuModel: "", threads: 0 })
            property var s: null
            property var hist: ({ cpu: [], ram: [], disk: [], net: [], gpu: [] })
            property real netPeak: 1
            property string q: ""
            property int selPid: -1
            property int res: 0
            Process {
                running: true
                command: ["python3", Quickshell.shellDir + "/apps/taskmon.py"]
                stdout: SplitParser {
                    onRead: (line) => {
                        let d; try { d = JSON.parse(line); } catch (e) { return; }
                        if (d.kind === "static") { win.info = d; return; }
                        win.s = d;
                        let h = win.hist, push = (k, v) => h[k] = h[k].concat([v]).slice(-60);
                        push("cpu", d.cpu); push("ram", d.mem.total ? d.mem.used / d.mem.total * 100 : 0);
                        push("disk", d.disk ? d.disk.busy : 0);
                        win.netPeak = Math.max(win.netPeak * 0.98, d.net.rx, d.net.tx, 65536);
                        push("net", d.net.rx);
                        push("gpu", d.gpu ? d.gpu.busy : 0);
                        win.hist = h;
                        if (win.selPid === -1 && d.list.length) win.selPid = d.list[0].pid;
                    }
                }
            }

            function rate(b) { return b >= 1048576 ? (b / 1048576).toFixed(1) + " MB/s" : b >= 1024 ? Math.round(b / 1024) + " KB/s" : (b > 0 ? b + " B/s" : "0"); }
            function mem(b) { return b >= 1073741824 ? (b / 1073741824).toFixed(1) + " GB" : Math.round(b / 1048576) + " MB"; }
            function gib(b) { return (b / 1073741824).toFixed(1); }
            function uptime(sec) { let h = Math.floor(sec / 3600), m = Math.floor(sec % 3600 / 60), x = sec % 60; return h + ":" + String(m).padStart(2, "0") + ":" + String(x).padStart(2, "0"); }
            function pretty(g) {
                if (g.name === "quickshell") return "quickshell (Zone-C)";
                let e = DesktopEntries.heuristicLookup(g.name);
                return e && e.name ? e.name : g.name;
            }
            readonly property var procs: {
                if (!s) return [];
                let ql = q.trim().toLowerCase();
                return s.list.map(g => Object.assign({ label: pretty(g) }, g))
                             .filter(g => !ql || g.label.toLowerCase().indexOf(ql) !== -1 || g.name.toLowerCase().indexOf(ql) !== -1 || String(g.pid).indexOf(ql) === 0);
            }
            readonly property var selProc: procs.find(p => p.pid === selPid) || null

            readonly property var resources: {
                let d = s, out = [];
                if (!d) return out;
                let m = d.mem, cores = info.threads || d.cores.length;
                out.push({ k: "cpu", n: "CPU", v: Math.round(d.cpu) + "%" + (d.temp ? " · " + d.temp + "°C" : ""), big: Math.round(d.cpu) + "%",
                           desc: (info.cpuModel || "CPU") + " · " + cores + " luồng",
                           kv: [["Tiến trình", String(d.procs)], ["Luồng", d.threads.toLocaleString("vi-VN")], ["Nhiệt độ", d.temp ? d.temp + "°C" : "–"], ["Uptime", uptime(d.uptime)]] });
                out.push({ k: "ram", n: "Bộ nhớ", v: gib(m.used) + " / " + Math.round(m.total / 1073741824) + " GiB", big: Math.round(m.used / m.total * 100) + "%",
                           desc: "RAM " + Math.round(m.total / 1073741824) + " GiB",
                           kv: [["Đang dùng", gib(m.used) + " GiB"], ["Đệm", gib(m.cache) + " GiB"], ["Swap", gib(m.swapUsed) + " / " + gib(m.swapTotal) + " GiB"], ["Trống", gib(m.avail) + " GiB"]] });
                if (d.disk) out.push({ k: "disk", n: "Ổ đĩa", v: d.disk.name + " · " + d.disk.busy + "%", big: d.disk.busy + "%",
                           desc: (d.disk.model || d.disk.name) + " · " + Math.round(d.disk.size / 1e9) + " GB",
                           kv: [["Đọc", rate(d.disk.read)], ["Ghi", rate(d.disk.write)], ["Thiết bị", d.disk.name], ["Dung lượng", Math.round(d.disk.size / 1e9) + " GB"]] });
                out.push({ k: "net", n: d.net.wifi ? "Wi-Fi" : "Mạng", v: "↓ " + (d.net.rx / 1048576).toFixed(1) + " · ↑ " + (d.net.tx / 1048576).toFixed(1) + " MB/s", big: rate(d.net.rx),
                           desc: d.net.iface || "Không có kết nối",
                           kv: [["Nhận", rate(d.net.rx)], ["Gửi", rate(d.net.tx)], ["IPv4", d.net.ip || "–"], ["Giao diện", d.net.iface || "–"]] });
                if (d.gpu) out.push({ k: "gpu", n: "GPU", v: d.gpu.busy + "%" + (d.gpu.temp ? " · " + d.gpu.temp + "°C" : ""), big: d.gpu.busy + "%", desc: "GPU",
                           kv: [["Video RAM", mem(d.gpu.vram)], ["Nhiệt độ", d.gpu.temp ? d.gpu.temp + "°C" : "–"], ["Tải", d.gpu.busy + "%"], ["", ""]] });
                return out;
            }
            readonly property var curRes: resources[Math.min(res, resources.length - 1)] || null
            function series(k) { return k === "net" ? hist.net.map(v => v / netPeak * 100) : hist[k]; }

            // ---------------- services & boot ----------------
            readonly property var sysUnits: ["NetworkManager.service", "bluetooth.service", "sddm.service", "ufw.service", "firewalld.service", "cups.service", "power-profiles-daemon.service", "upower.service", "snapper-timeline.timer", "reflector.timer", "paccache.timer", "fstrim.timer"]
            readonly property var userUnits: ["pipewire.service", "wireplumber.service", "pipewire-pulse.service", "xdg-desktop-portal.service", "gnome-keyring-daemon.service", "zone-c-notify.service"]
            readonly property var unitDesc: ({ "NetworkManager.service": "Quản lý mạng", "bluetooth.service": "Bluetooth (bluez)", "sddm.service": "Màn hình đăng nhập", "ufw.service": "Tường lửa",
                "firewalld.service": "Tường lửa", "cups.service": "In ấn", "power-profiles-daemon.service": "Chế độ năng lượng", "upower.service": "Pin & nguồn",
                "snapper-timeline.timer": "Snapshot định kỳ", "reflector.timer": "Xếp hạng mirror", "paccache.timer": "Dọn bộ đệm pacman", "fstrim.timer": "TRIM ổ SSD",
                "pipewire.service": "Máy chủ âm thanh", "wireplumber.service": "Quản lý phiên âm thanh", "pipewire-pulse.service": "Tương thích PulseAudio",
                "xdg-desktop-portal.service": "Cổng ứng dụng (portal)", "gnome-keyring-daemon.service": "Kho khóa", "zone-c-notify.service": "Thông báo Zone-C" })
            property var units: []
            property var boot: ({ total: "", parts: "", blame: [] })
            Process {
                id: unitProc
                running: win.tab === 2
                command: ["bash", "-c", "systemctl show -p Id,Description,ActiveState,SubState,LoadState " + win.sysUnits.join(" ") + "; echo '#USER'; systemctl --user show -p Id,Description,ActiveState,SubState,LoadState " + win.userUnits.join(" ")]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let out = [], user = false;
                        for (const block of this.text.split(/\n\n|#USER\n/)) {
                            if (block.indexOf("#USER") !== -1) user = true;
                            let o = {};
                            block.split("\n").forEach(l => { let i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1); });
                            if (!o.Id || o.LoadState !== "loaded") { if (/#USER/.test(block)) user = true; continue; }
                            out.push({ id: o.Id, user: user || win.userUnits.indexOf(o.Id) !== -1, desc: win.unitDesc[o.Id] || o.Description, active: o.ActiveState, sub: o.SubState });
                        }
                        win.units = out;
                    }
                }
            }
            Timer { interval: 3000; repeat: true; running: win.tab === 2; onTriggered: unitProc.running = true }
            Process {
                running: win.tab === 3
                command: ["bash", "-c", "systemd-analyze 2>/dev/null | head -1; echo '#'; systemd-analyze blame --no-pager 2>/dev/null | head -8"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let parts = this.text.split("\n#\n"), head = parts[0] || "";
                        let total = (head.match(/=\s*([\d.]+(?:min )?[\d.]*m?s)/) || [])[1] || "";
                        let segs = [];
                        head.replace(/([\d.]+(?:min )?[\d.]*m?s) \((\w+)\)/g, (m, t, w) => { segs.push(w + " " + t); return m; });
                        let toMs = t => { let ms = 0; t.replace(/([\d.]+)(min|ms|s)/g, (m, v, u) => { ms += parseFloat(v) * (u === "min" ? 60000 : u === "s" ? 1000 : 1); return m; }); return ms; };
                        let blame = (parts[1] || "").trim().split("\n").filter(l => l.trim()).map(l => { let m = l.trim().match(/^(.+?)\s+(\S+\.\S+|\S+)$/); let t = l.trim().split(/\s+/); let unit = t.pop(); let time = t.join(" "); return { n: unit.replace(/\.service$/, ""), t: time, ms: toMs(time) }; });
                        let max = Math.max(1, ...blame.map(b => b.ms));
                        win.boot = { total: total, parts: segs.join(" + "), blame: blame.map(b => Object.assign(b, { w: b.ms / max })) };
                    }
                }
            }
            Process { id: act; onExited: unitProc.running = true }

            Item {
                id: keys
                anchors.fill: parent
                focus: true
                Keys.onPressed: (e) => {
                    if (details.visible) { if (e.key === Qt.Key_Escape) { details.visible = false; e.accepted = true; } return; }
                    let i = win.procs.findIndex(p => p.pid === win.selPid);
                    if (win.tab !== 0) return;
                    if (e.key === Qt.Key_Down) { let p = win.procs[Math.min(i + 1, win.procs.length - 1)]; if (p) win.selPid = p.pid; e.accepted = true; }
                    else if (e.key === Qt.Key_Up) { let p = win.procs[Math.max(0, i - 1)]; if (p) win.selPid = p.pid; e.accepted = true; }
                    else if (e.key === Qt.Key_Delete) { win.kill(); e.accepted = true; }
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { details.show(); e.accepted = true; }
                    else if ((e.modifiers & Qt.ControlModifier) && e.key === Qt.Key_F) { search.input.forceActiveFocus(); e.accepted = true; }
                }
            }
            function kill() {
                let p = selProc;
                if (!p) return;
                let cmd = ["kill", "-TERM"].concat(p.pids.map(String));
                Quickshell.execDetached(p.mine ? cmd : ["pkexec"].concat(cmd));
            }

            // ---------------- title bar ----------------
            Rectangle {
                width: parent.width; height: 56
                color: Fz.crust
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Fz.line }
                Row {
                    x: 16; anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    FIcon { name: "TaskManager:m-pulse"; color: Fz.acc; anchors.verticalCenter: parent.verticalCenter }
                    FText { text: "Giám sát hệ thống"; px: 14; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                    Item { width: 10; height: 1 }
                    FSeg { options: ["Tiến trình", "Hiệu năng", "Dịch vụ", "Khởi động"]; current: win.tab; onPicked: (i) => win.tab = i; anchors.verticalCenter: parent.verticalCenter }
                }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    FInput {
                        id: search
                        width: 240; height: 36; radius: 11; fontSize: 13; icon: "TaskManager:m-search"
                        color: Fz.well(0.25); border.color: input.activeFocus ? Fz.glow : Fz.line
                        placeholder: "Tìm tiến trình"
                        onTextChanged: { win.q = text; if (text) win.tab = 0; }
                        Keys.onEscapePressed: { text = ""; keys.forceActiveFocus(); }
                    }
                    FIconBtn { ghost: true; icon: "TaskManager:m-x"; iconSize: 15; label: "Đóng"; onClicked: app.open = false }
                }
            }

            // ---------------- body ----------------
            Item {
                id: body
                x: 20; y: 56 + 16
                width: parent.width - 40
                height: parent.height - 56 - 52 - 32

                // Tiến trình
                Column {
                    visible: win.tab === 0
                    anchors.fill: parent
                    spacing: 10
                    Row {
                        width: parent.width
                        spacing: 10
                        Repeater {
                            model: win.resources.slice(0, 4)
                            delegate: Mc {
                                required property var modelData
                                width: (body.width - 30) / 4; height: 62
                                Column {
                                    x: 14; anchors.verticalCenter: parent.verticalCenter
                                    FText { text: parent.parent.modelData.n; px: 12; color: Fz.sub }
                                    FText { text: parent.parent.modelData.big; mono: true; px: 20; weight: Font.Medium }
                                }
                                Spark { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; data: win.series(parent.modelData.k) }
                            }
                        }
                    }
                    Pr {
                        header: true
                        width: parent.width; height: 32
                    }
                    ListView {
                        id: plist
                        width: parent.width; height: parent.height - 62 - 32 - 20
                        clip: true
                        spacing: 1
                        model: win.procs
                        boundsBehavior: Flickable.StopAtBounds
                        delegate: Pr {
                            required property var modelData
                            width: plist.width
                            p: modelData
                            on: modelData.pid === win.selPid
                            onPicked: { win.selPid = modelData.pid; keys.forceActiveFocus(); }
                            onOpened: { win.selPid = modelData.pid; details.show(); }
                        }
                    }
                }

                // Hiệu năng
                Row {
                    visible: win.tab === 1
                    anchors.fill: parent
                    spacing: 16
                    Column {
                        width: 260
                        spacing: 4
                        Repeater {
                            model: win.resources
                            delegate: Rectangle {
                                id: side
                                required property var modelData
                                required property int index
                                width: 260; height: 58; radius: 12
                                color: win.res === index ? Fz.accA(0.13) : (sideMouse.containsMouse ? Fz.fg(0.05) : "transparent")
                                Row {
                                    x: 12; anchors.verticalCenter: parent.verticalCenter
                                    spacing: 12
                                    Spark { data: win.series(side.modelData.k); anchors.verticalCenter: parent.verticalCenter }
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        FText { text: side.modelData.n; px: 13.5; weight: Font.DemiBold }
                                        FText { text: side.modelData.v; mono: true; px: 11.5; color: Fz.sub }
                                    }
                                }
                                MouseArea { id: sideMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.res = side.index }
                            }
                        }
                    }
                    Mc {
                        width: parent.width - 276; height: parent.height
                        Column {
                            x: 16; y: 16
                            width: parent.width - 32
                            height: parent.height - 32
                            spacing: 10
                            Item {
                                width: parent.width; height: 36
                                Row {
                                    anchors.baseline: big.baseline
                                    spacing: 12
                                    FText { id: ttl; text: win.curRes ? win.curRes.n : ""; px: 22; weight: Font.DemiBold }
                                    FText { anchors.baseline: ttl.baseline; text: win.curRes ? win.curRes.desc : ""; px: 13; color: Fz.sub }
                                }
                                FText { id: big; anchors.right: parent.right; anchors.bottom: parent.bottom; text: win.curRes ? win.curRes.big : ""; mono: true; px: 28 }
                            }
                            Canvas {
                                id: chart
                                width: parent.width
                                height: Math.min(300, parent.height - 36 - 16 - (cores.visible ? cores.height : 0) - 60 - 40)
                                property var data: win.curRes ? win.series(win.curRes.k) : []
                                onDataChanged: requestPaint()
                                onWidthChanged: requestPaint()
                                onPaint: {
                                    let c = getContext("2d"); c.reset();
                                    let W = width, H = height * 250 / 260;
                                    c.strokeStyle = Fz.fg(0.07); c.lineWidth = 1;
                                    for (const f of [0.25, 0.5, 0.75]) { c.beginPath(); c.moveTo(0, Math.round(H * f) + 0.5); c.lineTo(W, Math.round(H * f) + 0.5); c.stroke(); }
                                    let d = data; if (d.length < 2) return;
                                    let X = i => (60 - d.length + i) * W / 59, Y = v => H - Math.min(100, v) / 100 * H;
                                    c.beginPath(); c.moveTo(X(0), Y(d[0])); for (let i = 1; i < d.length; i++) c.lineTo(X(i), Y(d[i]));
                                    c.lineTo(W, height); c.lineTo(X(0), height); c.closePath(); c.fillStyle = Fz.accA(0.1); c.fill();
                                    c.beginPath(); c.moveTo(X(0), Y(d[0])); for (let i = 1; i < d.length; i++) c.lineTo(X(i), Y(d[i]));
                                    c.strokeStyle = Fz.acc; c.lineWidth = 2; c.lineJoin = "round"; c.stroke();
                                }
                            }
                            Item {
                                width: parent.width; height: 16
                                FText { text: "60 giây trước"; mono: true; px: 11.5; color: Fz.dim }
                                FText { anchors.right: parent.right; text: "0"; mono: true; px: 11.5; color: Fz.dim }
                            }
                            Grid {
                                id: cores
                                visible: win.curRes && win.curRes.k === "cpu"
                                width: parent.width
                                columns: 8; columnSpacing: 8; rowSpacing: 8
                                Repeater {
                                    model: win.s ? win.s.cores : []
                                    delegate: Column {
                                        required property var modelData
                                        required property int index
                                        width: (body.width - 276 - 32 - 56) / 8
                                        spacing: 4
                                        Rectangle {
                                            width: parent.width; height: 44; radius: 6; color: Fz.fg(0.06); clip: true
                                            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: Math.max(4, modelData) / 100 * 44; color: Fz.acc; opacity: Math.min(1, 0.45 + modelData / 60) }
                                        }
                                        FText { text: "CPU" + index + " " + Math.round(modelData) + "%"; mono: true; px: 11; color: Fz.sub }
                                    }
                                }
                            }
                        }
                        Row {
                            x: 16; anchors.bottom: parent.bottom; anchors.bottomMargin: 16
                            width: parent.width - 32
                            spacing: 10
                            Repeater {
                                model: win.curRes ? win.curRes.kv : []
                                delegate: Column {
                                    required property var modelData
                                    width: (parent.width - 30) / 4
                                    FText { text: modelData[0]; px: 11.5; color: Fz.sub }
                                    FText { text: modelData[1]; mono: true; px: 14 }
                                }
                            }
                        }
                    }
                }

                // Dịch vụ
                Flickable {
                    visible: win.tab === 2
                    anchors.fill: parent
                    contentHeight: svcGrp.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Grp {
                        id: svcGrp
                        width: parent.width
                        Repeater {
                            model: win.units
                            delegate: GRow {
                                required property var modelData
                                padY: 8
                                implicitHeight: 50
                                readonly property bool running: modelData.active === "active"
                                readonly property bool waiting: modelData.id.endsWith(".timer") && modelData.active === "active"
                                Rectangle { width: 8; height: 8; radius: 4; color: Fz.acc; anchors.verticalCenter: parent.verticalCenter }
                                Column {
                                    width: parent.width - 8 - 3 * 14 - chip.width - btn.width
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    FText { text: modelData.id; mono: true; px: 13; weight: Font.Medium }
                                    FText { text: modelData.desc + (modelData.user ? " · user" : ""); px: 12.5; color: Fz.sub }
                                }
                                FChip {
                                    id: chip; anchors.verticalCenter: parent.verticalCenter
                                    kind: waiting ? "" : running ? "ok" : "bad"
                                    text: waiting ? "Chờ hẹn giờ" : running ? "Đang chạy" : modelData.active === "failed" ? "Lỗi" : "Đã dừng"
                                }
                                FBtn {
                                    id: btn; height: 30; fontSize: 12; anchors.verticalCenter: parent.verticalCenter
                                    text: running ? "Khởi động lại" : "Khởi động"
                                    onClicked: { act.command = ["systemctl"].concat(modelData.user ? ["--user"] : []).concat([running ? "restart" : "start", modelData.id]); act.running = true; }
                                }
                            }
                        }
                    }
                }

                // Khởi động
                Column {
                    visible: win.tab === 3
                    width: parent.width
                    spacing: 10
                    Mc {
                        width: parent.width; height: 80
                        Row {
                            x: 16; anchors.verticalCenter: parent.verticalCenter
                            spacing: 30
                            Column {
                                FText { text: "Thời gian khởi động"; px: 12; color: Fz.sub }
                                FText { text: win.boot.total || "–"; mono: true; px: 26 }
                            }
                            FText { anchors.verticalCenter: parent.verticalCenter; text: win.boot.parts; mono: true; px: 12.5; color: Fz.sub2 }
                        }
                    }
                    Grp {
                        width: parent.width
                        Repeater {
                            model: win.boot.blame
                            delegate: GRow {
                                required property var modelData
                                implicitHeight: 46; padY: 6
                                FText { width: parent.width - 300 - 60 - 28; elide: Text.ElideRight; text: modelData.n; mono: true; px: 13; weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
                                FBar { width: 300; value: modelData.w; anchors.verticalCenter: parent.verticalCenter }
                                FText { width: 60; horizontalAlignment: Text.AlignRight; text: modelData.t; mono: true; px: 13.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
                            }
                        }
                    }
                }
            }

            // ---------------- footer ----------------
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 52
                color: Fz.crust
                Rectangle { width: parent.width; height: 1; color: Fz.line }
                FText {
                    x: 20; anchors.verticalCenter: parent.verticalCenter; px: 12.5; color: Fz.sub
                    text: win.tab === 0 ? (win.s ? win.procs.length + " tiến trình · CPU " + Math.round(win.s.cpu) + "% · RAM " + win.gib(win.s.mem.used) + " GiB" : "Đang đọc…")
                        : win.tab === 2 ? "systemd · " + win.units.length + " đơn vị hiển thị" : win.tab === 3 ? "systemd-analyze blame" : "Cập nhật mỗi giây"
                }
                Row {
                    visible: win.tab === 0
                    anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    FBtn { text: "Chi tiết"; onClicked: details.show() }
                    FBtn { kind: "danger"; icon: "TaskManager:m-stop"; iconSize: 14; text: "Kết thúc tiến trình"; onClicked: win.kill() }
                }
            }

            // ---------------- details sheet ----------------
            Rectangle {
                id: details
                visible: false
                anchors.fill: parent
                color: Fz.surf(0.45)
                property var p: null
                property string cmd: ""
                property string started: ""
                function show() {
                    if (!win.selProc) return;
                    p = win.selProc; cmd = ""; started = "";
                    detProc.command = ["ps", "-o", "lstart=,args=", "-p", String(p.pid)];
                    detProc.running = true;
                    visible = true;
                }
                Process {
                    id: detProc
                    stdout: StdioCollector { onStreamFinished: { let t = this.text.trim(); details.started = t.slice(0, 24).trim(); details.cmd = t.slice(24).trim(); } }
                }
                MouseArea { anchors.fill: parent; onClicked: details.visible = false }
                Solid {
                    anchors.centerIn: parent
                    width: 560; height: dcol.implicitHeight + 48
                    radius: 22
                    MouseArea { anchors.fill: parent }
                    Column {
                        id: dcol
                        x: 24; y: 24
                        width: parent.width - 48
                        spacing: 14
                        Row {
                            spacing: 12
                            Rectangle { width: 40; height: 40; radius: 12; color: Fz.s0
                                        FText { anchors.centerIn: parent; text: details.p ? details.p.label.charAt(0).toUpperCase() : ""; px: 16; weight: Font.Bold; color: Fz.acc } }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                FText { text: details.p ? details.p.label : ""; px: 16; weight: Font.DemiBold }
                                FText { text: details.p ? details.p.name + " · " + details.p.user : ""; mono: true; px: 12; color: Fz.sub }
                            }
                        }
                        Rectangle {
                            width: parent.width; height: cmdText.implicitHeight + 20; radius: 12
                            color: Fz.well(0.25); border.width: 1; border.color: Fz.line
                            FText { id: cmdText; x: 12; y: 10; width: parent.width - 24; wrapMode: Text.WrapAnywhere; maximumLineCount: 4; elide: Text.ElideRight; text: details.cmd || "…"; mono: true; px: 12 }
                        }
                        Grid {
                            columns: 2; columnSpacing: 20; rowSpacing: 8
                            width: parent.width
                            Repeater {
                                model: details.p ? [["PID", String(details.p.pid)], ["Số tiến trình", String(details.p.n)], ["Luồng", String(details.p.threads)], ["CPU", details.p.cpu.toFixed(1) + "%"],
                                                    ["Bộ nhớ", win.mem(details.p.rss)], ["Đĩa", win.rate(details.p.io)], ["Bắt đầu", details.started || "–"], ["Người dùng", details.p.user]] : []
                                delegate: Item {
                                    required property var modelData
                                    width: (dcol.width - 20) / 2; height: 22
                                    FText { text: modelData[0]; px: 12.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
                                    FText { anchors.right: parent.right; text: modelData[1]; mono: true; px: 12.5; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }
                        Row {
                            anchors.right: parent.right
                            spacing: 8
                            FBtn { text: "Đóng"; onClicked: details.visible = false }
                            FBtn { kind: "danger"; text: "Kết thúc tiến trình"; onClicked: { details.visible = false; win.kill(); } }
                        }
                    }
                }
            }
        }
    }

    // `.mc` metric card
    component Mc: Rectangle {
        radius: 16
        color: Fz.fg(0.035)
        border.width: 1; border.color: Fz.fg(0.08)
    }
    // `.sp` sparkline, 60x30
    component Spark: Canvas {
        property var data: []
        width: 60; height: 30
        onDataChanged: requestPaint()
        onPaint: {
            let c = getContext("2d"); c.reset();
            let d = data; if (!d || d.length < 2) return;
            let pts = d.slice(-20);
            c.beginPath();
            for (let i = 0; i < pts.length; i++) { let x = i * width / (pts.length - 1), y = height - Math.min(100, pts[i]) / 100 * height; i ? c.lineTo(x, y) : c.moveTo(x, y); }
            c.strokeStyle = Fz.acc; c.lineWidth = 1.6; c.lineJoin = "round"; c.stroke();
        }
    }
    // `.pr` process row: name, PID, CPU, memory, disk, network
    component Pr: Rectangle {
        id: pr
        property var p: null
        property bool header: false
        property bool on: false
        signal picked()
        signal opened()
        height: 38; radius: 10
        color: header ? "transparent" : on ? Fz.accA(0.13) : (prMouse.containsMouse ? Fz.fg(0.05) : "transparent")
        readonly property real nameW: width - 28 - 80 - 90 - 90 - 90 - 80 - 50
        Row {
            x: 14; anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Item {
                width: pr.nameW; height: 24
                FText { visible: pr.header; anchors.verticalCenter: parent.verticalCenter; text: "Tiến trình"; px: 12; weight: Font.DemiBold; color: Fz.sub }
                Row {
                    visible: !pr.header
                    spacing: 10
                    Rectangle { width: 24; height: 24; radius: 7; color: Fz.s0
                                FText { anchors.centerIn: parent; text: pr.p ? pr.p.label.charAt(0).toUpperCase() : ""; px: 11; weight: Font.Bold; color: Fz.acc } }
                    FText { id: pn; width: Math.min(implicitWidth, pr.nameW - 34 - pu.implicitWidth - 10); elide: Text.ElideRight; text: pr.p ? pr.p.label + (pr.p.n > 1 ? " (" + pr.p.n + ")" : "") : ""; px: 13; anchors.verticalCenter: parent.verticalCenter }
                    FText { id: pu; text: pr.p ? pr.p.user : ""; px: 11.5; color: Fz.dim; anchors.verticalCenter: parent.verticalCenter }
                }
            }
            Num { head: pr.header; width: 80; text: pr.header ? "PID" : pr.p ? String(pr.p.pid) : "" }
            Num { head: pr.header; width: 90; text: pr.header ? "CPU ▾" : pr.p ? pr.p.cpu.toFixed(1) + "%" : ""; hot: !pr.header && pr.p && pr.p.cpu > 5 }
            Num { head: pr.header; width: 90; text: pr.header ? "Bộ nhớ" : pr.p ? win_mem(pr.p.rss) : "" }
            Num { head: pr.header; width: 90; text: pr.header ? "Đĩa" : pr.p ? win_rate(pr.p.io) : "" }
            Num { head: pr.header; width: 80; text: pr.header ? "Mạng" : "–" }
        }
        function win_mem(b) { return b >= 1073741824 ? (b / 1073741824).toFixed(1) + " GB" : Math.round(b / 1048576) + " MB"; }
        function win_rate(b) { return b >= 1048576 ? (b / 1048576).toFixed(1) + " MB/s" : b >= 1024 ? Math.round(b / 1024) + " KB/s" : (b > 0 ? b + " B/s" : "0"); }
        MouseArea { id: prMouse; visible: !pr.header; anchors.fill: parent; hoverEnabled: true; onClicked: pr.picked(); onDoubleClicked: pr.opened() }
    }
    component Num: FText {
        property bool hot: false
        property bool head: false
        horizontalAlignment: Text.AlignRight
        anchors.verticalCenter: parent.verticalCenter
        mono: !head; px: head ? 12 : 12.5
        weight: head ? Font.DemiBold : Font.Normal
        color: head ? Fz.sub : hot ? Fz.yellow : Fz.sub2
    }
}
