import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.media

// One vertical equalizer band (-12…+12 dB). `strike` is the position of the
// lightning sweep across all bands; the band flares as it passes.
Item {
    id: root

    required property int band
    property real strike: 0
    property real strikeFade: 1

    readonly property real gain: EqualizerService.gains[band] ?? 0
    readonly property real dist: strike - band
    readonly property real hit: dist >= 0 && dist < 1 ? Math.sin(dist * Math.PI) : 0
    readonly property real energy: 1 - strikeFade

    property real surge: 0
    property bool fired: false

    onDistChanged: {
        if (dist <= 0.05) {
            fired = false;
        } else if (dist > 0.4 && !fired) {
            fired = true;
            surgeAnim.restart();
        }
    }

    NumberAnimation {
        id: surgeAnim

        target: root
        property: "surge"
        from: 1
        to: 0
        duration: 1500
        easing.type: Easing.OutSine
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: UiScale.s(5)

        Item {
            id: column

            readonly property real shownGain: area.pressed ? area.dragGain : root.gain
            // 0 at the top (+12 dB), 1 at the bottom (-12 dB).
            readonly property real position: (12 - shownGain) / 24

            Layout.fillHeight: true
            Layout.fillWidth: true

            Rectangle {
                id: track

                anchors.horizontalCenter: parent.horizontalCenter
                y: UiScale.s(9)
                width: UiScale.s(10)
                height: parent.height - UiScale.s(18)
                radius: UiScale.s(4)
                color: Colours.alpha(Colours.surface0, 0.7)
                clip: true

                Rectangle {
                    width: parent.width
                    y: column.position * parent.height
                    height: parent.height - y
                    radius: parent.radius
                    color: Colours.blue

                    Behavior on y {
                        enabled: !area.pressed
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutQuart
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        opacity: root.surge

                        gradient: Gradient {
                            GradientStop { position: 0; color: Colours.mauve }
                            GradientStop { position: 0.5; color: Colours.blue }
                            GradientStop { position: 1; color: "transparent" }
                        }
                    }
                }
            }

            // Shockwave ring as the strike passes.
            Rectangle {
                anchors.centerIn: track
                width: track.width + UiScale.s(20) + root.surge * UiScale.s(40)
                height: track.height + UiScale.s(20) + root.surge * UiScale.s(60)
                radius: UiScale.s(14) + root.surge * UiScale.s(20)
                color: "transparent"
                border.color: Colours.mauve
                border.width: UiScale.s(2) + root.surge * UiScale.s(4)
                opacity: root.surge * 0.8 * root.energy
                visible: opacity > 0.01
            }

            Rectangle {
                id: handle

                anchors.horizontalCenter: parent.horizontalCenter
                y: track.y + column.position * track.height - height / 2
                width: UiScale.s(18)
                height: width
                radius: width / 2
                color: Colours.text
                scale: 1 + root.hit * 0.4 * root.energy

                Behavior on y {
                    enabled: !area.pressed
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutQuart
                    }
                }

                Rectangle {
                    z: -1
                    anchors.centerIn: parent
                    width: parent.width + UiScale.s(36) * root.hit
                    height: width
                    radius: width / 2
                    color: [Colours.mauve, Colours.pink, Colours.lavender, Colours.mauve, Colours.blue][root.band % 5]
                    opacity: root.hit * root.energy
                    visible: opacity > 0.01
                    layer.enabled: visible
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blurMax: 32
                        blur: 1
                    }
                }
            }

            MouseArea {
                id: area

                property real dragGain: 0

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                function gainAt(y: real): real {
                    const t = Math.max(0, Math.min(1, (y - track.y) / track.height));
                    return Math.round(12 - t * 24);
                }

                onPressed: mouse => dragGain = gainAt(mouse.y)
                onPositionChanged: mouse => dragGain = gainAt(mouse.y)
                onReleased: EqualizerService.setBand(root.band, dragGain)
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: EqualizerService.label(root.band)
            font.pixelSize: Tokens.font.size.tiny
            color: Colours.overlay1
        }
    }
}
