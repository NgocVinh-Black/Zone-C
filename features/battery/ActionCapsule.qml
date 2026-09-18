import QtQuick
import qs.core.theme
import qs.core.ui

// A session action (lock, suspend, reboot, power off): hold to fill it with liquid;
// when full it flashes and emits `confirmed`. Heavier actions take longer to fill.
Rectangle {
    id: root

    property string glyph: ""
    property color accent: Colours.mauve
    property real weight: 1

    signal confirmed

    radius: Tokens.block.radius
    color: hold.containsMouse ? Colours.surface1 : Colours.surface0
    border.color: hold.containsMouse ? accent : Colours.surface2
    border.width: hold.containsMouse ? 2 : 1
    scale: hold.pressed ? 0.98 - 0.01 * weight : (hold.containsMouse ? 1.08 : 1)

    Behavior on color {
        ColorAnimation { duration: 200 }
    }
    Behavior on scale {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutQuart
        }
    }

    WaveFill {
        anchors.fill: parent
        level: hold.level
        radius: root.radius
        colorStart: root.accent
        colorEnd: Qt.lighter(root.accent, 1.2)
    }

    Rectangle {
        id: flash

        anchors.fill: parent
        radius: root.radius
        color: Colours.white
        opacity: 0
    }

    Icon {
        anchors.centerIn: parent
        text: root.glyph
        font.pixelSize: Tokens.font.size.weatherIcon
        color: hold.containsMouse ? Colours.text : Colours.subtext0
    }

    // The part of the glyph under the liquid turns dark.
    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.height * hold.level
        clip: true

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.height / 2 - height / 2 - (root.height - parent.height)
            text: root.glyph
            font.pixelSize: Tokens.font.size.weatherIcon
            color: Colours.crust
        }
    }

    HoldArea {
        id: hold

        anchors.fill: parent
        holdDuration: 550 * root.weight
        onConfirmed: {
            flash.opacity = 0.6;
            flashOut.restart();
            root.confirmed();
        }
    }

    NumberAnimation {
        id: flashOut

        target: flash
        property: "opacity"
        to: 0
        duration: 500
        easing.type: Easing.OutExpo
    }
}
