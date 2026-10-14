import QtQuick
import Quickshell
import Quickshell.Io
import "../"

// File chooser of the FilePicker artboard ("Chọn tệp Mở / Lưu"), as an overlay inside a shell window.
// show(title, extensions, startDir, mode, saveName) -> accepted(path) | canceled()
Item {
    id: root
    anchors.fill: parent
    visible: false

    property string title: "Mở tệp"
    property string subtitle: "Zone-C"
    property string mode: "open"             // "open" | "save"
    property var exts: []                    // ["png", "jpg"]; empty = everything
    property string filterLabel: "Tất cả tệp"
    property string dir: home
    property var history: []
    property var entries: []
    property int sel: -1
    property string query: ""
    property bool allFiles: false
    readonly property string home: Quickshell.env("HOME") || "/"
    readonly property string user: Quickshell.env("USER") || ""
    signal accepted(string path)
    signal canceled()

    function show(t, e, start, m, saveName) {
        title = t || "Mở tệp";
        exts = e || [];
        filterLabel = exts.length ? "Tệp phù hợp (" + exts.map(x => "*." + x).join(", ") + ")" : "Tất cả tệp";
        mode = m || "open";
        nameField.text = saveName || "";
        allFiles = false;
        history = [];
        go(start || home, false);
        visible = true;
        forceActiveFocus();
    }
    function close(ok) {
        visible = false;
        if (!ok) canceled();
    }
    function go(path, remember) {
        if (remember !== false && dir !== path) history = history.concat([dir]);
        dir = path;
        sel = -1;
        query = "";
        lister.running = false;
        lister.running = true;
    }
    function matches(e) {
        if (e.dir || allFiles || exts.length === 0) return true;
        let n = e.name.toLowerCase();
        return exts.some(x => n.endsWith("." + x));
    }
    readonly property var crumbs: {
        if (dir === "recent:") return ["Gần đây"];
        let rel = dir.indexOf(home) === 0 ? user + dir.slice(home.length) : dir;
        return rel.split("/").filter(s => s !== "");
    }
    readonly property var shown: entries.filter(e => query === "" || e.name.toLowerCase().indexOf(query.toLowerCase()) !== -1)
    function pick(e) {
        if (e.dir) { go(dir.replace(/\/$/, "") + "/" + e.name); return; }
        if (mode === "save") { nameField.text = e.name; return; }
        if (!matches(e)) return;
        visible = false;
        accepted(dir.replace(/\/$/, "") + "/" + e.name);
    }
    function confirm() {
        if (mode === "save") {
            let n = nameField.text.trim();
            if (n === "") return;
            visible = false;
            accepted(dir.replace(/\/$/, "") + "/" + n);
            return;
        }
        if (sel >= 0 && sel < shown.length) pick(shown[sel]);
    }

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
        if (b < 1073741824) return (b / 1048576).toFixed(1) + " MB";
        return (b / 1073741824).toFixed(1) + " GB";
    }
    function iconFor(e) {
        if (e.dir) return "p-folder";
        let n = e.name.toLowerCase();
        if (/\.(png|jpe?g|webp|gif|svg|bmp|avif)$/.test(n)) return "p-image";
        return "p-doc";
    }

    // places: XDG user dirs + removable drives
    property var places: []
    property var devices: []
    Process {
        running: true
        command: ["bash", "-c", "for k in DESKTOP DOWNLOAD DOCUMENTS PICTURES; do xdg-user-dir $k 2>/dev/null || echo; done; echo ---; for d in /run/media/$USER/*; do [ -d \"$d\" ] && echo \"$d\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.split("---");
                let x = parts[0].trim().split("\n");
                let h = root.home;
                root.places = [
                    { n: "Thư mục cá nhân", i: "p-home", p: h },
                    { n: "Màn hình nền", i: "p-desk", p: x[0] || h + "/Desktop" },
                    { n: "Tải xuống", i: "p-down", p: x[1] || h + "/Downloads" },
                    { n: "Tài liệu", i: "p-doc", p: x[2] || h + "/Documents" },
                    { n: "Hình ảnh", i: "p-image", p: x[3] || h + "/Pictures" }
                ];
                root.devices = (parts[1] || "").trim().split("\n").filter(s => s !== "").map(p => ({ n: p.split("/").pop(), i: "p-usb", p: p }));
            }
        }
    }

    Process {
        id: lister
        command: root.dir === "recent:"
            ? ["bash", "-c", "find \"$HOME\" -maxdepth 3 -type f -not -path '*/.*' -mtime -7 -printf '%T@\\tf\\t%p\\t%s\\n' 2>/dev/null | sort -rn | head -60"]
            : ["bash", "-c", "cd -- \"$1\" 2>/dev/null || exit; for f in *; do [ -e \"$f\" ] || continue; if [ -d \"$f\" ]; then n=$(find \"$f\" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l); printf '%s\\td\\t%s\\t%s\\n' \"$(stat -c %Y \"$f\")\" \"$f\" \"$n\"; else printf '%s\\tf\\t%s\\t%s\\n' \"$(stat -c %Y \"$f\")\" \"$f\" \"$(stat -c %s \"$f\")\"; fi; done", "_", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = [];
                this.text.split("\n").forEach(l => {
                    let c = l.split("\t");
                    if (c.length < 4) return;
                    let full = c[2];
                    out.push({ name: root.dir === "recent:" ? full.split("/").pop() : full, path: full, dir: c[1] === "d", t: Number(c[0]), size: Number(c[3]) });
                });
                if (root.dir !== "recent:") out.sort((a, b) => (a.dir === b.dir) ? a.name.localeCompare(b.name, "vi") : (a.dir ? -1 : 1));
                root.entries = out;
            }
        }
    }
    Process { id: mkdir; onExited: { lister.running = false; lister.running = true; } }

    Keys.onEscapePressed: close(false)
    Keys.onReturnPressed: confirm()

    // dimmed backdrop (rgba(surf, .45) in the artboard)
    Rectangle {
        anchors.fill: parent
        color: Fz.surf(0.45)
        MouseArea { anchors.fill: parent; onClicked: root.close(false) }
    }

    // `.solid` dialog, 1000x700, radius 22
    Rectangle {
        id: dialog
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, Math.min(92, (parent.height - height) / 2))
        width: Math.min(1000, parent.width - 40)
        height: Math.min(700, parent.height - 80)
        radius: 22
        color: Fz.mantle
        border.width: 1; border.color: Fz.line
        clip: true
        MouseArea { anchors.fill: parent }

        // header
        Rectangle {
            id: head
            width: parent.width; height: 60
            color: Fz.crust
            radius: 22
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 22; color: Fz.crust }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Fz.line }
            Column {
                x: 20; anchors.verticalCenter: parent.verticalCenter
                FText { text: root.title; px: 15; weight: Font.DemiBold }
                FText { text: "Yêu cầu từ " + root.subtitle + " · xdg-desktop-portal"; color: Fz.sub; px: 12 }
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                FSeg { options: ["Mở tệp", "Lưu tệp"]; current: root.mode === "save" ? 1 : 0; onPicked: (i) => root.mode = i === 1 ? "save" : "open"; anchors.verticalCenter: parent.verticalCenter }
                FIconBtn { ghost: true; icon: "p-x"; iconSize: 15; label: "Đóng"; onClicked: root.close(false); anchors.verticalCenter: parent.verticalCenter }
            }
        }

        // places
        Rectangle {
            id: nav
            y: 60; width: 210; height: parent.height - 60
            color: Fz.crust
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Fz.line }
            Column {
                x: 10; y: 8
                width: parent.width - 20
                spacing: 1
                NavRow { label: "Gần đây"; icon: "p-clock"; on: root.dir === "recent:"; onClicked: root.go("recent:") }
                FText { leftPadding: 10; topPadding: 12; bottomPadding: 4; text: "VỊ TRÍ"; color: Fz.dim; px: 10.5; weight: Font.DemiBold; font.letterSpacing: 10.5 * 0.09 }
                Repeater {
                    model: root.places
                    delegate: NavRow { required property var modelData; label: modelData.n; icon: modelData.i; on: root.dir === modelData.p; onClicked: root.go(modelData.p) }
                }
                FText { visible: root.devices.length > 0; leftPadding: 10; topPadding: 12; bottomPadding: 4; text: "THIẾT BỊ"; color: Fz.dim; px: 10.5; weight: Font.DemiBold; font.letterSpacing: 10.5 * 0.09 }
                Repeater {
                    model: root.devices
                    delegate: NavRow { required property var modelData; label: modelData.n; icon: modelData.i; on: root.dir === modelData.p; onClicked: root.go(modelData.p) }
                }
            }
        }

        // main column
        Item {
            x: 210; y: 60
            width: parent.width - 210; height: parent.height - 60

            Item {
                id: tools
                width: parent.width; height: 52
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Fz.line }
                Row {
                    x: 14; anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    FIconBtn { ghost: true; icon: "p-left"; label: "Quay lại"; anchors.verticalCenter: parent.verticalCenter
                        onClicked: if (root.history.length) { let h = root.history.slice(); let p = h.pop(); root.history = h; root.go(p, false); } }
                    FIconBtn { ghost: true; icon: "p-up"; label: "Lên một cấp"; anchors.verticalCenter: parent.verticalCenter
                        onClicked: if (root.dir !== "/" && root.dir !== "recent:") root.go(root.dir.replace(/\/[^/]*\/?$/, "") || "/") }
                    Row {
                        width: tools.width - 14 - 36 - 36 - 12 - 200 - 6 - 36 - 6 - 14 - 6
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        clip: true
                        Repeater {
                            model: root.crumbs
                            delegate: Row {
                                required property var modelData
                                required property int index
                                readonly property bool last: index === root.crumbs.length - 1
                                spacing: 6
                                FText { visible: index > 0; text: "/"; color: Fz.dim; px: 13 }
                                FText { text: modelData; px: 13; color: last ? Fz.tx : Fz.sub; weight: last ? Font.DemiBold : Font.Normal }
                            }
                        }
                    }
                    Rectangle {
                        width: 200; height: 34; radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        color: Fz.well(0.25); border.width: 1; border.color: Fz.line
                        Row {
                            x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                            FIcon { name: "p-search"; size: 14; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
                            Item {
                                width: 160; height: 20; anchors.verticalCenter: parent.verticalCenter
                                TextInput { id: search; anchors.fill: parent; verticalAlignment: TextInput.AlignVCenter; color: Fz.tx; font.family: Fz.font; font.pointSize: 13 * 0.75; clip: true; onTextChanged: root.query = text }
                                FText { visible: search.text === ""; anchors.verticalCenter: parent.verticalCenter; text: "Tìm…"; color: Fz.dim; px: 13 }
                            }
                        }
                    }
                    FIconBtn { icon: "p-plus"; label: "Thư mục mới"; anchors.verticalCenter: parent.verticalCenter
                        onClicked: if (root.dir !== "recent:") { mkdir.command = ["bash", "-c", "cd -- \"$1\" && n='Thư mục mới'; i=2; while [ -e \"$n\" ]; do n=\"Thư mục mới $i\"; i=$((i+1)); done; mkdir -- \"$n\"", "_", root.dir]; mkdir.running = true; } }
                }
            }

            // column header `.lr`
            Item {
                id: colHead
                y: 52; width: parent.width; height: 30
                Row {
                    x: 20; anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    FText { width: colHead.width - 40 - 130 - 90 - 20; text: "Tên"; color: Fz.sub; px: 11.5; weight: Font.DemiBold }
                    FText { width: 130; text: "Ngày sửa"; color: Fz.sub; px: 11.5; weight: Font.DemiBold }
                    FText { width: 90; text: "Kích thước"; color: Fz.sub; px: 11.5; weight: Font.DemiBold; horizontalAlignment: Text.AlignRight }
                }
            }

            ListView {
                id: files
                y: 82
                x: 8
                width: parent.width - 16
                height: parent.height - 82 - foot.height
                clip: true
                spacing: 1
                model: root.shown
                boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool on: root.sel === index
                    readonly property bool dim: (root.mode === "save" && !modelData.dir) || !root.matches(modelData)
                    width: files.width; height: 38; radius: 10
                    color: on ? Fz.acc : (rowMouse.containsMouse ? Fz.fg(0.05) : "transparent")
                    opacity: dim ? 0.4 : 1
                    Row {
                        x: 12; anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        Row {
                            width: files.width - 24 - 130 - 90 - 20
                            spacing: 10
                            FIcon { name: root.iconFor(modelData); color: on ? Fz.ink : Fz.tx; anchors.verticalCenter: parent.verticalCenter }
                            FText { width: parent.width - 27; elide: Text.ElideRight; text: modelData.name; px: 13; color: on ? Fz.ink : Fz.tx; anchors.verticalCenter: parent.verticalCenter }
                        }
                        FText { width: 130; text: root.fmtDate(modelData.t); px: 13; color: on ? Fz.ink : Fz.sub }
                        FText { width: 90; mono: true; text: modelData.dir ? modelData.size + " mục" : root.fmtSize(modelData.size); px: 12; color: on ? Fz.ink : Fz.sub; horizontalAlignment: Text.AlignRight }
                    }
                    MouseArea { id: rowMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.sel = index
                        onDoubleClicked: root.pick(modelData) }
                }
                FText { anchors.centerIn: parent; visible: root.shown.length === 0; text: root.query ? "Không có tệp nào khớp “" + root.query + "”" : "Thư mục trống"; color: Fz.sub; px: 13 }
            }

            // footer
            Rectangle {
                id: foot
                anchors.bottom: parent.bottom
                width: parent.width
                height: footCol.implicitHeight + 28
                color: Fz.crust
                Rectangle { width: parent.width; height: 1; color: Fz.line }
                Column {
                    id: footCol
                    x: 16; y: 14
                    width: parent.width - 32
                    spacing: 10
                    Row {
                        visible: root.mode === "save"
                        width: parent.width; spacing: 10
                        FText { width: 70; text: "Tên tệp"; color: Fz.sub; px: 13; anchors.verticalCenter: parent.verticalCenter }
                        FInput { id: nameField; width: parent.width - 80; height: 38; onAccepted: root.confirm() }
                    }
                    Row {
                        width: parent.width; spacing: 10
                        FText { width: 70; text: "Loại"; color: Fz.sub; px: 13; anchors.verticalCenter: parent.verticalCenter }
                        FSelect { width: parent.width - 70 - 10 - cancelB.width - 10 - okB.width - 10; options: [root.filterLabel, "Tất cả tệp"]; current: root.allFiles ? 1 : 0; onPicked: (i) => root.allFiles = i === 1; anchors.verticalCenter: parent.verticalCenter }
                        FBtn { id: cancelB; height: 38; text: "Hủy"; onClicked: root.close(false) }
                        FBtn { id: okB; height: 38; width: Math.max(110, implicitWidth); kind: "pri"; text: root.mode === "save" ? "Lưu" : "Mở"; onClicked: root.confirm() }
                    }
                }
            }
        }
    }

    // `.nv` place row
    component NavRow: Rectangle {
        id: nv
        property string label
        property string icon
        property bool on: false
        signal clicked()
        width: 190; height: 32; radius: 10
        color: on ? Fz.acc : (nvMouse.containsMouse ? Fz.fg(0.06) : "transparent")
        Row {
            x: 10; anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            FIcon { name: nv.icon; size: 16; color: nv.on ? Fz.ink : (nvMouse.containsMouse ? Fz.tx : Fz.sub2); anchors.verticalCenter: parent.verticalCenter }
            FText { text: nv.label; px: 13; weight: nv.on ? Font.Medium : Font.Normal; color: nv.on ? Fz.ink : (nvMouse.containsMouse ? Fz.tx : Fz.sub2); anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { id: nvMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: nv.clicked() }
    }
}
