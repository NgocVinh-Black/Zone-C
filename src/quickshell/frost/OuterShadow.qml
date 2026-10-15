import QtQuick
import QtQuick.Effects

// CSS box-shadow for a rounded rectangle the size of its parent: the shadow is cut out under the
// shape itself, so translucent glass above it is not darkened (QML's RectangularShadow alone fills
// underneath too).
Item {
    id: r
    property real radius: 24
    property real blur: 30
    property real offsetY: 10
    property color color: Qt.rgba(0, 0, 0, 0.3)
    anchors.fill: parent
    readonly property real m: blur + Math.abs(offsetY) + 6

    Item {
        id: src
        x: -r.m; y: -r.m
        width: r.width + 2 * r.m; height: r.height + 2 * r.m
        layer.enabled: r.width > 0 && r.height > 0
        layer.effect: MultiEffect { maskEnabled: true; maskInverted: true; maskSource: hole; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0 }
        RectangularShadow { x: r.m; y: r.m; width: r.width; height: r.height; radius: r.radius; blur: r.blur; offset.y: r.offsetY; color: r.color }
    }
    Item {
        id: hole
        visible: false
        layer.enabled: true
        width: src.width; height: src.height
        Rectangle { x: r.m; y: r.m; width: r.width; height: r.height; radius: r.radius; color: "black" }
    }
}
