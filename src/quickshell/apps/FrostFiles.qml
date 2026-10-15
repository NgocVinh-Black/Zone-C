import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../frost"

// File manager of the Frost design (FileManager.dc.html): "Máy tính này" with folders, drives and network
// places, plus folder listings in list or grid view, a details pane and a status bar. A real window
// (class org.quickshell, title "Zone-C · Tệp"), floated and sized by the Hyprland rules.
Scope {
    id: app
    property bool open: false
    property string startPath: "computer:"
    signal navigate(string path)

    function show(path) {
        if (open) { if (path) navigate(path); return; }
        startPath = path || "computer:";
        open = true;
    }
    Connections { target: Fz; function onOpenRequest(name, arg) { if (name === "files") app.show(arg); } }
    IpcHandler {
        target: "files"
        function toggle(): void { app.open ? (app.open = false) : app.show(""); }
        function open(path: string): void { app.show(path); }
    }

    LazyLoader {
        active: app.open
        FloatingWindow {
            id: win
            title: "Zone-C · Tệp"
            implicitWidth: 1392
            implicitHeight: 828
            minimumSize: Qt.size(900, 560)
            color: Fz.mantle
            visible: true
            onVisibleChanged: if (!visible) app.open = false
            Component.onCompleted: { fm.go(app.startPath, false); places.running = true; }
            Connections { target: app; function onNavigate(path) { fm.go(path); } }

            Item {
                id: keys
                anchors.fill: parent
                focus: true
                Keys.onPressed: (e) => {
                    let ctrl = e.modifiers & Qt.ControlModifier, alt = e.modifiers & Qt.AltModifier;
                    if (dlg.visible || menu.visible) { if (e.key === Qt.Key_Escape) { dlg.visible = false; menu.visible = false; e.accepted = true; } return; }
                    if (e.key === Qt.Key_Down) { fm.sel = Math.min(fm.sel + (fm.grid && !fm.isPc ? 4 : 1), fm.shown.length - 1); e.accepted = true; }
                    else if (e.key === Qt.Key_Up) { fm.sel = Math.max(0, fm.sel - (fm.grid && !fm.isPc ? 4 : 1)); e.accepted = true; }
                    else if (e.key === Qt.Key_Right && fm.grid) { fm.sel = Math.min(fm.sel + 1, fm.shown.length - 1); e.accepted = true; }
                    else if (e.key === Qt.Key_Left && fm.grid && !alt) { fm.sel = Math.max(0, fm.sel - 1); e.accepted = true; }
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { if (fm.cur) fm.activate(fm.cur); e.accepted = true; }
                    else if (e.key === Qt.Key_Backspace || (alt && e.key === Qt.Key_Up)) { fm.up(); e.accepted = true; }
                    else if (alt && e.key === Qt.Key_Left) { fm.back(); e.accepted = true; }
                    else if (alt && e.key === Qt.Key_Right) { fm.forward(); e.accepted = true; }
                    else if (e.key === Qt.Key_Delete && fm.cur) { fm.trash(fm.cur); e.accepted = true; }
                    else if (e.key === Qt.Key_F2 && fm.cur) { dlg.ask("rename", fm.cur); e.accepted = true; }
                    else if (e.key === Qt.Key_F5) { fm.refreshAll(); e.accepted = true; }
                    else if (ctrl && e.key === Qt.Key_H) { fm.hidden = !fm.hidden; fm.list(); e.accepted = true; }
                    else if (ctrl && e.key === Qt.Key_F) { search.input.forceActiveFocus(); e.accepted = true; }
                    else if (ctrl && e.key === Qt.Key_W) { app.open = false; e.accepted = true; }
                }
            }

            // ---------------- model ----------------
            QtObject {
                id: fm
                readonly property string home: Quickshell.env("HOME") || "/"
                readonly property string user: Quickshell.env("USER") || ""
                property string dir: "computer:"
                property var back_: []
                property var fwd: []
                property var entries: []
                property int sel: 0
                property string query: ""
                property bool grid: false
                property bool hidden: false
                property var xdg: ({})
                property var counts: ({})
                property var drives: []
                property var netPlaces: []
                property int newDownloads: 0
                property real trashBytes: 0
                property real rootFree: 0
                property real rootSize: 0
                property int driveSel: 0
                readonly property bool isPc: dir === "computer:"
                readonly property string trashDir: home + "/.local/share/Trash/files"
                readonly property var shown: entries.filter(e => query === "" || e.name.toLowerCase().indexOf(query.toLowerCase()) !== -1)
                readonly property var cur: isPc ? null : (shown[sel] || null)

                function go(path, remember) {
                    if (remember !== false && path !== dir) { back_ = back_.concat([dir]); fwd = []; }
                    dir = path; sel = 0; query = ""; search.text = "";
                    if (isPc) refreshAll(); else list();
                }
                function back() { if (!back_.length) return; fwd = fwd.concat([dir]); let p = back_[back_.length - 1]; back_ = back_.slice(0, -1); go(p, false); }
                function forward() { if (!fwd.length) return; back_ = back_.concat([dir]); let p = fwd[fwd.length - 1]; fwd = fwd.slice(0, -1); go(p, false); }
                function up() { if (isPc) return; if (dir === "/") { go("computer:"); return; } go(dir.replace(/\/[^\/]*\/?$/, "") || "/"); }
                function join(n) { return dir.replace(/\/$/, "") + "/" + n; }
                function activate(e) { if (e.dir) go(e.path); else Quickshell.execDetached(["xdg-open", e.path]); }
                function trash(e) { Quickshell.execDetached(["gio", "trash", e.path]); refreshSoon.restart(); }
                function list() { lister.running = false; lister.running = true; }
                function refreshAll() { places.running = false; places.running = true; if (!isPc) list(); }

                readonly property string crumb: {
                    if (isPc) return "Máy tính này";
                    if (dir === home) return "Thư mục cá nhân";
                    if (dir === trashDir) return "Thùng rác";
                    for (const p of placeList) if (p.p === dir) return p.n;
                    return dir.split("/").pop() || "/";
                }
                readonly property string crumbIcon: isPc ? "f-pc" : (dir === home ? "f-home" : (dir === trashDir ? "f-trash" : (placeList.find(p => p.p === dir) || { i: "f-folder" }).i))
                readonly property var placeList: [
                    { n: "Màn hình nền", i: "f-desk", p: xdg.DESKTOP || home + "/Desktop" },
                    { n: "Tải xuống", i: "f-down", p: xdg.DOWNLOAD || home + "/Downloads" },
                    { n: "Tài liệu", i: "f-doc", p: xdg.DOCUMENTS || home + "/Documents" },
                    { n: "Hình ảnh", i: "f-image", p: xdg.PICTURES || home + "/Pictures" },
                    { n: "Nhạc", i: "f-music", p: xdg.MUSIC || home + "/Music" },
                    { n: "Video", i: "f-video", p: xdg.VIDEOS || home + "/Videos" },
                    { n: "Zone-C", i: "f-code", p: home + "/Zone-C" }
                ]

                function fmtDate(epoch) {
                    let d = new Date(epoch * 1000), now = new Date();
                    let day0 = new Date(now.getFullYear(), now.getMonth(), now.getDate());
                    let hm = String(d.getHours()).padStart(2, "0") + ":" + String(d.getMinutes()).padStart(2, "0");
                    if (d >= day0) return "Hôm nay " + hm;
                    if (d >= new Date(day0 - 86400000)) return "Hôm qua";
                    return String(d.getDate()).padStart(2, "0") + "/" + String(d.getMonth() + 1).padStart(2, "0") + "/" + d.getFullYear();
                }
                function fmtSize(b) {
                    if (b < 1024) return b + " B";
                    if (b < 1048576) return Math.round(b / 1024) + " KB";
                    if (b < 1073741824) return (b / 1048576).toFixed(1).replace(/\.0$/, "") + " MB";
                    return (b / 1073741824).toFixed(1).replace(/\.0$/, "") + " GB";
                }
                function gb(b) { return Math.round(b / 1073741824); }
                readonly property var kinds: [
                    [/\.(png|jpe?g|webp|gif|svg|bmp|avif|heic)$/, "f-image", "Ảnh"], [/\.(mp4|mkv|webm|mov|avi)$/, "f-video", "Video"],
                    [/\.(mp3|flac|ogg|opus|wav|m4a)$/, "f-music", "Âm thanh"], [/\.(lua|qml|js|ts|py|sh|c|cpp|h|rs|go|java|nix|toml|ya?ml|conf|ini|css|html)$/, "f-code", ""],
                    [/^\.(bashrc|zshrc|profile|bash_profile)$/, "f-code", "Shell"], [/\.(zip|tar|gz|xz|zst|7z|rar)$/, "f-folder", "Tệp nén"]
                ]
                function kind(e) {
                    if (e.dir) return { i: "f-folder", t: "Thư mục" };
                    let n = e.name.toLowerCase(), ext = n.indexOf(".") > 0 ? n.split(".").pop() : "";
                    for (const k of kinds) if (k[0].test(n)) {
                        let label = k[2] === "Ảnh" ? "Ảnh " + ext.toUpperCase() : k[2] === "Video" ? "Video " + ext.toUpperCase() : k[2] === "Âm thanh" ? "Âm thanh " + ext.toUpperCase() : (k[2] || ({ lua: "Lua", qml: "QML", js: "JavaScript", py: "Python", sh: "Shell", json: "JSON" })[ext] || ext.toUpperCase());
                        return { i: k[1], t: label };
                    }
                    if (/\.(odt|docx?|pdf|txt|md|json|xlsx?|ods|pptx?)$/.test(n)) return { i: "f-doc", t: ({ odt: "Tài liệu", doc: "Tài liệu", docx: "Tài liệu", pdf: "PDF", txt: "Văn bản", md: "Markdown", json: "JSON" })[ext] || "Tài liệu" };
                    return { i: "f-doc", t: ext ? ext.toUpperCase() : "Tệp" };
                }
                function sub(e) { return e.dir ? e.size + " mục" : fmtSize(e.size); }
                function perms(m) { let s = ""; for (let i = 2; i >= 0; i--) { let v = (parseInt(m, 8) >> (i * 3)) & 7; s += (v & 4 ? "r" : "-") + (v & 2 ? "w" : "-") + (v & 1 ? "x" : "-"); } return s; }
            }
            Timer { id: refreshSoon; interval: 400; onTriggered: fm.refreshAll() }

            Process {
                id: lister
                command: ["bash", "-c", "cd -- \"$1\" 2>/dev/null || exit; [ \"$2\" = 1 ] && shopt -s dotglob; for f in *; do [ -e \"$f\" ] || continue; if [ -d \"$f\" ]; then n=$(find \"$f\" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l); printf '%s\\td\\t%s\\t%s\\t%s\\n' \"$(stat -c %Y \"$f\")\" \"$f\" \"$n\" \"$(stat -c %a \"$f\")\"; else printf '%s\\tf\\t%s\\t%s\\t%s\\n' \"$(stat -c %Y \"$f\")\" \"$f\" \"$(stat -c %s \"$f\")\" \"$(stat -c %a \"$f\")\"; fi; done", "_", fm.dir, fm.hidden ? "1" : "0"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let out = [];
                        this.text.split("\n").forEach(l => {
                            let c = l.split("\t");
                            if (c.length < 5) return;
                            out.push({ name: c[2], path: fm.join(c[2]), dir: c[1] === "d", t: Number(c[0]), size: Number(c[3]), mode: c[4] });
                        });
                        out.sort((a, b) => (a.dir === b.dir) ? a.name.replace(/^\./, "~").localeCompare(b.name.replace(/^\./, "~"), "vi") : (a.dir ? -1 : 1));
                        fm.entries = out;
                        fm.sel = Math.min(fm.sel, Math.max(0, out.length - 1));
                    }
                }
            }
            // "Máy tính này": XDG dirs, item counts, mounts, gvfs places, trash size, fresh downloads
            Process {
                id: places
                command: ["bash", "-c", "for k in DESKTOP DOWNLOAD DOCUMENTS PICTURES MUSIC VIDEOS; do echo \"X\t$k\t$(xdg-user-dir $k 2>/dev/null)\"; done;"
                    + "for d in \"$(xdg-user-dir DESKTOP)\" \"$(xdg-user-dir DOWNLOAD)\" \"$(xdg-user-dir DOCUMENTS)\" \"$(xdg-user-dir PICTURES)\" \"$(xdg-user-dir MUSIC)\" \"$(xdg-user-dir VIDEOS)\" \"$HOME/Zone-C\"; do [ -d \"$d\" ] && echo \"C\t$d\t$(find \"$d\" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)\"; done;"
                    + "echo \"N\t$(find \"$(xdg-user-dir DOWNLOAD)\" -mindepth 1 -maxdepth 1 -mmin -1440 2>/dev/null | wc -l)\";"
                    + "echo \"T\t$(du -sb \"$HOME/.local/share/Trash/files\" 2>/dev/null | cut -f1)\";"
                    + "findmnt -b -r -n -o SOURCE,TARGET,FSTYPE,SIZE,USED -t btrfs,ext4,xfs,vfat,exfat,ntfs,ntfs3,f2fs,fuseblk | while read -r s t f z u; do t=$(printf '%b' \"$t\"); "
                    + "dev=${s%%[*}; enc=0; lsblk -s -no TYPE \"$dev\" 2>/dev/null | grep -q crypt && enc=1; tr=$(lsblk -s -dno TRAN \"$dev\" 2>/dev/null | grep -v '^$' | tail -1); lbl=$(lsblk -no LABEL \"$dev\" 2>/dev/null | head -1); "
                    + "echo \"M\t$s\t$t\t$f\t$z\t$u\t$enc\t$tr\t$lbl\"; done;"
                    + "for g in /run/user/$(id -u)/gvfs/*; do [ -d \"$g\" ] && echo \"G\t$g\"; done"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let x = {}, counts = {}, drives = [], net = [], seen = {};
                        this.text.split("\n").forEach(l => {
                            let c = l.split("\t");
                            if (c[0] === "X" && c[2]) x[c[1]] = c[2];
                            else if (c[0] === "C") counts[c[1]] = Number(c[2]);
                            else if (c[0] === "N") fm.newDownloads = Number(c[1]);
                            else if (c[0] === "T") fm.trashBytes = Number(c[1] || 0);
                            else if (c[0] === "M") {
                                let src = c[1], t = c[2], fs = c[3], size = Number(c[4]), used = Number(c[5]), enc = c[6] === "1", tran = c[7], lbl = c[8];
                                let dev = src.replace(/\[.*$/, ""), key = dev + "|" + t;
                                if (seen[key] || !(t === "/" || t === "/home" || t.indexOf("/boot") === 0 || t.indexOf("/efi") === 0 || t.indexOf("/run/media/") === 0 || t.indexOf("/mnt/") === 0)) return;
                                seen[key] = true;
                                let removable = t.indexOf("/run/media/") === 0;
                                let name = t === "/" ? "Hệ thống" : t === "/home" ? "Thư mục cá nhân" : (fs === "vfat" && /boot|efi/.test(t)) ? "EFI" : (lbl || t.split("/").pop());
                                let devName = dev.split("/").pop();
                                if (t === "/") { fm.rootFree = size - used; fm.rootSize = size; }
                                let kv = [["Hệ tập tin", fs + (fs === "btrfs" ? " (subvol)" : "")], ["Gắn tại", t]];
                                if (enc) kv.push(["Mã hóa", "LUKS"]);
                                if (tran) kv.push([removable ? "Cổng" : "Giao tiếp", tran.toUpperCase()]);
                                kv.push(["Đã dùng", size < 2147483648 ? Math.round(used / 1048576) + " / " + Math.round(size / 1048576) + " MB" : fm.gb(used) + " / " + fm.gb(size) + " GB"]);
                                drives.push({ i: t === "/home" ? "f-home" : (tran === "usb" || removable ? "f-usb" : "f-ssd"), n: name, m: t + " · " + devName + " · " + fs,
                                              path: t, lock: enc, size: size, used: used, removable: removable, dev: dev, kv: kv });
                            } else if (c[0] === "G") {
                                let g = c[1], b = g.split("/").pop();
                                let isPhone = b.indexOf("mtp:") === 0 || b.indexOf("gphoto2:") === 0;
                                let host = (b.match(/host=([^,]+)/) || [])[1] || b;
                                let share = (b.match(/share=([^,]+)/) || [])[1] || "";
                                let item = { i: isPhone ? "f-phone" : (b.indexOf("google-drive") === 0 ? "f-cloud" : "f-nas"), n: isPhone ? decodeURIComponent(host.replace(/_/g, " ")) : host,
                                             m: b.split(":")[0] + "://" + host + (share ? "/" + share : ""), path: g };
                                if (isPhone) drives.push({ i: "f-phone", n: item.n, m: "MTP · Bộ nhớ trong", path: g, lock: false, size: 0, used: 0, kv: [["Giao thức", "MTP"]] });
                                else net.push(item);
                            }
                        });
                        fm.xdg = x; fm.counts = counts; fm.drives = drives; fm.netPlaces = net;
                        fm.driveSel = Math.min(fm.driveSel, Math.max(0, drives.length - 1));
                    }
                }
            }
            Process { id: runner; onExited: refreshSoon.restart() }

            // ---------------- title bar ----------------
            Rectangle {
                id: tbar
                width: parent.width; height: 52
                color: Fz.crust
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Fz.line }
                Row {
                    x: 16; anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 26
                    spacing: 6
                    FIconBtn { ghost: true; icon: "f-left"; label: "Quay lại"; opacity: fm.back_.length ? 1 : 0.4; onClicked: fm.back() }
                    FIconBtn { ghost: true; icon: "f-right"; label: "Tiếp"; opacity: fm.fwd.length ? 1 : 0.4; onClicked: fm.forward() }
                    FIconBtn { ghost: true; icon: "f-up"; label: "Lên một cấp"; opacity: fm.isPc ? 0.4 : 1; onClicked: fm.up() }
                    Rectangle {
                        width: parent.width - 3 * 42 - 246 - viewSeg.width - 42 - 42 - 6
                        height: 36; radius: 11
                        color: Fz.well(0.25); border.width: 1; border.color: Fz.line
                        Row {
                            x: 12; anchors.verticalCenter: parent.verticalCenter
                            spacing: 8
                            FIcon { name: fm.crumbIcon; size: 15; color: Fz.acc; anchors.verticalCenter: parent.verticalCenter }
                            FText { text: fm.crumb; px: 13; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                        }
                        FText {
                            anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, parent.width - 220); elide: Text.ElideLeft
                            text: fm.isPc ? "computer:///" : fm.dir; mono: true; px: 11.5; color: Fz.dim
                        }
                    }
                    FInput {
                        id: search
                        width: 240; height: 36; radius: 11; fontSize: 13; icon: "f-search"
                        color: Fz.well(0.25); border.color: input.activeFocus ? Fz.glow : Fz.line
                        placeholder: "Tìm trong " + fm.crumb
                        onTextChanged: { fm.query = text; fm.sel = 0; }
                        Keys.onEscapePressed: { text = ""; keys.forceActiveFocus(); }
                    }
                    FSeg {
                        id: viewSeg
                        options: [{ icon: "f-grid" }, { icon: "f-list" }]
                        current: fm.isPc || fm.grid ? 0 : 1
                        onPicked: (i) => fm.grid = i === 0
                    }
                    FIconBtn { icon: "f-folderplus"; label: "Thư mục mới"; onClicked: { if (fm.isPc) fm.go(fm.home); dlg.ask("mkdir", null); } }
                    FIconBtn { ghost: true; icon: "f-x"; iconSize: 15; label: "Đóng"; onClicked: app.open = false }
                }
            }

            // ---------------- sidebar ----------------
            Rectangle {
                id: nav
                y: 52; width: 230; height: parent.height - 52 - 30
                color: Fz.crust
                Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Fz.line }
                Column {
                    x: 10; y: 8
                    width: parent.width - 20
                    spacing: 1
                    Nv { text: "Máy tính này"; icon: "f-pc"; on: fm.isPc; onClicked: fm.go("computer:") }
                    Gh { text: "Truy cập nhanh" }
                    Nv { text: "Thư mục cá nhân"; icon: "f-home"; on: fm.dir === fm.home; onClicked: fm.go(fm.home) }
                    Repeater {
                        model: fm.placeList.filter(p => p.n !== "Video" && (p.n !== "Zone-C" || fm.counts[p.p] !== undefined))
                        delegate: Nv {
                            required property var modelData
                            text: modelData.n; icon: modelData.i; on: fm.dir === modelData.p
                            badge: modelData.n === "Tải xuống" && fm.newDownloads > 0 ? fm.newDownloads + " mới" : ""
                            onClicked: fm.go(modelData.p)
                        }
                    }
                    Gh { text: "Thiết bị" }
                    Repeater {
                        model: fm.drives.filter(d => d.path !== "/home" && !/^(\/boot|\/efi)/.test(d.path))
                        delegate: Nv {
                            required property var modelData
                            text: modelData.n; icon: modelData.i; on: fm.dir === modelData.path
                            rightIcon: modelData.removable ? "f-eject" : ""
                            onRightClicked: { runner.command = ["bash", "-c", "udisksctl unmount -b \"$1\" && udisksctl power-off -b \"$1\" 2>/dev/null; true", "_", modelData.dev]; runner.running = true; }
                            onClicked: fm.go(modelData.path)
                        }
                    }
                    Gh { visible: fm.netPlaces.length > 0; text: "Mạng" }
                    Repeater {
                        model: fm.netPlaces
                        delegate: Nv { required property var modelData; text: modelData.n; icon: modelData.i; on: fm.dir === modelData.path; onClicked: fm.go(modelData.path) }
                    }
                }
                Nv {
                    x: 10; anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                    width: parent.width - 20
                    text: "Thùng rác"; icon: "f-trash"; on: fm.dir === fm.trashDir
                    badge: fm.trashBytes > 0 ? fm.fmtSize(fm.trashBytes) : ""
                    onClicked: fm.go(fm.trashDir)
                }
            }

            // ---------------- details ----------------
            Rectangle {
                id: aside
                anchors.right: parent.right
                y: 52; width: 280; height: parent.height - 52 - 30
                color: Fz.crust
                Rectangle { width: 1; height: parent.height; color: Fz.line }
                readonly property var d: fm.isPc ? (fm.drives[fm.driveSel] || null) : null
                readonly property var info: fm.isPc
                    ? (d ? { i: d.i, n: d.n, m: d.m, kv: d.kv } : { i: "f-pc", n: "Máy tính này", m: "computer:///", kv: [] })
                    : (fm.cur ? { i: fm.kind(fm.cur).i, n: fm.cur.name, m: fm.cur.path,
                                  kv: [["Loại", fm.kind(fm.cur).t], [fm.cur.dir ? "Nội dung" : "Kích thước", fm.sub(fm.cur)], ["Sửa lúc", fm.fmtDate(fm.cur.t)], ["Quyền", fm.perms(fm.cur.mode)]] }
                              : { i: fm.crumbIcon, n: fm.crumb, m: fm.dir, kv: [["Nội dung", fm.entries.length + " mục"]] })
                Column {
                    x: 20; y: 20
                    width: parent.width - 40
                    spacing: 12
                    Rectangle {
                        width: parent.width; height: 120; radius: 16
                        color: Fz.accA(0.08)
                        FIcon { anchors.centerIn: parent; name: aside.info.i; size: 52; strokeWidth: 1.3; color: Fz.acc }
                    }
                    Column {
                        width: parent.width
                        FText { width: parent.width; elide: Text.ElideMiddle; text: aside.info.n; px: 16; weight: Font.DemiBold }
                        FText { width: parent.width; elide: Text.ElideMiddle; text: aside.info.m; mono: true; px: 12; color: Fz.sub }
                    }
                    Column {
                        width: parent.width
                        Repeater {
                            model: aside.info.kv
                            delegate: Item {
                                required property var modelData
                                width: parent.width; height: 31
                                FText { anchors.verticalCenter: parent.verticalCenter; text: modelData[0]; px: 12.5; color: Fz.sub }
                                FText { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: modelData[1]; mono: true; px: 12.5 }
                                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Fz.fg(0.06) }
                            }
                        }
                    }
                }
                Row {
                    x: 20; anchors.bottom: parent.bottom; anchors.bottomMargin: 20
                    spacing: 6
                    FBtn { width: 117; text: "Mở"; onClicked: { if (fm.isPc) { if (aside.d) fm.go(aside.d.path); } else if (fm.cur) fm.activate(fm.cur); } }
                    FBtn { width: 117; text: "Dung lượng"; onClicked: Fz.open("settings", "storage") }
                }
            }

            // ---------------- content ----------------
            Item {
                id: content
                x: nav.width; y: 52
                width: parent.width - nav.width - aside.width
                height: parent.height - 52 - 30
                clip: true

                // Máy tính này
                Flickable {
                    visible: fm.isPc
                    anchors.fill: parent
                    contentHeight: pcCol.implicitHeight + 40
                    boundsBehavior: Flickable.StopAtBounds
                    Column {
                        id: pcCol
                        x: 24; y: 20
                        width: parent.width - 48
                        H3 { text: "Thư mục"; first: true }
                        Grid {
                            columns: 4; spacing: 10
                            width: parent.width
                            Repeater {
                                model: fm.placeList.filter(p => fm.counts[p.p] !== undefined).concat([{ n: "Thùng rác", i: "f-trash", p: fm.trashDir, trash: true }])
                                delegate: Fd {
                                    required property var modelData
                                    width: (pcCol.width - 30) / 4
                                    icon: modelData.i; text: modelData.n
                                    sub: modelData.trash ? (fm.trashBytes > 0 ? fm.fmtSize(fm.trashBytes) : "Trống") : fm.counts[modelData.p] + " mục"
                                    onClicked: fm.go(modelData.p)
                                }
                            }
                        }
                        H3 { text: "Ổ đĩa & thiết bị" }
                        Grid {
                            columns: 3; spacing: 10
                            width: parent.width
                            Repeater {
                                model: fm.drives
                                delegate: Rectangle {
                                    id: dv
                                    required property var modelData
                                    required property int index
                                    readonly property bool on: fm.driveSel === index
                                    readonly property int pct: modelData.size > 0 ? Math.round(modelData.used / modelData.size * 100) : 0
                                    width: (pcCol.width - 20) / 3; height: 116
                                    radius: 16
                                    color: on ? Fz.accA(0.07) : Fz.fg(dvMouse.containsMouse ? 0.07 : 0.035)
                                    border.width: on ? 2 : 1; border.color: on ? Fz.acc : Fz.fg(0.08)
                                    Column {
                                        x: 14; y: 14
                                        width: parent.width - 28
                                        spacing: 10
                                        Row {
                                            width: parent.width; spacing: 12
                                            Rectangle { width: 44; height: 44; radius: 13; color: Fz.accA(0.12)
                                                        FIcon { anchors.centerIn: parent; name: dv.modelData.i; size: 22; color: Fz.acc } }
                                            Column {
                                                width: parent.width - 56 - (dv.modelData.lock ? 26 : 0)
                                                anchors.verticalCenter: parent.verticalCenter
                                                FText { width: parent.width; elide: Text.ElideRight; text: dv.modelData.n; px: 14; weight: Font.DemiBold }
                                                FText { width: parent.width; elide: Text.ElideRight; text: dv.modelData.m; mono: true; px: 11.5; color: Fz.sub }
                                            }
                                            FIcon { visible: dv.modelData.lock; name: "f-lock"; size: 14; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
                                        }
                                        FBar { width: parent.width; height: 6; value: dv.pct / 100; fill: dv.pct > 70 ? Fz.yellow : Fz.acc }
                                        FText {
                                            px: 12; color: Fz.sub2
                                            text: dv.modelData.size === 0 ? "Thiết bị di động" : (dv.modelData.size - dv.modelData.used >= 1073741824
                                                  ? "Trống " + fm.gb(dv.modelData.size - dv.modelData.used) + " GB" : "Trống " + Math.round((dv.modelData.size - dv.modelData.used) / 1048576) + " MB") + " · đã dùng " + dv.pct + "%"
                                        }
                                    }
                                    MouseArea { id: dvMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: fm.driveSel = dv.index; onDoubleClicked: fm.go(dv.modelData.path) }
                                }
                            }
                        }
                        H3 { text: "Vị trí mạng" }
                        Grid {
                            columns: 3; spacing: 10
                            width: parent.width
                            Repeater {
                                model: fm.netPlaces
                                delegate: Fd { required property var modelData; width: (pcCol.width - 20) / 3; icon: modelData.i; text: modelData.n; sub: modelData.m; subMono: true; onClicked: fm.go(modelData.path) }
                            }
                            Fd { width: (pcCol.width - 20) / 3; dashed: true; icon: "f-plus"; text: "Kết nối máy chủ…"; sub: "SMB, SFTP, WebDAV"; onClicked: dlg.ask("connect", null) }
                        }
                    }
                }

                // folder: list
                Column {
                    visible: !fm.isPc && !fm.grid
                    x: 24; y: 20
                    width: parent.width - 48
                    height: parent.height - 20
                    spacing: 4
                    Row {
                        width: parent.width; height: 32
                        leftPadding: 12; rightPadding: 12; spacing: 10
                        readonly property real nameW: width - 24 - 150 - 110 - 90 - 30
                        FText { width: parent.nameW; text: "Tên"; px: 12; weight: Font.DemiBold; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
                        FText { width: 150; text: "Ngày sửa"; px: 12; weight: Font.DemiBold; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
                        FText { width: 110; text: "Loại"; px: 12; weight: Font.DemiBold; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
                        FText { width: 90; horizontalAlignment: Text.AlignRight; text: "Kích thước"; px: 12; weight: Font.DemiBold; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
                    }
                    ListView {
                        id: listView
                        width: parent.width; height: parent.height - 36
                        clip: true
                        model: fm.shown
                        currentIndex: fm.sel
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                        boundsBehavior: Flickable.StopAtBounds
                        delegate: Rectangle {
                            id: lr
                            required property var modelData
                            required property int index
                            readonly property var k: fm.kind(modelData)
                            width: listView.width; height: 40; radius: 10
                            color: index === fm.sel ? Fz.accA(0.12) : (lrMouse.containsMouse ? Fz.fg(0.05) : "transparent")
                            Row {
                                x: 12; anchors.verticalCenter: parent.verticalCenter
                                spacing: 10
                                Row {
                                    width: lr.width - 24 - 150 - 110 - 90 - 30
                                    spacing: 10
                                    FIcon { name: lr.k.i; color: Fz.acc; anchors.verticalCenter: parent.verticalCenter }
                                    FText { width: parent.width - 27; elide: Text.ElideRight; text: lr.modelData.name; px: 13; anchors.verticalCenter: parent.verticalCenter }
                                }
                                FText { width: 150; text: fm.fmtDate(lr.modelData.t); px: 13; color: Fz.sub }
                                FText { width: 110; elide: Text.ElideRight; text: lr.k.t; px: 13; color: Fz.sub }
                                FText { width: 90; horizontalAlignment: Text.AlignRight; text: fm.sub(lr.modelData); mono: true; px: 12; color: Fz.sub }
                            }
                            MouseArea {
                                id: lrMouse; anchors.fill: parent; hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (e) => { fm.sel = lr.index; keys.forceActiveFocus(); if (e.button === Qt.RightButton) menu.popup(lr.modelData, mapToItem(win.contentItem, e.x, e.y)); }
                                onDoubleClicked: fm.activate(lr.modelData)
                            }
                        }
                    }
                }

                // folder: grid
                GridView {
                    id: gridView
                    visible: !fm.isPc && fm.grid
                    x: 24; y: 20
                    width: parent.width - 48; height: parent.height - 20
                    clip: true
                    cellWidth: width / 4; cellHeight: 76
                    model: fm.shown
                    currentIndex: fm.sel
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Item {
                        required property var modelData
                        required property int index
                        width: gridView.cellWidth; height: gridView.cellHeight
                        Fd {
                            x: 5; width: parent.width - 10
                            icon: fm.kind(parent.modelData).i; text: parent.modelData.name; sub: fm.sub(parent.modelData)
                            on: parent.index === fm.sel
                            onClicked: { fm.sel = parent.index; keys.forceActiveFocus(); }
                            onDoubleClicked: fm.activate(parent.modelData)
                            onMenu: (p) => { fm.sel = parent.index; menu.popup(parent.modelData, p); }
                        }
                    }
                }
                FText {
                    visible: !fm.isPc && fm.shown.length === 0 && !lister.running
                    anchors.centerIn: parent
                    text: fm.query ? "Không có tệp khớp “" + fm.query + "”." : "Thư mục trống."
                    px: 13; color: Fz.sub
                }
            }

            // ---------------- status ----------------
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 30
                color: Fz.crust
                Rectangle { width: parent.width; height: 1; color: Fz.line }
                FText {
                    x: 16; anchors.verticalCenter: parent.verticalCenter; px: 12; color: Fz.sub
                    text: fm.isPc ? (Object.keys(fm.counts).length + 1) + " thư mục · " + fm.drives.length + " ổ đĩa · " + fm.netPlaces.length + " vị trí mạng"
                                  : fm.shown.length + " mục" + (fm.cur ? " · đã chọn " + fm.cur.name : "")
                }
                FText {
                    anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                    text: "trống " + fm.gb(fm.rootFree) + " GB / " + fm.gb(fm.rootSize) + " GB"; mono: true; px: 12; color: Fz.sub
                }
            }

            // ---------------- context menu ----------------
            MouseArea { anchors.fill: parent; visible: menu.visible; onClicked: menu.visible = false }
            FMenu {
                id: menu
                visible: false
                property var item: null
                function popup(it, p) { item = it; x = Math.min(p.x, win.width - width - 8); y = Math.min(p.y, win.height - height - 8); visible = true; }
                FMenuItem { text: "Mở"; icon: "f-right"; onTriggered: { menu.visible = false; fm.activate(menu.item); } }
                FMenuItem { visible: menu.item && menu.item.dir; text: "Mở trong terminal"; icon: "f-code"; onTriggered: { menu.visible = false; Quickshell.execDetached(["bash", "-c", "cd -- \"$1\" && exec ${TERMINAL:-kitty}", "_", menu.item.path]); } }
                FMenuItem { text: "Đổi tên"; hint: "F2"; onTriggered: { menu.visible = false; dlg.ask("rename", menu.item); } }
                FMenuItem { text: "Sao chép đường dẫn"; onTriggered: { menu.visible = false; Quickshell.execDetached(["wl-copy", menu.item.path]); } }
                FMenuSep {}
                FMenuItem { text: fm.dir === fm.trashDir ? "Xóa vĩnh viễn" : "Chuyển vào thùng rác"; icon: "f-trash"; hint: "Del"; danger: true
                            onTriggered: { menu.visible = false; if (fm.dir === fm.trashDir) { runner.command = ["gio", "remove", menu.item.path]; runner.running = true; } else fm.trash(menu.item); } }
            }

            // ---------------- name prompt (new folder, rename, connect) ----------------
            Rectangle {
                id: dlg
                visible: false
                anchors.fill: parent
                color: Fz.surf(0.45)
                property string kind: ""
                property var target: null
                function ask(k, t) {
                    kind = k; target = t;
                    field.text = k === "rename" ? t.name : (k === "mkdir" ? "Thư mục mới" : "smb://");
                    visible = true;
                    field.input.forceActiveFocus(); field.input.selectAll();
                }
                function done() {
                    let v = field.text.trim();
                    visible = false; keys.forceActiveFocus();
                    if (!v) return;
                    if (kind === "mkdir") runner.command = ["mkdir", "-p", "--", fm.join(v)];
                    else if (kind === "rename") runner.command = ["mv", "-n", "--", target.path, fm.join(v)];
                    else { runner.command = ["gio", "mount", v]; }
                    runner.running = true;
                }
                MouseArea { anchors.fill: parent; onClicked: { dlg.visible = false; keys.forceActiveFocus(); } }
                Solid {
                    anchors.centerIn: parent
                    width: 420; height: dcol.implicitHeight + 44
                    radius: 22
                    MouseArea { anchors.fill: parent }
                    Column {
                        id: dcol
                        x: 22; y: 22
                        width: parent.width - 44
                        spacing: 14
                        FText { text: dlg.kind === "mkdir" ? "Thư mục mới" : dlg.kind === "rename" ? "Đổi tên" : "Kết nối máy chủ"; px: 16; weight: Font.DemiBold }
                        FInput { id: field; width: parent.width; onAccepted: dlg.done(); Keys.onEscapePressed: { dlg.visible = false; keys.forceActiveFocus(); } }
                        FText { visible: dlg.kind === "connect"; text: "Ví dụ: smb://192.168.1.10/share, sftp://máy-chủ, dav://…"; px: 12; color: Fz.sub }
                        Row {
                            anchors.right: parent.right
                            spacing: 8
                            FBtn { text: "Hủy"; onClicked: { dlg.visible = false; keys.forceActiveFocus(); } }
                            FBtn { kind: "pri"; text: dlg.kind === "connect" ? "Kết nối" : dlg.kind === "rename" ? "Đổi tên" : "Tạo"; onClicked: dlg.done() }
                        }
                    }
                }
            }
        }
    }

    // `.nv` sidebar row
    component Nv: Rectangle {
        id: nv
        property string text
        property string icon
        property string badge: ""
        property string rightIcon: ""
        property bool on: false
        signal clicked()
        signal rightClicked()
        width: parent ? parent.width : 0; height: 32; radius: 10
        color: on ? Fz.acc : (nvMouse.containsMouse ? Fz.fg(0.06) : "transparent")
        MouseArea { id: nvMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: nv.clicked() }
        Row {
            x: 10; anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            FIcon { name: nv.icon; size: 16; color: nv.on ? Fz.ink : (nvMouse.containsMouse ? Fz.tx : Fz.sub2); anchors.verticalCenter: parent.verticalCenter }
            FText { width: nv.width - 46 - (nv.badge || nv.rightIcon ? 50 : 0); elide: Text.ElideRight; text: nv.text; px: 13; weight: nv.on ? Font.Medium : Font.Normal
                    color: nv.on ? Fz.ink : (nvMouse.containsMouse ? Fz.tx : Fz.sub2); anchors.verticalCenter: parent.verticalCenter }
        }
        FText { visible: nv.badge !== ""; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                text: nv.badge; px: 11; opacity: 0.7; color: nv.on ? Fz.ink : Fz.sub2 }
        Item {
            visible: nv.rightIcon !== ""
            anchors.right: parent.right; anchors.rightMargin: 4
            width: 26; height: 26; anchors.verticalCenter: parent.verticalCenter
            FIcon { anchors.centerIn: parent; name: nv.rightIcon; size: 13; opacity: 0.7; color: nv.on ? Fz.ink : Fz.sub2 }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: nv.rightClicked() }
        }
    }
    // `.gh` group heading
    component Gh: FText {
        leftPadding: 10; topPadding: 12; bottomPadding: 4
        px: 10.5; weight: Font.DemiBold; color: Fz.dim
        font.letterSpacing: 10.5 * 0.09; font.capitalization: Font.AllUppercase
    }
    // `.h3` section heading
    component H3: FText {
        property bool first: false
        leftPadding: 4; topPadding: first ? 0 : 24; bottomPadding: 10
        px: 12; weight: Font.DemiBold; color: Fz.sub
        font.letterSpacing: 12 * 0.08; font.capitalization: Font.AllUppercase
    }
    // `.fd` folder card
    component Fd: Rectangle {
        id: fd
        property string icon
        property string text
        property string sub
        property bool subMono: false
        property bool dashed: false
        property bool on: false
        signal clicked()
        signal doubleClicked()
        signal menu(point p)
        height: 66; radius: 14
        color: on ? Fz.accA(0.12) : Fz.fg(fdMouse.containsMouse ? 0.07 : 0.035)
        border.width: 1; border.color: dashed ? "transparent" : Fz.fg(0.07)
        Canvas {
            visible: fd.dashed
            anchors.fill: parent
            onPaint: { let c = getContext("2d"); c.reset(); c.setLineDash([3, 3]); c.strokeStyle = Fz.fg(0.14); c.lineWidth = 1;
                       c.beginPath(); c.roundedRect(0.5, 0.5, width - 1, height - 1, 14, 14); c.stroke(); }
        }
        Row {
            x: 12; anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            Rectangle { width: 40; height: 40; radius: 12; color: Fz.accA(0.12)
                        FIcon { anchors.centerIn: parent; name: fd.icon; color: Fz.acc } }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: fd.width - 76
                FText { width: parent.width; elide: Text.ElideRight; text: fd.text; px: 13.5; weight: Font.Medium }
                FText { width: parent.width; elide: Text.ElideRight; text: fd.sub; mono: fd.subMono; px: 11.5; color: Fz.sub }
            }
        }
        MouseArea {
            id: fdMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (e) => { if (e.button === Qt.RightButton) fd.menu(mapToItem(null, e.x, e.y)); else fd.clicked(); }
            onDoubleClicked: fd.doubleClicked()
        }
    }
}
