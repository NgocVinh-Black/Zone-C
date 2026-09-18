pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// PipeWire audio shared by the volume and battery features: default devices,
// every output/input device and every application stream.
Singleton {
    id: root

    readonly property bool ready: Pipewire.ready
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property var nodes: Pipewire.nodes.values.filter(n => n.audio)
    readonly property var outputs: nodes.filter(n => n.isSink && !n.isStream)
    readonly property var inputs: nodes.filter(n => !n.isSink && !n.isStream)
    readonly property var streams: nodes.filter(n => n.isSink && n.isStream)

    // Default output, 0–1.
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    function setVolume(node: var, value: real): void {
        if (!node?.audio)
            return;
        if (value > 0 && node.audio.muted)
            node.audio.muted = false;
        node.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMute(node: var): void {
        if (node?.audio)
            node.audio.muted = !node.audio.muted;
    }

    function setDefault(node: var): void {
        if (!node)
            return;
        if (node.isSink)
            Pipewire.preferredDefaultAudioSink = node;
        else
            Pipewire.preferredDefaultAudioSource = node;
    }

    // Human name for a device or stream.
    function label(node: var): string {
        if (!node)
            return "";
        if (node.isStream)
            return node.properties?.["application.name"] || node.nickname || node.name;
        return node.description || node.nickname || node.name;
    }

    // Secondary line: the stream's media name, or the device's system name.
    function detail(node: var): string {
        if (!node)
            return "";
        if (node.isStream)
            return node.properties?.["media.name"] || "Audio Stream";
        return node.name;
    }

    // Keeps volume and mute of every tracked node bound and up to date.
    PwObjectTracker {
        objects: root.nodes
    }
}
