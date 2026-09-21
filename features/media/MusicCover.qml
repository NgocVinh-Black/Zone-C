import QtQuick
import QtQuick.Effects
import qs.core.state
import qs.core.theme
import qs.features.media

// The album cover as a spinning record with a glow while playing.
Item {
    id: root

    property bool playing: false

    scale: playing ? 1 : 0.9

    Behavior on scale {
        NumberAnimation {
            duration: 800
            easing.type: Easing.OutElastic
            easing.overshoot: 1.2
        }
    }

    Rectangle {
        anchors.centerIn: disc
        width: disc.width + UiScale.s(20)
        height: width
        radius: width / 2
        color: Colours.mauve
        opacity: root.playing ? 0.5 : 0
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 32
            blur: 1
        }

        Behavior on opacity {
            NumberAnimation { duration: 500 }
        }
    }

    Rectangle {
        id: disc

        anchors.fill: parent
        radius: width / 2
        color: Colours.surface1
        border.width: UiScale.s(4)
        border.color: root.playing ? Colours.mauve : Colours.overlay0

        Behavior on border.color {
            ColorAnimation { duration: 500 }
        }

        NumberAnimation on rotation {
            from: 0
            to: 360
            duration: 8000
            loops: Animation.Infinite
            paused: !root.playing
        }

        Item {
            anchors.fill: parent
            anchors.margins: UiScale.s(4)

            Image {
                id: art

                anchors.fill: parent
                source: MediaService.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }

            Rectangle {
                id: mask

                anchors.fill: parent
                radius: width / 2
                visible: false
                layer.enabled: true
            }

            MultiEffect {
                anchors.fill: parent
                source: art
                maskEnabled: true
                maskSource: mask
                opacity: art.status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 800 }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Colours.alpha(Colours.mauve, 0.2)
                opacity: art.status === Image.Ready ? 1 : 0
            }

            // Spindle hole.
            Rectangle {
                anchors.centerIn: parent
                width: UiScale.s(40)
                height: width
                radius: width / 2
                color: Colours.black
                opacity: 0.8
            }
        }
    }
}
