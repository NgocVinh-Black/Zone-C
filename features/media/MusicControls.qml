import QtQuick
import QtQuick.Layouts
import qs.core.services
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.media

// Title (scrolling when long), artist, output device and source, the seek bar
// with a flowing gradient, and the transport buttons.
ColumnLayout {
    id: root

    property real textReveal: 1
    property real controlsReveal: 1
    property real flow: 0

    spacing: UiScale.s(15)

    NumberAnimation on flow {
        from: 0
        to: 1
        duration: 8000
        loops: Animation.Infinite
    }

    ColumnLayout {
        spacing: UiScale.s(6)
        opacity: root.textReveal

        transform: Translate {
            x: UiScale.s(30) * (1 - root.textReveal)
        }

        Item {
            id: titleClip

            readonly property int gap: UiScale.s(60)
            readonly property bool overflow: title.implicitWidth > width

            Layout.fillWidth: true
            Layout.preferredHeight: UiScale.s(28)
            clip: true

            Row {
                id: marquee

                spacing: titleClip.gap

                StyledText {
                    id: title

                    text: MediaService.title || "Nothing playing"
                    font.pixelSize: Tokens.font.size.large
                    onTextChanged: marquee.x = 0
                }

                StyledText {
                    visible: titleClip.overflow
                    text: title.text
                    font.pixelSize: Tokens.font.size.large
                }

                SequentialAnimation on x {
                    running: titleClip.overflow
                    loops: Animation.Infinite

                    PauseAnimation {
                        duration: 3000
                    }
                    NumberAnimation {
                        from: 0
                        to: -(title.implicitWidth + titleClip.gap)
                        duration: (title.implicitWidth + titleClip.gap) * 25
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: MediaService.artist ? "BY " + MediaService.artist : ""
            elide: Text.ElideRight
            maximumLineCount: 1
            color: Colours.subtext0
        }

        RowLayout {
            spacing: UiScale.s(10)

            Rectangle {
                Layout.preferredHeight: UiScale.s(24)
                Layout.preferredWidth: device.implicitWidth + UiScale.s(20)
                radius: UiScale.s(4)
                color: Colours.alpha(Colours.white, 0.1)

                RowLayout {
                    id: device

                    anchors.centerIn: parent
                    spacing: UiScale.s(6)

                    Icon {
                        text: String.fromCodePoint(0xF04C3)
                        font.pixelSize: Tokens.font.size.body
                        color: Colours.mauve
                    }

                    StyledText {
                        text: Audio.label(Audio.sink) || "Speaker"
                        font.pixelSize: Tokens.font.size.label
                        color: Colours.overlay2
                    }
                }
            }

            StyledText {
                text: "VIA " + MediaService.source
                font.pixelSize: Tokens.font.size.label
                font.italic: true
                color: Colours.overlay2
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: UiScale.s(5)
        opacity: root.controlsReveal

        transform: Translate {
            x: UiScale.s(20) * (1 - root.controlsReveal)
            y: UiScale.s(10) * (1 - root.controlsReveal)
        }

        Item {
            id: seek

            readonly property real shown: area.pressed ? area.dragValue : MediaService.percent

            Layout.fillWidth: true
            Layout.preferredHeight: UiScale.s(20)

            Rectangle {
                id: track

                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: UiScale.s(12)
                radius: height / 2
                color: Colours.alpha(Colours.surface0, 0.7)
                clip: true

                Rectangle {
                    width: Math.max(height, track.width * seek.shown / 100)
                    height: parent.height
                    radius: height / 2
                    clip: true

                    Rectangle {
                        width: UiScale.s(2000)
                        height: parent.height
                        x: -root.flow * UiScale.s(1000)

                        gradient: Gradient {
                            orientation: Gradient.Horizontal

                            GradientStop { position: 0; color: Qt.lighter(Colours.blue, 1.2) }
                            GradientStop { position: 0.1666; color: Qt.lighter(Colours.sapphire, 1.15) }
                            GradientStop { position: 0.3333; color: Qt.lighter(Colours.mauve, 1.15) }
                            GradientStop { position: 0.5; color: Qt.lighter(Colours.blue, 1.2) }
                            GradientStop { position: 0.6666; color: Qt.lighter(Colours.sapphire, 1.15) }
                            GradientStop { position: 0.8333; color: Qt.lighter(Colours.mauve, 1.15) }
                            GradientStop { position: 1; color: Qt.lighter(Colours.blue, 1.2) }
                        }
                    }
                }
            }

            Rectangle {
                width: UiScale.s(18)
                height: width
                radius: width / 2
                color: Colours.text
                anchors.verticalCenter: parent.verticalCenter
                x: (parent.width - width) * seek.shown / 100
                scale: area.pressed ? 1.3 : 1

                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutBack
                    }
                }
            }

            MouseArea {
                id: area

                property real dragValue: 0

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: mouse => dragValue = Math.max(0, Math.min(100, mouse.x / width * 100))
                onPositionChanged: mouse => dragValue = Math.max(0, Math.min(100, mouse.x / width * 100))
                onReleased: MediaService.seek(dragValue)
            }
        }

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: MediaService.positionText
                font.pixelSize: Tokens.font.size.pill
                color: Colours.overlay2
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: MediaService.lengthText
                font.pixelSize: Tokens.font.size.pill
                color: Colours.overlay2
            }
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: UiScale.s(30)
        opacity: root.controlsReveal

        transform: Translate {
            y: UiScale.s(20) * (1 - root.controlsReveal)
        }

        TransportButton {
            glyph: String.fromCodePoint(0xF048)
            onActivated: MediaService.previous()
        }

        Item {
            Layout.preferredWidth: UiScale.s(50)
            Layout.preferredHeight: UiScale.s(50)

            Rectangle {
                id: pulse

                anchors.fill: parent
                radius: width / 2
                color: Colours.mauve
                opacity: 0

                ParallelAnimation {
                    id: pulseAnim

                    NumberAnimation {
                        target: pulse
                        property: "scale"
                        from: 1
                        to: 1.8
                        duration: 500
                        easing.type: Easing.OutQuart
                    }
                    NumberAnimation {
                        target: pulse
                        property: "opacity"
                        from: 0.5
                        to: 0
                        duration: 500
                        easing.type: Easing.OutQuart
                    }
                }

                Connections {
                    target: MediaService

                    function onPlayingChanged(): void {
                        if (MediaService.playing)
                            pulseAnim.restart();
                    }
                }
            }

            Icon {
                anchors.centerIn: parent
                text: MediaService.playing ? String.fromCodePoint(0xF04C) : String.fromCodePoint(0xF04B)
                font.pixelSize: UiScale.s(42)
                color: playArea.pressed ? Colours.pink : Colours.mauve
                scale: playArea.pressed ? 0.8 : 1

                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutBack
                    }
                }
            }

            HoverArea {
                id: playArea

                onClicked: MediaService.playPause()
            }
        }

        TransportButton {
            glyph: String.fromCodePoint(0xF051)
            onActivated: MediaService.next()
        }
    }

    component TransportButton: Item {
        id: button

        property string glyph: ""

        signal activated

        Layout.preferredWidth: UiScale.s(30)
        Layout.preferredHeight: UiScale.s(30)

        Icon {
            anchors.centerIn: parent
            text: button.glyph
            font.pixelSize: Tokens.font.size.weatherIcon
            color: buttonArea.pressed ? Colours.text : Colours.overlay2
        }

        HoverArea {
            id: buttonArea

            onClicked: button.activated()
        }
    }
}
