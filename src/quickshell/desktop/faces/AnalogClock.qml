import QtQuick
import QtQuick.Shapes
import "../../"
import "../../frost"

// "Đồng hồ kim": glass dial drawn like the editor tile (17/40 ring, hour and minute hands).
Glass {
    id: root
    implicitWidth: 200
    implicitHeight: 200
    radius: 100
    readonly property real hourA: ((DateTime.now.getHours() % 12) + DateTime.now.getMinutes() / 60) * 30
    readonly property real minA: DateTime.now.getMinutes() * 6
    Repeater {
        model: 12
        delegate: Rectangle {
            required property int index
            width: 2; height: index % 3 === 0 ? 10 : 5; radius: 1
            color: index % 3 === 0 ? Fz.acc : Fz.fg(0.3)
            x: root.width / 2 - 1; y: 14
            transform: Rotation { origin.x: 1; origin.y: root.height / 2 - 14; angle: index * 30 }
        }
    }
    Rectangle { x: root.width / 2 - 2; y: root.height / 2 - 52; width: 4; height: 54; radius: 2; color: Fz.acc
        transform: Rotation { origin.x: 2; origin.y: 52; angle: root.hourA } }
    Rectangle { x: root.width / 2 - 1.5; y: root.height / 2 - 76; width: 3; height: 78; radius: 1.5; color: Fz.tx
        transform: Rotation { origin.x: 1.5; origin.y: 76; angle: root.minA } }
    Rectangle { anchors.centerIn: parent; width: 10; height: 10; radius: 5; color: Fz.acc }
}
