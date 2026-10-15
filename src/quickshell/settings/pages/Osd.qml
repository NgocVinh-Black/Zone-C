import QtQuick
import "../"
import "../../"
import "../../frost"

// OSD: which pop-ups show, where, and for how long, with a live preview.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    Grp {
        width: parent.width
        SRow { title: "Âm lượng"; CfgToggle { key: "osd.volume"; def: true } }
        SRow { title: "Độ sáng"; CfgToggle { key: "osd.brightness"; def: true } }
        SRow { title: "Đổi bộ gõ (VI / US)"; CfgToggle { key: "osd.kb"; def: true } }
        SRow { title: "Caps Lock / Num Lock"; CfgToggle { key: "osd.caps"; def: true } }
        SRow { title: "Vị trí"; CfgSeg { key: "osd.position"; def: "bottom"; options: ["Trên", "Dưới", "Phải"]; values: ["top", "bottom", "right"] } }
        SRow { title: "Thời gian hiển thị"; CfgSelect { key: "osd.duration"; def: 1500; options: ["1 giây", "1.5 giây", "3 giây"]; values: [1000, 1500, 3000] } }
    }
    H3 { text: "Xem trước" }
    Card {
        width: parent.width; height: 96
        Glass {
            anchors.centerIn: parent
            width: 300; height: 56; radius: 28
            Row {
                x: 20; anchors.verticalCenter: parent.verticalCenter
                spacing: 14
                FIcon { name: "s-sound"; anchors.verticalCenter: parent.verticalCenter }
                FBar { width: 300 - 40 - 17 - 28 - 30; value: OsdController.sysVolume / 100; anchors.verticalCenter: parent.verticalCenter }
                FText { text: Math.round(OsdController.sysVolume); mono: true; px: 13; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: OsdController.show("volume") }
        }
    }
}
