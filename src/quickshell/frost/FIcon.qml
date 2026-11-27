import QtQuick
import QtQuick.Shapes
import "Icons.js" as Icons

// Stroke icon drawn from the design's inline SVG symbols (frost/Icons.js), like `.ic` in zone.css:
// no fill, currentColor stroke 1.75, round caps and joins.
Item {
    id: root
    property string name: ""
    property real size: 17
    property color color: Fz.tx
    property real strokeWidth: 1.75

    readonly property var icon: Icons.get(name)
    readonly property real _vb: icon ? icon.vb[2] : 24

    implicitWidth: size
    implicitHeight: size

    Item {
        width: root._vb
        height: root._vb
        scale: root.size / root._vb
        transformOrigin: Item.TopLeft

        Repeater {
            model: root.icon ? root.icon.parts : []
            delegate: Shape {
                required property var modelData
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: modelData.fill ? root.color : "transparent"
                    strokeColor: modelData.stroke ? root.color : "transparent"
                    strokeWidth: modelData.stroke ? (modelData.sw !== null ? modelData.sw : root.strokeWidth) : -1
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathSvg { path: modelData.d }
                }
            }
        }
    }
}
