import QtQuick
import qs.core.bar
import qs.core.config
import qs.core.services
import qs.core.theme
import qs.core.ui
import "schema.js" as Schema

// Numbered workspace buttons with a sliding highlight behind the active one.
BarWidget {
    id: root

    readonly property var settings: Config.feature("workspaces", Schema.fields)
    readonly property int shownCount: Math.max(settings.count, Hypr.activeWorkspaceId)
    readonly property int step: Tokens.workspace.size + Tokens.workspace.spacing

    implicitWidth: buttons.implicitWidth
    implicitHeight: Tokens.workspace.size

    Rectangle {
        id: highlight

        readonly property int activeIndex: Hypr.activeWorkspaceId - 1
        property int previousIndex: activeIndex
        readonly property real targetLeft: activeIndex * root.step
        property real left: targetLeft
        property real right: targetLeft + Tokens.workspace.size

        // The leading edge moves first so the pill stretches, then catches up.
        onActiveIndexChanged: {
            const forward = activeIndex > previousIndex;
            leftAnim.duration = forward ? Tokens.anim.highlightTrail : Tokens.anim.highlightLead;
            rightAnim.duration = forward ? Tokens.anim.highlightLead : Tokens.anim.highlightTrail;
            previousIndex = activeIndex;
            left = targetLeft;
            right = targetLeft + Tokens.workspace.size;
        }

        x: left
        width: right - left
        height: Tokens.workspace.size
        radius: Tokens.workspace.radius
        color: Colours.mauve

        Behavior on left {
            Anim {
                id: leftAnim

                easing.type: Easing.OutExpo
            }
        }

        Behavior on right {
            Anim {
                id: rightAnim

                easing.type: Easing.OutExpo
            }
        }
    }

    Row {
        id: buttons

        spacing: Tokens.workspace.spacing

        Repeater {
            model: root.shownCount

            delegate: WorkspaceButton {
                required property int index

                workspaceId: index + 1
            }
        }
    }
}
