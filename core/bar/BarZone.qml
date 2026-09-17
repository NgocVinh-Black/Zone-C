import QtQuick
import qs.core.theme

// A horizontal run of bar groups (left, center or right).
Row {
    id: root

    required property var groups
    required property var screen
    required property var barWindow

    spacing: Tokens.block.gap

    Repeater {
        model: root.groups

        delegate: BarGroup {
            required property var modelData

            names: modelData
            screen: root.screen
            barWindow: root.barWindow
        }
    }
}
