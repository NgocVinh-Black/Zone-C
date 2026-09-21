import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.core.state
import qs.core.theme
import qs.core.ui

// The central orb of the network popup. Offline or scanning it shows a status;
// with a connected network or device it glows in the accent and can be held to disconnect.
Item {
    id: root

    property color accent: Colours.mauve
    property bool powered: false
    property bool pending: false
    property string mode: "wifi"
    // { id, name, icon } of the connected network/device, or null.
    property var device: null
    // Makes glyphs smaller when several cores share the ring.
    property real crowd: 0

    signal disconnectRequested(var device)

    readonly property bool online: powered && device !== null
    readonly property bool danger: online && (hold.containsMouse || hold.level > 0)

    // Pulsing outline, shown while connected.
    Rectangle {
        anchors.centerIn: parent
        width: parent.width + UiScale.s(15)
        height: width
        radius: width / 2
        color: "transparent"
        border.color: root.danger ? Colours.red : root.accent
        border.width: UiScale.s(3)
        opacity: root.online ? 0.35 : 0

        SequentialAnimation on scale {
            loops: Animation.Infinite
            running: root.online
            NumberAnimation { to: 1.04; duration: 1100; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 1100; easing.type: Easing.InOutSine }
        }
    }

    // Glow.
    Rectangle {
        anchors.centerIn: parent
        width: parent.width + UiScale.s(40)
        height: width
        radius: width / 2
        color: root.danger ? Colours.red : root.accent
        opacity: root.online ? (root.danger ? 0.3 : 0.15) : 0

        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }

        SequentialAnimation on scale {
            loops: Animation.Infinite
            running: root.online
            NumberAnimation { to: hold.containsMouse ? 1.15 : 1.1; duration: hold.containsMouse ? 800 : 2000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: hold.containsMouse ? 800 : 2000; easing.type: Easing.InOutSine }
        }
    }

    Rectangle {
        id: orb

        anchors.fill: parent
        radius: width / 2
        border.width: UiScale.s(2)
        border.color: !root.powered ? Colours.crust : (root.danger ? Colours.maroon : (root.online ? Qt.lighter(root.accent, 1.1) : Colours.surface1))
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Colours.black
            shadowOpacity: root.powered ? 0.5 : 0
            shadowBlur: 1
            shadowVerticalOffset: UiScale.s(6)
        }

        gradient: Gradient {
            GradientStop {
                position: 0
                color: !root.powered ? Colours.mantle : (root.danger ? Qt.lighter(Colours.red, 1.15) : (root.online ? Qt.lighter(root.accent, 1.15) : Colours.surface0))

                Behavior on color {
                    ColorAnimation { duration: 300 }
                }
            }
            GradientStop {
                position: 1
                color: !root.powered ? Colours.crust : (root.danger ? Colours.red : (root.online ? root.accent : Colours.base))

                Behavior on color {
                    ColorAnimation { duration: 300 }
                }
            }
        }

        WaveFill {
            anchors.fill: parent
            shape: "circle"
            level: hold.level
            colorStart: Colours.surface1
            colorEnd: Colours.crust
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: UiScale.s(6)
            visible: !root.online

            Icon {
                Layout.alignment: Qt.AlignHCenter
                text: root.mode === "wifi" ? String.fromCodePoint(0xF092E) : String.fromCodePoint(0xF00B2)
                font.pixelSize: UiScale.s(48) - UiScale.s(16) * root.crowd
                color: root.powered ? Colours.overlay0 : Colours.surface2
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.pending ? (root.powered ? "Powering On..." : "Powering Off...") : (root.powered ? "Scanning..." : "Radio Offline")
                font.pixelSize: Tokens.font.size.body - UiScale.s(3) * root.crowd
                color: Colours.overlay0
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: UiScale.s(4)
            visible: root.online

            Icon {
                Layout.alignment: Qt.AlignHCenter
                text: hold.containsMouse ? (root.mode === "wifi" ? String.fromCodePoint(0xF05AA) : String.fromCodePoint(0xF00B2)) : (root.device?.icon ?? "")
                font.pixelSize: UiScale.s(48) - UiScale.s(16) * root.crowd
                color: hold.level > 0.5 ? Colours.text : Colours.crust
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: UiScale.s(150) - UiScale.s(50) * root.crowd
                horizontalAlignment: Text.AlignHCenter
                text: root.device?.name ?? ""
                font.pixelSize: Tokens.font.size.clock - UiScale.s(4) * root.crowd
                font.weight: Font.Black
                color: hold.level > 0.5 ? Colours.text : Colours.crust
                elide: Text.ElideRight
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: hold.level > 0.01 ? "Hold..." : "Connected"
                font.pixelSize: Tokens.font.size.small
                color: Colours.alpha(hold.level > 0.5 ? Colours.text : Colours.crust, 0.6)
            }
        }

        HoldArea {
            id: hold

            anchors.fill: parent
            enabled: root.online
            holdDuration: 800
            onConfirmed: {
                root.disconnectRequested(root.device);
                reset();
            }
        }
    }
}
