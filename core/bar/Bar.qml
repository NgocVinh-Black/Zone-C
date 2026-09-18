import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.config
import qs.core.theme

// Transparent top panel holding three zones of floating blocks.
PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: Tokens.bar.marginTop
        left: Tokens.bar.marginSide
        right: Tokens.bar.marginSide
    }

    implicitHeight: Tokens.bar.height
    exclusiveZone: Tokens.bar.height
    color: "transparent"

    WlrLayershell.namespace: "zone-c-bar"

    Item {
        anchors.fill: parent

        BarZone {
            id: left

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            groups: Config.bar.left
            screen: bar.screen
            barWindow: bar
            enterX: -Tokens.bar.enterOffset
            enterDelay: Tokens.bar.enterLeftDelay
        }

        BarZone {
            id: right

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            groups: Config.bar.right
            screen: bar.screen
            barWindow: bar
            enterX: Tokens.bar.enterOffset
            enterDelay: Tokens.bar.enterRightDelay
        }

        // Centered on the screen, but pushed aside instead of overlapping the other zones.
        BarZone {
            anchors.verticalCenter: parent.verticalCenter
            x: {
                const centered = (parent.width - width) / 2;
                const minX = left.width > 0 ? left.width + Tokens.bar.zoneGap : 0;
                const maxX = right.width > 0 ? right.x - width - Tokens.bar.zoneGap : parent.width - width;
                return Math.max(minX, Math.min(centered, maxX));
            }
            groups: Config.bar.center
            screen: bar.screen
            barWindow: bar
            enterY: -Tokens.bar.enterOffset
            enterDelay: Tokens.bar.enterCenterDelay
        }
    }
}
