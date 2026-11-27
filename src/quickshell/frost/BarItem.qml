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
    // tooltip: the label in a small glass bubble under the item after a short hover (the bar window
    // keeps 36px of transparent room below the bar for shadows, which fits it)
    property bool tipShown: false
    Timer { interval: 600; running: root.hovered && root.label !== "" && !root.on; onTriggered: root.tipShown = true }
    onHoveredChanged: if (!hovered) tipShown = false
    Rectangle {
        visible: root.tipShown && root.hovered
        z: 100
        y: root.height + 6
        // centred under the item, but kept 6px inside the bar window so the end items' tips aren't cut off
        x: {
            let cx = (root.width - width) / 2;
            let win = root.Window.window;
            if (!win || !root.tipShown) return Math.round(cx);
            let gx = root.mapToItem(null, 0, 0).x;
            return Math.round(Math.max(6 - gx, Math.min(cx, win.width - 6 - gx - width)));
        }
        width: tip.implicitWidth + 18; height: 24; radius: 8
        color: Fz.mantle
        border.width: 1; border.color: Fz.line2
        FText { id: tip; anchors.centerIn: parent; text: root.label; px: 12; color: Fz.tx }
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
