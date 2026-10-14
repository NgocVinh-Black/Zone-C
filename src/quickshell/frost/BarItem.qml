import QtQuick

// `.it` from TopBar.dc.html: 32px clickable slot inside a bar pill; `.it.on` when its panel is open.
Rectangle {
    id: root
    default property alias content: row.data
    property bool on: false
    property real padX: 10
    property string label: ""
    readonly property bool hovered: mouse.containsMouse
    readonly property color fgColor: on ? Fz.ink : (hovered ? Fz.tx : Fz.sub2)
    signal clicked()
    signal rightClicked()
    signal wheel(int steps)

    implicitWidth: row.implicitWidth + padX * 2
    implicitHeight: 32
    radius: 10
    color: on ? Fz.acc : (hovered ? Fz.fg(0.08) : "transparent")
    Accessible.role: Accessible.Button
    Accessible.name: label

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (e) => e.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        onWheel: (e) => root.wheel(e.angleDelta.y > 0 ? 1 : -1)
    }
}
