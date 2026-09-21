import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.media

// Now playing (spinning cover, title, progress, controls) above a 10-band equalizer,
// inside a slowly rotating gradient frame over the blurred album art.
Item {
    id: root

    property var screen: null
    property string arg: ""

    readonly property string status: MediaService.available ? (MediaService.playing ? "Playing" : "Paused") : "Stopped"
    property real orbitAngle: 0

    Reveal {
        id: introMain
        duration: 760
    }
    Reveal {
        id: introCover
        delay: 70
        duration: 810
        overshoot: 1.0
    }
    Reveal {
        id: introText
        delay: 150
        duration: 760
    }
    Reveal {
        id: introControls
        delay: 230
        duration: 760
        overshoot: 0.8
    }
    Reveal {
        id: introSeparator
        delay: 310
        duration: 660
    }

    NumberAnimation on orbitAngle {
        from: 0
        to: Math.PI * 2
        duration: Tokens.anim.orbit
        loops: Animation.Infinite
    }

    Item {
        anchors.fill: parent
        scale: Tokens.popup.introScale + (1 - Tokens.popup.introScale) * introMain.value
        opacity: introMain.value

        transform: Translate {
            y: Tokens.popup.introLift * (1 - introMain.value)
        }

        // Gradient frame: a rotating gradient seen through a 3px gap around the inner surface.
        Rectangle {
            anchors.fill: parent
            radius: UiScale.s(14)
            color: Colours.base
            clip: true

            Rectangle {
                width: Math.max(parent.width, parent.height) * 2
                height: width
                anchors.centerIn: parent

                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Colours.mauve
                    }
                    GradientStop {
                        position: 0.33
                        color: Colours.blue
                    }
                    GradientStop {
                        position: 0.66
                        color: Colours.red
                    }
                    GradientStop {
                        position: 1
                        color: Colours.mauve
                    }
                }

                NumberAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 5000
                    loops: Animation.Infinite
                }
            }
        }

        Rectangle {
            id: inner

            anchors.fill: parent
            anchors.margins: UiScale.s(3)
            radius: UiScale.s(10)
            color: Colours.base
            clip: true
            layer.enabled: true

            Image {
                id: blurSource

                anchors.fill: parent
                source: MediaService.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: blurSource
                blurEnabled: true
                blurMax: 64
                blur: 1
                brightness: -0.3
                opacity: blurSource.status === Image.Ready && root.status !== "Stopped" ? 0.9 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 800
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            Rectangle {
                width: parent.width * 0.8
                height: width
                radius: width / 2
                x: (parent.width - width) / 2 + Math.cos(root.orbitAngle * 2) * UiScale.s(150)
                y: (parent.height - height) / 2 + Math.sin(root.orbitAngle * 2) * UiScale.s(100)
                color: root.status === "Playing" ? Colours.mauve : Colours.surface2
                opacity: root.status === "Playing" ? 0.08 : (root.status === "Paused" ? 0.04 : 0)

                Behavior on opacity {
                    NumberAnimation { duration: 1000 }
                }
            }

            Rectangle {
                width: parent.width * 0.9
                height: width
                radius: width / 2
                x: (parent.width - width) / 2 - Math.sin(root.orbitAngle * 1.5) * UiScale.s(150)
                y: (parent.height - height) / 2 - Math.cos(root.orbitAngle * 1.5) * UiScale.s(100)
                color: root.status === "Playing" ? Colours.blue : Colours.surface1
                opacity: root.status === "Playing" ? 0.08 : (root.status === "Paused" ? 0.02 : 0)

                Behavior on opacity {
                    NumberAnimation { duration: 1000 }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: UiScale.s(20)
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: UiScale.s(220)
                    spacing: UiScale.s(25)

                    MusicCover {
                        Layout.preferredWidth: UiScale.s(220)
                        Layout.preferredHeight: UiScale.s(220)
                        Layout.alignment: Qt.AlignVCenter
                        playing: root.status === "Playing"
                        opacity: introCover.value

                        transform: Translate {
                            x: UiScale.s(-40) * (1 - introCover.value)
                            y: UiScale.s(10) * (1 - introCover.value)
                        }
                    }

                    MusicControls {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        textReveal: introText.value
                        controlsReveal: introControls.value
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: UiScale.s(2)
                    Layout.topMargin: UiScale.s(20)
                    Layout.bottomMargin: UiScale.s(20)
                    radius: UiScale.s(1)
                    color: Colours.alpha(Colours.white, 0.1)
                    opacity: introSeparator.value

                    transform: Translate {
                        y: UiScale.s(15) * (1 - introSeparator.value)
                    }
                }

                EqualizerPanel {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
