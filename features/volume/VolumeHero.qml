import QtQuick
import QtQuick.Layouts
import qs.core.services
import qs.core.state
import qs.core.theme
import qs.core.ui

// The selected device: a round liquid gauge (click to mute), its name and a master slider.
RowLayout {
    id: root

    property var node: null
    property color accent: Colours.blue
    property string subtitle: ""

    readonly property int volume: Math.round((node?.audio?.volume ?? 0) * 100)
    readonly property bool muted: node?.audio?.muted ?? false

    spacing: UiScale.s(25)

    Item {
        Layout.preferredWidth: UiScale.s(130)
        Layout.preferredHeight: UiScale.s(130)

        // Soft halo and a breathing ring.
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + UiScale.s(40)
            height: width
            radius: width / 2
            color: root.muted ? Colours.red : root.accent
            opacity: root.muted ? 0.3 : 0.15

            Behavior on color {
                ColorAnimation { duration: 300 }
            }
        }

        Rectangle {
            id: ring

            anchors.centerIn: parent
            width: parent.width + UiScale.s(15)
            height: width
            radius: width / 2
            color: "transparent"
            border.color: root.accent
            border.width: UiScale.s(3)
            opacity: root.muted ? 0 : 0.3

            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { to: 1.04; duration: 1300; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 1300; easing.type: Easing.InOutSine }
            }
        }

        Rectangle {
            id: core

            anchors.fill: parent
            radius: width / 2
            color: Colours.base
            border.color: root.muted ? Colours.red : Qt.lighter(root.accent, 1.1)
            border.width: 2
            clip: true

            WaveFill {
                anchors.fill: parent
                shape: "circle"
                level: root.muted ? 0 : Math.min(100, root.volume) / 100
                colorStart: Qt.lighter(root.accent, 1.15)
                colorEnd: root.accent
                // Keep the surface moving even at a steady volume.
                waveAmplitude: UiScale.s(6)

                Behavior on level {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutQuint
                    }
                }
            }

            StyledText {
                anchors.centerIn: parent
                text: root.muted ? "MUTE" : root.volume + "%"
                font.pixelSize: UiScale.s(32)
                font.weight: Font.Black
                color: root.muted ? Colours.red : (root.volume > 50 ? Colours.crust : Colours.text)
            }

            HoverArea {
                onClicked: Audio.toggleMute(root.node)
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: UiScale.s(10)

        ColumnLayout {
            spacing: UiScale.s(2)

            StyledText {
                Layout.fillWidth: true
                text: Audio.label(root.node) || "No device"
                font.pixelSize: Tokens.font.size.large
                font.weight: Font.Black
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.subtitle
                font.pixelSize: Tokens.font.size.pill
                font.weight: Font.Normal
                color: Colours.subtext0
                elide: Text.ElideRight
            }
        }

        Item {
            Layout.fillHeight: true
        }

        FillSlider {
            Layout.fillWidth: true
            Layout.preferredHeight: UiScale.s(24)
            value: root.volume
            dimmed: root.muted
            colorStart: root.muted ? Colours.surface2 : root.accent
            colorEnd: Qt.lighter(colorStart, 1.15)
            onMoved: value => Audio.setVolume(root.node, value / 100)
        }
    }
}
