import QtQuick
import QtQuick.Layouts
import qs.core.state
import qs.core.theme
import qs.core.ui
import qs.features.battery

// Power profile switch: a gradient slider pill springs to the selected profile.
Rectangle {
    id: root

    property color accent: Colours.blue

    readonly property var profiles: [
        { name: "performance", glyph: String.fromCodePoint(0xF04C5), label: "Perform" },
        { name: "balanced", glyph: String.fromCodePoint(0xF05D1), label: "Balance" },
        { name: "power-saver", glyph: String.fromCodePoint(0xF032A), label: "Saver" }
    ]
    readonly property int selected: Math.max(0, profiles.findIndex(p => p.name === BatteryService.profile))

    radius: Tokens.block.radius
    color: Colours.surface0
    border.color: Colours.surface1
    border.width: 1

    Rectangle {
        width: (parent.width - UiScale.s(2)) / 3
        height: parent.height - UiScale.s(2)
        y: UiScale.s(1)
        x: UiScale.s(1) + width * root.selected
        radius: UiScale.s(10)

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: root.accent

                Behavior on color {
                    ColorAnimation { duration: 400 }
                }
            }
            GradientStop {
                position: 1
                color: Qt.lighter(root.accent, 1.15)

                Behavior on color {
                    ColorAnimation { duration: 400 }
                }
            }
        }

        Behavior on x {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: root.profiles

            delegate: Item {
                id: option

                required property var modelData
                required property int index
                readonly property bool active: index === root.selected

                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    anchors.centerIn: parent
                    spacing: UiScale.s(8)

                    Icon {
                        text: option.modelData.glyph
                        font.pixelSize: Tokens.font.size.title
                        color: option.active ? Colours.crust : (optionArea.containsMouse ? Colours.text : Colours.subtext0)
                    }

                    StyledText {
                        text: option.modelData.label
                        font.pixelSize: Tokens.font.size.pill
                        font.weight: Font.Black
                        color: option.active ? Colours.crust : (optionArea.containsMouse ? Colours.text : Colours.subtext0)
                    }
                }

                HoverArea {
                    id: optionArea

                    onClicked: BatteryService.setProfile(option.modelData.name)
                }
            }
        }
    }
}
