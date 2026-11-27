import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"
import "../../"
import "../../frost"

// Màn hình: arrangement, enable, resolution, refresh rate, scale, VRR (applied with `hyprctl eval
// hl.monitor{…}`, scale saved for monitors.lua), plus the blue-light filter and brightness.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    property var mons: []
    property string sel: ""
    readonly property var m: mons.find(x => x.name === sel) || mons[0] || null
    readonly property var modes: {
        if (!m) return [];
        let out = {};
        (m.availableModes || []).forEach(s => { let r = s.match(/^(\d+)x(\d+)@([\d.]+)Hz$/); if (!r) return; let k = r[1] + "x" + r[2]; (out[k] = out[k] || []).push(Math.round(parseFloat(r[3]) * 100) / 100); });
        return Object.keys(out).sort((a, b) => parseInt(b) - parseInt(a)).map(k => ({ res: k, rates: out[k].filter((v, i, a) => a.indexOf(v) === i).sort((x, y) => x - y) }));
    }
    readonly property string curRes: m ? m.width + "x" + m.height : ""
    readonly property var rates: (modes.find(x => x.res === curRes) || { rates: [] }).rates
    readonly property var scales: [1, 1.25, 1.5, 1.6, 2]

    Process {
        id: probe
        running: true
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector { onStreamFinished: { try { page.mons = JSON.parse(this.text); if (!page.sel && page.mons.length) page.sel = page.mons[0].name; } catch (e) {} } }
    }
    Timer { id: reprobe; interval: 800; onTriggered: probe.running = true }
    function apply(patch) {
        if (!m) return;
        let p = Object.assign({ mode: curRes + "@" + m.refreshRate.toFixed(2), scale: m.scale, vrr: m.vrr ? 1 : 0, disabled: m.disabled === true }, patch);
        let lua = 'hl.monitor({ output = "' + m.name + '", mode = "' + p.mode + '", position = "' + m.x + 'x' + m.y + '", scale = ' + p.scale + ', vrr = ' + p.vrr + ', disabled = ' + p.disabled + ' })';
        Quickshell.execDetached(["hyprctl", "eval", lua]);
        if (patch.scale !== undefined) Config.setSetting("display.monitors." + m.name + ".scale", patch.scale);
        reprobe.restart();
    }
    function tag(mon) { let d = (mon.description || "").replace(/\s+0x[0-9A-F]+$/i, ""); return mon.name + (d ? " · " + d : ""); }

    // ---------- arrangement ----------
    Rectangle {
        id: stage
        width: parent.width; height: 200; radius: 16
        color: Fz.well(0.22); border.width: 1; border.color: Fz.line
        readonly property var box: {
            let xs = page.mons.filter(x => !x.disabled), minX = 0, minY = 0, maxX = 1, maxY = 1;
            if (xs.length) { minX = Math.min(...xs.map(x => x.x)); minY = Math.min(...xs.map(x => x.y)); maxX = Math.max(...xs.map(x => x.x + x.width / x.scale)); maxY = Math.max(...xs.map(x => x.y + x.height / x.scale)); }
            return { minX, minY, w: maxX - minX, h: maxY - minY };
        }
        readonly property real k: Math.min((width - 200) / box.w, (height - 70) / box.h)
        Repeater {
            model: page.mons
            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool on: page.m && page.m.name === modelData.name
                width: modelData.width / modelData.scale * stage.k; height: modelData.height / modelData.scale * stage.k
                x: (stage.width - stage.box.w * stage.k) / 2 + (modelData.x - stage.box.minX) * stage.k
                y: (stage.height - stage.box.h * stage.k) / 2 + (modelData.y - stage.box.minY) * stage.k
                radius: 12
                color: on ? Fz.s0 : Fz.base
                border.width: on ? 2.5 : 1.5; border.color: on ? Fz.acc : Fz.s2
                opacity: modelData.disabled ? 0.5 : 1
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    FText { anchors.horizontalCenter: parent.horizontalCenter; text: index + 1; px: 18; weight: Font.Bold }
                    FText { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; px: 12.5 }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.sel = modelData.name }
            }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 12
            spacing: 8
            FBtn { text: Fz.tr("Nhận diện"); onClicked: ident.show() }
            FBtn {
                text: Fz.tr("Nhân bản"); visible: page.mons.length > 1
                onClicked: { let a = page.mons[0], b = page.mons[1]; Quickshell.execDetached(["hyprctl", "eval", 'hl.monitor({ output = "' + b.name + '", mode = "preferred", position = "auto", scale = ' + b.scale + ', mirror = "' + a.name + '" })']); reprobe.restart(); }
            }
        }
    }

    // big numbers on every screen for two seconds
    Scope {
        id: ident
        property bool shown: false
        function show() { shown = true; identTimer.restart(); }
        Timer { id: identTimer; interval: 2000; onTriggered: ident.shown = false }
        Variants {
            model: ident.shown ? Quickshell.screens : []
            PanelWindow {
                required property var modelData
                screen: modelData
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "qs-identify"
                exclusionMode: ExclusionMode.Ignore
                anchors { top: true; left: true }
                margins { top: 80; left: 40 }
                implicitWidth: 160; implicitHeight: 160
                color: "transparent"
                Glass {
                    anchors.fill: parent; radius: 32
                    FText { anchors.centerIn: parent; text: Quickshell.screens.indexOf(modelData) + 1; px: 80; weight: Font.Light }
                }
            }
        }
    }

    H3 { text: page.m ? page.tag(page.m) : "" }
    Grp {
        width: parent.width
        SRow { title: Fz.tr("Bật màn hình này"); FToggle { on: page.m ? !page.m.disabled : false; enabled: page.mons.length > 1; onToggled: (v) => page.apply({ disabled: !v }) } }
        SRow {
            title: Fz.tr("Độ phân giải")
            FSelect {
                options: page.modes.map((x, i) => x.res.replace("x", Fz.tr(" × ")) + (i === 0 ? Fz.tr(" (Khuyên dùng)") : ""))
                current: Math.max(0, page.modes.findIndex(x => x.res === page.curRes))
                onPicked: (i) => { let md = page.modes[i]; page.apply({ mode: md.res + "@" + md.rates[md.rates.length - 1].toFixed(2) }); }
            }
        }
        SRow {
            title: Fz.tr("Tần số quét")
            FSeg {
                options: page.rates.map(r => Math.round(r) + " Hz")
                current: Math.max(0, page.rates.findIndex(r => page.m && Math.abs(r - page.m.refreshRate) < 0.5))
                onPicked: (i) => page.apply({ mode: page.curRes + "@" + page.rates[i].toFixed(2) })
            }
        }
        SRow {
            title: Fz.tr("Tỷ lệ giao diện")
            FSeg {
                options: page.scales.map(s => Math.round(s * 100) + "%")
                current: Math.max(0, page.scales.findIndex(s => page.m && Math.abs(s - page.m.scale) < 0.01))
                onPicked: (i) => page.apply({ scale: page.scales[i] })
            }
        }
        SRow { title: Fz.tr("Đồng bộ thích ứng (VRR)"); FToggle { on: page.m ? page.m.vrr === true : false; onToggled: (v) => page.apply({ vrr: v ? 1 : 0 }) } }
    }

    H3 { text: Fz.tr("Bộ lọc ánh sáng xanh") }
    Grp {
        width: parent.width
        SRow {
            title: Fz.tr("Bật bộ lọc"); sub: Fz.tr("Ánh sáng màn hình ấm")
            FToggle { on: page.m ? Config.getSetting("display.monitors." + page.m.name + ".enabled", false) === true : false; onToggled: (v) => BlueLight.setEnabled(page.m ? page.m.name : "", v) }
        }
        SRow {
            title: Fz.tr("Lịch trình tự động"); sub: Fz.tr("Theo hoàng hôn và bình minh tại ") + (Location.city && Location.city !== "Unknown" ? Location.city : Fz.tr("vị trí của bạn"))
            FToggle { on: BlueLight.getSavedAuto(page.m ? page.m.name : ""); onToggled: (v) => BlueLight.setAuto(page.m ? page.m.name : "", v) }
        }
        SRow {
            title: Fz.tr("Nhiệt độ màu")
            FText { text: Fz.tr("Lạnh"); px: 13.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
            FSlider { id: tempSlider; width: 200; from: 0; to: 100; value: BlueLight.getSavedTemperature(page.m ? page.m.name : ""); anchors.verticalCenter: parent.verticalCenter
                      onMoved: (v) => tempSave.restart() }
            FText { text: Fz.tr("Ấm"); px: 13.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
            Timer { id: tempSave; interval: 250; onTriggered: BlueLight.setTemperature(page.m ? page.m.name : "", tempSlider.value) }
        }
        SRow {
            title: Fz.tr("Độ sáng")
            FSlider { id: bri; width: 220; from: 1; to: 100; value: OsdController.sysBrightness || 50; anchors.verticalCenter: parent.verticalCenter
                      onMoved: (v) => briSave.restart() }
            FText { width: 44; horizontalAlignment: Text.AlignRight; text: Math.round(bri.value) + "%"; mono: true; px: 13.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
            Timer { id: briSave; interval: 120; onTriggered: Quickshell.execDetached(["bash", Caching.zoneCDir + "/scripts/brightness.sh", "set", String(Math.round(bri.value))]) }
        }
    }
}
