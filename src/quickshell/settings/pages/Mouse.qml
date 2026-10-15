import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../../"
import "../../frost"

// Chuột & touchpad: primary button, pointer speed, acceleration, natural scrolling, cursor theme,
// tap-to-click, disable-while-typing and three-finger gestures (Hyprland input options).
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    property var cursors: []
    Process {
        running: true
        command: ["bash", "-c", "for d in /usr/share/icons/* ~/.local/share/icons/* ~/.icons/*; do [ -d \"$d/cursors\" ] && basename \"$d\"; done | sort -u; echo '#'; echo \"${XCURSOR_THEME:-}\"; echo \"${XCURSOR_SIZE:-24}\""]
        stdout: StdioCollector { onStreamFinished: { let p = this.text.split("#"); page.cursors = p[0].trim().split("\n").filter(x => x); page.envCursor = (p[1] || "").trim().split("\n")[0] || ""; } }
    }
    property string envCursor: ""
    readonly property string cursor: Config.getSetting("hypr_cursor.theme", envCursor || "Adwaita")
    readonly property int cursorSize: Number(Config.getSetting("hypr_cursor.size", 24)) || 24
    function setCursor(theme) {
        Config.setSetting("hypr_cursor.theme", theme);
        Quickshell.execDetached(["hyprctl", "setcursor", theme, String(cursorSize)]);
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "cursor-theme", theme]);
    }

    H3 { first: true; text: "Chuột" }
    Grp {
        width: parent.width
        SRow { title: "Nút chính"; FSeg { options: ["Trái", "Phải"]; current: HyprConf.get("input.left_handed", false) ? 1 : 0; onPicked: (i) => HyprConf.set("input.left_handed", i === 1) } }
        SRow {
            title: "Tốc độ con trỏ"
            FSlider { id: ptr; width: 220; from: -1; to: 1; step: 0.05; value: HyprConf.get("input.sensitivity", 0); anchors.verticalCenter: parent.verticalCenter; onMoved: (v) => ptrSave.restart() }
            Timer { id: ptrSave; interval: 300; onTriggered: HyprConf.set("input.sensitivity", Math.round(ptr.value * 100) / 100) }
        }
        SRow { title: "Tăng tốc"; FToggle { on: HyprConf.get("input.accel_profile", "flat") !== "flat"; onToggled: (v) => HyprConf.set("input.accel_profile", v ? "adaptive" : "flat") } }
        SRow { title: "Cuộn tự nhiên"; FToggle { on: HyprConf.get("input.natural_scroll", false); onToggled: (v) => HyprConf.set("input.natural_scroll", v) } }
        SRow {
            title: "Con trỏ"
            FSelect {
                options: page.cursors.map(c => c + " · " + page.cursorSize)
                current: Math.max(0, page.cursors.indexOf(page.cursor))
                onPicked: (i) => page.setCursor(page.cursors[i])
            }
        }
    }

    H3 { text: "Touchpad & cử chỉ" }
    Grp {
        width: parent.width
        SRow { title: "Chạm để nhấp"; FToggle { on: HyprConf.get("input.touchpad.tap_to_click", true); onToggled: (v) => HyprConf.set("input.touchpad.tap_to_click", v) } }
        SRow { title: "Tắt khi đang gõ"; FToggle { on: HyprConf.get("input.touchpad.disable_while_typing", false); onToggled: (v) => HyprConf.set("input.touchpad.disable_while_typing", v) } }
        SRow {
            title: "Vuốt 3 ngón ngang"
            FSelect {
                options: ["Chuyển workspace", "Không làm gì"]
                current: Config.getSetting("hypr_gestures.horizontal", true) !== false ? 0 : 1
                onPicked: (i) => HyprConf.setGesture("horizontal", i === 0)
            }
        }
        SRow {
            title: "Vuốt 3 ngón lên"
            FSelect {
                options: ["Mở launcher", "Tổng quan", "Không làm gì"]
                readonly property var values: ["launcher", "overview", "none"]
                current: Math.max(0, values.indexOf(Config.getSetting("hypr_gestures.up", "launcher")))
                onPicked: (i) => HyprConf.setGesture("up", values[i])
            }
        }
    }
}
