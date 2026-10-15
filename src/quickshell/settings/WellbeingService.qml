import QtQuick
import Quickshell
import "../"

// Background half of Settings → Sức khỏe số: the 20-20-20 eye-break reminder and focus mode
// (focus mode turns on Không làm phiền and restores the previous state when it ends).
Scope {
    Timer {
        interval: 20 * 60 * 1000; repeat: true
        running: Config.getSetting("wellbeing.eyes", true) !== false
        onTriggered: Quickshell.execDetached(["notify-send", "-a", "Sức khỏe số", "-i", "eye", "Nghỉ mắt 20 giây", "Nhìn một vật cách khoảng 6 mét trong 20 giây."])
    }
    readonly property bool focus: Config.getSetting("wellbeing.focus", false) === true
    onFocusChanged: {
        if (!Config.dataReady) return;
        if (focus) {
            Config.setSetting("wellbeing.dndBefore", Config.getSetting("notifications.dnd", false) === true);
            Config.setSetting("notifications.dnd", true);
        } else {
            Config.setSetting("notifications.dnd", Config.getSetting("wellbeing.dndBefore", false) === true);
        }
    }
}
