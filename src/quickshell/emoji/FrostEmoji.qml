import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"
import "../frost"

// Emoji and character picker of the Frost design (EmojiPicker.dc.html). Opens next to the pointer
// (Super + .); Enter copies the pick and types it into the focused app when wtype is installed.
PanelWindow {
    id: win
    property bool open: false
    SurfaceGuard { name: "emoji"; shown: win.open; onCloseRequested: win.open = false }
    visible: open
    WlrLayershell.namespace: "qs-emoji"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    property int tab: 0                    // emoji, symbols, kaomoji
    property int sel: 0
    property string query: ""
    property var emoji: []
    property var recent: []
    property point at: Qt.point(860, 210)

    readonly property var symbols: [["→",Fz.tr("mũi tên phải")],["←",Fz.tr("mũi tên trái")],["↑",Fz.tr("mũi tên lên")],["↓",Fz.tr("mũi tên xuống")],["⇄",Fz.tr("đổi chiều")],["•",Fz.tr("chấm tròn")],["…",Fz.tr("dấu ba chấm")],["—",Fz.tr("gạch dài")],["°",Fz.tr("độ")],["±",Fz.tr("cộng trừ")],
        [Fz.tr("×"),Fz.tr("nhân")],[Fz.tr("÷"),"chia"],["≈",Fz.tr("xấp xỉ")],["≠",Fz.tr("khác")],["≤",Fz.tr("nhỏ hơn bằng")],["≥",Fz.tr("lớn hơn bằng")],["∞",Fz.tr("vô cực")],["√",Fz.tr("căn")],[Fz.tr("π"),"pi"],[Fz.tr("Σ"),Fz.tr("tổng")],
        ["₫",Fz.tr("đồng")],["€","euro"],["$",Fz.tr("đô la")],["©",Fz.tr("bản quyền")],["®",Fz.tr("đăng ký")],["™",Fz.tr("nhãn hiệu")],["§",Fz.tr("mục")],["¶",Fz.tr("đoạn")],["✓",Fz.tr("tích")],["★","sao"],
        ["⌘","command"],["⌥","option"],["⇧","shift"],["⌃","control"],["⏎","enter"],["⌫",Fz.tr("xóa lùi")],["⎋","escape"],["⇥","tab"],["␣",Fz.tr("dấu cách")],["⌨",Fz.tr("bàn phím")],
        ["←→",Fz.tr("hai chiều")],["⟶",Fz.tr("mũi tên dài")],["½",Fz.tr("một nửa")],["¼",Fz.tr("một phần tư")],["²",Fz.tr("bình phương")],["³",Fz.tr("lập phương")],["µ","micro"],[Fz.tr("Ω"),Fz.tr("ôm")],[Fz.tr("Δ"),"delta"],[Fz.tr("λ"),"lambda"]]
    readonly property var kaomoji: [["(＾▽＾)","vui"],["(╯°□°)╯︵ ┻━┻",Fz.tr("lật bàn")],["¯\\_(ツ)_/¯",Fz.tr("nhún vai")],[Fz.tr("(｡•́︿•̀｡)"),Fz.tr("buồn")],[Fz.tr("ʕ•ᴥ•ʔ"),Fz.tr("gấu")],[Fz.tr("(=^･ω･^=)"),Fz.tr("mèo")],
        [Fz.tr("(ง •̀_•́)ง"),Fz.tr("quyết tâm")],[Fz.tr("(っ˘ω˘ς )"),Fz.tr("ôm")],["(≧◡≦)",Fz.tr("hạnh phúc")],["(¬‿¬)",Fz.tr("tinh quái")],["(⌐■_■)",Fz.tr("ngầu")],[Fz.tr("(ಥ﹏ಥ)"),Fz.tr("khóc")]]

    readonly property var list: {
        let q = query.trim().toLowerCase();
        if (tab === 0) {
            let base = emoji.map(x => [x.e, x.vi || x.n, x.n]);
            if (!q) {
                let rec = recent.map(e => base.find(b => b[0] === e)).filter(x => x);
                return rec.concat(base.filter(b => recent.indexOf(b[0]) === -1)).slice(0, 400);
            }
            return base.filter(b => b[1].toLowerCase().indexOf(q) !== -1 || b[2].toLowerCase().indexOf(q) !== -1).slice(0, 200);
        }
        let src = tab === 1 ? symbols : kaomoji;
        return src.map(x => [x[0], x[1], x[1]]).filter(x => !q || x[1].indexOf(q) !== -1);
    }
    onListChanged: sel = 0
    readonly property var cur: list[sel] || null

    FileView {
        path: Caching.zoneCDir ? Caching.zoneCDir + "/assets/emoji.json" : ""
        onLoaded: { try { win.emoji = JSON.parse(text()); } catch (e) {} }
    }
    readonly property string recentFile: Caching.cacheDir ? Caching.cacheDir + "/emoji_recent.json" : ""
    FileView { path: win.recentFile; onLoaded: { try { win.recent = JSON.parse(text()); } catch (e) {} } }

    function show() {
        query = ""; field.text = ""; sel = 0;
        cursor.running = true;
        open = true;
        focusTimer.restart();
    }
    Timer { id: focusTimer; interval: 40; onTriggered: field.forceActiveFocus() }
    Process {
        id: cursor
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector { onStreamFinished: { try { let p = JSON.parse(this.text); win.at = Qt.point(p.x + 16, p.y + 16); } catch (e) {} } }
    }
    Connections { target: Fz; function onOpenRequest(name, arg) { if (name === "emoji") win.open ? (win.open = false) : win.show(); } }
    IpcHandler { target: "emoji"; function toggle(): void { win.open ? (win.open = false) : win.show(); } }

    // "U+1F600": walk code points (the QML engine's Array.from splits surrogate pairs)
    function codes(s) {
        let out = [];
        for (let i = 0; i < s.length && out.length < 3;) {
            let cp = s.codePointAt(i);
            out.push("U+" + cp.toString(16).toUpperCase());
            i += cp > 0xffff ? 2 : 1;
        }
        return out.join(" ");
    }
    function insert(item) {
        if (!item) return;
        if (tab === 0) {
            let r = [item[0]].concat(recent.filter(x => x !== item[0])).slice(0, 24);
            recent = r;
            Quickshell.execDetached(["bash", "-c", "printf '%s' \"$2\" > \"$1\"", "_", recentFile, JSON.stringify(r)]);
        }
        open = false;
        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | wl-copy; command -v wtype >/dev/null && { sleep 0.15; wtype -- \"$1\"; }", "_", item[0]]);
    }

    MouseArea { anchors.fill: parent; onClicked: win.open = false }

    Glass {
        id: box
        x: Math.max(8, Math.min(win.at.x, win.width - width - 8))
        y: Math.max(58, Math.min(win.at.y, win.height - height - 8))
        width: 420
        height: col.implicitHeight + 28
        MouseArea { anchors.fill: parent }

        Column {
            id: col
            x: 14; y: 14
            width: parent.width - 28
            spacing: 10

            Rectangle {
                width: parent.width; height: 42; radius: 13
                color: Fz.well(0.28); border.width: 1; border.color: Fz.line2
                Row {
                    x: 12; anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    FIcon { name: "e-search"; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
                    Item {
                        width: col.width - 24 - 17 - 20 - k.width; height: 22; anchors.verticalCenter: parent.verticalCenter
                        TextInput {
                            id: field; anchors.fill: parent; verticalAlignment: TextInput.AlignVCenter
                            color: Fz.tx; font.family: Fz.font; font.pointSize: 14 * 0.75; clip: true
                            onTextChanged: win.query = text
                            Keys.onPressed: (e) => {
                                let cols = win.tab === 2 ? 2 : 8;
                                if (e.key === Qt.Key_Escape) { win.open = false; e.accepted = true; }
                                else if (e.key === Qt.Key_Right) { win.sel = Math.min(win.sel + 1, win.list.length - 1); e.accepted = true; }
                                else if (e.key === Qt.Key_Left) { win.sel = Math.max(0, win.sel - 1); e.accepted = true; }
                                else if (e.key === Qt.Key_Down) { win.sel = Math.min(win.sel + cols, win.list.length - 1); e.accepted = true; }
                                else if (e.key === Qt.Key_Up) { win.sel = Math.max(0, win.sel - cols); e.accepted = true; }
                                else if (e.key === Qt.Key_Tab) { win.tab = (win.tab + 1) % 3; e.accepted = true; }
                                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { win.insert(win.cur); e.accepted = true; }
                            }
                        }
                        FText { anchors.verticalCenter: parent.verticalCenter; visible: field.text === ""; text: Fz.tr("Tìm: tim, cười, lửa, mũi tên…"); color: Fz.dim; px: 14 }
                    }
                    FKbd { id: k; text: "Super ."; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            FSeg {
                width: parent.width
                btnWidth: (parent.width - 6 - 4) / 3
                options: ["Emoji", Fz.tr("Ký tự"), "Kaomoji"]
                current: win.tab
                onPicked: (i) => { win.tab = i; field.forceActiveFocus(); }
            }

            Caps {
                px: 10.5; leftPadding: 4; topPadding: 2
                text: win.query.trim() ? Fz.tr("Kết quả cho “") + win.query.trim() + "”" : (win.tab === 0 ? (win.recent.length ? Fz.tr("Dùng gần đây · Phổ biến") : Fz.tr("Phổ biến")) : (win.tab === 1 ? Fz.tr("Mũi tên · Toán · Tiền tệ · Phím") : "Kaomoji"))
            }

            GridView {
                id: grid
                width: parent.width
                height: Math.min(300, Math.ceil(win.list.length / (win.tab === 2 ? 2 : 8)) * cellHeight)
                clip: true
                cellWidth: width / (win.tab === 2 ? 2 : 8)
                cellHeight: win.tab === 2 ? 46 : 50
                model: win.list
                currentIndex: win.sel
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
                boundsBehavior: Flickable.StopAtBounds
                delegate: Item {
                    required property var modelData
                    required property int index
                    width: grid.cellWidth; height: grid.cellHeight
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 2; radius: 12
                        color: index === win.sel ? Fz.acc : (emMouse.containsMouse ? Fz.fg(0.08) : "transparent")
                        Text {
                            anchors.centerIn: parent
                            text: modelData[0]
                            font.family: win.tab === 0 ? "Noto Color Emoji" : Fz.font
                            font.pointSize: (win.tab === 0 ? 24 : (win.tab === 1 ? 20 : 13)) * 0.75
                            color: index === win.sel ? Fz.ink : Fz.tx
                        }
                    }
                    MouseArea { id: emMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onEntered: win.sel = index; onClicked: win.insert(modelData) }
                }
            }
            FText { visible: win.list.length === 0; width: parent.width; topPadding: 30; bottomPadding: 30; horizontalAlignment: Text.AlignHCenter; text: Fz.tr("Không tìm thấy."); color: Fz.sub; px: 13 }

            Item {
                width: parent.width; height: 52
                Rectangle { width: parent.width; height: 1; color: Fz.line }
                Row {
                    x: 6; y: 10
                    spacing: 12
                    Text { width: 40; horizontalAlignment: Text.AlignHCenter; text: win.cur ? win.cur[0] : ""; font.family: "Noto Color Emoji"; font.pointSize: (win.tab === 2 ? 14 : 30) * 0.75; color: Fz.tx; anchors.verticalCenter: parent.verticalCenter }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: col.width - 12 - 40 - 24 - hint.width
                        FText { width: parent.width; elide: Text.ElideRight; text: win.cur ? win.cur[1].charAt(0).toUpperCase() + win.cur[1].slice(1) : ""; px: 13.5; weight: Font.DemiBold }
                        FText { mono: true; px: 11.5; color: Fz.sub; text: win.cur ? win.codes(win.cur[0]) : "" }
                    }
                }
                Row { id: hint; anchors.right: parent.right; anchors.rightMargin: 6; y: 20; spacing: 4
                      FKbd { text: "Enter" } FText { text: Fz.tr("chèn"); px: 12; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter } }
            }
        }
    }
}
