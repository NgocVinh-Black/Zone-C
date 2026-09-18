pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "MediaLogic.js" as Logic

// The current MPRIS player: the one playing, otherwise the first one.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null

    readonly property bool available: player !== null && title !== ""
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string artUrl: player?.trackArtUrl ?? ""
    readonly property string source: player?.identity ?? "Offline"

    // Seconds.
    readonly property real position: player?.position ?? 0
    readonly property real length: player?.lengthSupported ? player.length : 0
    readonly property real percent: length > 0 ? Math.min(100, position / length * 100) : 0
    readonly property string positionText: Logic.formatTime(position)
    readonly property string lengthText: Logic.formatTime(length)
    readonly property string timeText: positionText + " / " + lengthText

    function playPause(): void {
        if (player?.canTogglePlaying)
            player.togglePlaying();
    }

    function next(): void {
        if (player?.canGoNext)
            player.next();
    }

    function previous(): void {
        if (player?.canGoPrevious)
            player.previous();
    }

    // Seek to a 0–100 position.
    function seek(percentValue: real): void {
        if (player?.canSeek && length > 0)
            player.position = length * Math.max(0, Math.min(100, percentValue)) / 100;
    }

    // MPRIS doesn't push position updates; ask for a fresh value every second while playing.
    Timer {
        running: root.playing
        interval: 1000
        repeat: true
        onTriggered: root.player?.positionChanged()
    }
}
