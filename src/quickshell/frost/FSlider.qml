import QtQuick

// `.rng`: range input drawn with the accent colour (accent-color: var(--acc)).
Item {
    id: root
    property real from: 0
    property real to: 100
    property real value: 0
    property real step: 1
    signal moved(real value)
    implicitWidth: 220
    implicitHeight: 18
    readonly property real frac: to > from ? (value - from) / (to - from) : 0

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: 8; width: parent.width - 16; height: 4; radius: 2
        color: Fz.fg(0.22)
        Rectangle { width: parent.width * root.frac; height: parent.height; radius: 2; color: Fz.acc }
    }
    Rectangle {
        width: 16; height: 16; radius: 8
        x: 8 + (root.width - 16) * root.frac - 8
        anchors.verticalCenter: parent.verticalCenter
        color: Fz.acc
        border.width: 2; border.color: Fz.light ? "#ffffff" : Fz.ink
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function set(mx) {
            let f = Math.max(0, Math.min(1, (mx - 8) / (root.width - 16)));
            let v = root.from + f * (root.to - root.from);
            v = Math.round(v / root.step) * root.step;
            if (v !== root.value) { root.value = v; root.moved(v); }
        }
        onPressed: (e) => set(e.x)
        onPositionChanged: (e) => { if (pressed) set(e.x); }
        onWheel: (e) => { let v = Math.max(root.from, Math.min(root.to, root.value + (e.angleDelta.y > 0 ? root.step : -root.step) * 5)); root.value = v; root.moved(v); }
    }
}
