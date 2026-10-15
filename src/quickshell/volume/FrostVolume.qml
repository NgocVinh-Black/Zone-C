import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../"
import "../frost"

// Volume and mixer panel of the Frost design (Volume.dc.html).
Item {
    id: root
    focus: true
    readonly property real fitHeight: col.implicitHeight + 32

    readonly property var sink: Audio.defaultSink
    readonly property var source: Audio.defaultSource
    readonly property int master: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    PwObjectTracker { objects: [root.sink, root.source].concat(Audio.outputs).concat(Audio.apps).filter(n => n) }
    PwNodePeakMonitor { id: micPeak; node: root.source; enabled: root.visible && root.source !== null }

    function props(n) { return (n && n.properties) || {}; }
    function devName(n) { return Fz.audioName(n); }
    function devSub(n) { return Fz.audioSub(n); }
    // HDMI ports only matter with an external screen plugged in
    readonly property var outputs: Audio.outputs.filter(n => root.sink === n || !/hdmi|displayport/i.test((n.description || "") + (props(n)["device.profile.description"] || "")) || Quickshell.screens.length > 1)
    // playback streams, one row per application
    readonly property var appGroups: {
        let g = {}, order = [];
        for (const n of Audio.apps) {
            let p = props(n);
            if (p["media.class"] && p["media.class"] !== "Stream/Output/Audio") continue;
            let name = p["application.name"] || (n.name || "").replace(/PC$/, "") || Fz.tr("Ứng dụng");
            if (/quickshell|cava/i.test(name)) continue;
            if (!g[name]) { g[name] = []; order.push(name); }
            g[name].push(n);
        }
        return order.map(k => ({ name: k, nodes: g[k] }));
    }

    function outIcon(n) {
        let p = n.properties || {};
        let s = ((p["device.bus"] || "") + " " + (p["device.form-factor"] || "") + " " + (n.name || "") + " " + (n.description || "")).toLowerCase();
        if (s.indexOf("bluez") !== -1 || s.indexOf("bluetooth") !== -1 || s.indexOf("headset") !== -1 || s.indexOf("headphone") !== -1) return "v-head";
        if (s.indexOf("hdmi") !== -1 || s.indexOf("displayport") !== -1) return "v-tv";
        return "v-spk";
    }
    function appIcon(name) {
        let a = (name || "").toLowerCase();
        if (/spotify|music|rhythmbox|mpv|vlc|player/.test(a)) return "v-music";
        if (/chrome|chromium|firefox|brave|browser|edge|opera/.test(a)) return "v-browser";
        if (/viber|telegram|discord|zalo|signal|slack|teams|zoom|meet/.test(a)) return "v-chat";
        return "v-bell";
    }

    Glass {
        anchors.fill: parent
        radius: 24

        Column {
            id: col
            x: 16; y: 16
            width: parent.width - 32
            spacing: 14

            Row {
                width: parent.width
                spacing: 12
                FIconBtn { on: root.muted; icon: root.muted ? "v-mute" : "Volume:v-vol"; label: Fz.tr("Tắt tiếng"); anchors.verticalCenter: parent.verticalCenter
                           onClicked: if (root.sink) Audio.toggleMute(root.sink) }
                Column {
                    width: parent.width - 36 - 24 - masterT.implicitWidth
                    anchors.verticalCenter: parent.verticalCenter
                    FText { text: Fz.tr("Âm lượng chính"); px: 15; weight: Font.DemiBold }
                    FText { width: parent.width; elide: Text.ElideRight; text: root.sink ? root.devName(root.sink) : Fz.tr("Không có thiết bị ra"); color: Fz.sub; px: 12 }
                }
                FText { id: masterT; mono: true; text: root.master + "%"; px: 22; weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
            }
            FSlider {
                width: parent.width
                from: 0; to: 150
                value: root.master
                onMoved: (v) => { if (root.sink) { if (root.muted) Audio.toggleMute(root.sink); Audio.setVolume(root.sink, v / 100); } }
            }

            Caps { px: 11; text: Fz.tr("Đầu ra") }
            Grp {
                width: parent.width
                Repeater {
                    model: root.outputs
                    delegate: Item {
                        id: orow
                        required property var modelData
                        readonly property bool on: root.sink === modelData
                        width: parent.width
                        height: 50
                        Rectangle { anchors.fill: parent; color: oMouse.containsMouse ? Fz.fg(0.04) : "transparent" }
                        Row {
                            x: 16; anchors.verticalCenter: parent.verticalCenter
                            spacing: 14
                            FRadio { on: orow.on; anchors.verticalCenter: parent.verticalCenter }
                            FIcon { name: root.outIcon(orow.modelData); color: Fz.acc; anchors.verticalCenter: parent.verticalCenter }
                            Lbl { width: orow.width - 32 - 18 - 17 - 28; anchors.verticalCenter: parent.verticalCenter
                                  title: root.devName(orow.modelData); sub: root.devSub(orow.modelData) }
                        }
                        MouseArea { id: oMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Audio.setDefaultOutput(orow.modelData) }
                    }
                }
            }

            Caps { px: 11; text: Fz.tr("Ứng dụng"); visible: root.appGroups.length > 0 }
            Grp {
                visible: root.appGroups.length > 0
                width: parent.width
                Repeater {
                    model: root.appGroups
                    delegate: GRow {
                        id: arow
                        required property var modelData
                        readonly property var node: modelData.nodes[0]
                        readonly property int v: node && node.audio ? Math.round(node.audio.volume * 100) : 0
                        implicitHeight: 52 + 10
                        Ico { icon: root.appIcon(arow.modelData.name); anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            width: arow.width - 32 - 36 - 14
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Item {
                                width: parent.width; height: 16
                                FText { width: parent.width - 50; elide: Text.ElideRight; text: arow.modelData.name; px: 13; weight: Font.Medium }
                                FText { anchors.right: parent.right; mono: true; text: arow.v + "%"; color: Fz.sub; px: 13 }
                            }
                            FSlider { width: parent.width; from: 0; to: 100; value: arow.v
                                      onMoved: (val) => { for (const n of arow.modelData.nodes) Audio.setVolume(n, val / 100); } }
                        }
                    }
                }
            }

            Grp {
                width: parent.width
                GRow {
                    id: mic
                    readonly property int v: root.source && root.source.audio ? Math.round(root.source.audio.volume * 100) : 0
                    readonly property bool off: root.source && root.source.audio ? root.source.audio.muted : true
                    Ico { icon: mic.off ? "micoff" : "v-mic"; anchors.verticalCenter: parent.verticalCenter
                          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (root.source) Audio.toggleMute(root.source) } }
                    Column {
                        width: mic.width - 32 - 36 - 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Item {
                            width: parent.width; height: 16
                            FText { width: parent.width - 50; elide: Text.ElideRight; text: root.source ? root.devName(root.source) : Fz.tr("Không có micro"); px: 13; weight: Font.Medium }
                            FText { anchors.right: parent.right; mono: true; text: mic.off ? Fz.tr("Tắt") : mic.v + "%"; color: Fz.sub; px: 13 }
                        }
                        Row {
                            width: parent.width
                            spacing: 3
                            Repeater {
                                model: 20
                                delegate: Rectangle {
                                    required property int index
                                    width: (parent.width - 19 * 3) / 20
                                    height: 8; radius: 2
                                    color: !mic.off && index < Math.round(Math.min(1, micPeak.peak * 1.6) * 20) ? Fz.acc : Fz.fg(0.12)
                                }
                            }
                        }
                    }
                }
            }

            FBtn { width: parent.width; text: Fz.tr("Cài đặt âm thanh · PipeWire"); onClicked: Fz.open("guide", "sound") }
        }
    }
}
