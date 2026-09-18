import QtQuick
import QtQuick.Layouts
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.clock

// Optional bottom strip of the calendar popup: flowing waves behind a horizontal
// timeline of the day's lessons from `scheduleCommand`.
Item {
    id: root

    required property var popup

    readonly property var schedule: ClockService.schedule
    readonly property real nowEpoch: ClockService.now.getTime() / 1000

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 1; color: Colours.alpha(Colours.crust, 0.6) }
        }
    }

    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Colours.alpha(Colours.surface1, 0.5)
    }

    Item {
        anchors.fill: parent
        opacity: 0.15
        clip: true

        Wave { period: Scale.s(100); amplitude: Scale.s(30); colour: Colours.mauve; duration: 4000 }
        Wave { period: Scale.s(120); amplitude: Scale.s(40); colour: Colours.sapphire; duration: 5500; reverse: true }
        Wave { period: Scale.s(80); amplitude: Scale.s(20); colour: Colours.peach; duration: 7000 }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Scale.s(25)
        spacing: Scale.s(15)

        RowLayout {
            Layout.fillWidth: true
            spacing: Scale.s(15)

            Rectangle {
                Layout.preferredWidth: Scale.s(40)
                Layout.preferredHeight: Scale.s(40)
                radius: width / 2
                color: Colours.surface0

                Icon {
                    anchors.centerIn: parent
                    text: String.fromCodePoint(0xF073)
                    font.pixelSize: Tokens.font.size.title
                    color: root.popup.textAccent
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.schedule.header
                font.pixelSize: Tokens.font.size.clock
                color: Colours.overlay0
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.preferredWidth: Scale.s(120)
                Layout.preferredHeight: Scale.s(36)
                radius: Scale.s(10)
                visible: root.schedule.link !== ""
                color: linkArea.containsMouse ? Colours.mauve : Colours.alpha(Colours.surface1, 0.5)
                border.color: Colours.mauve
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Scale.s(6)

                    StyledText {
                        text: "Open Web"
                        color: linkArea.containsMouse ? Colours.base : Colours.text
                    }

                    Icon {
                        text: String.fromCodePoint(0xF08E)
                        font.pixelSize: Tokens.font.size.body
                        color: linkArea.containsMouse ? Colours.base : Colours.text
                    }
                }

                HoverArea {
                    id: linkArea

                    onClicked: Qt.openUrlExternally(root.schedule.link)
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StyledText {
                anchors.centerIn: parent
                visible: root.schedule.lessons.length === 0
                text: "No scheduled events."
                font.italic: true
                font.weight: Font.Normal
                color: Colours.overlay0
            }

            Flickable {
                id: timeline

                // Spread the day's first to last lesson across the visible width.
                readonly property var lessons: root.schedule.lessons
                readonly property real startEpoch: lessons.length > 0 ? lessons[0].start : 0
                readonly property real endEpoch: lessons.length > 0 ? lessons[lessons.length - 1].end : 1
                readonly property real pxPerSecond: width / Math.max(1, endEpoch - startEpoch)

                anchors.fill: parent
                visible: lessons.length > 0
                clip: true
                contentWidth: width
                flickableDirection: Flickable.HorizontalFlick

                Repeater {
                    model: timeline.lessons

                    delegate: Item {
                        id: lesson

                        required property var modelData
                        readonly property bool active: root.nowEpoch >= modelData.start && root.nowEpoch <= modelData.end
                        readonly property bool past: root.nowEpoch > modelData.end

                        x: (modelData.start - timeline.startEpoch) * timeline.pxPerSecond
                        width: Math.max(1, (modelData.end - modelData.start) * timeline.pxPerSecond)
                        height: timeline.height
                        opacity: past ? 0.5 : 1

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.topMargin: Scale.s(10)
                            anchors.bottomMargin: Scale.s(10)
                            width: 1
                            color: Colours.alpha(Colours.surface1, 0.6)
                        }

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.leftMargin: Scale.s(12)
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Scale.s(4)

                            StyledText {
                                Layout.fillWidth: true
                                text: lesson.modelData.title ?? ""
                                font.pixelSize: Tokens.font.size.clock
                                font.weight: Font.Black
                                color: lesson.active ? root.popup.textAccent : Colours.text
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: String.fromCodePoint(0xF0150) + "  " + Qt.formatTime(new Date(lesson.modelData.start * 1000), "HH:mm") + "-" + Qt.formatTime(new Date(lesson.modelData.end * 1000), "HH:mm")
                                font.pixelSize: Tokens.font.size.label
                                color: Colours.subtext0
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: lesson.modelData.location ? String.fromCodePoint(0xF034E) + "  " + lesson.modelData.location : ""
                                font.pixelSize: Tokens.font.size.label
                                color: Colours.overlay0
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }

    component Wave: Canvas {
        id: wave

        property real period: 100
        property real amplitude: 20
        property color colour: Colours.mauve
        property int duration: 4000
        property bool reverse: false
        readonly property real waveLength: period * 2 * Math.PI

        width: parent.width + waveLength
        height: parent.height
        onWidthChanged: requestPaint()

        NumberAnimation on x {
            from: wave.reverse ? -wave.waveLength : 0
            to: wave.reverse ? 0 : -wave.waveLength
            duration: wave.duration
            loops: Animation.Infinite
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const cy = height / 2;
            ctx.beginPath();
            ctx.moveTo(0, cy);
            for (let i = 0; i <= width + Scale.s(20); i += Scale.s(10))
                ctx.lineTo(i, cy + Math.sin(i / period) * amplitude);
            ctx.strokeStyle = colour.toString();
            ctx.lineWidth = Scale.s(2);
            ctx.stroke();
        }
    }
}
