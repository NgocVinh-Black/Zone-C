import QtQuick
import QtQuick.Layouts
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.clock
import "CalendarLogic.js" as Logic

// Glass month calendar: header with month switching and a "back to today" button,
// weekday names and a 6×7 day grid that slides when the month changes.
Rectangle {
    id: root

    required property var popup

    property int monthOffset: 0
    property int targetOffset: 0
    property real contentOpacity: 1
    property real contentOffset: 0
    property int direction: 1

    readonly property bool hovered: hover.hovered
    readonly property var grid: Logic.monthGrid(ClockService.now, monthOffset)

    function shiftMonth(delta: int): void {
        setMonth(targetOffset + delta);
    }

    function setMonth(offset: int): void {
        if (offset === targetOffset)
            return;
        if (slide.running) {
            slide.stop();
            monthOffset = targetOffset;
        }
        direction = offset > targetOffset ? 1 : -1;
        targetOffset = offset;
        slide.start();
    }

    width: Scale.s(320)
    height: Scale.s(420)
    radius: Scale.s(14)
    color: Colours.alpha(Colours.surface0, 0.2)
    border.color: Colours.alpha(Colours.surface1, 0.4)
    border.width: 1

    HoverHandler {
        id: hover
    }

    SequentialAnimation {
        id: slide

        ParallelAnimation {
            NumberAnimation { target: root; property: "contentOpacity"; to: 0; duration: 200; easing.type: Easing.InSine }
            NumberAnimation { target: root; property: "contentOffset"; to: Scale.s(-20) * root.direction; duration: 200; easing.type: Easing.InSine }
        }
        ScriptAction {
            script: {
                root.monthOffset = root.targetOffset;
                root.contentOffset = Scale.s(20) * root.direction;
            }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "contentOpacity"; to: 1; duration: 350; easing.type: Easing.OutQuart }
            NumberAnimation { target: root; property: "contentOffset"; to: 0; duration: 350; easing.type: Easing.OutQuart }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Scale.s(25)
        spacing: Scale.s(15)

        RowLayout {
            Layout.fillWidth: true

            RoundButton {
                glyph: String.fromCodePoint(0xF00ED)
                opacity: root.targetOffset !== 0 ? 1 : 0
                enabled: root.targetOffset !== 0
                onActivated: root.setMonth(0)

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }

            RoundButton {
                glyph: String.fromCodePoint(0xF104)
                onActivated: root.shiftMonth(-1)
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(root.grid.first, "MMMM yyyy").toUpperCase()
                font.pixelSize: Tokens.font.size.clock
                font.weight: Font.Black
                opacity: root.contentOpacity

                transform: Translate {
                    x: root.contentOffset
                }
            }

            RoundButton {
                glyph: String.fromCodePoint(0xF105)
                onActivated: root.shiftMonth(1)
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                StyledText {
                    required property string modelData

                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.weight: Font.Black
                    color: Colours.overlay0
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rowSpacing: Scale.s(6)
            columnSpacing: Scale.s(6)
            opacity: root.contentOpacity

            transform: Translate {
                x: root.contentOffset
            }

            Repeater {
                model: root.grid.cells

                delegate: Rectangle {
                    id: cell

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Scale.s(10)
                    color: modelData.today ? root.popup.textAccent : (dayArea.containsMouse ? Colours.alpha(Colours.surface2, 0.4) : "transparent")
                    border.color: modelData.today ? Colours.surface0 : (dayArea.containsMouse ? Colours.overlay0 : "transparent")
                    border.width: modelData.today || dayArea.containsMouse ? 1 : 0
                    scale: dayArea.containsMouse ? 1.2 : 1

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutBack
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: cell.modelData.day
                        font.weight: cell.modelData.today ? Font.Black : Font.Bold
                        color: cell.modelData.today ? Colours.base : (cell.modelData.currentMonth ? Colours.text : Colours.surface0)
                    }

                    MouseArea {
                        id: dayArea

                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }
            }
        }
    }

    component RoundButton: Rectangle {
        id: button

        property string glyph: ""

        signal activated

        Layout.preferredWidth: Scale.s(32)
        Layout.preferredHeight: Scale.s(32)
        radius: width / 2
        color: buttonArea.containsMouse ? Colours.surface1 : "transparent"

        Icon {
            anchors.centerIn: parent
            text: button.glyph
            font.pixelSize: Tokens.font.size.clock
        }

        HoverArea {
            id: buttonArea

            onClicked: button.activated()
        }
    }
}
