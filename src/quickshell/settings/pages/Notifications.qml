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
        for (const a of ["Zone-C Updater", Fz.tr("Ảnh chụp màn hình"), Fz.tr("Thời tiết")]) if (!seen[a]) { seen[a] = true; out.push(a); }
        return out.slice(0, 12);
    }
    readonly property var appDesc: ({ "Zone-C Updater": "pacman · yay", [Fz.tr("Ảnh chụp màn hình")]: Fz.tr("Kèm ảnh xem trước"), [Fz.tr("Thời tiết")]: Fz.tr("Cảnh báo mưa"), "Viber": Fz.tr("Biểu ngữ · trả lời nhanh") })
    function setMuted(a, mute) {
        let m = muted.filter(x => x !== a);
        if (mute) m.push(a);
        Config.setSetting("notifications.mutedApps", m);
    }

    Grp {
        width: parent.width
        SRow { icon: "s-notif"; title: Fz.tr("Không làm phiền"); sub: Fz.tr("Tắt thông báo nổi trừ cảnh báo quan trọng"); CfgToggle { key: "notifications.dnd" } }
        SRow {
            title: Fz.tr("Vị trí thông báo nổi")
            CfgSelect {
                key: "notifications.position"; def: "top right"
                options: [Fz.tr("Trên cùng bên phải"), Fz.tr("Trên cùng bên trái"), Fz.tr("Giữa phía trên"), Fz.tr("Dưới cùng bên phải"), Fz.tr("Dưới cùng bên trái"), Fz.tr("Giữa phía dưới")]
                values: ["top right", "top left", "top center", "bottom right", "bottom left", "bottom center"]
            }
        }
        SRow { title: Fz.tr("Âm thanh thông báo"); CfgToggle { key: "notifications.sound"; def: true } }
        SRow {
            title: Fz.tr("Hiệu ứng âm thanh")
            FSelect {
                options: page.sounds.map(f => f.replace(/\.\w+$/, ""))
                current: page.soundIdx
                onPicked: (i) => Config.setSetting("notifications.soundFile", page.soundDir + page.sounds[i])
            }
            FIconBtn { icon: "s-play"; iconSize: 14; label: Fz.tr("Nghe thử"); onClicked: Quickshell.execDetached(["pw-play", page.soundDir + page.sounds[page.soundIdx]]) }
        }
        SRow { title: Fz.tr("Hoạt ảnh khi trống"); sub: Fz.tr("Hình minh họa khi không có thông báo nào"); CfgToggle { key: "notifications.showEmptyGraphic"; def: true } }
    }

    H3 { text: Fz.tr("Ứng dụng") }
    Grp {
        width: parent.width
        Repeater {
            model: page.apps
            delegate: SRow {
                required property var modelData
                title: modelData; sub: page.appDesc[modelData] || Fz.tr("Biểu ngữ · âm thanh")
                FToggle { on: page.muted.indexOf(modelData) === -1; onToggled: (v) => page.setMuted(modelData, !v) }
            }
        }
    }
    Item { width: 1; height: 12 }
    FBtn { text: Fz.tr("Thử nghiệm thông báo"); onClicked: Quickshell.execDetached(["notify-send", "-a", "Zone-C", Fz.tr("Thông báo thử"), Fz.tr("Đây là thông báo thử từ Cài đặt.")]) }
}
