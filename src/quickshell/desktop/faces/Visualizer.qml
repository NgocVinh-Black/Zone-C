import QtQuick
import "../../"
import "../../frost"

// "Visualizer · cava" (Widgets artboard): 40 accent bars on glass.
Glass {
    id: root
    implicitWidth: 540
    implicitHeight: 100
    radius: 22
    Component.onCompleted: Cava.registerConsumer()
    Component.onDestruction: Cava.unregisterConsumer()
    Row {
        anchors.fill: parent; anchors.margins: 14
        spacing: 4
        Repeater {
            model: 40
            delegate: Rectangle {
                required property int index
                readonly property real lv: { let b = Cava.barLevels; let v = (b && b.length) ? b[Math.floor(index * b.length / 40)] : 0; return Math.max(0.06, Math.min(1, v)); }
                width: (parent.width - 39 * 4) / 40
                height: parent.height * lv
                anchors.bottom: parent.bottom
                radius: 2
                color: Fz.acc
                opacity: 0.4 + lv / 1.7
                Behavior on height { NumberAnimation { duration: 90 } }
            }
        }
    }
}
