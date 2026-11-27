import QtQuick

// `.mi`: 36px menu row (accent on hover), optional icon, shortcut hint and submenu chevron.
Rectangle {
    id: root
    property string text: ""
    property string icon: ""
    property url image: ""
    property string hint: ""
    property bool chevron: false
    property bool danger: false
    property bool highlighted: false
    readonly property bool hl: highlighted || mouse.containsMouse
    signal triggered()
    width: parent ? parent.width : 240
    implicitWidth: row.implicitWidth + 20 + (hint !== "" ? hintT.implicitWidth + 24 : 0) + (chevron ? 30 : 0)
    implicitHeight: 36
    radius: 10
    color: hl ? Fz.acc : "transparent"
    readonly property color fgc: hl ? Fz.ink : (danger ? Fz.redTx : Fz.tx)
    Row {
        id: row
        x: 10; anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        FIcon { visible: root.icon !== ""; name: root.icon; size: 15; color: root.fgc; anchors.verticalCenter: parent.verticalCenter }
        Image { visible: root.icon === "" && root.image != ""; source: root.image; width: 15; height: 15; sourceSize: Qt.size(30, 30); anchors.verticalCenter: parent.verticalCenter }
        FText { text: root.text; px: 13.5; color: root.fgc; anchors.verticalCenter: parent.verticalCenter }
    }
    FText { id: hintT; visible: root.hint !== ""; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: root.hint; px: 11.5; opacity: 0.6; color: root.fgc }
    FIcon { visible: root.chevron; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; name: "chev"; size: 14; color: root.fgc }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.triggered() }
}
