import QtQuick
import "../../"
import "../../frost"

// "Tài nguyên" card of the Desktop artboard: CPU, RAM, disk, temperature rings.
Glass {
    id: root
    implicitWidth: 348
    implicitHeight: 120
    Component.onCompleted: SysData.subscribe()
    Component.onDestruction: SysData.unsubscribe()
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Fz.open("taskmanager") }
    Row {
        x: 20; y: 18
        width: root.width - 40
        Repeater {
            model: [["CPU", SysData.cpu, SysData.cpu + "%"], ["RAM", SysData.ramPercent, SysData.ramPercent + "%"],
                    [Fz.tr("Ổ đĩa"), SysData.diskPercent, SysData.diskPercent + "%"], [Fz.tr("Nhiệt"), SysData.temp, SysData.temp + "°"]]
            delegate: Column {
                required property var modelData
                width: (root.width - 40) / 4
                spacing: 6
                Ring { anchors.horizontalCenter: parent.horizontalCenter; size: 62; value: modelData[1]; label: modelData[2] }
                FText { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[0]; color: Fz.sub; px: 12 }
            }
        }
    }
}
