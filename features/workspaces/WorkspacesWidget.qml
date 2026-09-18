import QtQuick
import qs.core.bar
import qs.core.config
import qs.core.services
import qs.core.theme
import "schema.js" as Schema

// Numbered workspace pills 1…count; the active workspace is shown too when it is beyond count.
BarWidget {
    id: root

    readonly property var settings: Config.feature("workspaces", Schema.fields)
    readonly property int shownCount: Math.max(settings.count, Hypr.activeWorkspaceId)

    implicitWidth: buttons.implicitWidth
    implicitHeight: Tokens.workspace.size

    Row {
        id: buttons

        spacing: Tokens.workspace.spacing

        Repeater {
            model: root.shownCount

            delegate: WorkspaceButton {
                workspaceId: index + 1
            }
        }
    }
}
