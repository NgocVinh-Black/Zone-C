import QtQuick
import QtQuick.Effects
import "../../"
import "../../frost"

// "Khung ảnh": a picture in a rounded glass frame; the path is kept in the widget data.
Glass {
    id: root
    property string path: ""
    implicitWidth: 300
    implicitHeight: 200
    radius: 22

    Item {
        anchors.fill: parent
        anchors.margins: 8
        Image {
            id: img
            anchors.fill: parent
            source: root.path ? "file://" + root.path : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }
        Rectangle { id: mask; anchors.fill: parent; radius: 16; visible: false; layer.enabled: true }
        MultiEffect { anchors.fill: parent; source: img; maskEnabled: true; maskSource: mask; visible: img.status === Image.Ready }
        Column {
            anchors.centerIn: parent
            visible: img.status !== Image.Ready
            spacing: 8
            FIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "w-image"; size: 34; color: Fz.acc }
            FText { anchors.horizontalCenter: parent.horizontalCenter; text: "Chọn ảnh trong chế độ chỉnh widget"; color: Fz.sub; px: 12.5 }
        }
    }
}
