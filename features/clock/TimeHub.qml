import QtQuick
import QtQuick.Layouts
import qs.core.services
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.clock

// The floating clock: breathes, levitates and wobbles in 3D, pulses every second,
// and carries a dashed orbit of hourly forecast pills. Anchored by its centre.
Item {
    id: root

    required property var popup
    property real reveal: 1

    property real levitation: 0
    property real breath: 1
    property real pitch: 0
    property real yaw: 0
    property real roll: 0
    property real secondPulse: 1

    readonly property var hours: popup.day ? popup.day.hourly : []
    readonly property bool isToday: popup.weatherView === 0
    readonly property int currentHour: isToday ? Weather.nearestHour(hours, ClockService.now.getHours()) : -1

    width: 1
    height: 1
    opacity: reveal
    scale: 0.85 + 0.15 * reveal

    transform: [
        Translate {
            y: Scale.s(25) * (1 - root.reveal) + root.levitation
        },
        Rotation {
            axis { x: 1; y: 0; z: 0 }
            angle: root.pitch
        },
        Rotation {
            axis { x: 0; y: 1; z: 0 }
            angle: root.yaw
        },
        Rotation {
            axis { x: 0; y: 0; z: 1 }
            angle: root.roll
        }
    ]

    SequentialAnimation on levitation {
        loops: Animation.Infinite
        NumberAnimation { to: Scale.s(-15); duration: 4000; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 4000; easing.type: Easing.InOutSine }
    }
    SequentialAnimation on breath {
        loops: Animation.Infinite
        NumberAnimation { to: 1.035; duration: 3500; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 3500; easing.type: Easing.InOutSine }
    }
    SequentialAnimation on pitch {
        loops: Animation.Infinite
        NumberAnimation { to: 3.5; duration: 4200; easing.type: Easing.InOutSine }
        NumberAnimation { to: -3.5; duration: 4200; easing.type: Easing.InOutSine }
    }
    SequentialAnimation on yaw {
        loops: Animation.Infinite
        NumberAnimation { to: 2.5; duration: 5100; easing.type: Easing.InOutSine }
        NumberAnimation { to: -2.5; duration: 5100; easing.type: Easing.InOutSine }
    }
    SequentialAnimation on roll {
        loops: Animation.Infinite
        NumberAnimation { to: 1.5; duration: 5800; easing.type: Easing.InOutSine }
        NumberAnimation { to: -1.5; duration: 5800; easing.type: Easing.InOutSine }
    }

    Connections {
        target: ClockService

        function onNowChanged(): void {
            root.secondPulse = 1.06;
            pulseBack.restart();
        }
    }

    NumberAnimation {
        id: pulseBack

        target: root
        property: "secondPulse"
        to: 1
        duration: 600
        easing.type: Easing.OutQuint
    }

    Canvas {
        id: orbitPath

        property real breath: root.breath

        x: Scale.s(-400)
        y: Scale.s(-200)
        z: -10
        width: Scale.s(800)
        height: Scale.s(400)
        opacity: 0.25

        onBreathChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.beginPath();
            const rx = Scale.s(320) * breath;
            const ry = Scale.s(140) * breath;
            for (let a = 0; a <= Math.PI * 2; a += 0.05) {
                const px = width / 2 + Math.cos(a) * rx;
                const py = height / 2 + Math.sin(a) * ry;
                if (a === 0)
                    ctx.moveTo(px, py);
                else
                    ctx.lineTo(px, py);
            }
            ctx.strokeStyle = root.popup.textAccent.toString();
            ctx.lineWidth = Scale.s(1.5);
            ctx.setLineDash([Scale.s(4), Scale.s(10)]);
            ctx.stroke();
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0
        scale: 0.95 + 0.05 * root.secondPulse

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Scale.s(2)

            StyledText {
                text: Qt.formatTime(ClockService.now, "HH:mm")
                font.pixelSize: Scale.s(84)
                font.weight: Font.Black
                style: Text.Outline
                styleColor: Colours.alpha(Colours.crust, 0.4)
            }

            StyledText {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: Scale.s(15)
                text: Qt.formatTime(ClockService.now, ":ss")
                font.pixelSize: Scale.s(32)
                color: root.popup.textAccent
                opacity: root.secondPulse > 1.02 ? 1 : 0.6
                style: Text.Outline
                styleColor: Colours.alpha(Colours.crust, 0.4)
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(ClockService.now, "dddd, MMMM dd")
            font.pixelSize: Tokens.font.size.clock
            color: Colours.subtext0
            opacity: 0.9
        }
    }

    Item {
        opacity: root.popup.contentOpacity
        scale: root.popup.spinScale

        transform: Translate {
            x: root.popup.contentOffset * 1.5
        }

        Repeater {
            model: root.hours

            delegate: Item {
                id: pill

                required property var modelData
                required property int index

                readonly property bool highlighted: root.isToday && index === root.currentHour
                readonly property real angleDeg: root.isToday ? 65 + (index - root.currentHour) * 30 : index * 360 / Math.max(1, root.hours.length)
                readonly property real drift: root.isToday ? Math.sin(root.popup.orbitAngle * 10 + index) * 5 : -root.popup.orbitAngle * 180 / Math.PI * 1.5
                readonly property real rad: (angleDeg + drift + root.popup.spin) * Math.PI / 180
                readonly property real depth: Math.sin(rad)

                width: Scale.s(56)
                height: Scale.s(95)
                x: Math.cos(rad) * Scale.s(320) * root.breath - width / 2
                y: depth * Scale.s(140) * root.breath - height / 2
                z: depth * 100
                scale: highlighted ? 1.4 : (root.isToday ? 0.95 + 0.2 * depth : 0.9 + 0.25 * depth)
                opacity: highlighted ? 1 : (root.isToday ? 0.7 + 0.15 * (depth + 1) : 0.65 + 0.175 * (depth + 1))

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: pill.highlighted ? root.popup.textAccent : (hourArea.containsMouse ? Colours.surface2 : Colours.surface0)
                    border.color: pill.highlighted ? "transparent" : (hourArea.containsMouse ? root.popup.textAccent : Colours.surface1)
                    border.width: 1

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Scale.s(4)

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: pill.modelData.time
                            font.pixelSize: Tokens.font.size.label
                            color: pill.highlighted ? Colours.base : (hourArea.containsMouse ? Colours.text : Colours.overlay1)
                        }

                        Icon {
                            Layout.alignment: Qt.AlignHCenter
                            text: pill.modelData.icon
                            font.pixelSize: Tokens.font.size.title
                            color: pill.highlighted ? Colours.base : Colours[pill.modelData.tone]
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: pill.modelData.temp + "°"
                            font.weight: Font.Black
                            color: pill.highlighted ? Colours.base : Colours.text
                        }
                    }
                }

                MouseArea {
                    id: hourArea

                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
        }
    }
}
