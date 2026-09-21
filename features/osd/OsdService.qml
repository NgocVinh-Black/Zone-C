pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import qs.core.services
import qs.core.state
import "OsdLogic.js" as Logic
import "schema.js" as Schema

// Decides when the volume OSD is on screen. The volume keys go through wpctl, so
// there is nothing to listen to but PipeWire itself.
Singleton {
    id: root

    readonly property var settings: Config.feature("osd", Schema.fields)

    readonly property real volume: Audio.volume
    readonly property bool muted: Audio.muted
    readonly property int percent: Logic.percent(volume)
    readonly property real fill: Logic.fill(volume)
    readonly property string icon: Logic.icon(volume, muted)

    property bool shown: false
    // PipeWire reports its starting volume a moment after the shell comes up;
    // without this the OSD would greet every login.
    property bool armed: false

    function flash(): void {
        // The volume popup already shows all of this, and better.
        if (!armed || ShellState.activePopup === "volume")
            return;
        shown = true;
        hideTimer.restart();
    }

    onVolumeChanged: flash()
    onMutedChanged: flash()

    Timer {
        id: hideTimer

        interval: root.settings.timeoutMs
        onTriggered: root.shown = false
    }

    Timer {
        running: true
        interval: 1500
        onTriggered: root.armed = true
    }
}
