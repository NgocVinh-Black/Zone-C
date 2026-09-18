import QtQuick
import QtQuick.Layouts
import qs.core.services
import qs.core.state
import qs.core.theme
import qs.core.ui
import "VolumeLogic.js" as Logic

// One device or stream. The default device is a compact filled card; the others show
// a mute button and their own slider, and become the default when clicked.
Rectangle {
    id: root

    property var node: null
    property color accent: Colours.blue
    property bool isDefault: false

    readonly property int volume: Math.round((node?.audio?.volume ?? 0) * 100)
    readonly property bool muted: node?.audio?.muted ?? false
    readonly property string glyph: {
        const name = Audio.label(node).toLowerCase();
        if (node?.isStream)
            return String.fromCodePoint(0xF0386);
        if (!node?.isSink)
            return String.fromCodePoint(0xF036C);
        if (name.includes("headset") || name.includes("headphone") || name.includes("tune") || name.includes("buds"))
            return String.fromCodePoint(0xF02CB);
        return String.fromCodePoint(0xF04C3);
    }

    implicitHeight: isDefault ? Scale.s(60) : Scale.s(100)
    radius: Scale.s(14)
    color: isDefault ? accent : (cardArea.containsMouse ? Colours.alpha(Colours.white, 0.04) : Colours.alpha(Colours.white, 0.02))
    border.color: isDefault ? accent : Colours.alpha(Colours.white, 0.1)
    border.width: isDefault ? 2 : 1

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutQuint
        }
    }

    Behavior on color {
        ColorAnimation { duration: 300 }
    }

    MouseArea {
        id: cardArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.isDefault || root.node?.isStream ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: {
            if (!root.isDefault && !root.node?.isStream)
                Audio.setDefault(root.node);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Scale.s(15)
        spacing: Scale.s(12)

        RowLayout {
            Layout.fillWidth: true
            spacing: Scale.s(12)

            Icon {
                text: root.glyph
                font.pixelSize: Tokens.font.size.iconLarge
                color: root.isDefault ? Colours.crust : Colours.text
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Scale.s(2)

                StyledText {
                    Layout.fillWidth: true
                    text: Audio.label(root.node)
                    elide: Text.ElideRight
                    color: root.isDefault ? Colours.crust : Colours.text
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.isDefault ? "Active Default" : Audio.detail(root.node)
                    elide: Text.ElideRight
                    font.pixelSize: Tokens.font.size.small
                    font.weight: Font.Normal
                    color: root.isDefault ? Colours.alpha(Colours.crust, 0.8) : Colours.subtext0
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: !root.isDefault
            spacing: Scale.s(15)

            Rectangle {
                Layout.preferredWidth: Scale.s(32)
                Layout.preferredHeight: Scale.s(32)
                radius: width / 2
                color: muteArea.containsMouse ? Colours.alpha(Colours.white, 0.1) : "transparent"
                border.color: muteArea.containsMouse ? (root.muted ? Colours.overlay0 : root.accent) : "transparent"

                Icon {
                    anchors.centerIn: parent
                    text: Logic.icon(root.volume / 100, root.muted)
                    font.pixelSize: Tokens.font.size.title
                    color: root.muted ? Colours.overlay0 : Colours.subtext0
                }

                HoverArea {
                    id: muteArea

                    onClicked: Audio.toggleMute(root.node)
                }
            }

            FillSlider {
                Layout.fillWidth: true
                Layout.preferredHeight: Scale.s(14)
                value: root.volume
                dimmed: root.muted
                colorStart: root.muted ? Colours.surface2 : root.accent
                colorEnd: Qt.lighter(colorStart, 1.15)
                onMoved: value => Audio.setVolume(root.node, value / 100)
            }

            StyledText {
                Layout.preferredWidth: Scale.s(40)
                horizontalAlignment: Text.AlignRight
                text: root.volume + "%"
                font.pixelSize: Tokens.font.size.label
                color: Colours.subtext0
            }
        }
    }
}
