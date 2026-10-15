import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Networking
import "../"
import "../frost"

// Lock screen of the Frost design (Lock.dc.html). Lock.qml keeps the session lock and PAM;
// this surface only draws and forwards the password.
FocusScope {
    id: root
    property var lockRoot          // Lock.qml root: finishUnlock(), completeUnlock(), switchKbLayout(), kbLayout, isUnlocking
    property var pam
    property var lockUI
    property var screen
    property var powerActions      // { sleep(), reboot(), poweroff() }
    focus: true

    readonly property bool unlocking: lockRoot ? lockRoot.isUnlocking : false
    onUnlockingChanged: if (unlocking) fadeOut.start()
    NumberAnimation { id: fadeOut; target: root; property: "opacity"; to: 0; duration: 260; easing.type: Easing.InQuad; onFinished: root.lockRoot.completeUnlock() }
    Component.onCompleted: { opacity = 1; field.forceActiveFocus(); }

    function submit() {
        let t = field.text;
        if (t.length > 0 && pam.responseRequired && !lockUI.authenticating) {
            lockUI.authenticating = true;
            lockUI.failed = false;
            pam.respond(t);
        }
    }
    Connections {
        target: root.lockUI ?? null
        ignoreUnknownSignals: true
        function onFailedChanged() { if (root.lockUI.failed) { field.text = ""; shake.restart(); } }
    }

    // ---------- data ----------
    readonly property string screenName: screen && screen.name ? screen.name : ""
    readonly property string wall: {
        let p = Wallpaper.getWallpaperPath(screenName) || Wallpaper.getWallpaperPath("");
        if (p && !ZoneStyle.isVideo(p)) return "file://" + p;
        let c = Caching.getCacheDir("wallpaper");
        return "file://" + c + (screenName ? "/current_wallpaper_" + screenName + ".png" : "/current_wallpaper.png");
    }
    readonly property string ssid: {
        let ds = Networking.devices ? (Networking.devices.values || []) : [];
        for (const d of ds) if (d && d.type === DeviceType.Wifi && d.networks) for (const n of (d.networks.values || [])) if (n.connected) return n.name;
        return "";
    }
    readonly property var bat: UPower.displayDevice
    readonly property bool hasBat: bat.ready && bat.isLaptopBattery
    readonly property var player: MprisController.activePlayer
    readonly property bool hasMedia: player !== null && MprisController.trackTitle !== ""
    readonly property int notifCount: NotificationManager.globalNotificationHistory ? NotificationManager.globalNotificationHistory.count : 0
    readonly property string city: (Weather.activeLocation && Weather.activeLocation.city) ? Weather.activeLocation.city : ""
    readonly property string avatar: SystemInfo.avatarPath ? (SystemInfo.avatarPath.startsWith("file://") ? SystemInfo.avatarPath : "file://" + SystemInfo.avatarPath) : ""
    property bool hasFingerprint: false
    property bool showPw: false
    Process { running: true; command: ["bash", "-c", "command -v fprintd-list >/dev/null && fprintd-list \"$USER\" 2>/dev/null | grep -q 'finger' && echo yes"]
              stdout: StdioCollector { onStreamFinished: root.hasFingerprint = this.text.trim() === "yes" } }
    function fmt(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0"); }

    // ---------- backdrop ----------
    Rectangle { anchors.fill: parent; color: Fz.bg0 }
    Image { anchors.fill: parent; source: root.wall; fillMode: Image.PreserveAspectCrop; asynchronous: true; verticalAlignment: Image.AlignVCenter }
    Rectangle { anchors.fill: parent; color: Fz.scrimDeep }

    // ---------- status pills ----------
    Row {
        anchors.right: parent.right; anchors.rightMargin: 24
        y: 20
        spacing: 8
        Pill { onClicked: root.lockRoot.switchKbLayout()
               FText { text: root.lockRoot ? root.lockRoot.kbLayout : "VI"; px: 13; weight: Font.DemiBold } }
        Pill { visible: root.ssid !== ""
               FIcon { name: "k-wifi"; size: 15; anchors.verticalCenter: parent.verticalCenter }
               FText { text: root.ssid; px: 13; weight: Font.Medium } }
        Pill { visible: root.hasBat
               FIcon { name: "k-bat"; size: 18; anchors.verticalCenter: parent.verticalCenter }
               FText { mono: true; text: Math.round(root.bat.percentage * 100) + "%"; px: 12 } }
    }

    // ---------- clock ----------
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 110
        spacing: 6
        FText { anchors.horizontalCenter: parent.horizontalCenter; text: (Fz.weekdays[DateTime.now.getDay()] + " · " + Fz.dayMonth(DateTime.now)).toUpperCase()
                px: 16; weight: Font.DemiBold; font.letterSpacing: 16 * 0.2; color: Fz.sub2 }
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: clock.implicitWidth; height: 200 * 0.95
            FText { id: clock; y: -36; text: Qt.formatDateTime(DateTime.now, "HH:mm"); px: 200; weight: Font.ExtraLight; font.letterSpacing: -10 }
        }
        FText { anchors.horizontalCenter: parent.horizontalCenter; text: Fz.deg(Weather.currentTemp) + " " + Fz.weatherDesc(Weather.currentIcon) + (root.city ? " · " + root.city : ""); px: 15; color: Fz.sub2 }
    }

    // ---------- user + password ----------
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 520 * root.height / 900
        spacing: 14
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 88; height: 88
            RectangularShadow { anchors.fill: ring; radius: 47; blur: 15; color: Fz.glowA(0.4) }
            Rectangle { id: ring; anchors.fill: parent; anchors.margins: -3; radius: 47; color: Fz.acc }
            RoundImage { anchors.fill: parent; radius: 44; source: root.avatar; visible: ready }
            Rectangle { anchors.fill: parent; radius: 44; color: Fz.acc; visible: root.avatar === ""
                        FIcon { anchors.centerIn: parent; name: "zc"; size: 48; color: Fz.ink } }
        }
        FText { anchors.horizontalCenter: parent.horizontalCenter; text: SystemInfo.username; px: 20; weight: Font.DemiBold }
        Glass {
            id: pwBox
            anchors.horizontalCenter: parent.horizontalCenter
            width: 360; height: 54; radius: 27
            borderColor: root.lockUI && root.lockUI.failed ? Fz.redA(0.6) : (Fz.light ? Fz.glassEdge : Fz.line)
            SequentialAnimation on anchors.horizontalCenterOffset {
                id: shake; running: false
                NumberAnimation { to: -10; duration: 50 } NumberAnimation { to: 10; duration: 70 } NumberAnimation { to: -6; duration: 60 } NumberAnimation { to: 0; duration: 50 }
            }
            Item {
                x: 20; width: parent.width - 20 - 7 - 36 - 6 - 40 - 6; height: parent.height
                TextInput {
                    id: field
                    anchors.fill: parent
                    verticalAlignment: TextInput.AlignVCenter
                    color: Fz.tx; font.family: Fz.font; font.pointSize: 15 * 0.75
                    echoMode: root.showPw ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "•"
                    focus: true
                    clip: true
                    enabled: !root.lockUI || !root.lockUI.authenticating
                    onAccepted: root.submit()
                    Keys.onEscapePressed: text = ""
                }
                FText {
                    anchors.verticalCenter: parent.verticalCenter; visible: field.text === ""
                    text: !root.lockUI ? Fz.tr("Nhập mật khẩu") : root.lockUI.authenticating ? Fz.tr("Đang kiểm tra…") : root.lockUI.failed ? Fz.tr("Sai mật khẩu, thử lại") : Fz.tr("Nhập mật khẩu")
                    color: root.lockUI && root.lockUI.failed ? Fz.redTx : Fz.dim; px: 15
                }
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 7; anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                FIconBtn { ghost: true; icon: "k-eye"; label: Fz.tr("Hiện mật khẩu"); on: root.showPw; onClicked: root.showPw = !root.showPw; anchors.verticalCenter: parent.verticalCenter }
                FIconBtn { on: true; width: 40; height: 40; radius: 20; icon: "k-arrow"; label: Fz.tr("Mở khóa"); onClicked: root.submit(); anchors.verticalCenter: parent.verticalCenter }
            }
        }
        Row {
            visible: root.hasFingerprint
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            FIcon { name: "k-finger"; size: 15; color: Fz.sub2; anchors.verticalCenter: parent.verticalCenter }
            FText { text: Fz.tr("Hoặc chạm cảm biến vân tay"); px: 13; color: Fz.sub2 }
        }
    }

    // ---------- media + notifications ----------
    Glass {
        visible: root.hasMedia
        x: 28; y: parent.height - 28 - height
        width: 340; height: mcol.implicitHeight + 28
        Column {
            id: mcol
            x: 14; y: 14
            width: parent.width - 28
            spacing: 10
            Row {
                width: parent.width; spacing: 14
                MusicDisc { size: 56; art: { let a = MprisController.artUrl || ""; return a === "" ? "" : (a.startsWith("/") ? "file://" + a : a); } }
                Column {
                    width: parent.width - 70; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                    FText { text: ((MprisController.isPlaying ? Fz.tr("Đang phát") : Fz.tr("Tạm dừng")) + (root.player && root.player.identity ? " · " + root.player.identity : "")).toUpperCase(); px: 10.5; weight: Font.DemiBold; font.letterSpacing: 10.5 * 0.08; color: Fz.sub }
                    FText { width: parent.width; elide: Text.ElideRight; text: MprisController.trackTitle; px: 14; weight: Font.DemiBold }
                    FText { width: parent.width; elide: Text.ElideRight; text: MprisController.trackArtist; px: 12.5; color: Fz.sub }
                }
            }
            Column {
                width: parent.width; spacing: 6
                FBar { width: parent.width; value: root.player && root.player.length > 0 ? MprisController.livePosition / root.player.length : 0 }
                Item { width: parent.width; height: 14
                    FText { mono: true; text: root.fmt(MprisController.livePosition); px: 11; color: Fz.sub }
                    FText { anchors.right: parent.right; mono: true; text: root.player ? root.fmt(root.player.length) : "0:00"; px: 11; color: Fz.sub } }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 10
                FIconBtn { icon: "k-prev"; label: Fz.tr("Bài trước"); onClicked: if (root.player) root.player.previous() }
                FIconBtn { on: true; width: 56; height: 40; icon: MprisController.isPlaying ? "k-pause" : "m-play"; label: Fz.tr("Phát / tạm dừng"); onClicked: if (root.player) root.player.togglePlaying() }
                FIconBtn { icon: "k-next"; label: Fz.tr("Bài tiếp"); onClicked: if (root.player) root.player.next() }
            }
        }
    }
    Row {
        visible: root.notifCount > 0
        x: root.hasMedia ? 390 : 28
        y: parent.height - 44 - 16
        spacing: 8
        FIcon { name: "k-bell"; size: 15; color: Fz.sub2; anchors.verticalCenter: parent.verticalCenter }
        FText {
            // Settings → Quyền riêng tư "Ẩn nội dung thông báo khi khóa"
            readonly property bool hide: Config.getSetting("lock.hideNotifications", true) !== false
            readonly property var last: root.notifCount > 0 ? NotificationManager.globalNotificationHistory.get(0) : null
            text: hide || !last ? root.notifCount + Fz.tr(" thông báo · nội dung ẩn khi khóa") : root.notifCount + Fz.tr(" thông báo · ") + last.appName + ": " + last.summary
            width: Math.min(implicitWidth, 520); elide: Text.ElideRight
            px: 13; color: Fz.sub2
        }
    }

    // "Đổi người dùng" needs a display manager with a greeter switch (LightDM's Seat API; SDDM has
    // none) and a second account, otherwise the button would do nothing
    property bool canSwitchUser: false
    Process {
        running: true
        command: ["bash", "-c", "busctl --system list 2>/dev/null | grep -q org.freedesktop.DisplayManager && [ $(getent passwd | awk -F: '$3>=1000 && $3<60000' | wc -l) -gt 1 ] && echo yes"]
        stdout: StdioCollector { onStreamFinished: root.canSwitchUser = this.text.trim() === "yes" }
    }

    // ---------- session buttons ----------
    Row {
        anchors.right: parent.right; anchors.rightMargin: 28
        y: parent.height - 28 - 44
        spacing: 8
        FBtn { visible: root.canSwitchUser; height: 44; radius: 22; padX: 18; text: Fz.tr("Đổi người dùng")
               onClicked: Quickshell.execDetached(["busctl", "--system", "call", "org.freedesktop.DisplayManager", "/org/freedesktop/DisplayManager/Seat0", "org.freedesktop.DisplayManager.Seat", "SwitchToGreeter"]) }
        FIconBtn { width: 44; height: 44; radius: 22; icon: "k-moon"; label: Fz.tr("Ngủ"); onClicked: root.powerActions.sleep() }
        FIconBtn { width: 44; height: 44; radius: 22; icon: "k-restart"; label: Fz.tr("Khởi động lại"); onClicked: root.powerActions.reboot() }
        FIconBtn { width: 44; height: 44; radius: 22; icon: "k-off"; iconColor: Fz.red; label: Fz.tr("Tắt máy"); onClicked: root.powerActions.poweroff() }
    }

    // `.pill`
    component Pill: Rectangle {
        default property alias content: prow.data
        height: 34; radius: 12
        width: prow.implicitWidth + 24
        color: Fz.glass2
        border.width: 1; border.color: Fz.line
        signal clicked()
        Row { id: prow; anchors.centerIn: parent; spacing: 8 }
        MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
    }
}
