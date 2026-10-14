import QtQuick
import "../../"
import "../../frost"

// "Hôm nay" agenda card of the Desktop artboard.
Glass {
    id: root
    implicitWidth: 348
    implicitHeight: col.implicitHeight + 32
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Fz.open("calendar") }
    Column {
        id: col
        x: 18; y: 16
        width: root.width - 36
        spacing: 10
        Row {
            spacing: 8
            FIcon { name: "m-cal"; size: 15; color: Fz.acc; anchors.verticalCenter: parent.verticalCenter }
            FText { text: "HÔM NAY"; color: Fz.sub; px: 11; weight: Font.DemiBold; font.letterSpacing: 11 * 0.08; anchors.verticalCenter: parent.verticalCenter }
        }
        Repeater {
            model: Agenda.today.slice(0, 3)
            delegate: Row {
                required property var modelData
                required property int index
                spacing: 12
                FText { width: 42; mono: true; text: modelData.time || ""; color: Fz.sub; px: 12.5; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 3; height: 30; radius: 2; color: index === 0 ? Fz.acc : Fz.s2; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    FText { text: modelData.title; px: 14; weight: Font.Medium; width: col.width - 70; elide: Text.ElideRight }
                    FText { text: [Agenda.untilText(modelData), modelData.note || ""].filter(s => s !== "").join(" · "); color: Fz.sub; px: 12; visible: text !== "" }
                }
            }
        }
        FText { visible: Agenda.today.length === 0; text: "Không có sự kiện nào hôm nay"; color: Fz.sub; px: 13 }
    }
}
