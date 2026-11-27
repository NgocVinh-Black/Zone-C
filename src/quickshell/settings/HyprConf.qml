pragma Singleton
import QtQuick
import Quickshell
import "../"

// Hyprland options changed from Settings (input, cursor, animations, zoom…): applied live with
// `hyprctl eval hl.config{…}`, saved in settings.json under "hypr" and written to
// ~/.config/zone-c/hyprland-user.lua, which hyprland.lua loads last at start-up.
QtObject {
    readonly property var conf: Config.getSetting("hypr", {}) || {}
    readonly property string file: Quickshell.env("HOME") + "/.config/zone-c/hyprland-user.lua"

    function get(path, def) {
        let cur = conf;
        for (const k of path.split(".")) { if (cur === null || typeof cur !== "object" || !(k in cur)) return def; cur = cur[k]; }
        return cur;
    }
    function lua(v) {
        if (typeof v === "boolean" || typeof v === "number") return String(v);
        if (typeof v === "string") return JSON.stringify(v);
        return "{ " + Object.keys(v).map(k => k + " = " + lua(v[k])).join(", ") + " }";
    }
    function nest(path, value) { let o = {}, cur = o, ks = path.split("."); ks.slice(0, -1).forEach(k => cur = cur[k] = {}); cur[ks[ks.length - 1]] = value; return o; }
    function set(path, value) {
        let all = JSON.parse(JSON.stringify(conf)), cur = all, ks = path.split(".");
        ks.slice(0, -1).forEach(k => { if (typeof cur[k] !== "object" || cur[k] === null) cur[k] = {}; cur = cur[k]; });
        cur[ks[ks.length - 1]] = value;
        Config.setSetting("hypr", all);
        Quickshell.execDetached(["hyprctl", "eval", "hl.config(" + lua(nest(path, value)) + ")"]);
        write(all);
    }
    // three-finger gestures can only be registered at load time: rewrite the file and reload Hyprland
    function setGesture(key, value) {
        Config.setSetting("hypr_gestures." + key, value);
        let g = Object.assign({}, Config.getSetting("hypr_gestures", {}) || {});
        g[key] = value;
        write(conf, g);
        reloadTimer.restart();
    }
    property Timer reloadTimer: Timer { interval: 600; onTriggered: Quickshell.execDetached(["hyprctl", "reload"]) }
    function write(all, gestures) {
        let g = gestures || Config.getSetting("hypr_gestures", {}) || {};
        let out = "-- written by Zone-C Settings; edit there, not here\npcall(hl.config, " + lua(all) + ")\n";
        // gestures are registered by keybinds.lua from this table (loaded before it)
        let gl = "-- written by Zone-C Settings\n_G.zonec_gestures = { horizontal = " + (g.horizontal !== false) + ", up = \"" + (g.up || "none") + "\" }\n";
        Quickshell.execDetached(["bash", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\" && printf '%s' \"$4\" > \"$3\"", "_", file, out,
                                 Quickshell.env("HOME") + "/.config/zone-c/hyprland-gestures.lua", gl]);
    }
}
