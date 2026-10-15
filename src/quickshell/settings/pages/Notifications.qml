import QtQuick
import Quickshell
import "../"
import "../../"
import "../../frost"

// Thông báo: do-not-disturb, toast position, sound and its effect, empty-state art, per-app muting.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    readonly property string soundDir: Caching.zoneCDir + "/assets/sounds/notifications/"
    readonly property var sounds: ["Botanica.wav", "Curious.mp3", "Progress.wav", "Sine.wav", "Sneak.mp3", "WakeUp.mp3", "Wobbly.mp3"]
    readonly property string soundFile: Config.getSetting("notifications.soundFile", "") || ""
    readonly property int soundIdx: Math.max(0, sounds.findIndex(f => soundFile.endsWith("/" + f)))
    readonly property var muted: Config.getSetting("notifications.mutedApps", []) || []
    // apps seen in the notification history, plus a few the shell itself sends
    readonly property var apps: {
        let m = NotificationManager.globalNotificationHistory, seen = {}, out = [];
        for (let i = 0; m && i < m.count; i++) { let a = m.get(i).appName; if (a && !seen[a]) { seen[a] = true; out.push(a); } }
        for (const a of ["Zone-C Updater", "Ảnh chụp màn hình", "Thời tiết"]) if (!seen[a]) { seen[a] = true; out.push(a); }
        return out.slice(0, 12);
    }
    readonly property var appDesc: ({ "Zone-C Updater": "pacman · yay", "Ảnh chụp màn hình": "Kèm ảnh xem trước", "Thời tiết": "Cảnh báo mưa", "Viber": "Biểu ngữ · trả lời nhanh" })
    function setMuted(a, mute) {
        let m = muted.filter(x => x !== a);
        if (mute) m.push(a);
        Config.setSetting("notifications.mutedApps", m);
    }

    Grp {
        width: parent.width
        SRow { icon: "s-notif"; title: "Không làm phiền"; sub: "Tắt thông báo nổi trừ cảnh báo quan trọng"; CfgToggle { key: "notifications.dnd" } }
        SRow {
            title: "Vị trí thông báo nổi"
            CfgSelect {
                key: "notifications.position"; def: "top right"
                options: ["Trên cùng bên phải", "Trên cùng bên trái", "Giữa phía trên", "Dưới cùng bên phải", "Dưới cùng bên trái", "Giữa phía dưới"]
                values: ["top right", "top left", "top center", "bottom right", "bottom left", "bottom center"]
            }
        }
        SRow { title: "Âm thanh thông báo"; CfgToggle { key: "notifications.sound"; def: true } }
        SRow {
            title: "Hiệu ứng âm thanh"
            FSelect {
                options: page.sounds.map(f => f.replace(/\.\w+$/, ""))
                current: page.soundIdx
                onPicked: (i) => Config.setSetting("notifications.soundFile", page.soundDir + page.sounds[i])
            }
            FIconBtn { icon: "s-play"; iconSize: 14; label: "Nghe thử"; onClicked: Quickshell.execDetached(["pw-play", page.soundDir + page.sounds[page.soundIdx]]) }
        }
        SRow { title: "Hoạt ảnh khi trống"; sub: "Hiện mèo ngủ khi không có thông báo"; CfgToggle { key: "notifications.showEmptyGraphic"; def: true } }
    }

    H3 { text: "Ứng dụng" }
    Grp {
        width: parent.width
        Repeater {
            model: page.apps
            delegate: SRow {
                required property var modelData
                title: modelData; sub: page.appDesc[modelData] || "Biểu ngữ · âm thanh"
                FToggle { on: page.muted.indexOf(modelData) === -1; onToggled: (v) => page.setMuted(modelData, !v) }
            }
        }
    }
    Item { width: 1; height: 12 }
    FBtn { text: "Thử nghiệm thông báo"; onClicked: Quickshell.execDetached(["notify-send", "-a", "Zone-C", "Thông báo thử", "Đây là thông báo thử từ Cài đặt."]) }
}
