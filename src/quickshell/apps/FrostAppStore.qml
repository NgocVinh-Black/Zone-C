import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../frost"

// App store of the Frost design (AppStore.dc.html): categories, search across pacman, the AUR and
// Flathub, a details pane and install / remove. pacman and Flatpak run here (polkit asks for the
// password); AUR builds open in a terminal because makepkg is interactive.
Scope {
    id: app
    property bool open: false
    property string startCat: "discover"

    function show(cat) { startCat = cat || "discover"; open = true; }
    Connections { target: Fz; function onOpenRequest(name, arg) { if (name === "appstore") app.open ? (app.open = false) : app.show(arg); } }
    IpcHandler {
        target: "appstore"
        function toggle(): void { app.open ? (app.open = false) : app.show(""); }
        function open(category: string): void { app.show(category); }
    }

    // curated catalogue: name, description, letter, tile colour, source, package / Flatpak id, category
    readonly property var catalog: [
        ["Blender", Fz.tr("Dựng hình 3D"), "B", "peach", "pacman", "blender", "gfx"],
        ["Visual Studio Code", Fz.tr("Trình soạn thảo mã"), "C", "#BFE3F5", "AUR", "visual-studio-code-bin", "dev"],
        ["GIMP", Fz.tr("Chỉnh sửa ảnh"), "G", "yellow", "pacman", "gimp", "gfx"],
        ["Obsidian", Fz.tr("Ghi chú Markdown"), "O", "#DCD3EE", "Flatpak", "md.obsidian.Obsidian", "office"],
        ["Spotify", Fz.tr("Nghe nhạc"), "S", "green", "Flatpak", "com.spotify.Client", "media"],
        ["Steam", Fz.tr("Chơi game"), "S", "glow", "pacman", "steam", "game"],
        ["LibreOffice", Fz.tr("Bộ văn phòng"), "L", "#CFE4D8", "pacman", "libreoffice-fresh", "office"],
        ["Discord", Fz.tr("Trò chuyện"), "D", "#C9D2F5", "Flatpak", "com.discordapp.Discord", "chat"],
        ["btop", Fz.tr("Giám sát tài nguyên"), "b", "#F0D3DA", "pacman", "btop", "tool"],
        ["Inkscape", Fz.tr("Đồ họa vector"), "I", "#DCD3EE", "pacman", "inkscape", "gfx"],
        ["Krita", Fz.tr("Vẽ kỹ thuật số"), "K", "#F0D3DA", "pacman", "krita", "gfx"],
        ["Neovim", Fz.tr("Trình soạn thảo trong terminal"), "N", "#CFE4D8", "pacman", "neovim", "dev"],
        ["Zed", Fz.tr("Trình soạn thảo mã nhanh"), "Z", "#BFE3F5", "pacman", "zed", "dev"],
        ["Docker", "Container", "D", "#C9D2F5", "pacman", "docker", "dev"],
        ["mpv", Fz.tr("Trình phát video"), "m", "#DCD3EE", "pacman", "mpv", "media"],
        ["OBS Studio", Fz.tr("Quay & phát trực tiếp"), "O", "peach", "pacman", "obs-studio", "media"],
        ["Kdenlive", Fz.tr("Dựng phim"), "K", "#BFE3F5", "pacman", "kdenlive", "media"],
        ["Lutris", Fz.tr("Quản lý game"), "L", "yellow", "pacman", "lutris", "game"],
        ["Heroic", "Epic & GOG", "H", "#F0D3DA", "Flatpak", "com.heroicgameslauncher.hgl", "game"],
        ["Telegram", Fz.tr("Nhắn tin"), "T", "#BFE3F5", "pacman", "telegram-desktop", "chat"],
        ["Thunderbird", Fz.tr("Thư điện tử"), "T", "#C9D2F5", "pacman", "thunderbird", "chat"],
        ["Zotero", Fz.tr("Quản lý tài liệu tham khảo"), "Z", "#F0D3DA", "Flatpak", "org.zotero.Zotero", "office"],
        ["Okular", Fz.tr("Đọc PDF"), "O", "#CFE4D8", "pacman", "okular", "office"],
        ["GParted", Fz.tr("Phân vùng ổ đĩa"), "G", "peach", "pacman", "gparted", "tool"],
        ["Timeshift", Fz.tr("Sao lưu hệ thống"), "T", "green", "pacman", "timeshift", "tool"],
        ["Flatseal", Fz.tr("Quyền ứng dụng Flatpak"), "F", "#BFE3F5", "Flatpak", "com.github.tchx84.Flatseal", "tool"]
    ].map(a => ({ name: a[0], desc: a[1], letter: a[2], color: a[3], src: a[4], id: a[5], cat: a[6] }))
    readonly property var cats: [["discover", Fz.tr("Khám phá"), "AppStore:s-compass"], ["installed", Fz.tr("Đã cài"), "AppStore:s-box"], ["updates", Fz.tr("Cập nhật"), "AppStore:s-upd"],
        ["dev", Fz.tr("Phát triển"), "AppStore:s-code"], ["gfx", Fz.tr("Đồ họa"), "AppStore:s-pen"], ["media", Fz.tr("Âm nhạc & video"), "AppStore:s-music"], ["game", Fz.tr("Trò chơi"), "AppStore:s-game"],
        ["chat", Fz.tr("Liên lạc"), "AppStore:s-chat"], ["office", Fz.tr("Văn phòng"), "AppStore:s-doc"], ["tool", Fz.tr("Tiện ích hệ thống"), "AppStore:s-wrench"]]

    LazyLoader {
        active: app.open
        FloatingWindow {
            id: win
            title: Fz.tr("Zone-C · Cửa hàng ứng dụng")
            implicitWidth: 1320
            implicitHeight: 810
            minimumSize: Qt.size(1000, 600)
            color: Fz.mantle
            visible: true
            onVisibleChanged: if (!visible) app.open = false

            property string cat: app.startCat
            property string src: "all"
            property string q: ""
            property var status: ({})          // id -> installed version
            property var results: []
            property bool searching: false
            property var installedList: []
            property var updatesList: []
            property bool hasAur: true
            property bool hasFlatpak: false
            property var sel: app.catalog[0]
            property var details: ({})         // "src:id" -> info
            property var jobs: ({})            // "src:id" -> { kind, pct, line }

            function key(a) { return a.src + ":" + a.id; }
            function tile(a) {
                let c = a.color || ["peach", "#BFE3F5", "yellow", "#DCD3EE", "green", "glow", "#CFE4D8", "#C9D2F5", "#F0D3DA"][Math.abs(a.name.split("").reduce((h, ch) => h * 31 + ch.charCodeAt(0) | 0, 7)) % 9];
                return c === "peach" ? Fz.peach : c === "yellow" ? Fz.yellow : c === "green" ? Fz.green : c === "glow" ? Fz.glow : c;
            }
            function isInstalled(a) { return a.installed === true || status[a.id] !== undefined; }
            function decorate(a) { return Object.assign({ letter: a.name.charAt(0).toUpperCase() }, a); }

            readonly property var list: {
                let base;
                if (q.trim().length >= 2) base = results;
                else if (cat === "installed") base = installedList;
                else if (cat === "updates") base = updatesList;
                else base = app.catalog.filter(a => cat === "discover" || a.cat === cat);
                let ql = q.trim().toLowerCase();
                return base.filter(a => (src === "all" || a.src === src) && (ql.length >= 2 || !ql || a.name.toLowerCase().indexOf(ql) !== -1)).map(decorate);
            }
            readonly property string listTitle: (q.trim().length >= 2 ? Fz.tr("Kết quả cho “") + q.trim() + "”" : app.cats.find(c => c[0] === cat)[1]) + " · " + list.length + Fz.tr(" ứng dụng")

            // ---------------- queries ----------------
            function query(args, cb) {
                let p = queryComp.createObject(win, { command: ["python3", Quickshell.shellDir + "/apps/pkg.py"].concat(args) });
                p.done.connect((d) => { cb(d); p.destroy(); });
                p.running = true;
            }
            Component {
                id: queryComp
                Process {
                    id: qp
                    signal done(var d)
                    stdout: StdioCollector { onStreamFinished: { try { qp.done(JSON.parse(this.text)); } catch (e) { qp.done({ data: null }); } } }
                }
            }
            function refreshStatus() {
                query(["status"].concat(app.catalog.map(a => a.id)), d => { if (d.data) { win.status = d.data; win.hasAur = d.aur; win.hasFlatpak = d.flatpak; } });
                query(["installed"], d => { if (d.data) win.installedList = d.data; });
            }
            Component.onCompleted: {
                refreshStatus();
                query(["updates"], d => { if (d.data) win.updatesList = d.data; });
                loadInfo(sel);
            }
            Timer { id: searchDelay; interval: 450; onTriggered: { let qq = win.q.trim(); if (qq.length < 2) return; win.searching = true; win.query(["search", qq], d => { if (d.arg === win.q.trim()) { win.results = d.data || []; win.searching = false; } }); } }
            onQChanged: searchDelay.restart()
            function loadInfo(a) {
                if (!a || details[key(a)]) return;
                query(["info", a.src, a.id], d => { let x = Object.assign({}, win.details); x[win.key(a)] = d.data || {}; win.details = x; });
            }
            function pick(a) { sel = a; loadInfo(a); }
            onListChanged: if (list.length && !list.some(a => key(a) === key(sel))) pick(list[0])

            // ---------------- install / remove ----------------
            readonly property string terminal: { let l = Config.getSetting("launcher", {}); return (l && l.terminalCommand) ? l.terminalCommand : "kitty -e"; }
            function act(a) {
                let k = key(a), inst = isInstalled(a), cmd;
                if (jobs[k]) return;
                if (a.src === "AUR") {
                    let sh = (inst ? "yay -Rns " : "yay -S ") + a.id + Fz.tr("; echo; read -n1 -p 'Nhấn phím bất kỳ để đóng…'");
                    Quickshell.execDetached(["bash", "-c", win.terminal + " bash -c \"$1\"", "_", sh]);
                    watchAur.restart();
                    return;
                }
                if (a.src === "Flatpak") cmd = inst ? ["flatpak", "uninstall", "-y", "--noninteractive", a.id] : ["flatpak", "install", "-y", "--noninteractive", "flathub", a.id];
                else cmd = inst ? ["pkexec", "pacman", "-Rns", "--noconfirm", a.id] : ["pkexec", "pacman", "-S", "--needed", "--noconfirm", a.id];
                let j = Object.assign({}, jobs); j[k] = { kind: inst ? "remove" : "install", pct: -1, line: "" }; jobs = j;
                let p = jobComp.createObject(win, { command: cmd, jobKey: k });
                p.running = true;
            }
            Timer { id: watchAur; interval: 15000; repeat: true; property int n: 0; onTriggered: { win.refreshStatus(); if (++n > 40) { stop(); n = 0; } } }
            Component {
                id: jobComp
                Process {
                    id: jp
                    property string jobKey
                    stdout: SplitParser {
                        splitMarker: ""
                        onRead: (chunk) => {
                            let lines = chunk.split(/[\r\n]+/).filter(l => l.trim());
                            if (!lines.length) return;
                            let last = lines[lines.length - 1].trim(), pm = chunk.match(/(\d{1,3})%/g), m = pm ? [0, pm[pm.length - 1].slice(0, -1)] : null;
                            let j = Object.assign({}, win.jobs);
                            if (!j[jp.jobKey]) return;
                            j[jp.jobKey] = Object.assign({}, j[jp.jobKey], { line: last.slice(0, 80), pct: m ? Math.min(100, Number(m[1])) : j[jp.jobKey].pct });
                            win.jobs = j;
                        }
                    }
                    onExited: (code) => {
                        let j = Object.assign({}, win.jobs); delete j[jobKey]; win.jobs = j;
                        if (code !== 0) Quickshell.execDetached(["notify-send", "-a", Fz.tr("Cửa hàng"), Fz.tr("Không thực hiện được"), jobKey.split(":")[1] + Fz.tr(" · mã lỗi ") + code]);
                        win.refreshStatus();
                        destroy();
                    }
                }
            }
            function btnLabel(a) {
                let j = jobs[key(a)];
                if (j) return j.kind === "install" ? Fz.tr("Đang cài…") : Fz.tr("Đang gỡ…");
                if (cat === "updates" && q.trim().length < 2) return Fz.tr("Cập nhật");
                return isInstalled(a) ? Fz.tr("Gỡ cài đặt") : Fz.tr("Cài đặt");
            }
            function cmdFor(a) {
                if (cat === "updates") return a.src === "Flatpak" ? "flatpak update " + a.id : a.src === "AUR" ? "yay -S " + a.id : "sudo pacman -Syu";
                return a.src === "Flatpak" ? "flatpak install flathub " + a.id : (a.src === "AUR" ? "yay -S " + a.id : "sudo pacman -S " + a.id);
            }
            function primary(a) {
                if (cat === "updates" && q.trim().length < 2) { updateAll(); return; }
                act(a);
            }
            function updateAll() {
                let sh = (win.hasAur ? "yay -Syu" : "sudo pacman -Syu") + (win.hasFlatpak ? "; flatpak update -y" : "") + Fz.tr("; echo; read -n1 -p 'Nhấn phím bất kỳ để đóng…'");
                Quickshell.execDetached(["bash", "-c", win.terminal + " bash -c \"$1\"", "_", sh]);
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: (e) => {
                    if ((e.modifiers & Qt.ControlModifier) && e.key === Qt.Key_F) { search.input.forceActiveFocus(); e.accepted = true; }
                    else if ((e.modifiers & Qt.ControlModifier) && e.key === Qt.Key_W) { app.open = false; e.accepted = true; }
                }
            }

            // ---------------- categories ----------------
            Rectangle {
                id: nav
                width: 230; height: parent.height
                color: Fz.crust
                Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Fz.line }
                Column {
                    x: 10; y: 14
                    width: parent.width - 20
                    spacing: 2
                    Row {
                        leftPadding: 8; topPadding: 4; bottomPadding: 14
                        spacing: 10
                        Ico { width: 34; height: 34; on: true; icon: "AppStore:s-box" }
                        FText { text: Fz.tr("Cửa hàng"); px: 15; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Repeater {
                        model: app.cats
                        delegate: Rectangle {
                            id: nv
                            required property var modelData
                            readonly property bool on: win.cat === modelData[0] && win.q.trim().length < 2
                            readonly property string badge: modelData[0] === "updates" && win.updatesList.length ? String(win.updatesList.length) : ""
                            width: parent.width; height: 34; radius: 10
                            color: on ? Fz.acc : (nvMouse.containsMouse ? Fz.fg(0.06) : "transparent")
                            Row {
                                x: 10; anchors.verticalCenter: parent.verticalCenter
                                spacing: 10
                                FIcon { name: nv.modelData[2]; size: 16; color: nv.on ? Fz.ink : (nvMouse.containsMouse ? Fz.tx : Fz.sub2); anchors.verticalCenter: parent.verticalCenter }
                                FText { text: nv.modelData[1]; px: 13.5; weight: nv.on ? Font.Medium : Font.Normal; color: nv.on ? Fz.ink : (nvMouse.containsMouse ? Fz.tx : Fz.sub2); anchors.verticalCenter: parent.verticalCenter }
                            }
                            Rectangle {
                                visible: nv.badge !== ""
                                anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                width: bt.implicitWidth + 14; height: 18; radius: 8
                                color: nv.on ? Fz.ink : Fz.acc
                                FText { id: bt; anchors.centerIn: parent; text: nv.badge; px: 11; weight: Font.Bold; color: nv.on ? Fz.acc : Fz.ink }
                            }
                            MouseArea { id: nvMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { win.cat = nv.modelData[0]; search.text = ""; } }
                        }
                    }
                }
                Rectangle {
                    x: 10; anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                    width: parent.width - 20; height: note.implicitHeight + 20; radius: 12
                    color: Fz.fg(0.04)
                    Row {
                        x: 10; anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        FIcon { name: "AppStore:s-shield"; size: 15; color: Fz.acc; anchors.verticalCenter: parent.verticalCenter }
                        FText { id: note; width: nav.width - 20 - 20 - 23; wrapMode: Text.Wrap; text: Fz.tr("Gói AUR do cộng đồng duy trì, hãy xem PKGBUILD"); px: 12; color: Fz.sub }
                    }
                }
            }

            // ---------------- search bar ----------------
            Item {
                id: head
                x: nav.width; width: parent.width - nav.width; height: 64
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Fz.line }
                Row {
                    x: 20; anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    FInput {
                        id: search
                        width: head.width - 40 - 20 - srcSeg.width - 36
                        height: 40; radius: 12; icon: "AppStore:s-search"
                        color: Fz.well(0.25); border.color: input.activeFocus ? Fz.glow : Fz.line
                        placeholder: Fz.tr("Tìm trong pacman, AUR và Flatpak")
                        onTextChanged: win.q = text
                        Keys.onEscapePressed: text = ""
                    }
                    FSeg { id: srcSeg; options: [Fz.tr("Tất cả"), "pacman", "AUR", "Flatpak"]; current: ["all", "pacman", "AUR", "Flatpak"].indexOf(win.src)
                           onPicked: (i) => win.src = ["all", "pacman", "AUR", "Flatpak"][i]; anchors.verticalCenter: parent.verticalCenter }
                    FIconBtn { ghost: true; icon: "AppStore:s-x"; iconSize: 15; label: Fz.tr("Đóng"); onClicked: app.open = false; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            // ---------------- list ----------------
            Flickable {
                id: main
                x: nav.width; y: 64
                width: parent.width - nav.width - aside.width
                height: parent.height - 64
                clip: true
                contentHeight: mcol.implicitHeight + 36
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: mcol
                    x: 20; y: 18
                    width: main.width - 40
                    spacing: 16
                    // featured banner
                    Item {
                        visible: win.cat === "discover" && win.q.trim().length < 2
                        width: parent.width; height: 170
                        Rectangle {
                            id: bannerMask
                            anchors.fill: parent; radius: 20; clip: true; color: Fz.surf(1)
                            Image {
                                anchors.fill: parent
                                source: { let p = Wallpaper.getWallpaperPath(""); return p && !ZoneStyle.isVideo(p) ? "file://" + p : ""; }
                                fillMode: Image.PreserveAspectCrop
                                verticalAlignment: Image.AlignVCenter
                                sourceSize.width: 1000
                            }
                        }
                        Rectangle { anchors.fill: parent; radius: 20; color: Fz.surf(0.55) }
                        Column {
                            x: 24; anchors.bottom: parent.bottom; anchors.bottomMargin: 24
                            spacing: 6
                            FChip { kind: "acc"; text: Fz.tr("Nổi bật tuần này") }
                            FText { text: "Blender"; px: 26; weight: Font.DemiBold }
                            FText { text: Fz.tr("Dựng hình 3D, hoạt ảnh và dựng phim. Miễn phí, mã nguồn mở."); px: 13.5; color: Fz.sub2 }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.pick(win.decorate(app.catalog[0])) }
                    }
                    Item {
                        width: parent.width; height: 14
                        Caps { text: win.listTitle; px: 11 }
                        Row {
                            visible: win.cat === "updates" && win.q.trim().length < 2 && win.updatesList.length > 0
                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            FBtn { height: 30; fontSize: 12; kind: "pri"; text: Fz.tr("Cập nhật tất cả"); onClicked: win.updateAll() }
                        }
                    }
                    FText { visible: win.searching; text: Fz.tr("Đang tìm trong pacman") + (win.hasAur ? ", AUR" : "") + (win.hasFlatpak ? Fz.tr(" và Flathub") : "") + "…"; px: 13; color: Fz.sub }
                    FText { visible: !win.searching && win.list.length === 0; text: win.cat === "updates" ? Fz.tr("Hệ thống đã được cập nhật.") : Fz.tr("Không có ứng dụng nào."); px: 13; color: Fz.sub }
                    Grid {
                        width: parent.width
                        columns: 3; spacing: 10
                        Repeater {
                            model: win.list.slice(0, 150)
                            delegate: Rectangle {
                                id: ac
                                required property var modelData
                                readonly property bool on: win.sel && win.key(win.sel) === win.key(modelData)
                                width: (mcol.width - 20) / 3; height: 112
                                radius: 18
                                color: Fz.fg(acMouse.containsMouse ? 0.07 : 0.035)
                                border.width: on ? 2 : 1; border.color: on ? Fz.acc : Fz.fg(0.08)
                                MouseArea { id: acMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.pick(ac.modelData) }
                                Column {
                                    x: 14; y: 14
                                    width: parent.width - 28
                                    spacing: 10
                                    Row {
                                        width: parent.width; spacing: 12
                                        Rectangle { width: 48; height: 48; radius: 15; color: win.tile(ac.modelData)
                                                    FText { anchors.centerIn: parent; text: ac.modelData.letter; px: 19; weight: Font.Bold; color: Fz.light ? "#ffffff" : Fz.ink } }
                                        Column {
                                            width: parent.width - 60; anchors.verticalCenter: parent.verticalCenter
                                            FText { width: parent.width; elide: Text.ElideRight; text: ac.modelData.name; px: 14; weight: Font.DemiBold }
                                            FText { width: parent.width; elide: Text.ElideRight; text: ac.modelData.old ? ac.modelData.old + " → " + ac.modelData.version : ac.modelData.desc; px: 12; color: Fz.sub }
                                        }
                                    }
                                    Item {
                                        width: parent.width; height: 30
                                        Row {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 8
                                            FChip { text: ac.modelData.src }
                                            Row {
                                                visible: (ac.modelData.votes || 0) > 0
                                                spacing: 3; anchors.verticalCenter: parent.verticalCenter
                                                FIcon { name: "AppStore:s-star"; size: 12; color: Fz.yellow; anchors.verticalCenter: parent.verticalCenter }
                                                FText { text: ac.modelData.votes || ""; px: 12; color: Fz.yellow }
                                            }
                                        }
                                        FBtn {
                                            anchors.right: parent.right
                                            height: 30; fontSize: 12
                                            readonly property bool upd: win.cat === "updates" && win.q.trim().length < 2
                                            kind: !win.jobs[win.key(ac.modelData)] && (upd || !win.isInstalled(ac.modelData)) ? "pri" : ""
                                            text: win.btnLabel(ac.modelData)
                                            onClicked: { win.pick(ac.modelData); upd ? win.updateAll() : win.act(ac.modelData); }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---------------- details ----------------
            Rectangle {
                id: aside
                anchors.right: parent.right; y: 64
                width: 300; height: parent.height - 64
                color: Fz.crust
                Rectangle { width: 1; height: parent.height; color: Fz.line }
                readonly property var a: win.sel ? win.decorate(win.sel) : null
                readonly property var d: a ? (win.details[win.key(a)] || {}) : {}
                readonly property var job: a ? win.jobs[win.key(a)] : null
                Column {
                    x: 20; y: 20
                    width: parent.width - 40
                    spacing: 14
                    Rectangle { width: 72; height: 72; radius: 22; color: aside.a ? win.tile(aside.a) : "transparent"
                                FText { anchors.centerIn: parent; text: aside.a ? aside.a.letter : ""; px: 28; weight: Font.Bold; color: Fz.light ? "#ffffff" : Fz.ink } }
                    Column {
                        width: parent.width
                        FText { width: parent.width; elide: Text.ElideRight; text: aside.a ? aside.a.name : ""; px: 20; weight: Font.DemiBold }
                        FText { width: parent.width; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight; text: aside.a ? (aside.a.desc || aside.d.desc || "") : ""; px: 13; color: Fz.sub }
                    }
                    FBtn {
                        width: parent.width; height: 42
                        readonly property bool upd: win.cat === "updates" && win.q.trim().length < 2
                        kind: aside.a && !aside.job && (upd || !win.isInstalled(aside.a)) ? "pri" : ""
                        text: aside.a ? win.btnLabel(aside.a) : ""
                        onClicked: if (aside.a) win.primary(aside.a)
                    }
                    Column {
                        visible: !!aside.job
                        width: parent.width
                        spacing: 6
                        Item {
                            width: parent.width; height: 6
                            FBar { anchors.fill: parent; visible: !!aside.job && aside.job.pct >= 0; value: aside.job ? aside.job.pct / 100 : 0 }
                            Rectangle {
                                visible: !!aside.job && aside.job.pct < 0
                                anchors.fill: parent; radius: 3; color: Fz.fg(0.1); clip: true
                                Rectangle {
                                    width: parent.width * 0.3; height: parent.height; radius: 3; color: Fz.acc
                                    NumberAnimation on x { from: -60; to: 260; duration: 1200; loops: Animation.Infinite; running: aside.job !== null }
                                }
                            }
                        }
                        FText { width: parent.width; elide: Text.ElideRight; mono: true; px: 11.5; color: Fz.sub
                                text: aside.job ? (aside.job.kind === "install" ? Fz.tr("Đang tải") : Fz.tr("Đang gỡ")) + (aside.job.pct >= 0 ? " · " + aside.job.pct + "%" : "") + " · " + (aside.a ? aside.a.src : "") : "" }
                    }
                    Column {
                        width: parent.width
                        Repeater {
                            model: aside.a ? [[Fz.tr("Nguồn"), aside.a.src + (aside.d.repo ? " · " + aside.d.repo : "")], [Fz.tr("Phiên bản"), aside.d.version || aside.a.version || win.status[aside.a.id] || "…"],
                                              [Fz.tr("Dung lượng"), aside.d.size || aside.a.size || "–"], [Fz.tr("Giấy phép"), aside.d.license || "–"]] : []
                            delegate: Item {
                                required property var modelData
                                required property int index
                                width: parent.width; height: 31
                                FText { anchors.verticalCenter: parent.verticalCenter; text: modelData[0]; px: 12.5; color: Fz.sub }
                                FText { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: Math.min(implicitWidth, 170); elide: Text.ElideRight; text: modelData[1]; mono: true; px: 12.5 }
                                Rectangle { visible: index < 3; anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Fz.line }
                            }
                        }
                    }
                    Rectangle {
                        width: parent.width; height: cmdT.implicitHeight + 20; radius: 10
                        color: Fz.well(0.25)
                        FText { id: cmdT; x: 10; y: 10; width: parent.width - 20; wrapMode: Text.WrapAnywhere; text: aside.a ? win.cmdFor(aside.a) : ""; mono: true; px: 11.5; color: Fz.dim }
                    }
                    FText {
                        visible: !!(aside.d.url)
                        width: parent.width; elide: Text.ElideRight
                        text: aside.d.url || ""; px: 12; color: Fz.glow
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.openUrlExternally(aside.d.url) }
                    }
                }
            }
        }
    }
}
