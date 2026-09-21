pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import "ScaleMath.js" as ScaleMath

// Scales pixel sizes designed for 1920x1080 to the primary screen.
// Not named Scale: QtQuick has a Scale type, and it wins the name lookup
// in every file that imports QtQuick, which is all of them.
Singleton {
    readonly property var screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    readonly property real factor: screen ? ScaleMath.getScale(screen.width, screen.height, Config.general.uiScale) : Config.general.uiScale

    function s(value: real): int {
        return ScaleMath.s(value, factor);
    }
}
