import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.media

// Equalizer header (Apply/Saved, preset name), the ten bands with a lightning sweep
// whenever settings are applied, and the preset buttons.
ColumnLayout {
    id: root

    property real strike: 0
    property real strikeFade: 1

    spacing: Scale.s(15)

    Reveal {
        id: introHeader
        delay: 370
        duration: 710
    }
    Reveal {
        id: introSliders
        delay: 430
        duration: 860
        easingType: Easing.OutExpo
    }
    Reveal {
        id: introPresets
        delay: 550
        duration: 810
        overshoot: 0.8
    }

    Connections {
        target: EqualizerService

        function onApplyCountChanged(): void {
            lightning.restart();
        }
    }

    SequentialAnimation {
        id: lightning

        ScriptAction {
            script: {
                root.strikeFade = 0;
                root.strike = 0;
            }
        }
        NumberAnimation {
            target: root
            property: "strike"
            from: 0
            to: 10
            duration: 650
            easing.type: Easing.OutSine
        }
        PauseAnimation {
            duration: 150
        }
        NumberAnimation {
            target: root
            property: "strikeFade"
            from: 0
            to: 1
            duration: 800
            easing.type: Easing.OutQuad
        }
        ScriptAction {
            script: root.strike = 0
        }
    }

    RowLayout {
        Layout.fillWidth: true
        opacity: introHeader.value

        transform: Translate {
            y: Scale.s(15) * (1 - introHeader.value)
        }

        StyledText {
            Layout.fillWidth: true
            text: "Equalizer"
            font.pixelSize: Tokens.font.size.clock
            color: Colours.mauve
        }

        Rectangle {
            Layout.preferredHeight: Scale.s(28)
            Layout.preferredWidth: applyText.implicitWidth + Scale.s(30)
            radius: Scale.s(10)
            color: EqualizerService.pending ? Colours.mauve : Colours.surface1
            border.color: EqualizerService.pending ? Colours.mauve : Colours.surface2
            border.width: 1

            Behavior on color {
                ColorAnimation { duration: 300 }
            }

            StyledText {
                id: applyText

                anchors.centerIn: parent
                text: EqualizerService.pending ? "Apply" : "Saved"
                font.pixelSize: Tokens.font.size.label
                color: EqualizerService.pending ? Colours.base : Colours.subtext0
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: EqualizerService.pending ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (EqualizerService.pending)
                        EqualizerService.apply();
                }
            }
        }

        StyledText {
            Layout.leftMargin: Scale.s(15)
            text: EqualizerService.preset
            color: Colours.subtext0
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Scale.s(180)

        EqLightning {
            anchors.fill: parent
            strike: root.strike
            strikeFade: root.strikeFade
        }

        Row {
            anchors.fill: parent

            Repeater {
                model: EqualizerService.bands.length

                delegate: EqSlider {
                    required property int index

                    band: index
                    width: parent.width / EqualizerService.bands.length
                    height: parent.height
                    strike: root.strike
                    strikeFade: root.strikeFade
                    opacity: introSliders.value

                    transform: Translate {
                        y: (Scale.s(30) + index * Scale.s(8)) * (1 - introSliders.value)
                    }
                }
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 4
        rowSpacing: Scale.s(8)
        columnSpacing: Scale.s(10)
        opacity: introPresets.value

        transform: Translate {
            y: Scale.s(20) * (1 - introPresets.value)
        }

        Repeater {
            model: EqualizerService.presetNames

            delegate: Rectangle {
                id: presetButton

                required property string modelData
                readonly property bool active: EqualizerService.preset === modelData

                Layout.fillWidth: true
                Layout.preferredHeight: Scale.s(32)
                radius: Scale.s(8)
                color: active ? Colours.mauve : (presetArea.containsMouse ? Colours.surface1 : Colours.alpha(Colours.base, 0.75))
                scale: presetArea.containsMouse && !active ? 1.05 : 1

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutBack
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    text: presetButton.modelData
                    font.pixelSize: Tokens.font.size.label
                    color: presetButton.active ? Colours.base : (presetArea.containsMouse ? Colours.text : Colours.subtext0)
                }

                HoverArea {
                    id: presetArea

                    onClicked: EqualizerService.applyPreset(presetButton.modelData)
                }
            }
        }
    }
}
