import QtQuick
import Quickshell.Services.Mpris
import "../../"
import "../../frost"

// Desktop music card (Main.dc.html): disc cover, track, visualiser bars, progress and transport.
Glass {
    id: root
    implicitWidth: 380
    implicitHeight: col.implicitHeight + 36
    readonly property var player: MprisController.activePlayer
    readonly property bool has: player !== null && MprisController.trackTitle !== ""
    readonly property real len: player && player.length > 0 ? player.length : 0
    readonly property real pos: MprisController.livePosition
    readonly property string art: {
        let a = MprisController.artUrl || "";
        return a === "" ? "" : (a.startsWith("/") ? "file://" + a : a);
    }
    function fmt(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0"); }

    Component.onCompleted: Cava.registerConsumer()
    Component.onDestruction: Cava.unregisterConsumer()

    Column {
        id: col
        x: 18; y: 18
        width: root.width - 36
        spacing: 14

        Row {
            width: parent.width
            spacing: 16
            MusicDisc { size: 84; art: root.art; anchors.verticalCenter: parent.verticalCenter }
            Column {
                width: parent.width - 84 - 36 - 32
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                FText { text: (root.has ? (MprisController.isPlaying ? Fz.tr("Đang phát") : Fz.tr("Tạm dừng")) + (root.player.identity ? " · " + root.player.identity : "") : Fz.tr("Trình phát nhạc")).toUpperCase(); color: Fz.sub; px: 11; weight: Font.DemiBold; font.letterSpacing: 11 * 0.08 }
                FText { width: parent.width; elide: Text.ElideRight; text: root.has ? MprisController.trackTitle : Fz.tr("Không phát nhạc"); px: 17; weight: Font.DemiBold }
                FText { width: parent.width; elide: Text.ElideRight; text: root.has ? MprisController.trackArtist : Fz.tr("Mở Spotify hoặc trình phát bất kỳ"); color: Fz.sub; px: 13 }
            }
            FIconBtn { ghost: true; icon: "m-heart"; label: Fz.tr("Yêu thích"); anchors.verticalCenter: parent.verticalCenter }
        }

        Row {
            width: parent.width
            height: 28
            spacing: 3
            Repeater {
                model: 40
                delegate: Rectangle {
                    required property int index
                    readonly property real lv: {
                        let b = Cava.barLevels;
                        let v = (b && b.length) ? b[Math.floor(index * b.length / 40)] : 0;
                        return MprisController.isPlaying ? Math.max(0.08, Math.min(1, v)) : 0.08;
                    }
                    width: (parent.width - 39 * 3) / 40
                    height: 28 * lv
                    anchors.bottom: parent.bottom
                    radius: 2
                    color: Fz.accA(0.35 + lv / 2)
                    Behavior on height { NumberAnimation { duration: 90 } }
                }
            }
        }

        Column {
            width: parent.width
            spacing: 6
            FBar { width: parent.width; value: root.len > 0 ? root.pos / root.len : 0 }
            Item {
                width: parent.width; height: 14
                FText { mono: true; text: root.fmt(root.pos); color: Fz.sub; px: 11.5 }
                FText { anchors.right: parent.right; mono: true; text: root.fmt(root.len); color: Fz.sub; px: 11.5 }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            FIconBtn { ghost: true; icon: "m-shuffle"; label: Fz.tr("Trộn bài"); on: root.player ? root.player.shuffle === true : false
                onClicked: if (root.player && root.player.shuffleSupported) root.player.shuffle = !root.player.shuffle }
            FIconBtn { icon: "m-prev"; label: Fz.tr("Bài trước"); onClicked: if (root.player && root.player.canGoPrevious) root.player.previous() }
            FIconBtn { on: true; width: 56; height: 42; icon: MprisController.isPlaying ? "m-pause" : "m-play"; label: MprisController.isPlaying ? Fz.tr("Tạm dừng") : Fz.tr("Phát")
                onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying() }
            FIconBtn { icon: "m-next"; label: Fz.tr("Bài tiếp"); onClicked: if (root.player && root.player.canGoNext) root.player.next() }
            FIconBtn { ghost: true; icon: "m-repeat"; label: Fz.tr("Lặp lại"); on: root.player ? root.player.loopState !== MprisLoopState.None : false
                onClicked: if (root.player && root.player.loopSupported) root.player.loopState = root.player.loopState === MprisLoopState.None ? MprisLoopState.Playlist : MprisLoopState.None }
        }
    }
}
