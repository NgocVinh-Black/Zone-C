import QtQuick
import QtQuick.Effects

// Record-style cover from the desktop music card: dark disc, dashed groove, round cover ringed in accent.
Item {
    id: root
    property real size: 84
    property string art: ""
    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.fill: parent; radius: width / 2; color: Fz.light ? Fz.s0 : Fz.crust
        border.width: 1; border.color: Fz.fg(0.1)
    }
    Canvas {
        id: groove
        anchors.fill: parent; anchors.margins: root.size * 0.1
        onPaint: { let c = getContext("2d"); c.reset(); c.strokeStyle = Fz.fg(Fz.light ? 0.2 : 0.18); c.lineWidth = 1; c.setLineDash([3, 3]);
                   c.beginPath(); c.arc(width / 2, height / 2, width / 2 - 0.5, 0, Math.PI * 2); c.stroke(); }
        Connections { target: Fz; function onLightChanged() { groove.requestPaint(); } }
    }
    Rectangle {
        anchors.centerIn: parent
        width: root.size * 0.5 + 8; height: width; radius: width / 2
        color: Fz.accA(Fz.light ? 0.4 : 0.35)
        Rectangle { anchors.fill: parent; anchors.margins: 1; radius: width / 2; color: Fz.light ? Fz.s0 : Fz.crust }
    }
    Item {
        anchors.centerIn: parent
        width: root.size * 0.5; height: width
        Image {
            id: cover
            anchors.fill: parent
            source: root.art
            fillMode: Image.PreserveAspectCrop
            visible: false
            sourceSize: Qt.size(128, 128)
        }
        MultiEffect {
            anchors.fill: parent; source: cover; visible: cover.status === Image.Ready
            maskEnabled: true; maskSource: coverMask
        }
        Rectangle { id: coverMask; anchors.fill: parent; radius: width / 2; visible: false; layer.enabled: true }
        FIcon { anchors.centerIn: parent; visible: cover.status !== Image.Ready; name: "music"; size: parent.width * 0.5; color: Fz.acc }
    }
}
