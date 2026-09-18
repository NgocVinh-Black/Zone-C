import QtQuick
import qs.core.services
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.clock
import "CalendarLogic.js" as Logic

// Calendar on the left, a floating clock orbited by hourly forecasts in the middle,
// daily weather stats on the right and an optional schedule strip at the bottom.
// Left/Right switch the forecast day, or the month while the calendar is hovered.
Item {
    id: root

    property var screen: null
    property string arg: ""

    readonly property var tones: Logic.timeTones(ClockService.now.getHours())
    readonly property color timeColor: Colours[tones[0]]
    readonly property color timeAccent: Colours[tones[1]]
    readonly property color textAccent: Qt.tint(timeAccent, Colours.alpha(Colours.text, 0.35))

    readonly property var forecast: Weather.forecast
    property int weatherView: 0
    property int targetView: 0
    readonly property var day: forecast[weatherView] ?? null
    readonly property color weatherTone: day ? Colours[day.tone] : Colours.mauve

    // Forecast day switch: content slides and fades, the orbit spins through.
    property real contentOpacity: 1
    property real contentOffset: 0
    property real spin: 0
    property real spinScale: 1
    property int direction: 1

    property real orbitAngle: 0

    focus: true

    Keys.onLeftPressed: calendar.hovered ? calendar.shiftMonth(-1) : setView(targetView - 1)
    Keys.onRightPressed: calendar.hovered ? calendar.shiftMonth(1) : setView(targetView + 1)

    function setView(index: int): void {
        if (index < 0 || index >= forecast.length || index === targetView)
            return;
        if (switchAnim.running) {
            switchAnim.stop();
            weatherView = targetView;
        }
        direction = index > weatherView ? 1 : -1;
        targetView = index;
        switchAnim.start();
    }

    Reveal {
        id: introMain
        delay: 20
    }
    Reveal {
        id: introAmbient
        delay: 170
        duration: 1000
        easingType: Easing.OutSine
    }
    Reveal {
        id: introClock
        delay: 270
        duration: 900
        overshoot: 1.15
    }
    Reveal {
        id: introCalendar
        delay: 370
        duration: 850
        easingType: Easing.OutQuint
    }
    Reveal {
        id: introWeather
        delay: 420
        duration: 850
        easingType: Easing.OutQuint
    }

    NumberAnimation on orbitAngle {
        from: 0
        to: Math.PI * 2
        duration: Tokens.anim.orbit
        loops: Animation.Infinite
    }

    SequentialAnimation {
        id: switchAnim

        ParallelAnimation {
            NumberAnimation { target: root; property: "contentOpacity"; to: 0; duration: 250; easing.type: Easing.InSine }
            NumberAnimation { target: root; property: "contentOffset"; to: Scale.s(-40) * root.direction; duration: 250; easing.type: Easing.InSine }
            NumberAnimation { target: root; property: "spin"; to: 180 * root.direction; duration: 300; easing.type: Easing.InBack }
            NumberAnimation { target: root; property: "spinScale"; to: 0.8; duration: 300; easing.type: Easing.InCubic }
        }
        ScriptAction {
            script: {
                root.weatherView = root.targetView;
                root.contentOffset = Scale.s(40) * root.direction;
                root.spin = -180 * root.direction;
            }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "contentOpacity"; to: 1; duration: 450; easing.type: Easing.OutQuart }
            NumberAnimation { target: root; property: "contentOffset"; to: 0; duration: 450; easing.type: Easing.OutQuart }
            NumberAnimation { target: root; property: "spin"; to: 0; duration: 600; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            NumberAnimation { target: root; property: "spinScale"; to: 1; duration: 500; easing.type: Easing.OutBack }
        }
    }

    Item {
        anchors.fill: parent
        scale: 0.95 + 0.05 * introMain.value
        opacity: introMain.value

        Rectangle {
            anchors.fill: parent
            radius: Tokens.popup.radius
            color: Colours.base
            border.color: Colours.surface0
            border.width: 1
            clip: true

            Blob {
                size: parent.width * 0.5
                centerX: parent.width * 0.75 + Math.cos(root.orbitAngle * 1.5) * Scale.s(350)
                centerY: parent.height * 0.3 + Math.sin(root.orbitAngle * 1.5) * Scale.s(200)
                opacity: 0.025 * introAmbient.value
                color: root.weatherTone
            }

            Blob {
                size: parent.width * 0.6
                centerX: parent.width * 0.25 - Math.sin(root.orbitAngle * 1.2) * Scale.s(300)
                centerY: parent.height * 0.7 - Math.cos(root.orbitAngle * 1.2) * Scale.s(250)
                opacity: 0.02 * introAmbient.value
                color: root.timeColor
            }

            Blob {
                size: parent.width * 0.45
                centerX: parent.width * 0.5 + Math.cos(-root.orbitAngle * 1.8) * Scale.s(400)
                centerY: parent.height * 0.5 - Math.sin(-root.orbitAngle * 1.8) * Scale.s(350)
                opacity: 0.015 * introAmbient.value
                color: root.timeAccent
            }

            // Huge faint weather glyph drifting behind everything.
            Icon {
                id: backdrop

                property real drift: 0

                anchors.centerIn: parent
                anchors.verticalCenterOffset: ClockService.hasSchedule ? Scale.s(-100) : 0
                text: root.day ? root.day.icon : ""
                font.pixelSize: Scale.s(800)
                color: root.weatherTone
                opacity: (0.03 + 0.01 * Math.sin(root.orbitAngle * 4)) * introAmbient.value * root.contentOpacity

                transform: [
                    Translate {
                        y: backdrop.drift
                    },
                    Translate {
                        x: root.contentOffset * 2
                    }
                ]

                SequentialAnimation on drift {
                    loops: Animation.Infinite
                    NumberAnimation { to: Scale.s(-20); duration: 6000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0; duration: 6000; easing.type: Easing.InOutSine }
                }
            }

            TimeHub {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: ClockService.hasSchedule ? Scale.s(-100) : 0
                z: 5
                popup: root
                reveal: introClock.value
            }

            CalendarGrid {
                id: calendar

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: Scale.s(40)
                z: 10
                popup: root
                opacity: introCalendar.value

                transform: Translate {
                    x: Scale.s(-40) * (1 - introCalendar.value)
                }
            }

            WeatherStats {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Scale.s(40)
                z: 10
                popup: root
                opacity: introWeather.value

                transform: Translate {
                    x: Scale.s(40) * (1 - introWeather.value)
                }
            }

            Loader {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Scale.s(240)
                z: 20
                active: ClockService.hasSchedule
                sourceComponent: ScheduleStrip {
                    popup: root
                }
            }
        }
    }

    component Blob: Rectangle {
        property real size: 0
        property real centerX: 0
        property real centerY: 0

        width: size
        height: size
        radius: size / 2
        x: centerX - size / 2
        y: centerY - size / 2

        Behavior on color {
            ColorAnimation { duration: 1000 }
        }
    }
}
