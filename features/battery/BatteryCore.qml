import QtQuick
import QtQuick.Layouts
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.battery

// The breathing battery orb: a gradient ring filled to the charge level, with a
// travelling surge while charging (or a drain shimmer) when hovered.
Item {
    id: root

    property color colourStart: Colours.blue
    property color colourEnd: Qt.lighter(colourStart, 1.15)

    readonly property bool danger: !BatteryService.charging && BatteryService.percent < 15
    readonly property bool hovered: area.containsMouse

    property real shownPercent: BatteryService.percent
    property real textPulse: 0
    property real pump: 0
    property real drain: 1

    width: UiScale.s(260)
    height: width

    Behavior on shownPercent {
        NumberAnimation {
            duration: 1200
            easing.type: Easing.OutQuint
        }
    }

    SequentialAnimation on textPulse {
        loops: Animation.Infinite
        NumberAnimation { from: 0; to: 1; duration: 1200; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1; to: 0; duration: 1200; easing.type: Easing.InOutSine }
    }

    NumberAnimation on pump {
        running: root.hovered && BatteryService.charging
        loops: Animation.Infinite
        from: 0
        to: 1
        duration: 1200
        easing.type: Easing.InOutSine
    }

    NumberAnimation on drain {
        running: root.hovered && !BatteryService.charging
        loops: Animation.Infinite
        from: 1
        to: 0
        duration: 1600
        easing.type: Easing.InOutSine
    }

    // Glow halo.
    Rectangle {
        anchors.centerIn: parent
        width: parent.width + UiScale.s(45)
        height: width
        radius: width / 2
        color: root.danger ? Colours.red : root.colourStart
        opacity: root.danger ? 0.25 : 0.15

        Behavior on color {
            ColorAnimation { duration: 400 }
        }

        SequentialAnimation on scale {
            loops: Animation.Infinite
            NumberAnimation { to: root.hovered ? 1.15 : 1.08; duration: root.hovered ? 800 : 2000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: root.hovered ? 800 : 2000; easing.type: Easing.InOutSine }
        }
    }

    Rectangle {
        id: orb

        anchors.fill: parent
        radius: width / 2

        gradient: Gradient {
            GradientStop { position: 0; color: Colours.surface0 }
            GradientStop { position: 1; color: Colours.base }
        }

        SequentialAnimation on scale {
            loops: Animation.Infinite
            NumberAnimation { to: root.hovered ? 1.05 : (root.danger ? 1.04 : 1.01); duration: root.hovered ? 1200 : (root.danger ? 600 : 2500); easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: root.hovered ? 1200 : (root.danger ? 600 : 2500); easing.type: Easing.InOutSine }
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Colours.maroon
            opacity: root.danger ? 0.2 : 0

            Behavior on opacity {
                NumberAnimation { duration: 1000 }
            }
        }

        Canvas {
            id: ring

            anchors.fill: parent
            rotation: 180

            Connections {
                target: root

                function onShownPercentChanged(): void {
                    ring.requestPaint();
                }
                function onPumpChanged(): void {
                    ring.requestPaint();
                }
                function onDrainChanged(): void {
                    ring.requestPaint();
                }
                function onColourStartChanged(): void {
                    ring.requestPaint();
                }
                function onHoveredChanged(): void {
                    ring.requestPaint();
                }
            }

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const cx = width / 2;
                const cy = height / 2;
                const r = width / 2 - UiScale.s(18);
                const end = root.shownPercent / 100 * 2 * Math.PI;
                const start = root.colourStart.toString();
                const finish = root.colourEnd.toString();

                ctx.lineCap = "round";
                ctx.lineWidth = UiScale.s(8);
                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                ctx.strokeStyle = Colours.alpha(Colours.white, 0.05).toString();
                ctx.stroke();

                const grad = ctx.createLinearGradient(0, height, width, 0);
                grad.addColorStop(0, start);
                grad.addColorStop(1, finish);
                ctx.lineWidth = UiScale.s(14);
                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, end);
                ctx.strokeStyle = grad;
                ctx.stroke();

                if (!root.hovered || end <= 0.1)
                    return;

                if (BatteryService.charging) {
                    const surge = root.pump * (end + 0.6) - 0.3;
                    if (surge > 0 && surge < end) {
                        ctx.globalAlpha = 0.5 * Math.sin(root.pump * Math.PI);
                        ctx.lineWidth = UiScale.s(22);
                        ctx.strokeStyle = start;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, Math.max(0, surge - 0.4), Math.min(end, surge + 0.4));
                        ctx.stroke();

                        ctx.globalAlpha = 0.8 * Math.sin(root.pump * Math.PI);
                        ctx.lineWidth = UiScale.s(28);
                        ctx.strokeStyle = finish;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, Math.max(0, surge - 0.2), Math.min(end, surge + 0.2));
                        ctx.stroke();
                    }
                    if (root.pump > 0.7) {
                        const flare = (root.pump - 0.7) / 0.3;
                        ctx.globalAlpha = (1 - flare) * 0.6;
                        ctx.fillStyle = finish;
                        ctx.beginPath();
                        ctx.arc(cx + Math.cos(end) * r, cy + Math.sin(end) * r, UiScale.s(7) + flare * UiScale.s(15), 0, 2 * Math.PI);
                        ctx.fill();
                    }
                } else {
                    const centre = root.drain * end;
                    for (let d = 0; d < 2; d++) {
                        const spread = 0.2 + d * 0.15;
                        const a = Math.max(0, centre - spread);
                        const b = Math.min(end, centre + spread);
                        if (a >= b)
                            continue;
                        ctx.globalAlpha = 0.2 * Math.sin(root.drain * Math.PI);
                        ctx.lineWidth = UiScale.s(14) + (1 - d) * UiScale.s(2);
                        ctx.strokeStyle = finish;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, a, b);
                        ctx.stroke();
                    }
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: UiScale.s(-2)

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: UiScale.s(8)

                Icon {
                    text: BatteryService.charging ? String.fromCodePoint(0xF0084) : (BatteryService.percent > 20 ? String.fromCodePoint(0xF0079) : String.fromCodePoint(0xF0083))
                    font.pixelSize: UiScale.s(28)
                    color: root.colourStart
                }

                StyledText {
                    text: Math.round(root.shownPercent) + "%"
                    font.pixelSize: UiScale.s(54)
                    font.weight: Font.Black
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: BatteryService.stateText.toUpperCase()
                font.pixelSize: Tokens.font.size.pill
                color: BatteryService.charging ? Qt.tint(Colours.green, Colours.alpha(Colours.white, root.textPulse * 0.4)) : (root.danger ? Qt.tint(Colours.red, Colours.alpha(Colours.white, root.textPulse * 0.3)) : Colours.subtext0)
            }
        }

        MouseArea {
            id: area

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }
    }
}
