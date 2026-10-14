import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"
import "../frost"

// Clipboard history of the Frost design (Clipboard.dc.html), backed by cliphist.
PanelWindow {
    id: win
    screen: ClipboardController.screen
    visible: ClipboardController.isVisible
    WlrLayershell.namespace: "qs-clipboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    property var items: []
    property int total: 0
    property string query: ""
    property int filter: 0                // all, text, image, link, pinned
    property int sel: 0
    property var seen: ({})
    readonly property string cacheDir: Caching.cacheDir ? Caching.cacheDir + "/clipboard" : ""
    readonly property string fetcher: Caching.qsDir + "/clipboard/clip_fetcher.py"

    function close() { ClipboardController.hide(); }
    onVisibleChanged: if (visible) { query = ""; field.text = ""; sel = 0; refresh(); focusTimer.restart(); }
    Timer { id: focusTimer; interval: 40; onTriggered: field.forceActiveFocus() }

    function kind(it) {
        if (it.type === "image") return "image";
        let c = (it.content || "").trim();
        if (/^(https?|ftp):\/\/\S+$/i.test(c)) return "link";
        if (/^(sudo |bash |sh |yay |pacman |git |cd |ls |quickshell |zone-c |curl |systemctl |hyprctl |npm |pip |python|nvim |code )/.test(c) || /\$\(|&&|\|\s*\w|;\s*\w|^[#$] /.test(c)) return "code";
        return "text";
    }
    // "[[ binary data 33 KiB png 1440x900 ]]" -> "Ảnh PNG · 1440×900"; copied files keep their name
    function imageLabel(it) {
        let m = /binary data\s+([\d.]+\s*\w+)\s+(\w+)\s+(\d+)x(\d+)/.exec(it.meta || "");
        if (m) return "Ảnh " + m[2].toUpperCase() + " · " + m[3] + "×" + m[4] + " · " + m[1];
        return (it.content || "").split("/").pop();
    }
    function ago(id) {
        let t = seen[id];
        if (!t) return "";
        let m = Math.floor((Date.now() - t) / 60000);
        return m < 1 ? "vừa xong" : m < 60 ? m + " phút" : m < 1440 ? Math.floor(m / 60) + " giờ" : Math.floor(m / 1440) + " ngày";
    }
    readonly property var shown: {
        let q = query.trim().toLowerCase();
        return items.filter(it => {
            let k = kind(it);
            let f = filter === 0 || (filter === 1 && (k === "text" || k === "code")) || (filter === 2 && k === "image") || (filter === 3 && k === "link") || (filter === 4 && it.pinned);
            return f && (q === "" || (k !== "image" && it.content.toLowerCase().indexOf(q) !== -1));
        }).sort((a, b) => (b.pinned ? 1 : 0) - (a.pinned ? 1 : 0));
    }
    onShownChanged: if (sel >= shown.length) sel = Math.max(0, shown.length - 1)

    // ---------- cliphist ----------
    Process {
        id: fetch
        command: ["python3", win.fetcher, "0", "60", win.cacheDir]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let list = JSON.parse(this.text);
                    let s = Object.assign({}, win.seen), now = Date.now(), changed = false;
                    list.forEach(it => { if (!s[it.id]) { s[it.id] = now; changed = true; } });
                    win.items = list;
                    if (changed) { win.seen = s; win.saveSeen(); }
                } catch (e) { win.items = []; }
            }
        }
    }
    Process { id: count; command: ["bash", "-c", "cliphist list | wc -l"]; stdout: StdioCollector { onStreamFinished: win.total = parseInt(this.text) || 0 } }
    Process { id: action; onExited: win.refresh() }
    function refresh() { fetch.running = true; count.running = true; }

    FileView { path: win.cacheDir ? win.cacheDir + "/seen.json" : ""; onLoaded: { try { win.seen = JSON.parse(text()); } catch (e) {} } }
    function saveSeen() { Quickshell.execDetached(["bash", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "_", cacheDir + "/seen.json", JSON.stringify(seen)]); }
    // new copies while the window is closed get their first-seen time too
    Process { running: true; command: ["wl-paste", "--watch", "echo", "1"]; stdout: SplitParser { onRead: (_) => { if (!win.visible) fetch.running = true; } } }

    function paste(it) {
        if (!it) return;
        Quickshell.execDetached(["bash", "-c", "cliphist decode \"$1\" | wl-copy && command -v wtype >/dev/null && (sleep 0.2; wtype -M ctrl v -m ctrl)", "_", it.id]);
        close();
    }
    function pin(it) { action.command = ["python3", fetcher, "pin", it.id, cacheDir]; action.running = true; }
    function remove(it) { action.command = ["python3", fetcher, "delete", it.id, cacheDir]; action.running = true; }
    function wipe() { action.command = ["python3", fetcher, "wipe", cacheDir]; action.running = true; }

    Rectangle { anchors.fill: parent; color: "transparent"; MouseArea { anchors.fill: parent; onClicked: win.close() } }

    Glass {
        x: parent.width - 300 - width
        y: 58
        width: 560
        height: col.implicitHeight + 28
        MouseArea { anchors.fill: parent }

        Column {
            id: col
            x: 14; y: 14
            width: parent.width - 28
            spacing: 10

            Row {
                width: parent.width
                spacing: 10
                Rectangle {
                    width: parent.width - 10 - clearBtn.width; height: 44; radius: 14
                    color: Fz.well(0.25); border.width: 1; border.color: Fz.line2
                    Row {
                        x: 14; anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        FIcon { name: "cb-search"; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
                        Item {
                            width: col.width - 10 - clearBtn.width - 28 - 27; height: 22; anchors.verticalCenter: parent.verticalCenter
                            TextInput {
                                id: field; anchors.fill: parent; verticalAlignment: TextInput.AlignVCenter
                                color: Fz.tx; font.family: Fz.font; font.pointSize: 14.5 * 0.75; clip: true
                                onTextChanged: { win.query = text; win.sel = 0; }
                                Keys.onPressed: (e) => {
                                    let it = win.shown[win.sel];
                                    if (e.key === Qt.Key_Escape) { win.close(); e.accepted = true; }
                                    else if (e.key === Qt.Key_Down) { win.sel = Math.min(win.sel + 1, win.shown.length - 1); e.accepted = true; }
                                    else if (e.key === Qt.Key_Up) { win.sel = Math.max(0, win.sel - 1); e.accepted = true; }
                                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { win.paste(it); e.accepted = true; }
                                    else if (e.key === Qt.Key_P && (e.modifiers & Qt.ControlModifier)) { if (it) win.pin(it); e.accepted = true; }
                                    else if (e.key === Qt.Key_Delete) { if (it) win.remove(it); e.accepted = true; }
                                    else if (e.key === Qt.Key_Tab) { win.filter = (win.filter + 1) % 5; e.accepted = true; }
                                }
                            }
                            FText { anchors.verticalCenter: parent.verticalCenter; visible: field.text === ""; text: "Tìm trong lịch sử clipboard"; color: Fz.dim; px: 14.5 }
                        }
                    }
                }
                FBtn { id: clearBtn; height: 44; kind: "danger"; text: "Xóa hết"; onClicked: win.wipe() }
            }

            FSeg {
                width: parent.width
                btnWidth: (parent.width - 6 - 8) / 5
                options: ["Tất cả", "Văn bản", "Ảnh", "Link", "Đã ghim"]
                current: win.filter
                onPicked: (i) => { win.filter = i; win.sel = 0; field.forceActiveFocus(); }
            }

            Column {
                width: parent.width
                spacing: 6
                Repeater {
                    model: win.shown.slice(0, 8)
                    delegate: Rectangle {
                        id: ci
                        required property var modelData
                        required property int index
                        readonly property string k: win.kind(modelData)
                        readonly property bool first: index === win.sel
                        width: col.width
                        height: k === "image" ? 72 : 56
                        radius: 14
                        color: first ? Fz.accA(0.12) : Fz.fg(ciMouse.containsMouse ? 0.07 : 0.04)
                        border.width: 1; border.color: first ? Fz.accA(0.35) : Fz.fg(0.06)
                        Row {
                            x: 12; anchors.verticalCenter: parent.verticalCenter
                            spacing: 12
                            Ico { icon: ({ text: "cb-text", code: "cb-code", image: "cb-image", link: "cb-link" })[ci.k]; anchors.verticalCenter: parent.verticalCenter }
                            RoundImage {
                                visible: ci.k === "image"
                                width: visible ? 92 : 0; height: 52; radius: 9
                                source: ci.k === "image" ? "file://" + ci.modelData.content : ""
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            FText {
                                width: ci.width - 24 - 36 - 12 * 4 - 60 - 30 - 30 - (ci.k === "image" ? 92 + 12 : 0)
                                elide: Text.ElideRight; maximumLineCount: 1
                                text: ci.k === "image" ? win.imageLabel(ci.modelData) : ci.modelData.content.replace(/\s+/g, " ")
                                mono: ci.k === "code" || ci.k === "link"
                                px: 13.5
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            FText { width: 60; horizontalAlignment: Text.AlignRight; text: win.ago(ci.modelData.id); px: 11.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
                            FIconBtn { width: 30; height: 30; ghost: !ci.modelData.pinned; on: ci.modelData.pinned; icon: "cb-pin"; iconSize: 14; label: "Ghim"; onClicked: win.pin(ci.modelData); anchors.verticalCenter: parent.verticalCenter }
                            FIconBtn { width: 30; height: 30; ghost: true; icon: "cb-trash"; iconSize: 14; label: "Xóa mục"; onClicked: win.remove(ci.modelData); anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea { id: ciMouse; anchors.fill: parent; anchors.rightMargin: 84; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onEntered: win.sel = ci.index; onClicked: win.paste(ci.modelData) }
                    }
                }
                FText { visible: win.shown.length === 0; width: parent.width; topPadding: 40; bottomPadding: 40; horizontalAlignment: Text.AlignHCenter; text: "Clipboard trống."; color: Fz.sub; px: 14 }
            }

            Item {
                width: parent.width
                height: 34
                Rectangle { width: parent.width; height: 1; color: Fz.line }
                Row {
                    x: 4; y: 4 + 6
                    spacing: 14
                    Row { spacing: 4; FKbd { text: "Enter" } FText { text: "dán"; px: 12; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter } }
                    Row { spacing: 4; FKbd { text: "Ctrl P" } FText { text: "ghim"; px: 12; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter } }
                    Row { spacing: 4; FKbd { text: "Del" } FText { text: "xóa"; px: 12; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter } }
                }
                FText { anchors.right: parent.right; anchors.rightMargin: 4; y: 4 + 9; text: "cliphist · " + win.total + " mục"; px: 12; color: Fz.sub }
            }
        }
    }
}
