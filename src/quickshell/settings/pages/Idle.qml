import QtQuick
import "../"
import "../../"
import "../../frost"

// Chờ & khóa: the idle chain dim → lock → screen off → suspend, inhibitors and custom actions.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    readonly property var idle: Config.getSetting("idle", { enabled: true, actions: {} })
    readonly property var actions: idle.actions || {}
    readonly property var chain: [["dim", "Làm mờ màn hình", "Trước khi làm mờ"], ["lock", "Khóa phiên", "Yêu cầu mật khẩu"], ["dpms", "Tắt màn hình (DPMS)", "Tắt hoàn toàn màn hình"], ["suspend", "Ngủ hệ thống", "Đưa máy vào chế độ ngủ"]]
    readonly property var steps: [60, 120, 150, 180, 300, 450, 600, 900, 1200, 1800, 3600]
    function mmss(s) { return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0"); }
    readonly property bool allMpris: Object.keys(actions).length > 0 && Object.keys(actions).every(k => actions[k].mprisInhibit === true)
    readonly property bool allRespect: Object.keys(actions).length === 0 || Object.keys(actions).every(k => actions[k].respectInhibitors !== false)
    function setAll(field, v) {
        let a = JSON.parse(JSON.stringify(actions));
        for (const k in a) a[k][field] = v;
        Config.setSetting("idle.actions", a);
    }
    function setAction(id, field, v) { Config.setSetting("idle.actions." + id + "." + field, v); }
    property bool adding: false
    function addCustom(cmd) {
        if (!cmd.trim()) return;
        let id = "custom" + Date.now();
        Config.setSetting("idle.actions." + id, { id: id, timeout: 600, enabled: true, respectInhibitors: true, mprisInhibit: false, command: cmd.trim(), resumeCommand: "", isCustom: true });
    }

    Grp {
        width: parent.width
        SRow { title: "Bật hệ thống trạng thái chờ"; CfgToggle { key: "idle.enabled"; def: true } }
        SRow { title: "Giữ màn hình luôn sáng"; sub: "Ngăn chờ thủ công (caffeine)"; CfgToggle { key: "idle.manualInhibit" } }
        SRow { title: "Chặn chờ khi đang phát phương tiện"; FToggle { on: page.allMpris; onToggled: (v) => page.setAll("mprisInhibit", v) } }
        SRow { title: "Tuân thủ bộ chặn từ ứng dụng"; sub: "Wayland idle-inhibit"; FToggle { on: page.allRespect; onToggled: (v) => page.setAll("respectInhibitors", v) } }
    }

    H3 { text: "Chuỗi tác vụ · làm mờ → khóa → tắt màn hình → ngủ" }
    Grp {
        width: parent.width
        Repeater {
            model: page.chain.concat(Object.keys(page.actions).filter(k => page.actions[k].isCustom).map(k => [k, page.actions[k].command, "Tác vụ tùy chỉnh"]))
            delegate: SRow {
                required property var modelData
                readonly property var a: page.actions[modelData[0]] || { timeout: ({ dim: 150, lock: 300, dpms: 450, suspend: 600 })[modelData[0]] || 300, enabled: true }
                iconText: page.mmss(a.timeout || 0); iconWidth: 44
                title: modelData[1]; titleMono: !!a.isCustom; sub: modelData[2]
                FSelect {
                    width: 130
                    options: page.steps.map(s => page.mmss(s))
                    current: Math.max(0, page.steps.indexOf(a.timeout))
                    onPicked: (i) => page.setAction(modelData[0], "timeout", page.steps[i])
                }
                FToggle { on: a.enabled !== false; onToggled: (v) => page.setAction(modelData[0], "enabled", v) }
            }
        }
        SRow {
            title: "Thêm tác vụ tùy chỉnh"; sub: "VD: playerctl pause"; subMono: true
            FInput { id: cmdField; visible: page.adding; width: 220; height: 36; placeholder: "lệnh…"; onAccepted: { page.addCustom(text); text = ""; page.adding = false; } }
            FBtn { icon: page.adding ? "" : "s-plus"; iconSize: 14; text: page.adding ? "Lưu" : "Thêm"
                   onClicked: { if (page.adding) { page.addCustom(cmdField.text); cmdField.text = ""; page.adding = false; } else { page.adding = true; cmdField.input.forceActiveFocus(); } } }
        }
    }
}
