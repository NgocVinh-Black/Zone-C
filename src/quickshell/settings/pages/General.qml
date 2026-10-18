import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../../"
import "../../frost"

// Chung: avatar, shell language, interface scale, quick actions, screenshot-on-release, location and
// weather, and copying settings.json.
Column {
    id: page
    property var app
    property var picker
    width: parent ? parent.width : 0

    readonly property string avatar: SystemInfo.avatarPath ? (SystemInfo.avatarPath.startsWith("file://") ? SystemInfo.avatarPath : "file://" + SystemInfo.avatarPath) : ""
    readonly property string home: Quickshell.env("HOME")
    function short(p) { return p && p.indexOf(home) === 0 ? "~" + p.slice(home.length) : p; }
    Connections {
        target: page.picker
        enabled: page.picker !== null && page.picker !== undefined
        ignoreUnknownSignals: true
        function onAccepted(path) {
            if (!page.picking) return;
            page.picking = false;
            Quickshell.execDetached(["bash", "-c", "cp -f -- \"$1\" \"$HOME/.face\" && rm -f \"$2\"", "_", path, Caching.getCacheDir("avatar") + "/avatar_cropped.png"]);
            Config.setSetting("general.avatarPath", page.home + "/.face");
            refetch.restart();
        }
        function onCanceled() { page.picking = false; }
    }
    property bool picking: false
    Timer { id: refetch; interval: 400; onTriggered: SystemInfo.fetch() }

    Grp {
        width: parent.width
        SRow {
            image: page.avatar
            title: Fz.tr("Ảnh đại diện"); sub: page.short(Config.getSetting("general.avatarPath", "") || page.home + "/.face"); subMono: true
            FBtn { text: Fz.tr("Chọn"); onClicked: { page.picking = true; page.picker.show(Fz.tr("Chọn ảnh đại diện"), ["png", "jpg", "jpeg", "webp"], page.home + "/Pictures", "open", ""); } }
        }
        SRow {
            title: Fz.tr("Ngôn ngữ giao diện")
            // the Frost interface is written in Vietnamese with an English translation (frost/En.js)
            CfgSeg { key: "general.language"; def: "vi"; options: [Fz.tr("Tiếng Việt"), "English"]; values: ["vi", "en"] }
        }
        SRow {
            title: Fz.tr("Tỷ lệ giao diện"); sub: Fz.tr("Áp dụng khi Zone-C khởi động lại")
            CfgSeg { key: "general.uiScale"; def: 100; options: ["90%", "100%", "110%", "125%"]; values: [90, 100, 110, 125] }
        }
        SRow { title: Fz.tr("Thao tác nhanh"); sub: Fz.tr("Lớp phủ quick actions nổi"); CfgToggle { key: "general.quickactions"; def: true } }
        SRow { title: Fz.tr("Chụp vùng khi thả chuột"); CfgToggle { key: "general.screenshotCaptureOnRelease" } }
    }

    H3 { text: Fz.tr("Vị trí & thời tiết") }
    Grp {
        width: parent.width
        SRow {
            icon: "s-pin"
            title: Location.city && Location.city !== "Unknown" ? Location.city : Fz.tr("Chưa xác định")
            sub: Location.latitude.toFixed(4) + ", " + Location.longitude.toFixed(4); subMono: true
            FBtn { text: Location.isDetecting ? Fz.tr("Đang tìm…") : Fz.tr("Tự động phát hiện"); onClicked: Location.detectAuto() }
        }
        SRow { title: Fz.tr("Tần suất cập nhật thời tiết"); CfgSelect { key: "general.weatherInterval"; def: 15; options: [Fz.tr("15 phút"), Fz.tr("30 phút"), Fz.tr("60 phút")]; values: [15, 30, 60] } }
        SRow { title: Fz.tr("Đơn vị nhiệt độ"); CfgSeg { key: "general.weatherUnit"; def: "metric"; options: ["°C", "°F", "K"]; values: ["metric", "imperial", "standard"] } }
    }

    H3 { text: Fz.tr("Sao lưu") }
    Grp {
        width: parent.width
        SRow {
            title: Fz.tr("Sao chép cài đặt"); sub: page.short(Config.settingsJsonPath); subMono: true
            FBtn { icon: "s-copy"; iconSize: 14; text: Fz.tr("Sao chép JSON"); onClicked: Quickshell.execDetached(["bash", "-c", "wl-copy < \"$1\"", "_", Config.settingsJsonPath]) }
        }
    }
}
