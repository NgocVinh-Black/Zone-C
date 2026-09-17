pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "VolumeLogic.js" as Logic

// Default audio output from PipeWire.
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool available: Pipewire.ready && sink !== null
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property string icon: Logic.icon(volume, muted)
    readonly property string percentText: Math.round(volume * 100) + "%"

    function setVolume(value: real): void {
        if (sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function stepVolume(direction: int): void {
        setVolume(Logic.step(volume, direction, 0.05));
    }

    function toggleMute(): void {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    // Keeps the sink's audio properties bound and up to date.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
}
