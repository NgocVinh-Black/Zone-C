import QtQuick
import QtQuick.Layouts
import qs.core.services
import qs.core.state
import qs.core.theme
import qs.core.ui

// Forecast day picker, a big counting temperature, the day's description and four
// ring gauges (wind, humidity, rain chance, feels-like).
Item {
    id: root

    required property var popup

    readonly property var target: popup.forecast[popup.targetView] ?? null
    property real shownTemp: target ? target.max : 0
    readonly property bool counting: tempAnim.running

    width: UiScale.s(320)
    height: UiScale.s(420)

    Behavior on shownTemp {
        NumberAnimation {
            id: tempAnim

            duration: 800
            easing.type: Easing.OutQuart
        }
    }

    readonly property color tempColour: {
        if (!counting || !target)
            return Colours.text;
        if (target.max > shownTemp)
            return Colours.red;
        if (target.max < shownTemp)
            return Colours.blue;
        return Colours.text;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: UiScale.s(20)

        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignTop
            spacing: UiScale.s(20)

            NudgeArrow {
                glyph: String.fromCodePoint(0xF053)
                nudge: -1
                onActivated: root.popup.setView(root.popup.targetView - 1)
            }

            StyledText {
                Layout.preferredWidth: UiScale.s(110)
                horizontalAlignment: Text.AlignHCenter
                text: root.target ? Qt.formatDate(new Date(root.target.date + "T12:00:00"), "dddd").toUpperCase() : "LOADING..."
                font.pixelSize: Tokens.font.size.clock
                font.weight: Font.Black
            }

            NudgeArrow {
                glyph: String.fromCodePoint(0xF054)
                nudge: 1
                onActivated: root.popup.setView(root.popup.targetView + 1)
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignRight
            spacing: UiScale.s(-5)

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Math.round(root.shownTemp) + "°"
                font.pixelSize: UiScale.s(84)
                font.weight: Font.Black
                color: root.tempColour
                style: Text.Outline
                styleColor: root.counting ? Colours.alpha(root.tempColour, 0.5) : Colours.alpha(Colours.crust, 0.4)

                Behavior on color {
                    ColorAnimation { duration: 300 }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.popup.day ? root.popup.day.desc : ""
                font.pixelSize: Tokens.font.size.clock
                color: root.popup.textAccent
                opacity: root.popup.contentOpacity

                transform: Translate {
                    x: root.popup.contentOffset
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            Layout.rightMargin: UiScale.s(10)
            spacing: UiScale.s(20)

            Gauge {
                glyph: String.fromCodePoint(0xF059D)
                label: "WIND"
                value: root.target ? root.target.wind + "m/s" : ""
                fill: root.target ? Math.min(1, root.target.wind / 25) : 0
            }
            Gauge {
                glyph: String.fromCodePoint(0xF058E)
                label: "HUMID"
                value: root.target ? root.target.humidity + "%" : ""
                fill: root.target ? root.target.humidity / 100 : 0
            }
            Gauge {
                glyph: String.fromCodePoint(0xF058C)
                label: "RAIN"
                value: root.target ? root.target.pop + "%" : ""
                fill: root.target ? root.target.pop / 100 : 0
            }
            Gauge {
                glyph: String.fromCodePoint(0xF050F)
                label: "FEELS"
                value: root.target ? root.target.feelsLike + "°" : ""
                fill: root.target ? Math.max(0, Math.min(1, (root.target.feelsLike + 15) / 55)) : 0
            }
        }
    }

    component NudgeArrow: MouseArea {
        id: arrow

        property string glyph: ""
        property int nudge: 1
        property real pulse: 0

        signal activated

        width: UiScale.s(30)
        height: UiScale.s(30)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: activated()

        SequentialAnimation on pulse {
            loops: Animation.Infinite
            NumberAnimation { to: UiScale.s(3) * arrow.nudge; duration: 1000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0; duration: 1000; easing.type: Easing.InOutSine }
        }

        Icon {
            anchors.centerIn: parent
            text: arrow.glyph
            font.pixelSize: Tokens.font.size.title
            color: arrow.containsMouse ? root.popup.textAccent : Colours.overlay1

            transform: Translate {
                x: arrow.containsMouse ? UiScale.s(5) * arrow.nudge : arrow.pulse
            }
        }
    }

    component Gauge: Item {
        id: gauge

        property string glyph: ""
        property string label: ""
        property string value: ""
        property real fill: 0
        property real shownFill: fill

        width: UiScale.s(68)
        height: UiScale.s(100)
        scale: gaugeArea.containsMouse ? 1.15 : 1

        Behavior on scale {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutBack
            }
        }

        Behavior on shownFill {
            NumberAnimation {
                duration: 1000
                easing.type: Easing.OutExpo
            }
        }

        Rectangle {
            width: UiScale.s(68)
            height: width
            radius: width / 2
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.popup.textAccent
            opacity: gaugeArea.containsMouse ? 0.3 : 0

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
        }

        Canvas {
            id: ring

            property real progress: gauge.shownFill

            width: UiScale.s(68)
            height: width
            anchors.horizontalCenter: parent.horizontalCenter
            rotation: -90
            onProgressChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const r = width / 2;
                ctx.beginPath();
                ctx.arc(r, r, r - UiScale.s(4), 0, 2 * Math.PI);
                ctx.strokeStyle = Colours.alpha(Colours.text, 0.1).toString();
                ctx.lineWidth = UiScale.s(3);
                ctx.stroke();
                if (progress > 0) {
                    ctx.beginPath();
                    ctx.arc(r, r, r - UiScale.s(4), 0, progress * 2 * Math.PI);
                    const grad = ctx.createLinearGradient(0, 0, width, height);
                    grad.addColorStop(0, root.popup.timeAccent.toString());
                    grad.addColorStop(1, Colours.sapphire.toString());
                    ctx.strokeStyle = grad;
                    ctx.lineWidth = UiScale.s(4);
                    ctx.lineCap = "round";
                    ctx.stroke();
                }
            }
        }

        StyledText {
            anchors.centerIn: ring
            text: gauge.value
            font.weight: Font.Black
        }

        RowLayout {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: UiScale.s(4)

            Icon {
                text: gauge.glyph
                font.pixelSize: Tokens.font.size.body
                color: gaugeArea.containsMouse ? root.popup.textAccent : Colours.overlay0
            }

            StyledText {
                text: gauge.label
                font.pixelSize: Tokens.font.size.label
                color: Colours.overlay0
            }
        }

        MouseArea {
            id: gaugeArea

            anchors.fill: parent
            hoverEnabled: true
        }
    }
}
