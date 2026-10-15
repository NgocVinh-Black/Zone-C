import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../"
import "../../"
import "../../frost"

// Âm thanh: output device, volume and left/right balance, microphone level, RNNoise noise reduction
// (a PipeWire filter-chain when the LADSPA plugin is installed) and the shell's own sound effects.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    readonly property var sink: Audio.defaultSink
    readonly property var source: Audio.defaultSource
    readonly property real vol: sink && sink.audio ? sink.audio.volume * 100 : 0
    readonly property real balance: {
        let v = sink && sink.audio ? sink.audio.volumes : [];
        if (!v || v.length < 2) return 50;
        let l = v[0], r = v[1], m = Math.max(l, r);
        if (m <= 0) return 50;
        return l >= r ? 50 * r / m : 100 - 50 * l / m;
    }
    function setBalance(b) {
        if (!sink || !sink.audio) return;
        let v = sink.audio.volume, n = (sink.audio.volumes || []).length;
        if (n < 2) return;
        let l = v * Math.min(1, (100 - b) / 50), r = v * Math.min(1, b / 50), out = [];
        for (let i = 0; i < n; i++) out.push(i % 2 === 0 ? l : r);
        sink.audio.volumes = out;
    }
    function icon(n) {
        let p = (n && n.properties) || {};
        if (p["device.api"] === "bluez5") return "s-head";
        if (/hdmi|displayport/i.test((p["device.profile.description"] || "") + (n.description || ""))) return "s-display";
        return "s-spk";
    }

    // RNNoise: ~/.config/pipewire/pipewire.conf.d/99-zone-c-rnnoise.conf
    readonly property string rnConf: Quickshell.env("HOME") + "/.config/pipewire/pipewire.conf.d/99-zone-c-rnnoise.conf"
    property bool rnAvailable: false
    property bool rnOn: false
    Process {
        id: rnProbe
        running: true
        command: ["bash", "-c", "ls /usr/lib/ladspa/librnnoise_ladspa.so >/dev/null 2>&1 && echo avail; [ -f \"$1\" ] && echo on", "_", page.rnConf]
        stdout: StdioCollector { onStreamFinished: { page.rnAvailable = this.text.indexOf("avail") !== -1; page.rnOn = this.text.indexOf("on") !== -1; } }
    }
    readonly property string rnBody: "context.modules = [{ name = libpipewire-module-filter-chain args = { node.description = \"Micro khử ồn (Zone-C)\" media.name = \"Micro khử ồn\" filter.graph = { nodes = [{ type = ladspa name = rnnoise plugin = /usr/lib/ladspa/librnnoise_ladspa.so label = noise_suppressor_mono control = { \"VAD Threshold (%)\" = 50.0 } }] } capture.props = { node.name = \"capture.rnnoise_source\" node.passive = true audio.rate = 48000 } playback.props = { node.name = \"rnnoise_source\" media.class = Audio/Source audio.rate = 48000 } } }]"
    function setRn(on) {
        let cmd = on ? "mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' \"$2\" > \"$1\"" : "rm -f \"$1\"";
        Quickshell.execDetached(["bash", "-c", cmd + "; systemctl --user restart pipewire pipewire-pulse", "_", rnConf, rnBody]);
        rnOn = on;
    }

    H3 { first: true; text: Fz.tr("Đầu ra") }
    Grp {
        width: parent.width
        Repeater {
            model: Audio.outputs
            delegate: Item {
                required property var modelData
                width: parent.width; height: outRow.height
                SRow {
                    id: outRow
                    x: 36; width: parent.width - 36
                    icon: page.icon(modelData); title: Fz.audioName(modelData); sub: Fz.audioSub(modelData)
                }
                FRadio { x: 16; anchors.verticalCenter: parent.verticalCenter; on: page.sink === modelData }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Audio.setDefaultOutput(modelData) }
            }
        }
    }
    Item { width: 1; height: 10 }
    Grp {
        width: parent.width
        SRow {
            title: Fz.tr("Âm lượng")
            FSlider { id: volS; width: 220; from: 0; to: 150; value: page.vol; anchors.verticalCenter: parent.verticalCenter; onMoved: (v) => Audio.setVolume(page.sink, v) }
            FText { width: 44; horizontalAlignment: Text.AlignRight; text: Math.round(page.vol) + "%"; mono: true; px: 13.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
        }
        SRow {
            title: Fz.tr("Cân bằng trái / phải")
            FText { text: "T"; px: 13.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
            FSlider { width: 220; from: 0; to: 100; value: page.balance; anchors.verticalCenter: parent.verticalCenter; onMoved: (v) => page.setBalance(v) }
            FText { text: "P"; px: 13.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    H3 { text: Fz.tr("Đầu vào") }
    Grp {
        width: parent.width
        SRow {
            icon: "s-mic"; title: page.source ? Fz.audioName(page.source) : Fz.tr("Không có micro")
            FSlider { width: 220; from: 0; to: 100; value: page.source && page.source.audio ? page.source.audio.volume * 100 : 0; anchors.verticalCenter: parent.verticalCenter
                      onMoved: (v) => Audio.setVolume(page.source, v) }
            FText { width: 44; horizontalAlignment: Text.AlignRight; text: Math.round(page.source && page.source.audio ? page.source.audio.volume * 100 : 0) + "%"; mono: true; px: 13.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
        }
        SRow {
            title: Fz.tr("Khử tiếng ồn"); sub: page.rnAvailable ? Fz.tr("RNNoise qua PipeWire") : Fz.tr("Cần gói noise-suppression-for-voice")
            FToggle { enabled: page.rnAvailable; opacity: enabled ? 1 : 0.5; on: page.rnOn; onToggled: (v) => page.setRn(v) }
        }
    }

    H3 { text: Fz.tr("Hiệu ứng âm thanh Zone-C") }
    Grp {
        width: parent.width
        SRow { title: Fz.tr("Tắt hiệu ứng âm thanh"); sub: Fz.tr("Click, toggle, mở popup…"); CfgToggle { key: "general.muteSfx" } }
        SRow { title: Fz.tr("Âm lượng hiệu ứng"); sub: Fz.tr("Không ảnh hưởng âm thanh hệ thống"); CfgRange { key: "general.sfxVolume"; from: 0; to: 100; def: 100; unit: "%" } }
    }
    Item { width: 1; height: 12 }
    FBtn { text: Fz.tr("Mở Equalizer"); onClicked: Fz.open("music") }
}
