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
    // while dragging the thumb follows the pointer; otherwise it shows `value`, which stays bound to
    // the owner's source (a setting, the system volume) instead of being overwritten here
    property real dragValue: 0
    readonly property real shown: drag.pressed ? dragValue : value
    readonly property real frac: to > from ? (shown - from) / (to - from) : 0

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
    // an owner that does not follow moved() keeps the dropped value
    Timer { id: settle; interval: 400; onTriggered: if (Math.abs(root.value - root.dragValue) > root.step / 2) root.value = root.dragValue }
    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function set(mx) {
            let f = Math.max(0, Math.min(1, (mx - 8) / (root.width - 16)));
            let v = root.from + f * (root.to - root.from);
            v = Math.round(v / root.step) * root.step;
            if (v !== root.dragValue || !pressed) { root.dragValue = v; root.moved(v); }
        }
        onPressed: (e) => { root.dragValue = root.value; set(e.x); }
        onReleased: settle.restart()
        onPositionChanged: (e) => { if (pressed) set(e.x); }
        onWheel: (e) => { let v = Math.max(root.from, Math.min(root.to, root.value + (e.angleDelta.y > 0 ? root.step : -root.step) * 5)); root.dragValue = v; root.moved(v); settle.restart(); }
    }
}
