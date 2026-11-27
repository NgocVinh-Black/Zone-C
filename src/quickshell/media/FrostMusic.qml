import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../"
import "../frost"

// Music player panel of the Frost design (Music.dc.html).
Item {
    id: root
    focus: true
    readonly property real fitHeight: col.implicitHeight + 40

    readonly property var player: MprisController.activePlayer
    readonly property bool has: player !== null && MprisController.trackTitle !== ""
    readonly property real len: player && player.length > 0 ? player.length : 0
    readonly property real pos: MprisController.livePosition
    readonly property string art: { let a = MprisController.artUrl || ""; return a === "" ? "" : (a.startsWith("/") ? "file://" + a : a); }
    readonly property string album: player && player.trackAlbum ? player.trackAlbum : ""
    property bool liked: false
    function fmt(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0"); }

    Component.onCompleted: Cava.registerConsumer()
    Component.onDestruction: Cava.unregisterConsumer()

    Glass {
        anchors.fill: parent
        radius: 24

        Column {
            id: col
            x: 20; y: 20
            width: parent.width - 40
            spacing: 16

            Row {
                width: parent.width
                spacing: 20
                MusicDisc { size: 150; art: root.art; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    width: parent.width - 150 - 36 - 40
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    FText { text: (root.has ? (MprisController.isPlaying ? Fz.tr("Đang phát") : Fz.tr("Tạm dừng")) + (root.player.identity ? " · " + root.player.identity : "") : Fz.tr("Trình phát nhạc")).toUpperCase()
                            color: Fz.sub; px: 11; weight: Font.DemiBold; font.letterSpacing: 11 * 0.08 }
                    FText { width: parent.width; elide: Text.ElideRight; text: root.has ? MprisController.trackTitle : Fz.tr("Không phát nhạc"); px: 22; weight: Font.DemiBold }
                    FText { width: parent.width; elide: Text.ElideRight; text: root.has ? MprisController.trackArtist : Fz.tr("Mở Spotify hoặc trình phát bất kỳ"); px: 14; color: Fz.sub }
                    FBtn {
                        visible: !root.has
                        readonly property var spotify: DesktopEntries.heuristicLookup("spotify")
                        text: spotify ? Fz.tr("Mở Spotify") : Fz.tr("Mở trình phát")
                        onClicked: spotify ? spotify.execute() : Fz.open("launcher")
                    }
                    Row {
                        topPadding: 6
                        spacing: 6
                        FChip { icon: "u-head"; text: Audio.defaultSink ? Fz.audioName(Audio.defaultSink) : ""; visible: text !== "" }
                        FChip { visible: root.album !== ""; text: "Album: " + root.album }
                    }
                }
                FIconBtn { ghost: !root.liked; on: root.liked; icon: "u-heart"; label: Fz.tr("Yêu thích"); anchors.verticalCenter: parent.verticalCenter; onClicked: root.liked = !root.liked }
            }

            Row {
                width: parent.width
                height: 34
                spacing: 3
                Repeater {
                    model: 48
                    delegate: Rectangle {
                        required property int index
                        readonly property real lv: {
                            let b = Cava.barLevels;
                            let v = (b && b.length) ? b[Math.floor(index * b.length / 48)] : 0;
                            return MprisController.isPlaying ? Math.max(0.08, Math.min(1, v)) : 0.08;
                        }
                        width: (parent.width - 47 * 3) / 48
                        height: 34 * lv
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
                Item {
                    width: parent.width; height: 6
                    FBar { anchors.fill: parent; value: root.len > 0 ? root.pos / root.len : 0 }
                    MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                onClicked: (e) => { if (root.player && root.player.canSeek && root.len > 0) root.player.position = root.len * Math.max(0, Math.min(1, e.x / width)); } }
                }
                Item {
                    width: parent.width; height: 15
                    FText { mono: true; text: root.fmt(root.pos); color: Fz.sub; px: 12 }
                    FText { anchors.right: parent.right; mono: true; text: root.fmt(root.len); color: Fz.sub; px: 12 }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12
                FIconBtn { ghost: !(root.player && root.player.shuffle); on: root.player ? root.player.shuffle === true : false; icon: "u-shuffle"; label: Fz.tr("Trộn bài")
                           onClicked: if (root.player && root.player.shuffleSupported) root.player.shuffle = !root.player.shuffle }
                FIconBtn { icon: "u-prev"; label: Fz.tr("Bài trước"); onClicked: if (root.player && root.player.canGoPrevious) root.player.previous() }
                FIconBtn { on: true; width: 60; height: 44; icon: MprisController.isPlaying ? "u-pause" : "u-play"; label: MprisController.isPlaying ? Fz.tr("Tạm dừng") : Fz.tr("Phát")
                           onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying() }
                FIconBtn { icon: "u-next"; label: Fz.tr("Bài tiếp"); onClicked: if (root.player && root.player.canGoNext) root.player.next() }
                FIconBtn { readonly property bool looping: root.player ? root.player.loopState !== MprisLoopState.None : false
                           ghost: !looping; on: looping; icon: "u-repeat"; label: Fz.tr("Lặp lại")
                           onClicked: if (root.player && root.player.loopSupported) root.player.loopState = looping ? MprisLoopState.None : MprisLoopState.Playlist }
            }
        }
    }
}
