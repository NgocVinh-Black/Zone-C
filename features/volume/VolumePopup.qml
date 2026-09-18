import QtQuick
import QtQuick.Layouts
import qs.core.popup
import qs.core.services
import qs.core.state
import qs.core.theme
import qs.core.ui
import "VolumeLogic.js" as Logic

// Mixer: the selected default device as a liquid gauge with a master slider, a tab
// bar (outputs, inputs, application streams) and a card per device or stream.
PopupBase {
    id: root

    property string tab: arg === "inputs" || arg === "streams" ? arg : "outputs"

    readonly property color tabColour: tab === "outputs" ? Colours.blue : (tab === "inputs" ? Colours.mauve : Colours.green)
    // The streams tab controls the default output.
    readonly property var hero: tab === "inputs" ? Audio.source : Audio.sink
    readonly property var nodes: tab === "outputs" ? Audio.outputs : (tab === "inputs" ? Audio.inputs : Audio.streams)

    blobPrimary: tabColour
    blobSecondary: Qt.lighter(tabColour, 1.3)
    blobPrimaryOpacity: 0.06
    blobSecondaryOpacity: 0.04

    Reveal {
        id: introHeader
        delay: 100
    }
    Reveal {
        id: introContent
        delay: 250
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.popup.padding
        spacing: Scale.s(20)

        VolumeHero {
            Layout.fillWidth: true
            Layout.preferredHeight: Scale.s(150)
            node: root.hero
            accent: root.tabColour
            subtitle: root.tab === "streams" ? "Master Output Volume" : Audio.detail(root.hero)
            opacity: introHeader.value

            transform: Translate {
                y: Scale.s(-20) * (1 - introHeader.value)
            }
        }

        Rectangle {
            id: tabBar

            readonly property var tabs: [
                { id: "outputs", icon: String.fromCodePoint(0xF04C3), label: "Outputs" },
                { id: "inputs", icon: String.fromCodePoint(0xF036C), label: "Inputs" },
                { id: "streams", icon: String.fromCodePoint(0xF0386), label: "Streams" }
            ]

            Layout.fillWidth: true
            Layout.preferredHeight: Scale.s(54)
            radius: Scale.s(14)
            color: Colours.alpha(Colours.white, 0.05)
            border.color: Colours.alpha(Colours.white, 0.1)
            border.width: 1
            opacity: introHeader.value

            Rectangle {
                width: (parent.width - 2) / 3
                height: parent.height - 2
                y: 1
                x: 1 + width * tabBar.tabs.findIndex(t => t.id === root.tab)
                radius: Scale.s(10)

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: root.tabColour }
                    GradientStop { position: 1; color: Qt.lighter(root.tabColour, 1.15) }
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
                    model: tabBar.tabs

                    delegate: Item {
                        id: tabItem

                        required property var modelData
                        readonly property bool selected: root.tab === modelData.id

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Scale.s(8)

                            Icon {
                                text: tabItem.modelData.icon
                                font.pixelSize: Tokens.font.size.title
                                color: tabItem.selected ? Colours.crust : (tabArea.containsMouse ? Colours.text : Colours.subtext0)
                            }

                            StyledText {
                                text: tabItem.modelData.label
                                font.pixelSize: Tokens.font.size.pill
                                font.weight: Font.Black
                                color: tabItem.selected ? Colours.crust : (tabArea.containsMouse ? Colours.text : Colours.subtext0)
                            }
                        }

                        HoverArea {
                            id: tabArea

                            onClicked: root.tab = tabItem.modelData.id
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            opacity: introContent.value

            transform: Translate {
                y: Scale.s(20) * (1 - introContent.value)
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: root.nodes.length === 0
                spacing: Scale.s(10)

                Icon {
                    Layout.alignment: Qt.AlignHCenter
                    text: String.fromCodePoint(0xF075F)
                    font.pixelSize: Scale.s(32)
                    color: Colours.surface2
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.tab === "streams" ? "No apps playing audio" : "No devices found"
                    font.weight: Font.Normal
                    color: Colours.overlay0
                }
            }

            ListView {
                anchors.fill: parent
                clip: true
                spacing: Scale.s(12)
                model: root.nodes

                delegate: AudioNodeCard {
                    required property var modelData

                    width: ListView.view.width
                    node: modelData
                    accent: root.tabColour
                    isDefault: root.tab !== "streams" && modelData === root.hero
                }
            }
        }
    }
}
