import QtQuick

// Press-and-hold to confirm, as in v1: holding fills `level` towards 1 and emits
// `confirmed` when full; releasing early drains it back.
MouseArea {
    id: root

    property real level: 0
    property int holdDuration: 600
    property int drainDuration: 1500
    // After confirming, stay full until `reset()` is called.
    property bool latched: false

    signal confirmed

    function reset(): void {
        latched = false;
        fill.stop();
        drain.start();
    }

    hoverEnabled: true
    cursorShape: enabled && !latched ? Qt.PointingHandCursor : Qt.ArrowCursor

    onPressed: {
        if (latched)
            return;
        drain.stop();
        fill.start();
    }

    onReleased: {
        if (latched || level >= 1)
            return;
        fill.stop();
        drain.start();
    }

    NumberAnimation {
        id: fill

        target: root
        property: "level"
        to: 1
        duration: Math.max(1, root.holdDuration * (1 - root.level))
        easing.type: Easing.InSine
        onFinished: {
            root.latched = true;
            root.confirmed();
        }
    }

    NumberAnimation {
        id: drain

        target: root
        property: "level"
        to: 0
        duration: Math.max(1, root.drainDuration * root.level)
        easing.type: Easing.OutQuad
    }
}
