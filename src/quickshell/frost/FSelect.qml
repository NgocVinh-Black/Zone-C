import QtQuick
import QtQuick.Window

// `.sel`: drop-down (36px, base background). options: strings; current: index.
// The list opens on the window's top layer so clipped groups and scroll views don't cut it off.
Rectangle {
    id: root
    property var options: []
    property int current: 0
    property bool enabled_: true
    signal picked(int index)
    FontMetrics { id: fm; font.family: Fz.font; font.pointSize: 13.5 * 0.75 }
    implicitWidth: Math.max(130, options.reduce((m, o) => Math.max(m, fm.advanceWidth(String(o))), 0) + 48)
    implicitHeight: 36
    radius: 11
    color: Fz.base
    border.width: 1
    border.color: list.visible ? Fz.glow : Fz.line2
    opacity: enabled_ ? 1 : 0.5

    FText { id: label; x: 10; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 34; elide: Text.ElideRight; text: root.options[root.current] || ""; px: 13.5 }
    FIcon { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; name: "chev"; size: 14; color: Fz.sub; rotation: 90 }
    MouseArea { anchors.fill: parent; enabled: root.enabled_; cursorShape: Qt.PointingHandCursor; onClicked: list.visible ? root.close() : root.open() }

    function open() {
        let host = root.Window.window ? root.Window.window.contentItem : null;
        if (host) {
            catcher.parent = host; list.parent = host;
            let p = root.mapToItem(host, 0, root.height + 4);
            list.x = Math.min(p.x, host.width - list.width - 8);
            list.y = p.y + list.height > host.height - 8 ? root.mapToItem(host, 0, 0).y - list.height - 4 : p.y;
        } else {
            list.x = 0; list.y = root.height + 4;
        }
        catcher.visible = true; list.visible = true;
    }
    function close() { list.visible = false; catcher.visible = false; }
    Component.onDestruction: { list.destroy(); catcher.destroy(); }

    MouseArea {
        id: catcher
        visible: false
        z: 999
        width: parent ? parent.width : 0; height: parent ? parent.height : 0
        onPressed: root.close()
        onWheel: root.close()
    }
    Rectangle {
        id: list
        visible: false
        z: 1000
        width: root.width
        height: Math.min(col.implicitHeight + 8, 320)
        radius: 11
        color: Fz.mantle
        border.width: 1; border.color: Fz.line2
        Flickable {
            anchors.fill: parent; anchors.margins: 4
            contentHeight: col.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: col
                width: parent.width
                Repeater {
                    model: root.options
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: col.width; height: 32; radius: 8
                        color: index === root.current ? Fz.acc : (optMouse.containsMouse ? Fz.fg(0.06) : "transparent")
                        FText { id: optText; x: 8; anchors.verticalCenter: parent.verticalCenter; text: modelData; px: 13; color: index === root.current ? Fz.ink : Fz.tx }
                        MouseArea { id: optMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { root.current = index; root.picked(index); root.close(); } }
                    }
                }
            }
        }
    }
}
