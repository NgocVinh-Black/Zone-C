import QtQuick
import qs.core.services
import qs.core.theme
import qs.core.ui

Rectangle {
    id: root

    required property int workspaceId

    readonly property bool active: Hypr.activeWorkspaceId === workspaceId
    readonly property bool occupied: Hypr.isOccupied(workspaceId)
    readonly property bool hovered: area.containsMouse

    width: Tokens.workspace.size
    height: Tokens.workspace.size
    radius: Tokens.workspace.radius
    color: {
        if (active)
            return "transparent";
        if (hovered)
            return Colours.alpha(Colours.text, Tokens.workspace.hoverAlpha);
        if (occupied)
            return Colours.alpha(Colours.text, Tokens.workspace.occupiedAlpha);
        return "transparent";
    }

    Behavior on color {
        ColorAnim {}
    }

    StyledText {
        anchors.centerIn: parent
        text: root.workspaceId
        font.pixelSize: Tokens.font.size.body
        font.weight: root.active ? Font.Black : (root.occupied ? Font.Bold : Font.Medium)
        color: root.active ? Colours.crust : ((root.hovered || root.occupied) ? Colours.text : Colours.overlay0)

        Behavior on color {
            ColorAnim {}
        }
    }

    HoverArea {
        id: area

        onClicked: Hypr.focusWorkspace(root.workspaceId)
    }
}
