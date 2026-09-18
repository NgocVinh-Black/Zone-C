import QtQuick

// A 0 → 1 value that starts after `delay`, for staggered entrance animations:
//   Reveal { id: header; delay: 100; overshoot: 1.0 }
//   opacity: header.value
Item {
    id: root

    property real value: 0
    property int delay: 0
    property int duration: 800
    property int easingType: Easing.OutQuart
    property real overshoot: -1

    visible: false

    SequentialAnimation {
        running: true

        PauseAnimation {
            duration: root.delay
        }

        NumberAnimation {
            target: root
            property: "value"
            from: 0
            to: 1
            duration: root.duration
            easing.type: root.overshoot >= 0 ? Easing.OutBack : root.easingType
            easing.overshoot: root.overshoot >= 0 ? root.overshoot : 1.70158
        }
    }
}
