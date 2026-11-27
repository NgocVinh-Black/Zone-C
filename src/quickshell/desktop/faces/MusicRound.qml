import QtQuick
import QtQuick.Effects
import "../../"
import "../../frost"

// "Nhạc · tròn" (Widgets artboard): round glass with the cover and the track name.
Glass {
    id: root
    implicitWidth: 200
    implicitHeight: 200
    radius: 100
    readonly property string art: { let a = MprisController.artUrl || ""; return a === "" ? "" : (a.startsWith("/") ? "file://" + a : a); }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (MprisController.activePlayer) MprisController.activePlayer.togglePlaying() }
    Column {
        anchors.centerIn: parent
        spacing: 8
        Item {
            width: 86; height: 86
            anchors.horizontalCenter: parent.horizontalCenter
            Image { id: cov; anchors.fill: parent; source: root.art; fillMode: Image.PreserveAspectCrop; visible: false; sourceSize: Qt.size(172, 172) }
            Rectangle { id: m; anchors.fill: parent; radius: 43; visible: false; layer.enabled: true }
            MultiEffect { anchors.fill: parent; source: cov; maskEnabled: true; maskSource: m; visible: cov.status === Image.Ready }
            Rectangle { anchors.fill: parent; radius: 43; visible: cov.status !== Image.Ready; color: Fz.light ? Fz.s0 : Fz.crust
                FIcon { anchors.centerIn: parent; name: "music"; size: 34; color: Fz.acc } }
        }
        FText { anchors.horizontalCenter: parent.horizontalCenter; width: Math.min(implicitWidth, 160); elide: Text.ElideRight
            text: MprisController.trackTitle || Fz.tr("Không phát nhạc"); px: 12.5; weight: Font.DemiBold }
    }
}
