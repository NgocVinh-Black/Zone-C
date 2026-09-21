import QtQuick
import qs.core.feature

// No bar widget: the clipboard is opened by keybind. Name it in the `enabled`
// list of the shell config to load it.
Feature {
    name: "clipboard"
    popup: ({
            component: Qt.resolvedUrl("ClipboardPopup.qml"),
            anchor: "center",
            width: 800,
            height: 700,
            keyboard: "exclusive"
        })
}
