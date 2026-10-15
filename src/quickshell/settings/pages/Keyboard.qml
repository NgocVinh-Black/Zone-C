import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../../"
import "../../frost"

// Bàn phím: fcitx5 input methods and switch keys, key repeat, Caps Lock behaviour, main shortcuts.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    property var ims: []
    property string trigger: ""
    Process {
        running: true
        command: ["bash", "-c", "grep '^Name=' ~/.config/fcitx5/profile 2>/dev/null | cut -d= -f2; echo '#'; awk '/^\\[Hotkey\\/TriggerKeys\\]/{f=1;next} /^\\[/{f=0} f && /^0=/{sub(/^0=/,\"\");print;exit}' ~/.config/fcitx5/config 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = this.text.split("#");
                page.ims = p[0].trim().split("\n").filter(n => n && n !== "Default");
                page.trigger = (p[1] || "").trim() || "Control+space";
            }
        }
    }
    function imName(n) { return n === "unikey" ? "Tiếng Việt (Telex)" : n === "bamboo" ? "Tiếng Việt (Bamboo)" : n.indexOf("keyboard-") === 0 ? (n === "keyboard-us" ? "English (US)" : "Bàn phím " + n.slice(9).toUpperCase()) : n; }
    function imTag(n) { return /unikey|bamboo|vi/.test(n) ? "VI" : n.indexOf("keyboard-") === 0 ? n.slice(9, 11).toUpperCase() : n.slice(0, 2).toUpperCase(); }

    readonly property real rate: HyprConf.get("input.repeat_rate", 25)
    readonly property real delay: HyprConf.get("input.repeat_delay", 600)
    readonly property string opts: HyprConf.get("input.kb_options", "grp:alt_shift_toggle")
    function setCaps(v) {
        let o = opts.split(",").filter(x => x && x.indexOf("caps:") !== 0 && x !== "ctrl:nocaps");
        if (v) o.push(v);
        HyprConf.set("input.kb_options", o.join(","));
    }

    H3 { first: true; text: "Bộ gõ" }
    Grp {
        width: parent.width
        Repeater {
            model: page.ims
            delegate: SRow {
                required property var modelData
                required property int index
                iconText: page.imTag(modelData); iconOn: index === page.ims.length - 1 || /unikey|bamboo/.test(modelData)
                title: page.imName(modelData); sub: /unikey|bamboo/.test(modelData) ? "fcitx5 · " + (modelData === "unikey" ? "Unikey" : "Bamboo") : ""
                FBtn { text: "Tùy chọn"; onClicked: Quickshell.execDetached(["fcitx5-configtool"]) }
            }
        }
        SRow { visible: page.ims.length === 0; title: "Chưa cấu hình fcitx5"; FBtn { text: "Mở cấu hình"; onClicked: Quickshell.execDetached(["fcitx5-configtool"]) } }
        SRow {
            title: "Chuyển bộ gõ"
            Repeater { model: page.trigger.split("+").map(k => k === "Control" ? "Ctrl" : k === "space" ? "Space" : k); delegate: FKbd { required property var modelData; text: modelData; anchors.verticalCenter: parent.verticalCenter } }
        }
    }

    H3 { text: "Gõ phím" }
    Grp {
        width: parent.width
        SRow {
            title: "Tốc độ lặp phím"
            FSlider { width: 220; from: 10; to: 60; value: page.rate; anchors.verticalCenter: parent.verticalCenter; onMoved: (v) => rateSave.restart(); id: rateS }
            Timer { id: rateSave; interval: 300; onTriggered: HyprConf.set("input.repeat_rate", Math.round(rateS.value)) }
        }
        SRow {
            title: "Độ trễ trước khi lặp"
            FSlider { id: delayS; width: 220; from: 150; to: 1000; step: 25; value: page.delay; anchors.verticalCenter: parent.verticalCenter; onMoved: (v) => delaySave.restart() }
            Timer { id: delaySave; interval: 300; onTriggered: HyprConf.set("input.repeat_delay", Math.round(delayS.value)) }
        }
        SRow {
            title: "Phím Caps Lock"
            FSelect {
                options: ["Caps Lock", "Hoạt động như Esc", "Ctrl"]
                readonly property var values: ["", "caps:escape", "ctrl:nocaps"]
                current: page.opts.indexOf("caps:escape") !== -1 ? 1 : page.opts.indexOf("ctrl:nocaps") !== -1 ? 2 : 0
                onPicked: (i) => page.setCaps(values[i])
            }
        }
    }

    H3 { text: "Phím tắt" }
    Grp {
        width: parent.width
        Repeater {
            model: [["Mở launcher", "Super"], ["Bảng phím tắt", "Super + /"], ["Cài đặt", "Super + I"], ["Terminal", "Super + T"], ["Trình duyệt", "Super + W"], ["Đóng cửa sổ (hỏi)", "Super + Q"],
                    ["Chụp vùng", "Super + Shift + S"], ["Quay màn hình", "Super + Alt + R"], ["Chuyển workspace", "Super + PgUp / PgDn"]]
            delegate: SRow { required property var modelData; minH: 46; title: modelData[0]; titleWeight: Font.Normal; FKbd { text: modelData[1]; anchors.verticalCenter: parent.verticalCenter } }
        }
    }
    Item { width: 1; height: 12 }
    FBtn { text: "Xem tất cả phím tắt"; onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/keybinds-help"]) }
}
