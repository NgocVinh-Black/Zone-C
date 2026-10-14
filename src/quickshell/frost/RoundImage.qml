import QtQuick
import QtQuick.Effects

// Image clipped to a rounded rectangle (or a circle with radius = width / 2).
Item {
    id: root
    property url source
    property real radius: 10
    property int fillMode: Image.PreserveAspectCrop
    property size sourceSize: Qt.size(width * 2, height * 2)
    readonly property bool ready: img.status === Image.Ready

    Image { id: img; anchors.fill: parent; source: root.source; fillMode: root.fillMode; sourceSize: root.sourceSize; asynchronous: true; visible: false }
    Rectangle { id: mask; anchors.fill: parent; radius: root.radius; visible: false; layer.enabled: true }
    MultiEffect { anchors.fill: parent; source: img; maskEnabled: true; maskSource: mask; visible: root.ready }
}
