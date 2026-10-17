pragma Singleton
import QtQuick
import Quickshell
import "../"
import "En.js" as En

// Zone-C Frost: design tokens of the "Zone-C · Frost" canvas (zone.css), dark and light.
// Every v2 surface reads its colours, fonts and radii from here so the two modes stay in step.
Item {
    id: root
    visible: false

    readonly property bool light: ZoneStyle.isLight

    // Interface language (Settings → Chung → Ngôn ngữ giao diện): the Frost UI is written in Vietnamese;
    // any other language shows the English strings of En.js.
    readonly property string lang: { let l = Config.getSetting("general.language", "vi"); return typeof l === "string" && l ? l : "vi"; }
    readonly property bool en: lang !== "vi"
    // the same Vietnamese word with a different English meaning here ("Cài đặt" = Install / Settings)
    function trAs(vi, english) { return en ? english : vi; }
    function tr(s) {
        if (!en || typeof s !== "string") return s;
        let t = En.map[s];
        return t === undefined ? s : t;
    }

    readonly property var dark: ({
        crust: "#1c2428", mantle: "#232d32", base: "#2a353b", s0: "#34424a", s1: "#415058", s2: "#53646d",
        tx: "#edf3f6", sub: "#a7b8c1", sub2: "#c6d3d9", dim: "#7d909a",
        acc: "#d6e6ec", ink: "#162025", glow: "#9fd3e0", hi: "#ffffff", bg0: "#151c20",
        red: "#ff7b7b", green: "#a6dcbc", yellow: "#ecdcaa", peach: "#e9c9a8", redTx: "#ffb3b3", knob: "#c9d5db",
        fgRgb: [237, 243, 246], accRgb: [214, 230, 236], glowRgb: [159, 211, 224], surfRgb: [28, 36, 40],
        redRgb: [255, 123, 123], greenRgb: [166, 220, 188], yellowRgb: [236, 220, 170],
        wellRgb: [0, 0, 0], wellK: 1.0,
        glass: Qt.rgba(28 / 255, 36 / 255, 40 / 255, 0.74), glass2: Qt.rgba(35 / 255, 45 / 255, 50 / 255, 0.86),
        scrim: Qt.rgba(14 / 255, 20 / 255, 24 / 255, 0.34), scrimDeep: Qt.rgba(14 / 255, 20 / 255, 24 / 255, 0.62),
        scrimNight: Qt.rgba(10 / 255, 15 / 255, 18 / 255, 0.78),
        cardFill: Qt.rgba(237 / 255, 243 / 255, 246 / 255, 0.045),
        glassEdge: Qt.rgba(237 / 255, 243 / 255, 246 / 255, 0.08), shadow: Qt.rgba(0, 0, 0, 0.38)
    })

    readonly property var lightSet: ({
        crust: "#d6e2e8", mantle: "#e4ecf0", base: "#eef4f7", s0: "#dde7ec", s1: "#cfdce3", s2: "#bccdd6",
        tx: "#1f2d35", sub: "#44565f", sub2: "#2f3e46", dim: "#4a5d67",
        acc: "#2f5d72", ink: "#ffffff", glow: "#2f5d72", hi: "#1f2d35", bg0: "#e4ecf0",
        red: "#b3261e", green: "#226641", yellow: "#6e540e", peach: "#9a5a2a", redTx: "#a8302f", knob: "#ffffff",
        fgRgb: [31, 45, 53], accRgb: [47, 93, 114], glowRgb: [47, 93, 114], surfRgb: [244, 248, 250],
        redRgb: [179, 38, 30], greenRgb: [34, 102, 65], yellowRgb: [110, 84, 14],
        wellRgb: [31, 45, 53], wellK: 0.3,
        glass: Qt.rgba(244 / 255, 248 / 255, 250 / 255, 0.80), glass2: Qt.rgba(244 / 255, 248 / 255, 250 / 255, 0.88),
        scrim: Qt.rgba(238 / 255, 244 / 255, 247 / 255, 0.22), scrimDeep: Qt.rgba(238 / 255, 244 / 255, 247 / 255, 0.55),
        scrimNight: Qt.rgba(238 / 255, 244 / 255, 247 / 255, 0.72),
        cardFill: Qt.rgba(1, 1, 1, 0.55),
        glassEdge: Qt.rgba(1, 1, 1, 0.7), shadow: Qt.rgba(31 / 255, 45 / 255, 53 / 255, 0.16)
    })

    // "Màu nhấn" in Settings → Theme recolours the dark palette's accent (the light palette keeps its own)
    readonly property string accentHex: { let a = Config.getSetting("theme.accent", ""); return typeof a === "string" && /^#[0-9a-fA-F]{6}$/.test(a) ? a : ""; }
    readonly property var t: light ? lightSet : (accentHex ? Object.assign({}, dark, { acc: accentHex,
        accRgb: [parseInt(accentHex.slice(1, 3), 16), parseInt(accentHex.slice(3, 5), 16), parseInt(accentHex.slice(5, 7), 16)] }) : dark)

    readonly property color crust: t.crust
    readonly property color mantle: t.mantle
    readonly property color base: t.base
    readonly property color s0: t.s0
    readonly property color s1: t.s1
    readonly property color s2: t.s2
    readonly property color tx: t.tx
    readonly property color sub: highContrast ? t.sub2 : t.sub
    readonly property color sub2: t.sub2
    readonly property color dim: highContrast ? t.sub : t.dim
    readonly property color acc: t.acc
    readonly property color ink: t.ink
    readonly property color glow: t.glow
    readonly property color hi: t.hi
    readonly property color bg0: t.bg0
    readonly property color red: t.red
    readonly property color green: t.green
    readonly property color yellow: t.yellow
    readonly property color peach: t.peach
    readonly property color redTx: t.redTx
    readonly property color knob: t.knob
    readonly property color glass: t.glass
    readonly property color glass2: t.glass2
    readonly property color scrim: t.scrim
    readonly property color scrimDeep: t.scrimDeep
    readonly property color scrimNight: t.scrimNight
    readonly property color cardFill: t.cardFill
    readonly property color glassEdge: t.glassEdge
    readonly property color shadow: t.shadow
    // Settings → Trợ năng: high contrast thickens hairlines; text scale multiplies every FText size
    readonly property bool highContrast: Config.getSetting("access.highContrast", false) === true
    readonly property real textScale: Math.max(0.8, Math.min(1.6, (Number(Config.getSetting("access.textScale", 100)) || 100) / 100))
    readonly property color line: fg(highContrast ? 0.28 : (light ? 0.10 : 0.08))
    readonly property color line2: fg(highContrast ? 0.36 : (light ? 0.16 : 0.14))

    function _rgba(rgb, a) { return Qt.rgba(rgb[0] / 255, rgb[1] / 255, rgb[2] / 255, a); }
    // rgba(var(--fg-rgb), a) and friends from zone.css
    function fg(a) { return _rgba(t.fgRgb, a); }
    function accA(a) { return _rgba(t.accRgb, a); }
    function glowA(a) { return _rgba(t.glowRgb, a); }
    function surf(a) { return _rgba(t.surfRgb, a); }
    function redA(a) { return _rgba(t.redRgb, a); }
    function greenA(a) { return _rgba(t.greenRgb, a); }
    function yellowA(a) { return _rgba(t.yellowRgb, a); }
    // rgb(var(--well-sp) / calc(a * var(--well-k))): sunken wells (inputs, segmented controls)
    function well(a) { return _rgba(t.wellRgb, a * t.wellK); }

    // Settings → Theme "Phông chữ" (Geist by default, as in the design)
    readonly property string font: { let f = Config.getSetting("theme.frostFont", "Geist"); return typeof f === "string" && f ? f : "Geist"; }
    readonly property string mono: "Geist Mono"

    FontLoader { source: Caching.zoneCDir ? "file://" + Caching.zoneCDir + "/assets/fonts/Geist-Variable.ttf" : "" }
    FontLoader { source: Caching.zoneCDir ? "file://" + Caching.zoneCDir + "/assets/fonts/GeistMono-Variable.ttf" : "" }

    // Design pixels map 1:1 to logical pixels, scaled by the user's UI scale.
    function px(v) { return Scaler.s(v); }

    // scripts/weather.sh hands out Nerd Font glyphs; the design draws its own stroke icons.
    function weatherIcon(glyph) {
        let c = glyph && glyph.length ? glyph.codePointAt(0) : 0;
        if (c === 0xf185) return "sun";
        if (c === 0xf186) return "moon";
        if (c === 0xf0597) return "rain";
        if (c === 0xf0591) return "w-fog";
        if (c === 0xf0e7) return "w-storm";
        if (c === 0xf2dc) return "w-snow";
        return "cloud";
    }

    function weatherDesc(glyph) {
        return ({ sun: tr("Nắng"), moon: tr("Trời quang"), rain: tr("Có mưa"), "w-fog": tr("Sương mù"), "w-storm": tr("Giông bão"), "w-snow": tr("Có tuyết") })[weatherIcon(glyph)] || tr("Nhiều mây");
    }
    function deg(v) { return (v === undefined || v === null || v === "") ? "--°" : Math.round(Number(v)) + "°"; }

    // Name used in greetings: Settings > Người dùng (general.displayName), else the login name.
    readonly property string displayName: {
        let g = Config.getSetting("general", {});
        if (g && g.displayName) return g.displayName;
        let n = SystemInfo.username || "";
        return n.length ? n.charAt(0).toUpperCase() + n.slice(1) : "";
    }

    // Friendly names like the design ("Loa tích hợp · Analog stereo") instead of ALSA card strings.
    function audioName(n) {
        if (!n) return "";
        let p = ((n && n.properties) || {}), d = n.description || p["node.description"] || n.name || "";
        let prof = p["device.profile.description"] || "";
        if ((n.name || "").indexOf("easyeffects") === 0) return "Easy Effects";
        if (p["device.api"] === "bluez5" || (n.name || "").indexOf("bluez") !== -1) return d;
        if (/hdmi|displayport/i.test(prof || d)) return (prof || d).replace(/ Output.*$/, "").replace(/^.*(HDMI)/i, "$1");
        if (/speaker/i.test(prof || d)) return tr("Loa tích hợp");
        if (/headphone/i.test(prof || d)) return "Tai nghe 3.5 mm";
        if (/mic/i.test(prof || d)) return tr("Micro tích hợp");
        return d;
    }
    function audioSub(n) {
        let p = ((n && n.properties) || {}), d = (n.description || "") + " " + (p["device.profile.description"] || "");
        if ((n.name || "").indexOf("easyeffects") === 0) return tr("Bộ xử lý âm thanh");
        if (p["device.api"] === "bluez5" || (n.name || "").indexOf("bluez") !== -1) return "Bluetooth" + (p["api.bluez5.codec"] ? " · " + String(p["api.bluez5.codec"]).toUpperCase() : "");
        if (/hdmi|displayport/i.test(d)) return "HDMI";
        return "Analog stereo";
    }

    // "Thứ Tư 14/10" (bar) and "Thứ Tư, 14 tháng 10" (desktop, lock screen)
    // English: "Wed 14 Oct" / "Wednesday, October 14"
    readonly property var weekdays: en ? ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                                       : [tr("Chủ Nhật"), tr("Thứ Hai"), tr("Thứ Ba"), tr("Thứ Tư"), tr("Thứ Năm"), tr("Thứ Sáu"), tr("Thứ Bảy")]
    readonly property var months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    function dayShort(d) { return en ? weekdays[d.getDay()].slice(0, 3) : (d.getDay() === 0 ? "CN" : "T" + (d.getDay() + 1)); }
    function dateShort(d) { return en ? weekdays[d.getDay()].slice(0, 3) + " " + d.getDate() + " " + months[d.getMonth()].slice(0, 3) : weekdays[d.getDay()] + " " + d.getDate() + "/" + (d.getMonth() + 1); }
    function dateLong(d) { return en ? weekdays[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate() : weekdays[d.getDay()] + ", " + d.getDate() + tr(" tháng ") + (d.getMonth() + 1); }
    function dayMonth(d) { return en ? months[d.getMonth()] + " " + d.getDate() : d.getDate() + tr(" tháng ") + (d.getMonth() + 1); }
    function monthYear(d) { return en ? months[d.getMonth()] + " " + d.getFullYear() : tr("Tháng ") + (d.getMonth() + 1) + ", " + d.getFullYear(); }

    // Frost surfaces that live in their own window (overview, power menu, the three system apps…)
    // listen for this; everything else opens through the popup host like the bar always has.
    signal openRequest(string name, string arg)
    // Display name of a window's app from its Hyprland class; Zone-C's own Quickshell windows are
    // titled "Zone-C · <name>" and go by that name.
    function appName(cls, title) {
        let m = /^Zone-C · (.+)$/.exec(title || "");
        if (cls === "org.quickshell" && m) return tr(m[1]);
        let map = { "foot": "Foot", "kitty": "kitty", "google-chrome": "Chrome", "code": "VS Code", "code-oss": "VS Code", "org.gnome.Nautilus": tr("Tệp"), "ViberPC": "Viber", "Spotify": tr("Nhạc"), "spotify": tr("Nhạc") };
        return map[cls] || (cls ? cls.charAt(0).toUpperCase() + cls.slice(1) : (title || tr("Cửa sổ")));
    }

    // tab the Wi-Fi / Bluetooth panel shows, so the bar lights the matching button
    property string networkTab: "wifi"
    readonly property var standalone: ["overview", "alttab", "tray", "power", "taskmanager", "files", "appstore", "emoji", "keyring", "screenshare", "welcome", "settings", "guide"]
    function open(widget, arg) {
        if (widget === "guide") widget = "settings";
        if (standalone.indexOf(widget) !== -1) { openRequest(widget, arg || ""); return; }
        Quickshell.execDetached(["bash", Caching.zoneCDir + "/scripts/qs_manager.sh", "toggle", widget].concat(arg ? [arg] : []));
    }
}
