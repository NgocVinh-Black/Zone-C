import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"
import "../frost"

// App launcher of the Frost design (Launcher.dc.html): 680px glass 72px from the top, search field,
// three scopes (apps, files, actions), up to seven results and "> command" mode.
PanelWindow {
    id: win
    screen: LauncherController.screen
    visible: LauncherController.isVisible
    WlrLayershell.namespace: "qs-applauncher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    property int scope: 0                 // 0 apps, 1 files, 2 actions
    property int sel: 0
    property string query: ""
    readonly property bool cmdMode: query.charAt(0) === ">"
    readonly property string cmd: query.slice(1).trim()
    property var ranks: ({ focus: {}, launch: {}, context: {} })
    property var fileHits: []
    property var history: []
    property string imeBefore: ""
    readonly property string terminal: { let l = Config.getSetting("launcher", {}); return (l && l.terminalCommand) ? l.terminalCommand : "kitty -e"; }

    onVisibleChanged: {
        if (visible) {
            query = ""; field.text = ""; sel = 0;
            rankProc.running = true;
            imeProbe.running = true;
            focusTimer.restart();
        } else if (imeBefore === "unikey") {
            Quickshell.execDetached(["fcitx5-remote", "-o"]);
            imeBefore = "";
        }
    }
    Timer { id: focusTimer; interval: 40; onTriggered: field.forceActiveFocus() }
    function close() { LauncherController.hide(); }

    // Unikey off while typing in the launcher (footer note of the artboard), restored on close.
    Process {
        id: imeProbe
        command: ["fcitx5-remote", "-n"]
        stdout: StdioCollector { onStreamFinished: { win.imeBefore = this.text.trim(); if (win.imeBefore === "unikey") Quickshell.execDetached(["fcitx5-remote", "-c"]); } }
    }
    Process {
        id: rankProc
        command: ["python3", Caching.qsDir + "/launcher/app_rank.py", "--rank"]
        stdout: StdioCollector { onStreamFinished: { try { win.ranks = JSON.parse(this.text); } catch (e) {} } }
    }
    readonly property string histFile: Caching.cacheDir ? Caching.cacheDir + "/launcher/commands.json" : ""
    FileView { path: win.histFile; onLoaded: { try { win.history = JSON.parse(text()); } catch (e) { win.history = []; } } }
    function remember(c) {
        let h = [c].concat(history.filter(x => x !== c)).slice(0, 10);
        history = h;
        Quickshell.execDetached(["bash", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "_", histFile, JSON.stringify(h)]);
    }

    // ---------- sources ----------
    function appIcon(e) {
        let c = (e.categories || []).join(";").toLowerCase(), n = ((e.name || "") + " " + (e.id || "")).toLowerCase();
        if (n.indexOf("kitty") !== -1) return "l-cat";
        if (c.indexOf("terminalemulator") !== -1) return "l-terminal";
        if (c.indexOf("webbrowser") !== -1) return "l-browser";
        if (c.indexOf("ide") !== -1 || c.indexOf("texteditor") !== -1 || c.indexOf("development") !== -1) return "l-code";
        if (c.indexOf("instantmessaging") !== -1 || c.indexOf("chat") !== -1 || c.indexOf("email") !== -1) return "l-chat";
        if (c.indexOf("filemanager") !== -1) return "l-folder";
        if (c.indexOf("audio") !== -1 || c.indexOf("music") !== -1 || c.indexOf("player") !== -1) return "l-music";
        if (c.indexOf("graphics") !== -1 || c.indexOf("photography") !== -1 || c.indexOf("viewer") !== -1) return "l-image";
        if (c.indexOf("monitor") !== -1) return "l-pulse";
        if (c.indexOf("packagemanager") !== -1) return "l-box";
        if (c.indexOf("office") !== -1) return "l-doc";
        if (c.indexOf("settings") !== -1 || c.indexOf("system") !== -1) return "l-gear";
        return "l-box";
    }
    function score(e) {
        let cls = (e.startupClass || "").toLowerCase(), base = (e.id || "").toLowerCase().replace(".desktop", ""), nm = (e.name || "").toLowerCase();
        let r = ranks || {}, f = (r.focus || {}), l = (r.launch || {}), c = (r.context || {});
        return (f[cls] || f[base] || f[nm] || 0) + (l[e.name] || 0) + 0.5 * (c[cls] || c[base] || c[nm] || 0);
    }
    readonly property var apps: {
        let out = [], seen = {};
        let list = DesktopEntries.applications ? (DesktopEntries.applications.values || []) : [];
        for (const e of list) {
            if (e.noDisplay || seen[e.name]) continue;
            seen[e.name] = true;
            out.push({ name: e.name, desc: e.comment || e.genericName || "", icon: appIcon(e), score: score(e), run: () => { e.execute(); Quickshell.execDetached(["python3", Caching.qsDir + "/launcher/app_rank.py", "--log-launch", "--name", e.name]); } });
        }
        // shell panels open from here too (Cài đặt, Hình nền, Giám sát hệ thống…)
        const shellApps = [["Cài đặt", "Cài đặt Zone-C và hệ thống", "l-gear", "guide"], ["Hình nền", "Chọn hình nền và video nền", "l-image", "wallpaper"],
                           ["Giám sát hệ thống", "Tiến trình, hiệu năng, dịch vụ", "l-pulse", "taskmanager"], ["Tệp", "Quản lý tệp · Máy tính này", "l-folder", "files"],
                           ["Cửa hàng ứng dụng", "pacman · AUR · Flatpak", "l-box", "appstore"], ["Nhạc", "Trình phát nhạc & equalizer", "l-music", "music"]];
        for (const s of shellApps) if (!seen[s[0]]) out.push({ name: s[0], desc: s[1], icon: s[2], score: (ranks.launch || {})[s[0]] || 0, run: () => Fz.open(s[3]) });
        return out.sort((a, b) => b.score - a.score || a.name.localeCompare(b.name, "vi"));
    }
    readonly property var actions: [
        { name: "Khóa màn hình", desc: "Super + L", icon: "l-gear", run: () => Quickshell.execDetached(["bash", Caching.zoneCDir + "/scripts/lock.sh"]) },
        { name: "Bảng phím tắt", desc: "Super + /", icon: "l-gear", run: () => Quickshell.execDetached(["bash", "-c", "quickshell -p \"$MAIN_QML\" ipc call keybinds toggle"]) },
        { name: "Chụp vùng màn hình", desc: "Super + Shift + S", icon: "l-image", run: () => Quickshell.execDetached(["bash", Caching.zoneCDir + "/scripts/screenshot.sh"]) },
        { name: "Đổi chế độ sáng/tối", desc: "zonetheme mode toggle", icon: "l-gear", run: () => ZoneStyle.setMode("toggle") },
        { name: "Chỉnh widget màn hình", desc: "Thêm, sắp xếp và đổi preset widget", icon: "l-image", run: () => Quickshell.execDetached(["bash", "-c", "quickshell -p \"$MAIN_QML\" ipc call desktop edit"]) },
        { name: "Tổng quan cửa sổ", desc: "Super + Tab", icon: "l-gear", run: () => Fz.open("overview") },
        { name: "Menu nguồn", desc: "Khóa · Ngủ · Khởi động lại · Tắt máy", icon: "l-gear", run: () => Fz.open("power") }
    ]
    function calc(q) {
        if (!/^[\d\s+\-*/().,%^]+$/.test(q) || !/\d/.test(q) || !/[+\-*/%^]/.test(q)) return null;
        try { let v = Function("return (" + q.replace(/,/g, ".").replace(/\^/g, "**") + ")")(); return isFinite(v) ? String(Math.round(v * 1e10) / 1e10) : null; } catch (e) { return null; }
    }
    function match(list, q) {
        q = q.toLowerCase();
        if (!q) return list;
        return list.map(a => {
            let n = a.name.toLowerCase(), d = (a.desc || "").toLowerCase();
            let m = n === q ? 4 : n.indexOf(q) === 0 ? 3 : n.indexOf(q) !== -1 ? 2 : d.indexOf(q) !== -1 ? 1 : 0;
            return { a: a, m: m };
        }).filter(x => x.m > 0).sort((x, y) => y.m - x.m || (y.a.score || 0) - (x.a.score || 0)).map(x => x.a);
    }
    readonly property var results: {
        if (cmdMode) return [];
        let q = query.trim(), out = [];
        let c = calc(q);
        if (c !== null && scope === 0) out.push({ name: q + " = " + c, desc: "Kết quả tính · Enter để sao chép", icon: "l-terminal", run: () => Quickshell.execDetached(["wl-copy", "--", c]) });
        if (scope === 0) out = out.concat(match(apps, q));
        else if (scope === 1) out = fileHits;
        else out = match(actions, q);
        return out.slice(0, 7);
    }
    onResultsChanged: sel = 0

    readonly property string fileScript: "import os,sys,json,time\nq=sys.argv[1].lower().strip()\nh=os.path.expanduser('~')\nres=[]\nnow=time.time()\ndef ago(t):\n d=(now-t)/3600\n return 'sửa %d phút trước'%max(1,int(d*60)) if d<1 else ('sửa %d giờ trước'%int(d) if d<24 else ('hôm qua' if d<48 else '%d ngày trước'%int(d/24)))\nfor r,ds,fs in os.walk(h):\n ds[:]=[d for d in ds if not d.startswith('.') and d not in('node_modules','target','build')]\n if r[len(h):].count(os.sep)>=3: ds.clear()\n for f in fs:\n  if f.startswith('.') or (q and q not in f.lower()): continue\n  p=os.path.join(r,f)\n  try: t=os.path.getmtime(p)\n  except: continue\n  res.append((t,f,p))\nres.sort(reverse=True)\nprint(json.dumps([{'n':f,'d':'~'+os.path.dirname(p)[len(h):]+' · '+ago(t),'p':p} for t,f,p in res[:7]]))"
    Process {
        id: fileProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    win.fileHits = JSON.parse(this.text).map(x => ({
                        name: x.n, desc: x.d,
                        icon: /\.(png|jpe?g|webp|gif|svg)$/i.test(x.n) ? "l-image" : (/\.(lua|qml|py|sh|js|ts|rs|c|cpp|nix|conf)$/i.test(x.n) ? "l-pen" : "l-doc"),
                        run: () => Quickshell.execDetached(["xdg-open", x.p])
                    }));
                } catch (e) { win.fileHits = []; }
            }
        }
    }
    Timer { id: fileDebounce; interval: 180; onTriggered: { fileProc.command = ["python3", "-c", win.fileScript, win.query]; fileProc.running = true; } }
    onQueryChanged: if (scope === 1 && !cmdMode) fileDebounce.restart()
    onScopeChanged: { sel = 0; if (scope === 1) fileDebounce.restart(); }

    function activate() {
        if (cmdMode) {
            if (cmd === "") return;
            remember(cmd);
            Quickshell.execDetached(["bash", "-c", terminal + " " + cmd]);
            close();
            return;
        }
        let r = results[sel];
        if (!r) return;
        r.run();
        close();
    }

    // dimmed backdrop (`.scrim.deep`); clicking outside closes
    Rectangle { anchors.fill: parent; color: Fz.scrimDeep; MouseArea { anchors.fill: parent; onClicked: win.close() } }

    Glass {
        id: box
        x: (parent.width - width) / 2
        y: 72
        width: 680
        height: col.implicitHeight + 28
        MouseArea { anchors.fill: parent }

        Column {
            id: col
            x: 14; y: 14
            width: parent.width - 28
            spacing: 12

            Rectangle {
                width: parent.width; height: 58; radius: 18
                color: Fz.well(0.28); border.width: 1; border.color: Fz.line2
                Row {
                    x: 18; anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    FIcon { name: win.cmdMode ? "l-terminal" : "l-search"; size: 22; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
                    Item {
                        width: col.width - 36 - 22 - 24 - superKey.width
                        height: 30
                        anchors.verticalCenter: parent.verticalCenter
                        TextInput {
                            id: field
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            color: Fz.tx
                            font.family: Fz.font
                            font.pointSize: 19 * 0.75
                            selectionColor: Fz.accA(0.35)
                            clip: true
                            onTextChanged: win.query = text
                            Keys.onPressed: (e) => {
                                if (e.key === Qt.Key_Escape) { win.close(); e.accepted = true; }
                                else if (e.key === Qt.Key_Down) { win.sel = Math.min(win.sel + 1, Math.max(0, win.results.length - 1)); e.accepted = true; }
                                else if (e.key === Qt.Key_Up) { win.sel = Math.max(0, win.sel - 1); e.accepted = true; }
                                else if (e.key === Qt.Key_Tab) { win.scope = (win.scope + 1) % 3; e.accepted = true; }
                                else if (e.key === Qt.Key_Backtab) { win.scope = (win.scope + 2) % 3; e.accepted = true; }
                                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { win.activate(); e.accepted = true; }
                            }
                        }
                        FText { anchors.verticalCenter: parent.verticalCenter; visible: field.text === ""; text: "Tìm ứng dụng… gõ > để chạy lệnh"; px: 19; color: Fz.dim }
                    }
                    FKbd { id: superKey; text: "Super"; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            FSeg {
                width: parent.width
                btnWidth: (parent.width - 6 - 4) / 3
                options: ["Ứng dụng", "Tệp", "Thao tác"]
                current: win.scope
                onPicked: (i) => { win.scope = i; field.forceActiveFocus(); }
            }

            // "> command" mode
            Column {
                visible: win.cmdMode
                width: parent.width
                spacing: 2
                ResultRow { width: parent.width; first: true; mono: true; icon: "l-terminal"; title: win.cmd || "lệnh…"; desc: "Chạy trong terminal · " + win.terminal; onClicked: win.activate() }
                FText {
                    visible: win.history.length > 0
                    leftPadding: 12; topPadding: 4; bottomPadding: 4
                    textFormat: Text.StyledText
                    text: "Lịch sử: " + win.history.slice(0, 3).map(h => "<span style=\"font-family:'Geist Mono'\">" + h.replace(/&/g, "&amp;").replace(/</g, "&lt;") + "</span>").join(" · ")
                    px: 12.5; color: Fz.sub
                }
            }

            Column {
                visible: !win.cmdMode
                width: parent.width
                spacing: 2
                Repeater {
                    model: win.results
                    delegate: ResultRow {
                        required property var modelData
                        required property int index
                        width: col.width
                        first: index === win.sel
                        icon: modelData.icon
                        title: modelData.name
                        desc: modelData.desc || ""
                        onClicked: { win.sel = index; win.activate(); }
                        onHoveredChanged: if (hovered) win.sel = index
                    }
                }
                Item {
                    visible: win.results.length === 0
                    width: parent.width; height: 80
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        FText { text: win.scope === 1 && win.query === "" ? "Gõ tên tệp để tìm." : "Không có kết quả. Thử gõ"; color: Fz.sub; px: 14; anchors.verticalCenter: parent.verticalCenter }
                        FKbd { visible: !(win.scope === 1 && win.query === ""); text: "> lệnh"; anchors.verticalCenter: parent.verticalCenter }
                        FText { visible: !(win.scope === 1 && win.query === ""); text: "để chạy trong terminal."; color: Fz.sub; px: 14; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }

            // footer
            Item {
                width: parent.width
                height: 36
                Rectangle { width: parent.width; height: 1; color: Fz.line }
                Row {
                    x: 6; y: 6 + 4
                    spacing: 14
                    Row { spacing: 4; FKbd { text: "↑↓" } FText { text: "chọn"; px: 12; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter } }
                    Row { spacing: 4; FKbd { text: "Enter" } FText { text: "mở"; px: 12; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter } }
                    Row { spacing: 4; FKbd { text: "Tab" } FText { text: "đổi phạm vi"; px: 12; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter } }
                }
                FText { anchors.right: parent.right; anchors.rightMargin: 6; y: 6 + 8; text: "Xếp theo tần suất dùng · Unikey tự tắt khi gõ"; px: 12; color: Fz.sub }
            }
        }
    }

    // `.res` / `.res.first`
    component ResultRow: Rectangle {
        id: rr
        property bool first: false
        property bool mono: false
        property string icon
        property string title
        property string desc
        readonly property bool hovered: rrMouse.containsMouse
        signal clicked()
        height: 62
        radius: 14
        color: first ? Fz.acc : (hovered ? Fz.fg(0.06) : "transparent")
        Row {
            x: 12; anchors.verticalCenter: parent.verticalCenter
            spacing: 14
            Rectangle {
                width: 42; height: 42; radius: 13
                color: rr.first ? Fz.ink : Fz.s0
                FIcon { anchors.centerIn: parent; name: rr.icon; size: 20; color: Fz.acc }
            }
            Column {
                width: rr.width - 24 - 42 - 14 - 70
                anchors.verticalCenter: parent.verticalCenter
                FText { width: parent.width; elide: Text.ElideRight; text: rr.title; mono: rr.mono; px: 15; weight: Font.DemiBold; color: rr.first ? Fz.ink : Fz.tx }
                FText { width: parent.width; elide: Text.ElideRight; visible: text !== ""; text: rr.desc; px: 12.5; color: rr.first ? Fz.ink : Fz.tx; opacity: 0.72 }
            }
        }
        Row {
            visible: rr.first
            anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            opacity: 0.8
            FIcon { name: "l-enter"; size: 14; color: Fz.ink; anchors.verticalCenter: parent.verticalCenter }
            FText { text: rr.mono ? "Enter" : "Mở"; px: 11.5; color: Fz.ink; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { id: rrMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: rr.clicked() }
    }
}
