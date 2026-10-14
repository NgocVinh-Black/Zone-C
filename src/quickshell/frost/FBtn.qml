import QtQuick

// `.btn`, `.btn.pri`, `.btn.danger`: text button, optional leading icon.
Rectangle {
    id: root
    property string text: ""
    property string icon: ""
    property real iconSize: 15
    property string kind: ""          // "" | "pri" | "danger"
    property real fontSize: 13
    property real padX: 14
    property bool hovered: mouse.containsMouse
    signal clicked()

    implicitHeight: 36
    implicitWidth: row.implicitWidth + padX * 2
    radius: 11
    color: kind === "pri" ? (hovered ? Fz.hi : Fz.acc)
         : kind === "danger" ? Fz.redA(0.16)
         : Fz.fg(hovered ? 0.12 : 0.06)
    border.width: kind === "pri" ? 0 : 1
    border.color: kind === "danger" ? Fz.redA(0.3) : Fz.line2
    readonly property color fgColor: kind === "pri" ? Fz.ink : kind === "danger" ? Fz.redTx : Fz.tx

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7
        FIcon { visible: root.icon !== ""; name: root.icon; size: root.iconSize; color: root.fgColor; anchors.verticalCenter: parent.verticalCenter }
        FText { visible: root.text !== ""; text: root.text; color: root.fgColor; px: root.fontSize; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
