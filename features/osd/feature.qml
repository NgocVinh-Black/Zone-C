import QtQuick
import qs.core.feature

// No bar widget and no popup: the OSD is an overlay that appears on its own when
// the volume changes. Name it in the `enabled` list of the shell config to load it.
Feature {
    name: "osd"
    overlay: Qt.resolvedUrl("OsdOverlay.qml")
}
