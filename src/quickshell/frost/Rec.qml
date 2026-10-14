pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

// Screen recording state written by scripts/screenshot.sh (rec_pid + rec_start_epoch in the recording cache).
Item {
    id: root
    visible: false
    property bool active: false
    property real startEpoch: 0
    property int seconds: 0
    readonly property string elapsed: String(Math.floor(seconds / 60)).padStart(2, "0") + ":" + String(seconds % 60).padStart(2, "0")
    readonly property string dir: Caching.cacheDir ? Caching.cacheDir + "/recording" : ""

    Process {
        id: check
        command: ["bash", "-c", "d='" + root.dir + "'; p=$(cat \"$d/rec_pid\" 2>/dev/null); if [ -n \"$p\" ] && kill -0 \"$p\" 2>/dev/null; then cat \"$d/rec_start_epoch\" 2>/dev/null; else echo NONE; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                let e = parseInt(this.text.trim());
                root.active = !isNaN(e) && e > 0;
                root.startEpoch = root.active ? e : 0;
                root.seconds = root.active ? Math.max(0, Math.floor(Date.now() / 1000 - e)) : 0;
            }
        }
    }
    Timer { interval: 1000; running: root.dir !== ""; repeat: true; triggeredOnStart: true
        onTriggered: { if (root.active) root.seconds = Math.max(0, Math.floor(Date.now() / 1000 - root.startEpoch)); check.running = true; } }
}
