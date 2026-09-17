pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The current MPRIS player: the one playing, otherwise the first one.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null

    readonly property bool available: player !== null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle || "Unknown title"
    readonly property string artist: player?.trackArtist || ""
    readonly property string artUrl: player?.trackArtUrl ?? ""

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
}
