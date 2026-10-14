import QtQuick
import QtQuick.Shapes

// Progress ring of the "Tài nguyên" card: track fg .1, accent arc, value centred in Geist Mono.
Item {
    id: root
    property real value: 0        // 0..100
    property string label: ""
    property real size: 62
    property real thickness: 3.2 * size / 36
    implicitWidth: size
    implicitHeight: size

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Fz.fg(0.1); strokeWidth: root.thickness; fillColor: "transparent"
            PathAngleArc { centerX: root.size / 2; centerY: root.size / 2; radiusX: root.size * 15 / 36; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
        }
        ShapePath {
            strokeColor: Fz.acc; strokeWidth: root.thickness; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: root.size / 2; centerY: root.size / 2; radiusX: root.size * 15 / 36; radiusY: radiusX; startAngle: -90; sweepAngle: 360 * Math.max(0, Math.min(100, root.value)) / 100 }
        }
    }
    FText { anchors.centerIn: parent; text: root.label; mono: true; px: 12.5; weight: Font.Medium }
}
