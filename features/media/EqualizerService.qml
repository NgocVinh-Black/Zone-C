pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.state
import "MediaLogic.js" as Logic

// 10-band equalizer applied through EasyEffects. Slider moves are pending until
// `apply()`; presets apply at once. State survives restarts.
Singleton {
    id: root

    readonly property var bands: Logic.BANDS
    readonly property var presetNames: Logic.PRESET_ORDER

    property var gains: Logic.PRESETS.Flat.slice()
    property string preset: "Flat"
    property bool pending: false
    // Bumped whenever settings are pushed to EasyEffects, so the UI can flash.
    property int applyCount: 0

    readonly property string presetName: "zone-c-eq"
    readonly property string presetPath: (Quickshell.env("XDG_CONFIG_HOME") || Paths.home + "/.config") + "/easyeffects/output/" + presetName + ".json"

    function label(index: int): string {
        return Logic.bandLabel(bands[index]);
    }

    function setBand(index: int, gain: int): void {
        const next = gains.slice();
        next[index] = Math.max(-12, Math.min(12, gain));
        gains = next;
        preset = "Custom";
        pending = true;
    }

    function applyPreset(name: string): void {
        if (!Logic.PRESETS[name])
            return;
        gains = Logic.PRESETS[name].slice();
        preset = name;
        apply();
    }

    function apply(): void {
        pending = false;
        applyCount++;
        stateFile.setText(JSON.stringify({
            gains: gains,
            preset: preset
        }));
        presetFile.setText(JSON.stringify(Logic.easyEffectsPreset(gains), null, 2));
        load.restart();
    }

    FileView {
        id: stateFile

        path: Paths.stateDir + "/equalizer.json"
        printErrors: false
        atomicWrites: true

        onLoaded: {
            const state = Logic.parseState(text());
            root.gains = state.gains;
            root.preset = state.preset;
        }
    }

    FileView {
        id: presetFile

        path: root.presetPath
        printErrors: false
        atomicWrites: true
    }

    // Give the preset file a moment to land before EasyEffects reads it.
    Timer {
        id: load

        interval: 150
        onTriggered: easyEffects.running = true
    }

    Process {
        id: easyEffects

        command: ["easyeffects", "-l", root.presetName]
        onExited: code => {
            if (code !== 0)
                console.warn("[zone-c equalizer] easyeffects exited with", code);
        }
    }

    Process {
        running: true
        command: ["mkdir", "-p", Paths.stateDir, root.presetPath.substring(0, root.presetPath.lastIndexOf("/"))]
    }
}
