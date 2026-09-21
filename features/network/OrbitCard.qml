import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.core.state
import qs.core.theme
import qs.core.ui

// A floating card for a network, device or info value. Actionable cards are held to
// trigger (a liquid fill slides across); highlighted ones pulse an accent outline.
Item {
    id: root

    // { id, name, icon, action, info, actionable, highlight }
    required property var node
    property color accent: Colours.mauve
    property bool busy: false
    property bool connected: false

    signal triggered(var node)

    readonly property bool interactive: !node.info || node.actionable
    readonly property bool engaged: interactive && (hold.containsMouse || hold.pressed)
    readonly property real fill: connected ? 1 : hold.level

    width: UiScale.s(170)
    height: UiScale.s(60)

    Rectangle {
        id: card

        anchors.fill: parent
        radius: Tokens.block.radius
        color: root.engaged ? Colours.alpha(Colours.white, 0.16) : Colours.alpha(Colours.white, 0.05)
        border.width: root.engaged ? UiScale.s(2) : 1
        border.color: root.engaged || root.node.highlight ? root.accent : Colours.surface2
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Colours.black
            shadowOpacity: 0.3
            shadowBlur: 0.8
            shadowVerticalOffset: UiScale.s(4)
        }

        Behavior on color {
            ColorAnimation { duration: 200 }
        }

        WaveFill {
            anchors.fill: parent
            direction: "right"
            level: root.fill
            radius: card.radius
            colorStart: Qt.lighter(root.accent, 1.15)
            colorEnd: root.accent
            waveAmplitude: UiScale.s(12)
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.color: root.accent
            border.width: UiScale.s(2)
            visible: root.node.highlight && !root.busy && !root.connected

            SequentialAnimation on scale {
                loops: Animation.Infinite
                running: parent.visible
                NumberAnimation { to: 1.15; duration: 1200; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 1200; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: parent.visible
                NumberAnimation { to: 0; duration: 1200; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.8; duration: 1200; easing.type: Easing.InOutSine }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: UiScale.s(12)
            spacing: UiScale.s(10)

            Icon {
                text: root.node.icon
                font.pixelSize: Tokens.font.size.large
                color: root.fill > 0.3 ? Colours.crust : (root.busy ? Colours.text : root.accent)
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: UiScale.s(2)

                StyledText {
                    Layout.fillWidth: true
                    text: root.node.name
                    font.pixelSize: Tokens.font.size.pill
                    color: root.fill > 0.5 ? Colours.crust : (root.node.highlight ? root.accent : Colours.text)
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.busy ? "Connecting..." : (hold.level > 0.1 && hold.level < 1 ? "Hold..." : root.node.action)
                    font.pixelSize: Tokens.font.size.tiny
                    font.weight: Font.Normal
                    color: root.fill > 0.5 ? Colours.crust : (root.busy ? root.accent : Colours.overlay0)
                    elide: Text.ElideRight
                }
            }
        }
    }

    HoldArea {
        id: hold

        anchors.fill: parent
        enabled: root.interactive && !root.busy && !root.connected
        onConfirmed: {
            root.triggered(root.node);
            reset();
        }
    }
}
