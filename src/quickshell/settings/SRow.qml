import QtQuick
import "../frost"

// `.row` of the settings design: optional `.ico`, a `.lbl` (title + sub) that takes the free width,
// then the controls passed as children, right-aligned with a 14px gap.
Item {
    id: r
    property string title: ""
    property string sub: ""
    property bool subMono: false
    property bool titleMono: false
    property real titleSize: 14
    property int titleWeight: Font.Medium
    property string icon: ""
    property string iconText: ""
    property bool iconOn: false
    property real iconWidth: 36
    property string image: ""
    property real minH: 56
    default property alias content: right.data
    width: parent ? parent.width : 0
    // when the controls would squeeze the label (narrow window), they move under it
    readonly property bool stacked: right.implicitWidth > 0 && right.implicitWidth > (r.width - lbl.x - 16) * 0.6
    implicitHeight: stacked ? lbl.implicitHeight + right.implicitHeight + 10 + 24 : Math.max(minH, lbl.implicitHeight + 20, right.implicitHeight + 20)

    Rectangle {
        id: ico
        visible: r.icon !== "" || r.iconText !== ""
        x: 16; anchors.verticalCenter: parent.verticalCenter
        width: r.iconWidth; height: 36; radius: 11
        color: r.iconOn ? Fz.acc : Fz.fg(0.07)
        FIcon { visible: r.icon !== ""; anchors.centerIn: parent; name: r.icon; color: r.iconOn ? Fz.ink : Fz.acc }
        FText { visible: r.iconText !== ""; anchors.centerIn: parent; text: r.iconText; px: 12; weight: Font.Bold; mono: r.iconText.indexOf(":") !== -1; color: r.iconOn ? Fz.ink : Fz.acc }
    }
    RoundImage {
        id: img
        visible: r.image !== ""
        x: 16; anchors.verticalCenter: parent.verticalCenter
        width: 44; height: 44; radius: 22
        source: r.image
    }
    Column {
        id: lbl
        x: img.visible ? 16 + 44 + 14 : ico.visible ? 16 + ico.width + 14 : 16
        width: r.stacked ? r.width - x - 16 : Math.max(40, r.width - x - 16 - (right.implicitWidth > 0 ? right.implicitWidth + 14 : 0))
        y: r.stacked ? 12 : (r.height - implicitHeight) / 2
        spacing: 2
        FText { width: parent.width; elide: Text.ElideRight; text: r.title; mono: r.titleMono; px: r.titleSize; weight: r.titleWeight }
        FText { width: parent.width; elide: Text.ElideRight; visible: r.sub !== ""; text: r.sub; mono: r.subMono; px: 12.5; color: Fz.sub }
    }
    Row {
        id: right
        anchors.right: parent.right; anchors.rightMargin: 16
        y: r.stacked ? lbl.y + lbl.implicitHeight + 10 : (r.height - implicitHeight) / 2
        spacing: 14
    }
}
