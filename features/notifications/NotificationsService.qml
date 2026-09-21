pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.core.config
import "NotificationsLogic.js" as Logic
import "schema.js" as Schema

// The shell is the notification daemon: it owns org.freedesktop.Notifications, so
// no other daemon may run alongside it. Arrivals become toasts (unless do-not-disturb
// is on) and stay in the centre until they are dismissed.
Singleton {
    id: root

    readonly property var settings: Config.feature("notifications", Schema.fields)

    property bool doNotDisturb: false
    // Ids currently shown as toasts, newest first.
    property var toastIds: []
    // Arrival times, by id; the server does not keep them.
    property var times: ({})
    // Ticks so the "3m ago" labels stay honest without a timer per card.
    property double now: Date.now()

    readonly property var entries: Logic.order(server.trackedNotifications.values.map(notification => ({
                notification: notification,
                urgency: notification.urgency,
                time: root.times[notification.id] ?? 0
            })))
    readonly property int count: entries.length
    readonly property var toasts: toastIds.map(id => entries.find(entry => entry.notification.id === id)).filter(entry => !!entry)

    function receivedAt(id: int): double {
        return times[id] ?? now;
    }

    function hideToast(id: int): void {
        toastIds = toastIds.filter(other => other !== id);
    }

    function dismiss(entry: var): void {
        if (!entry)
            return;
        hideToast(entry.notification.id);
        entry.notification.dismiss();
    }

    function clear(): void {
        for (const entry of entries)
            entry.notification.dismiss();
        toastIds = [];
    }

    function toggleDoNotDisturb(): void {
        doNotDisturb = !doNotDisturb;
        if (doNotDisturb)
            toastIds = [];
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;

            const stamps = Object.assign({}, root.times);
            stamps[notification.id] = Date.now();
            root.times = stamps;

            const critical = notification.urgency >= NotificationUrgency.Critical;
            if (root.doNotDisturb && !critical)
                return;
            root.toastIds = [notification.id].concat(root.toastIds.filter(id => id !== notification.id)).slice(0, root.settings.maxToasts);
        }
    }

    // Lets Hyprland keybinds reach the notification centre:
    //   qs -c zone-c ipc call notifications clear
    IpcHandler {
        target: "notifications"

        function clear(): void {
            root.clear();
        }

        function dnd(): void {
            root.toggleDoNotDisturb();
        }
    }

    Timer {
        running: root.count > 0
        repeat: true
        interval: 30000
        onTriggered: root.now = Date.now()
    }
}
