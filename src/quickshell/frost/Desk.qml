pragma Singleton
import QtQuick

// Desktop widget state shared with other surfaces: which screen is editing (the bar hides there, like the
// Widgets artboard), each screen's preset and widget count, and requests from Settings → Widget.
QtObject {
    property string editingScreen: ""
    property var screens: ({})              // monitor -> { preset, count }
    signal editRequested(string monitor)
    signal presetRequested(string monitor, string name)
    function report(monitor, preset, count) {
        let s = Object.assign({}, screens);
        s[monitor] = { preset: preset, count: count };
        screens = s;
    }
}
