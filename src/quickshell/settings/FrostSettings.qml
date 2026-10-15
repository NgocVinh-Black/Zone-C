import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../frost"

// Settings window of the Frost design (SettingsWindow.dc.html): 27 pages in four groups with a search
// field, each page loaded from pages/<Name>.qml. Replaces the old guide popup ("guide" opens it too).
Scope {
    id: app
    property bool open: false
    property string page: "theme"
    property int updates: 0

    readonly property var groups: [
        ["Zone-C", [["theme", "Theme & giao diện"], ["bar", "Thanh bar"], ["launcher", "Launcher"], ["widgets", "Widget"], ["notif", "Thông báo"], ["osd", "OSD"], ["idle", "Chờ & khóa"], ["wellbeing", "Sức khỏe số"]]],
        ["Kết nối", [["wifi", "Wi-Fi"], ["bt", "Bluetooth"], ["net", "Mạng & VPN"]]],
        ["Thiết bị", [["display", "Màn hình"], ["sound", "Âm thanh"], ["power", "Pin & nguồn"], ["keyboard", "Bàn phím"], ["mouse", "Chuột & touchpad"]]],
        ["Hệ thống", [["general", "Chung"], ["access", "Trợ năng"], ["apps", "Ứng dụng"], ["printers", "Máy in"], ["storage", "Lưu trữ"], ["users", "Người dùng"], ["privacy", "Quyền riêng tư"], ["datetime", "Ngày & giờ"], ["language", "Ngôn ngữ & vùng"], ["updates", "Cập nhật"], ["about", "Giới thiệu"]]]
    ]
    readonly property var files: ({ theme: "Theme", bar: "Bar", launcher: "Launcher", widgets: "Widgets", notif: "Notifications", osd: "Osd", idle: "Idle", wellbeing: "Wellbeing",
        wifi: "Wifi", bt: "Bluetooth", net: "Network", display: "Display", sound: "Sound", power: "Power", keyboard: "Keyboard", mouse: "Mouse",
        general: "General", access: "Access", apps: "Apps", printers: "Printers", storage: "Storage", users: "Users", privacy: "Privacy",
        datetime: "DateTime", language: "Language", updates: "Updates", about: "About" })
    // tab names of the old guide popup
    readonly property var aliases: ({ notifications: "notif", bar_general: "bar", bar_modules: "bar", display_main: "display", display_widgets: "widgets", welcome: "theme", network: "wifi", bluetooth: "bt", digitalwellbeing: "wellbeing" })
    function title(k) { for (const g of groups) for (const i of g[1]) if (i[0] === k) return i[1]; return ""; }

    function show(p) {
        let k = aliases[p] || p;
        if (files[k]) page = k;
        open = true;
    }
    Connections {
        target: Fz
        function onOpenRequest(name, arg) {
            if (name !== "settings") return;
            if (app.open && !arg) app.open = false; else app.show(arg);
        }
    }
    IpcHandler {
        target: "settings"
        function toggle(): void { app.open ? (app.open = false) : app.show(""); }
        function open(page: string): void { app.show(page); }
    }

    // pending package updates for the sidebar badge
    Process {
        id: upd
        running: app.open
        command: ["python3", Quickshell.shellDir + "/apps/pkg.py", "updates"]
        stdout: StdioCollector { onStreamFinished: { try { let d = JSON.parse(this.text); app.updates = (d.data || []).length; app.updatesList = d.data || []; } catch (e) {} } }
    }
    property var updatesList: []
    function recheckUpdates() { upd.running = false; upd.running = true; }

    LazyLoader {
        active: app.open
        FloatingWindow {
            id: win
            title: "Zone-C · Cài đặt"
            implicitWidth: 1200
            implicitHeight: 780
            minimumSize: Qt.size(900, 560)
            color: Fz.mantle
            visible: true
            onVisibleChanged: if (!visible) app.open = false
            property string q: ""

            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: (e) => {
                    if ((e.modifiers & Qt.ControlModifier) && e.key === Qt.Key_F) { search.input.forceActiveFocus(); e.accepted = true; }
                    else if ((e.modifiers & Qt.ControlModifier) && e.key === Qt.Key_W) { app.open = false; e.accepted = true; }
                }
            }

            // ---------------- sidebar ----------------
            Rectangle {
                id: nav
                width: 260; height: parent.height
                color: Fz.crust
                Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Fz.line }
                Row {
                    x: 12; y: 16
                    spacing: 10
                    Rectangle {
                        width: 36; height: 36; radius: 11
                        gradient: Gradient { orientation: Gradient.Vertical; GradientStop { position: 0; color: Fz.s0 } GradientStop { position: 1; color: Fz.ink } }
                        border.width: 1; border.color: Fz.fg(0.1)
                        FIcon { anchors.centerIn: parent; name: "s-zc"; size: 24; color: Fz.acc }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        FText { text: "Cài đặt"; px: 14; weight: Font.DemiBold }
                        FText { text: "Zone-C · " + (ZoneStyle.preset || "Zone Frost").replace(/^Zone /, "") + (ZoneStyle.hasModes ? (ZoneStyle.isLight ? " Light" : " Dark") : ""); px: 11.5; color: Fz.sub }
                    }
                }
                FInput {
                    id: search
                    x: 12; y: 16 + 36 + 4 + 10
                    width: parent.width - 24; height: 36; radius: 11; fontSize: 13.5; icon: "s-search"
                    placeholder: "Tìm cài đặt"
                    onTextChanged: win.q = text
                    Keys.onEscapePressed: text = ""
                    Keys.onReturnPressed: { let f = navList.firstMatch(); if (f) app.page = f; }
                }
                Flickable {
                    id: navFlick
                    x: 10; y: search.y + search.height + 2
                    width: parent.width - 20; height: parent.height - y - 14
                    clip: true
                    contentHeight: navList.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    Column {
                        id: navList
                        width: parent.width
                        function firstMatch() {
                            let ql = win.q.trim().toLowerCase();
                            for (const g of app.groups) for (const i of g[1]) if (!ql || i[1].toLowerCase().indexOf(ql) !== -1) return i[0];
                            return "";
                        }
                        Repeater {
                            model: app.groups.map(g => [g[0], g[1].filter(i => !win.q.trim() || i[1].toLowerCase().indexOf(win.q.trim().toLowerCase()) !== -1)]).filter(g => g[1].length > 0)
                            delegate: Column {
                                required property var modelData
                                width: navList.width
                                spacing: 1
                                FText {
                                    leftPadding: 10; topPadding: 14; bottomPadding: 5
                                    text: modelData[0]; px: 10.5; weight: Font.DemiBold; color: Fz.dim
                                    font.letterSpacing: 10.5 * 0.09; font.capitalization: Font.AllUppercase
                                }
                                Repeater {
                                    model: modelData[1]
                                    delegate: Rectangle {
                                        id: nv
                                        required property var modelData
                                        readonly property bool on: app.page === modelData[0]
                                        readonly property string badge: modelData[0] === "updates" && app.updates > 0 ? String(app.updates) : ""
                                        width: navList.width; height: 32; radius: 10
                                        color: on ? Fz.acc : (nvMouse.containsMouse ? Fz.fg(0.06) : "transparent")
                                        Row {
                                            x: 10; anchors.verticalCenter: parent.verticalCenter
                                            spacing: 10
                                            FIcon { name: "s-" + nv.modelData[0]; size: 16; color: nv.on ? Fz.ink : (nvMouse.containsMouse ? Fz.tx : Fz.sub2); anchors.verticalCenter: parent.verticalCenter }
                                            FText { text: nv.modelData[1]; px: 13.5; weight: nv.on ? Font.Medium : Font.Normal; color: nv.on ? Fz.ink : (nvMouse.containsMouse ? Fz.tx : Fz.sub2); anchors.verticalCenter: parent.verticalCenter }
                                        }
                                        Rectangle {
                                            visible: nv.badge !== ""
                                            anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                                            width: bt.implicitWidth + 14; height: 18; radius: 9
                                            color: nv.on ? Fz.ink : Fz.acc
                                            FText { id: bt; anchors.centerIn: parent; text: nv.badge; px: 11; weight: Font.DemiBold; color: nv.on ? Fz.acc : Fz.ink }
                                        }
                                        MouseArea { id: nvMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: app.page = nv.modelData[0] }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---------------- header ----------------
            Item {
                id: head
                x: nav.width; width: parent.width - nav.width; height: 60
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Fz.line }
                FText { x: 32; anchors.verticalCenter: parent.verticalCenter; text: app.title(app.page); px: 20; weight: Font.DemiBold; font.letterSpacing: -0.2 }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    FIconBtn { width: 30; height: 30; ghost: true; icon: "s-min"; iconSize: 14; label: "Thu nhỏ"
                               onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.move({ workspace = 'special:minimized', follow = false })"]) }
                    FIconBtn { width: 30; height: 30; ghost: true; icon: "s-max"; iconSize: 13; label: "Phóng to"
                               onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.fullscreen({ mode = 'maximized' })"]) }
                    FIconBtn { width: 30; height: 30; ghost: true; icon: "s-x"; iconSize: 14; label: "Đóng"; onClicked: app.open = false }
                }
            }

            // file chooser for pages (avatar, VPN config…)
            FFilePicker { id: picker; z: 50; subtitle: "Cài đặt" }

            // ---------------- page ----------------
            Flickable {
                id: body
                x: nav.width; y: 60
                width: parent.width - nav.width; height: parent.height - 60
                clip: true
                contentHeight: pageLoader.height + 24 + 36
                boundsBehavior: Flickable.StopAtBounds
                Loader {
                    id: pageLoader
                    x: 32; y: 24
                    width: body.width - 64
                    source: Qt.resolvedUrl("pages/" + app.files[app.page] + ".qml")
                    onSourceChanged: body.contentY = 0
                    onLoaded: { if (item && item.hasOwnProperty("app")) item.app = app; if (item && item.hasOwnProperty("picker")) item.picker = picker; }
                }
            }
        }
    }
}
