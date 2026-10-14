import QtQuick

// `.seg`: segmented control. options: [{label, icon?}] or strings; current: index.
Rectangle {
    id: root
    property var options: []
    property int current: 0
    property real btnHeight: 30
    property real btnWidth: 0          // 0 = fit content
    property real fontSize: 13
    signal picked(int index)

    implicitWidth: row.implicitWidth + 6
    implicitHeight: btnHeight + 6
    radius: 12
    color: Fz.well(0.22)
    border.width: 1
    border.color: Fz.line

    Row {
        id: row
        x: 3; y: 3
        spacing: 2
        Repeater {
            model: root.options
            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool on: index === root.current
                readonly property string segLabel: typeof modelData === "string" ? modelData : (modelData.label || "")
                readonly property string segIcon: typeof modelData === "string" ? "" : (modelData.icon || "")
                width: root.btnWidth > 0 ? root.btnWidth : content.implicitWidth + 24
                height: root.btnHeight
                radius: 9
                color: on ? Fz.acc : "transparent"
                Row {
                    id: content
                    anchors.centerIn: parent
                    spacing: 6
                    FIcon { visible: segIcon !== ""; name: segIcon; size: segLabel === "" ? 20 : 14; color: on ? Fz.ink : (segMouse.containsMouse ? Fz.tx : Fz.sub2); anchors.verticalCenter: parent.verticalCenter }
                    FText { visible: segLabel !== ""; text: segLabel; px: root.fontSize; weight: Font.Medium; color: on ? Fz.ink : (segMouse.containsMouse ? Fz.tx : Fz.sub2); anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: segMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.current = index; root.picked(index); } }
            }
        }
    }
}
