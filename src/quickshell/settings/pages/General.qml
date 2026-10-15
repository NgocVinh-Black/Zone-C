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
            title: "Ảnh đại diện"; sub: page.short(Config.getSetting("general.avatarPath", "") || page.home + "/.face"); subMono: true
            FBtn { text: "Chọn"; onClicked: { page.picking = true; page.picker.show("Chọn ảnh đại diện", ["png", "jpg", "jpeg", "webp"], page.home + "/Pictures", "open", ""); } }
        }
        SRow {
            title: "Ngôn ngữ giao diện"
            CfgSelect {
                key: "general.language"; def: "vi"
                options: ["Tiếng Việt", "English", "Deutsch", "Español", "Italiano", "한국어", "Português", "Русский", "Українська", "Azərbaycan", "Հայերեն"]
                values: ["vi", "en", "de", "es", "it", "ko", "pt", "ru", "ua", "az", "hy"]
            }
        }
        SRow {
            title: "Tỷ lệ giao diện"; sub: "Áp dụng khi Zone-C khởi động lại"
            CfgSeg { key: "general.uiScale"; def: 100; options: ["90%", "100%", "110%", "125%"]; values: [90, 100, 110, 125] }
        }
        SRow { title: "Thao tác nhanh"; sub: "Lớp phủ quick actions nổi"; CfgToggle { key: "general.quickactions"; def: true } }
        SRow { title: "Chụp vùng khi thả chuột"; CfgToggle { key: "general.screenshotCaptureOnRelease" } }
    }

    H3 { text: "Vị trí & thời tiết" }
    Grp {
        width: parent.width
        SRow {
            icon: "s-pin"
            title: Location.city && Location.city !== "Unknown" ? Location.city : "Chưa xác định"
            sub: Location.latitude.toFixed(4) + ", " + Location.longitude.toFixed(4); subMono: true
            FBtn { text: Location.isDetecting ? "Đang tìm…" : "Tự động phát hiện"; onClicked: Location.detectAuto() }
        }
        SRow { title: "Tần suất cập nhật thời tiết"; CfgSelect { key: "general.weatherInterval"; def: 15; options: ["15 phút", "30 phút", "60 phút"]; values: [15, 30, 60] } }
        SRow { title: "Đơn vị nhiệt độ"; CfgSeg { key: "general.weatherUnit"; def: "metric"; options: ["°C", "°F", "K"]; values: ["metric", "imperial", "standard"] } }
    }

    H3 { text: "Sao lưu" }
    Grp {
        width: parent.width
        SRow {
            title: "Sao chép cài đặt"; sub: page.short(Config.settingsJsonPath); subMono: true
            FBtn { icon: "s-copy"; iconSize: 14; text: "Sao chép JSON"; onClicked: Quickshell.execDetached(["bash", "-c", "wl-copy < \"$1\"", "_", Config.settingsJsonPath]) }
        }
    }
}
