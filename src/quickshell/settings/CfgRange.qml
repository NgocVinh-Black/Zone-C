import QtQuick
import "../"
import "../frost"

// `.rng` + value label bound to a settings.json key. Writes are debounced while dragging.
Row {
    id: r
    property string key
    property real from: 0
    property real to: 100
    property real step: 1
    property real def: 0
    property string unit: ""
    property real scale: 1                 // stored = shown * scale
    property bool showValue: true
    property string leftLabel: ""
    property string rightLabel: ""
    property real sliderWidth: 220
    readonly property real stored: Number(Config.getSetting(key, def * scale)) / scale
    property real shown: stored
    onStoredChanged: if (!save.running) shown = stored
    spacing: 14
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    FText { visible: r.leftLabel !== ""; text: r.leftLabel; px: 13.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
    FSlider { width: r.sliderWidth; from: r.from; to: r.to; step: r.step; value: r.shown; anchors.verticalCenter: parent.verticalCenter
              onMoved: (v) => { r.shown = v; save.restart(); } }
    FText { visible: r.rightLabel !== ""; text: r.rightLabel; px: 13.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
    FText { visible: r.showValue; width: 44; horizontalAlignment: Text.AlignRight; text: Math.round(r.shown) + r.unit; mono: true; px: 13.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
    Timer { id: save; interval: 250; onTriggered: Config.setSetting(r.key, r.shown * r.scale) }
}
