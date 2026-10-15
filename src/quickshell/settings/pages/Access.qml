import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../../"
import "../../frost"

// Trợ năng: contrast, text size, screen zoom, large cursor, reduced motion, colour filters (Hyprland
// screen shaders), mono audio, visual alerts, on-screen keyboard and screen reader.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    property var have: ({})
    Process {
        running: true
        command: ["bash", "-c", "for b in wvkbd-mobintl orca; do command -v $b >/dev/null && echo $b; done"]
        stdout: StdioCollector { onStreamFinished: { let o = {}; this.text.trim().split("\n").forEach(b => { if (b) o[b] = true; }); page.have = o; } }
    }
    readonly property string shaders: Caching.zoneCDir + "/assets/shaders/"
    readonly property real zoomLvl: Number(Config.getSetting("access.zoomLevel", 200)) || 200
    function setZoom(on, lvl) {
        Config.setSetting("access.zoom", on);
        HyprConf.set("cursor.zoom_factor", on ? lvl / 100 : 1);
    }
    function setCursorSize(big) {
        let size = big ? 48 : 24, theme = Config.getSetting("hypr_cursor.theme", "") || "Adwaita";
        Config.setSetting("hypr_cursor.size", size);
        Quickshell.execDetached(["hyprctl", "setcursor", theme, String(size)]);
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "cursor-size", String(size)]);
    }

    H3 { first: true; text: Fz.tr("Nhìn") }
    Grp {
        width: parent.width
        SRow { title: Fz.tr("Tương phản cao"); sub: Fz.tr("Tăng độ đậm viền, chữ và nút"); CfgToggle { key: "access.highContrast" } }
        SRow { title: Fz.tr("Cỡ chữ giao diện"); CfgRange { key: "access.textScale"; from: 80; to: 160; step: 10; def: 100; unit: "%" } }
        SRow { title: Fz.tr("Phóng to màn hình"); sub: "Super + Alt + =  /  Super + Alt + −"; FToggle { on: Config.getSetting("access.zoom", false) === true; onToggled: (v) => page.setZoom(v, page.zoomLvl) } }
        SRow {
            title: Fz.tr("Mức phóng to")
            FSlider { id: zl; width: 220; from: 100; to: 400; step: 25; value: page.zoomLvl; anchors.verticalCenter: parent.verticalCenter
                      onMoved: (v) => { Config.setSetting("access.zoomLevel", v); zoomSave.restart(); } }
            FText { width: 44; horizontalAlignment: Text.AlignRight; text: Math.round(zl.value) + "%"; mono: true; px: 13.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
            Timer { id: zoomSave; interval: 250; onTriggered: if (Config.getSetting("access.zoom", false) === true) HyprConf.set("cursor.zoom_factor", zl.value / 100) }
        }
        SRow { title: Fz.tr("Con trỏ lớn"); FToggle { on: Number(Config.getSetting("hypr_cursor.size", 24)) >= 40; onToggled: (v) => page.setCursorSize(v) } }
        SRow { title: Fz.tr("Giảm chuyển động"); sub: Fz.tr("Tắt hoạt ảnh mở popup và chuyển workspace"); FToggle { on: HyprConf.get("animations.enabled", true) === false; onToggled: (v) => HyprConf.set("animations.enabled", !v) } }
        SRow {
            title: Fz.tr("Bộ lọc màu"); sub: Fz.tr("Hỗ trợ mù màu")
            FSelect {
                options: [Fz.tr("Tắt"), Fz.tr("Đỏ – lục (Deuteranopia)"), Fz.tr("Đỏ – lục (Protanopia)"), Fz.tr("Lam – vàng (Tritanopia)"), Fz.tr("Thang xám")]
                readonly property var files: ["", "deuteranopia.frag", "protanopia.frag", "tritanopia.frag", "grayscale.frag"]
                current: Math.max(0, files.findIndex(f => f && String(HyprConf.get("decoration.screen_shader", "")).endsWith(f)))
                onPicked: (i) => HyprConf.set("decoration.screen_shader", files[i] ? page.shaders + files[i] : "[[EMPTY]]")
            }
        }
    }

    H3 { text: "Nghe" }
    Grp {
        width: parent.width
        SRow { title: Fz.tr("Âm thanh mono"); sub: Fz.tr("Gộp hai kênh trái phải"); CfgToggle { key: "access.mono" } }
        SRow { title: Fz.tr("Nháy màn hình khi có cảnh báo"); CfgToggle { key: "access.flash" } }
    }

    H3 { text: Fz.tr("Gõ & đọc màn hình") }
    Grp {
        width: parent.width
        SRow { title: Fz.tr("Phím dính"); sub: Fz.tr("Hyprland chưa hỗ trợ phím dính"); FToggle { enabled: false; opacity: 0.5 } }
        SRow { title: Fz.tr("Phím chậm"); sub: Fz.tr("Hyprland chưa hỗ trợ phím chậm"); FToggle { enabled: false; opacity: 0.5 } }
        SRow {
            title: Fz.tr("Bàn phím ảo"); sub: page.have["wvkbd-mobintl"] ? Fz.tr("wvkbd · hiện trên cùng màn hình") : Fz.tr("Cần gói wvkbd")
            CfgToggle { key: "access.osk"; enabled: !!page.have["wvkbd-mobintl"]; opacity: enabled ? 1 : 0.5 }
        }
        SRow {
            title: Fz.tr("Trình đọc màn hình"); sub: page.have["orca"] ? Fz.tr("Orca · giọng tiếng Việt (espeak-ng)") : Fz.tr("Cần gói orca và espeak-ng")
            CfgToggle { key: "access.orca"; enabled: !!page.have["orca"]; opacity: enabled ? 1 : 0.5 }
        }
    }
}
