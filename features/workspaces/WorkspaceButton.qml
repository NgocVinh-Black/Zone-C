import QtQuick
import qs.core.services
import qs.core.theme
import qs.core.ui

// One numbered workspace pill. Active: filled accent; with windows: filled surface;
// empty: text only. Rises in one after another at startup.
Rectangle {
    id: root

    required property int workspaceId
    required property int index

    readonly property bool active: Hypr.activeWorkspaceId === workspaceId
    readonly property bool occupied: Hypr.isOccupied(workspaceId)
    readonly property bool hovered: area.containsMouse
    property bool entered: false

    width: Tokens.workspace.size
    height: Tokens.workspace.size
    radius: Tokens.workspace.radius
    color: {
        if (active)
            return Colours.mauve;
        if (hovered)
            return Colours.alpha(Colours.overlay0, Tokens.workspace.fillAlpha);
        if (occupied)
            return Colours.alpha(Colours.surface2, Tokens.workspace.fillAlpha);
        return "transparent";
    }
    scale: hovered && !active ? Tokens.workspace.hoverScale : 1
    opacity: entered ? 1 : 0

    transform: Translate {
        y: root.entered ? 0 : Tokens.pill.enterOffset

        Behavior on y {
            NumberAnimation {
                duration: Tokens.anim.slow
                easing.type: Easing.OutBack
            }
        }
    }

    Behavior on color {
        ColorAnim {}
    }

    Behavior on scale {
        Anim {
            easing.type: Easing.OutBack
        }
    }

    Behavior on opacity {
        Anim {
            duration: Tokens.anim.slow
        }
    }

    Timer {
        running: true
        interval: root.index * Tokens.workspace.enterStagger
        onTriggered: root.entered = true
    }

    StyledText {
        anchors.centerIn: parent
        text: root.workspaceId
        font.pixelSize: Tokens.font.size.body
        font.weight: root.active ? Font.Black : (root.occupied ? Font.Bold : Font.Medium)
        color: root.active || root.hovered ? Colours.crust : (root.occupied ? Colours.text : Colours.overlay0)

        Behavior on color {
            ColorAnim {}
        }
    }

    HoverArea {
        id: area

        onClicked: Hypr.focusWorkspace(root.workspaceId)
    }
}
