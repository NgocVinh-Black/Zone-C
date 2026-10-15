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

    H3 { first: true; text: "Nhìn" }
    Grp {
        width: parent.width
        SRow { title: "Tương phản cao"; sub: "Tăng độ đậm viền, chữ và nút"; CfgToggle { key: "access.highContrast" } }
        SRow { title: "Cỡ chữ giao diện"; CfgRange { key: "access.textScale"; from: 80; to: 160; step: 10; def: 100; unit: "%" } }
        SRow { title: "Phóng to màn hình"; sub: "Super + Alt + =  /  Super + Alt + −"; FToggle { on: Config.getSetting("access.zoom", false) === true; onToggled: (v) => page.setZoom(v, page.zoomLvl) } }
        SRow {
            title: "Mức phóng to"
            FSlider { id: zl; width: 220; from: 100; to: 400; step: 25; value: page.zoomLvl; anchors.verticalCenter: parent.verticalCenter
                      onMoved: (v) => { Config.setSetting("access.zoomLevel", v); zoomSave.restart(); } }
            FText { width: 44; horizontalAlignment: Text.AlignRight; text: Math.round(zl.value) + "%"; mono: true; px: 13.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
            Timer { id: zoomSave; interval: 250; onTriggered: if (Config.getSetting("access.zoom", false) === true) HyprConf.set("cursor.zoom_factor", zl.value / 100) }
        }
        SRow { title: "Con trỏ lớn"; FToggle { on: Number(Config.getSetting("hypr_cursor.size", 24)) >= 40; onToggled: (v) => page.setCursorSize(v) } }
        SRow { title: "Giảm chuyển động"; sub: "Tắt hoạt ảnh mở popup và chuyển workspace"; FToggle { on: HyprConf.get("animations.enabled", true) === false; onToggled: (v) => HyprConf.set("animations.enabled", !v) } }
        SRow {
            title: "Bộ lọc màu"; sub: "Hỗ trợ mù màu"
            FSelect {
                options: ["Tắt", "Đỏ – lục (Deuteranopia)", "Đỏ – lục (Protanopia)", "Lam – vàng (Tritanopia)", "Thang xám"]
                readonly property var files: ["", "deuteranopia.frag", "protanopia.frag", "tritanopia.frag", "grayscale.frag"]
                current: Math.max(0, files.findIndex(f => f && String(HyprConf.get("decoration.screen_shader", "")).endsWith(f)))
                onPicked: (i) => HyprConf.set("decoration.screen_shader", files[i] ? page.shaders + files[i] : "[[EMPTY]]")
            }
        }
    }

    H3 { text: "Nghe" }
    Grp {
        width: parent.width
        SRow { title: "Âm thanh mono"; sub: "Gộp hai kênh trái phải"; CfgToggle { key: "access.mono" } }
        SRow { title: "Nháy màn hình khi có cảnh báo"; CfgToggle { key: "access.flash" } }
    }

    H3 { text: "Gõ & đọc màn hình" }
    Grp {
        width: parent.width
        SRow { title: "Phím dính"; sub: "Hyprland chưa hỗ trợ phím dính"; FToggle { enabled: false; opacity: 0.5 } }
        SRow { title: "Phím chậm"; sub: "Hyprland chưa hỗ trợ phím chậm"; FToggle { enabled: false; opacity: 0.5 } }
        SRow {
            title: "Bàn phím ảo"; sub: page.have["wvkbd-mobintl"] ? "wvkbd · hiện trên cùng màn hình" : "Cần gói wvkbd"
            CfgToggle { key: "access.osk"; enabled: !!page.have["wvkbd-mobintl"]; opacity: enabled ? 1 : 0.5 }
        }
        SRow {
            title: "Trình đọc màn hình"; sub: page.have["orca"] ? "Orca · giọng tiếng Việt (espeak-ng)" : "Cần gói orca và espeak-ng"
            CfgToggle { key: "access.orca"; enabled: !!page.have["orca"]; opacity: enabled ? 1 : 0.5 }
        }
    }
}
