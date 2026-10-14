pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

// Personal events shown by the desktop "Hôm nay" card and the calendar popup.
// Stored as JSON in <state>/calendar/events.json: [{ id, date: "YYYY-MM-DD", time: "HH:MM", title, note }].
Item {
    id: root
    visible: false
    property var events: []
    readonly property string file: Caching.stateDir ? Caching.stateDir + "/calendar/events.json" : ""

    function key(d) { return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0"); }
    function on(d) {
        let k = key(d);
        return events.filter(e => e.date === k).sort((a, b) => (a.time || "").localeCompare(b.time || ""));
    }
    readonly property var today: { let _ = DateTime.now.getDate(); return on(DateTime.now); }

    // "Còn 49 phút" for an event later today, "" otherwise
    function untilText(e) {
        if (!e.time || e.date !== key(DateTime.now)) return "";
        let p = e.time.split(":"), t = new Date(DateTime.now);
        t.setHours(Number(p[0]), Number(p[1]), 0, 0);
        let m = Math.round((t - DateTime.now) / 60000);
        if (m <= 0 || m > 180) return "";
        return m < 60 ? "Còn " + m + " phút" : "Còn " + Math.floor(m / 60) + " giờ " + (m % 60) + " phút";
    }

    function add(dateKey, time, title, note) {
        let list = events.slice();
        list.push({ id: String(Date.now()), date: dateKey, time: time, title: title, note: note || "" });
        events = list;
        save();
    }
    function remove(id) { events = events.filter(e => e.id !== id); save(); }

    FileView {
        id: store
        path: root.file
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { let v = JSON.parse(text()); root.events = Array.isArray(v) ? v : []; } catch (e) { root.events = []; } }
        onLoadFailed: root.events = []
    }
    function save() {
        if (!file) return;
        Quickshell.execDetached(["bash", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "_", file, JSON.stringify(events)]);
    }
}
