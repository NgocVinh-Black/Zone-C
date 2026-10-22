import QtQuick
import QtQuick.Window
import QtQuick.Effects

// Zone Frost login screen — the "login" mode of Lock.dc.html: date, 200px clock, avatar with a glow
// ring, user chips, a glass password pill, session picker and sleep / restart / power-off.
// The wallpaper comes from current/theme.conf (written by the shell's scripts/sddm_sync.sh).
Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#151c20"

    // ---------- Frost dark tokens (zone.css) ----------
    readonly property color tx: "#edf3f6"
    readonly property color sub: "#a7b8c1"
    readonly property color sub2: "#c6d3d9"
    readonly property color acc: "#d6e6ec"
    readonly property color ink: "#162025"
    readonly property color glow: "#9fd3e0"
    readonly property color red: "#ff7b7b"
    readonly property color s0: "#34424a"
    readonly property color base: "#2a353b"
    function fg(a) { return Qt.rgba(237 / 255, 243 / 255, 246 / 255, a); }
    readonly property color glass: Qt.rgba(28 / 255, 36 / 255, 40 / 255, 0.74)
    readonly property string font: geist.status === FontLoader.Ready ? geist.name : "sans-serif"
    readonly property string mono: geistMono.status === FontLoader.Ready ? geistMono.name : "monospace"
    FontLoader { id: geist; source: "font/Geist-Variable.ttf" }
    FontLoader { id: geistMono; source: "font/GeistMono-Variable.ttf" }

    readonly property var live: (typeof config !== "undefined" && config) ? config : ({})
    function pick(key, fallback) { let v = live[key]; return v !== undefined && v !== null && String(v) !== "" ? String(v) : fallback; }

    readonly property bool preview: typeof sddm === "undefined"
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property string error: ""
    property var now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    // UI language of the shell (current/theme.conf lang=vi|en, synced by scripts/sddm_sync.sh), as on the lock screen
    readonly property bool en: pick("lang", "vi") !== "vi"
    readonly property var weekdays: en ? ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                                       : ["Chủ Nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy"]
    readonly property var months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    function dateLine(d) { return en ? weekdays[d.getDay()] + " · " + months[d.getMonth()] + " " + d.getDate() : weekdays[d.getDay()] + " · " + d.getDate() + " tháng " + (d.getMonth() + 1); }

    // models read through hidden views (SDDM models are not JS arrays)
    ListView { id: users; model: typeof userModel !== "undefined" ? userModel : null; visible: false; width: 1; height: 1
               delegate: Item { property string login: model.name || ""; property string real: model.realName || model.name || ""; property string icon: model.icon || "" } }
    ListView { id: sessions; model: typeof sessionModel !== "undefined" ? sessionModel : null; visible: false; width: 1; height: 1
               delegate: Item { property string sname: model.name || "" } }
    function userAt(i) { let it = users.itemAtIndex(i); return it ? it : null; }
    readonly property int userCount: users.count
    readonly property var cur: { let _ = root.userIndex + users.count; return userAt(userIndex); }
    readonly property string curName: cur ? cur.real : (typeof userModel !== "undefined" ? userModel.lastUser : "zone-c")
    readonly property string curLogin: cur ? cur.login : (typeof userModel !== "undefined" ? userModel.lastUser : "")
    function sessionName(i) { let it = sessions.itemAtIndex(i); return it ? it.sname : "Hyprland"; }

    function login() {
        if (preview) return;
        error = "";
        sddm.login(curLogin, pw.text, sessionIndex);
    }
    Connections {
        target: root.preview ? null : sddm
        function onLoginFailed() { root.error = root.en ? "Wrong password, try again" : "Sai mật khẩu, thử lại"; pw.text = ""; shake.restart(); pw.forceActiveFocus(); }
    }
    Component.onCompleted: { if (typeof keyboard !== "undefined") keyboard.numLock = true; pw.forceActiveFocus(); }

    // ---------- wallpaper + `.scrim.deep` ----------
    Image {
        anchors.fill: parent
        source: root.pick("background", "") !== "" ? Qt.resolvedUrl("current/" + root.pick("background", "")) : "bg.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(14 / 255, 20 / 255, 24 / 255, 0.62) }

    // ---------- top right: keyboard, host ----------
    Row {
        anchors.top: parent.top; anchors.right: parent.right; anchors.topMargin: 20; anchors.rightMargin: 24
        spacing: 8
        // same chip as the lock screen: the input language, not the XKB layout name
        Pill {
            bold: true
            label: {
                let s = typeof keyboard !== "undefined" && keyboard.layouts.length ? String(keyboard.layouts[keyboard.currentLayout].shortName).toLowerCase() : "us";
                return s === "us" || s === "gb" ? "EN" : s === "vn" ? "VI" : s.toUpperCase();
            }
        }
    }

    // ---------- clock ----------
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 110 * root.height / 900
        spacing: 6
        T { anchors.horizontalCenter: parent.horizontalCenter; text: root.dateLine(root.now).toUpperCase()
            px: 16; weight: 600; color: root.sub2; font.letterSpacing: 16 * 0.2 }
        T { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(root.now, "HH:mm"); px: 200; weight: 200; font.letterSpacing: -10; lineHeight: 0.95 }
    }

    // ---------- user, password, session ----------
    Column {
        id: form
        anchors.horizontalCenter: parent.horizontalCenter
        y: 520 * root.height / 900 - 60
        spacing: 14
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 88; height: 88
            Rectangle { anchors.fill: parent; anchors.margins: -3; radius: 47; color: root.acc
                        layer.enabled: true; layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Qt.rgba(159 / 255, 211 / 255, 224 / 255, 0.4); shadowBlur: 1; blurMax: 30 } }
            Rectangle {
                id: avatarClip
                anchors.fill: parent; radius: 44; color: root.s0
                T { anchors.centerIn: parent; visible: avatar.status !== Image.Ready; text: root.curName.charAt(0).toUpperCase(); px: 34; weight: 700; color: root.acc }
                Image {
                    id: avatar
                    anchors.fill: parent; fillMode: Image.PreserveAspectCrop
                    // SDDM's own face icon when it has one, else the avatar the shell synced (~/.face is not readable here)
                    source: root.pick("avatar", "") !== "" ? Qt.resolvedUrl("current/" + root.pick("avatar", "")) : (root.cur && root.cur.icon ? root.cur.icon : "")
                    visible: false
                }
                MultiEffect { anchors.fill: parent; source: avatar; visible: avatar.status === Image.Ready; maskEnabled: true; maskSource: mask }
                Item { id: mask; anchors.fill: parent; layer.enabled: true; visible: false; Rectangle { anchors.fill: parent; radius: 44 } }
            }
        }
        T { anchors.horizontalCenter: parent.horizontalCenter; text: root.curName; px: 20; weight: 600 }
        Row {
            visible: root.userCount > 1
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            Repeater {
                model: root.userCount
                delegate: Rectangle {
                    required property int index
                    readonly property var u: root.userAt(index)
                    readonly property bool on: index === root.userIndex
                    height: 36; radius: 18
                    width: chipRow.implicitWidth + 24
                    color: on ? root.acc : root.fg(chipMouse.containsMouse ? 0.12 : 0.06)
                    border.width: on ? 0 : 1; border.color: root.fg(0.14)
                    Row {
                        id: chipRow
                        anchors.centerIn: parent; spacing: 7
                        Rectangle { width: 22; height: 22; radius: 11; color: on ? root.ink : root.s0; anchors.verticalCenter: parent.verticalCenter
                                    T { anchors.centerIn: parent; text: u ? u.real.charAt(0).toUpperCase() : ""; px: 11; weight: 700; color: root.acc } }
                        T { text: u ? u.real : ""; px: 13; weight: 500; color: on ? root.ink : root.tx; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: chipMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.userIndex = index; pw.forceActiveFocus(); } }
                }
            }
        }
        // `.glass` password pill
        Rectangle {
            id: pill
            anchors.horizontalCenter: parent.horizontalCenter
            width: 360; height: 54; radius: 27
            color: root.glass
            border.width: 1; border.color: root.error ? Qt.rgba(1, 123 / 255, 123 / 255, 0.6) : root.fg(0.08)
            SequentialAnimation on anchors.horizontalCenterOffset {
                id: shake; running: false
                NumberAnimation { to: -10; duration: 50 } NumberAnimation { to: 10; duration: 70 } NumberAnimation { to: -6; duration: 60 } NumberAnimation { to: 0; duration: 50 }
            }
            TextInput {
                id: pw
                x: 20; anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 20 - 7 - 40 - 6 - 36 - 6
                color: root.tx; font.family: root.font; font.pointSize: 15 * 0.75
                echoMode: showPw.on ? TextInput.Normal : TextInput.Password
                passwordCharacter: "•"
                clip: true; focus: true
                onAccepted: root.login()
                Keys.onEscapePressed: text = ""
                T { anchors.verticalCenter: parent.verticalCenter; visible: pw.text === ""; text: root.error || (root.en ? "Enter password" : "Nhập mật khẩu"); px: 15; color: root.error ? root.red : Qt.rgba(125 / 255, 144 / 255, 154 / 255, 1) }
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 7; anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Ib { id: showPw; property bool on: false; ghost: true; glyph: "eye"; onClicked: on = !on }
                Ib { width: 40; height: 40; radius: 20; primary: true; glyph: "arrow"; onClicked: root.login() }
            }
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            Rectangle {
                width: 220; height: 36; radius: 18
                color: root.base; border.width: 1; border.color: root.fg(0.14)
                T { x: 14; anchors.verticalCenter: parent.verticalCenter; text: root.sessionName(root.sessionIndex) + " · Zone-C"; px: 13.5 }
                T { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: "⌄"; px: 14; color: root.sub }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (sessions.count > 0) root.sessionIndex = (root.sessionIndex + 1) % sessions.count }
            }
        }
    }

    // ---------- power ----------
    Row {
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 28
        spacing: 8
        Ib { width: 44; height: 44; radius: 22; glyph: "moon"; visible: root.preview || sddm.canSuspend; onClicked: if (!root.preview) sddm.suspend() }
        Ib { width: 44; height: 44; radius: 22; glyph: "restart"; visible: root.preview || sddm.canReboot; onClicked: if (!root.preview) sddm.reboot() }
        Ib { width: 44; height: 44; radius: 22; glyph: "off"; danger: true; visible: root.preview || sddm.canPowerOff; onClicked: if (!root.preview) sddm.powerOff() }
    }

    // ---------- pieces ----------
    component T: Text {
        property real px: 14
        property int weight: 400
        color: root.tx
        font.family: root.font
        font.pointSize: px * 0.75
        font.weight: weight
        font.variableAxes: ({ "wght": weight })
        renderType: Text.NativeRendering
    }
    component Pill: Rectangle {
        property string label
        property bool bold: false
        height: 34; radius: 17; width: pillText.implicitWidth + 28
        color: root.glass; border.width: 1; border.color: root.fg(0.09)
        T { id: pillText; anchors.centerIn: parent; text: parent.label; px: 13; weight: parent.bold ? 600 : 500; color: root.sub2 }
    }
    // `.ib` with a tiny vector glyph
    component Ib: Rectangle {
        id: ib
        property string glyph
        property bool ghost: false
        property bool primary: false
        property bool danger: false
        signal clicked()
        width: 36; height: 36; radius: 11
        color: primary ? root.acc : ghost ? (ibMouse.containsMouse ? root.fg(0.1) : "transparent") : root.fg(ibMouse.containsMouse ? 0.14 : 0.06)
        Canvas {
            anchors.centerIn: parent; width: 18; height: 18
            property color c: ib.primary ? root.ink : ib.danger ? root.red : root.tx
            onCChanged: requestPaint()
            onPaint: {
                let x = getContext("2d"); x.reset(); x.strokeStyle = c; x.lineWidth = 1.6; x.lineCap = "round"; x.lineJoin = "round";
                x.scale(18 / 24, 18 / 24); x.beginPath();
                if (ib.glyph === "arrow") { x.moveTo(5, 12); x.lineTo(19, 12); x.moveTo(13, 6); x.lineTo(19, 12); x.lineTo(13, 18); }
                else if (ib.glyph === "eye") { x.moveTo(2, 12); x.quadraticCurveTo(12, 2, 22, 12); x.quadraticCurveTo(12, 22, 2, 12); x.moveTo(15, 12); x.arc(12, 12, 3, 0, Math.PI * 2); }
                else if (ib.glyph === "moon") { x.arc(12, 12, 8, -0.5, Math.PI * 1.55); x.quadraticCurveTo(10, 11, 18, 7.5); }
                else if (ib.glyph === "restart") { x.arc(12, 12, 8, -Math.PI * 0.9, Math.PI * 0.75); x.moveTo(3, 4); x.lineTo(4.1, 9); x.lineTo(9, 8); }
                else if (ib.glyph === "off") { x.moveTo(12, 3); x.lineTo(12, 11); x.moveTo(7, 6.5); x.arc(12, 13, 7.5, -Math.PI * 0.72, Math.PI * 1.72); }
                x.stroke();
            }
        }
        MouseArea { id: ibMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ib.clicked() }
    }
}
