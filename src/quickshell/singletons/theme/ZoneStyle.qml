pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

// Zone-C: kieu hieu ung di kem preset mau.
//   Zone Thunder -> hinh nen video + vien dien chay (dong)
//   Zone Crystal -> hinh nen anh tinh + vien dung yen (tinh)
//   Zone Frost   -> hinh nen tuyet + bar dang vien rieng (modular) + dock kinh mo
// Man hinh khoa dung chinh hinh nen hien tai nen tu dong/tinh theo.
// Preset khac: giu nguyen hinh nen, vien chay nhu Thunder.
Item {
    id: root
    visible: false

    readonly property var styles: ({
        "Zone Thunder": {
            animated: true,
            wallpaper: "zone-c-natural-thunder.mp4",
            glow: "#1e8fff", bolt: "#4cc3ff", core: "#e8fbff", amp: 7
        },
        "Zone Crystal": {
            animated: false,
            wallpaper: "zone-c-crystal.png",
            glow: "#38b6ff", bolt: "#7ff0ff", core: "#ffffff", amp: 2.5
        },
        "Zone Frost": {
            animated: false,
            wallpaper: "zone-c-frost.jpg",
            glow: "#9fd3e0", bolt: "#cfeaf2", core: "#ffffff", amp: 2.5,
            dockGlass: true, dockTint: "#dce8ee", dockAlpha: 0.42,
            plainBorder: true, flatBar: true, artSuffix: "-frost",
            // Hai che do: dark (mac dinh) va light. Doi bang setMode() / zone-c ipc call zonetheme mode toggle
            palettes: {
                "dark": { "base": "#333f45", "mantle": "#2c373c", "crust": "#252f34", "text": "#e9f1f4", "subtext0": "#93a7b1", "subtext1": "#b7c7cf", "surface0": "#3e4b52", "surface1": "#4a5960", "surface2": "#58686f", "overlay0": "#6d7f87", "overlay1": "#8597a0", "overlay2": "#9daeb6", "blue": "#d6e6ec", "sapphire": "#cfe1e8", "peach": "#e3dccf", "green": "#cfe4d8", "red": "#ff6b6b", "mauve": "#d6e6ec", "pink": "#d6e6ec", "yellow": "#ece0b0", "maroon": "#c9d9df", "teal": "#cfe6e6" },
                "light": { "base": "#eef4f7", "mantle": "#e4ecf0", "crust": "#d6e2e8", "text": "#1f2d35", "subtext0": "#5d717b", "subtext1": "#44565f", "surface0": "#dde7ec", "surface1": "#cfdce3", "surface2": "#bccdd6", "overlay0": "#8fa3ad", "overlay1": "#768b95", "overlay2": "#5f747e", "blue": "#2f5d72", "sapphire": "#3a6c82", "peach": "#a8683a", "green": "#3f7a5c", "red": "#d64545", "mauve": "#2f5d72", "pink": "#3a6c82", "yellow": "#9a7d22", "maroon": "#4a7a8e", "teal": "#2f7277" }
            },
            lightStyle: { glow: "#2f5d72", bolt: "#2f5d72", core: "#ffffff", dockTint: "#ffffff", dockAlpha: 0.55 },
            // Bo cuc rieng cua Frost; bo cuc cua ban duoc luu lai va tra ve khi roi Frost
            layout: {
                "bar.style": "modular",
                "dock.floating": true,
                "launcher.position": "bottom",
                // Thu tu nhu bo cuc mac dinh, nhung tach nhom -> moi muc mot vien rieng
                "bar.modules": {
                    "left": ["left", "workspaces", "media"],
                    "center": ["info", "timedate", "weather"],
                    "right": ["tray", "sysmon", "kb", "wifi", "bt", "vol", "bat"]
                }
            }
        }
    })

    readonly property string preset: {
        let t = Config.getSetting("theme", {});
        return (t && t.activePreset) ? t.activePreset : "";
    }
    readonly property var baseStyle: styles[preset] || styles["Zone Thunder"]

    // Che do sang/toi (theme.mode). Preset khong co bang mau sang luon la "dark".
    readonly property bool hasModes: styles[preset] ? styles[preset].palettes !== undefined : false
    readonly property string mode: {
        let t = Config.getSetting("theme", {});
        return (hasModes && t && t.mode === "light") ? "light" : "dark";
    }
    readonly property bool isLight: mode === "light"
    readonly property var style: (isLight && baseStyle.lightStyle) ? Object.assign({}, baseStyle, baseStyle.lightStyle) : baseStyle

    readonly property bool animated: style.animated
    readonly property color borderGlow: style.glow
    readonly property color borderBolt: style.bolt
    readonly property color borderCore: style.core
    readonly property real borderAmplitude: style.amp

    // Dock kinh mo (chi preset co dockGlass, vd Zone Frost)
    readonly property bool dockGlass: styles[preset] ? styles[preset].dockGlass === true : false
    readonly property color dockGlassColor: dockGlass ? Qt.alpha(style.dockTint, style.dockAlpha) : "transparent"

    // Vien focus la mot duong manh dung yen (khong tia dien)
    readonly property bool plainBorder: styles[preset] ? styles[preset].plainBorder === true : false
    // Bar phang: moi muc la mot vien toi rieng, chu trang, khong to mau accent
    readonly property bool flatBar: styles[preset] ? styles[preset].flatBar === true : false
    readonly property color pillBorder: "transparent"
    readonly property color pillColor: ThemeBackend.base // cung mau nen voi popup
    readonly property color pillHover: ThemeBackend.surface0

    // Logo / con meo theo preset: Zone Frost dung ban mau bang (logo-frost.png, pushy-frost.gif...)
    readonly property string artSuffix: (styles[preset] && styles[preset].artSuffix) ? styles[preset].artSuffix : ""
    function art(name) {
        if (artSuffix === "") return name;
        let i = name.lastIndexOf(".");
        return name.substring(0, i) + artSuffix + name.substring(i);
    }

    // Avatar (~/.face) dang la logo Zone-C mac dinh -> doi theo preset; anh rieng cua ban thi giu nguyen
    property bool avatarIsLogo: false
    function avatarSource(path) {
        if (path === "") return "";
        if (avatarIsLogo && artSuffix !== "" && Caching.zoneCDir)
            return "file://" + Caching.zoneCDir + "/assets/" + art("logo.png");
        return "file://" + path;
    }
    Process {
        running: Caching.zoneCDir !== ""
        command: ["bash", "-c", "cmp -s \"$HOME/.face\" \"" + Caching.zoneCDir + "/assets/logo.png\""]
        onExited: (code) => root.avatarIsLogo = (code === 0)
    }

    property bool _ready: false

    function isVideo(p) {
        let lp = (p || "").toLowerCase();
        return lp.endsWith(".mp4") || lp.endsWith(".mkv") || lp.endsWith(".mov") || lp.endsWith(".webm");
    }

    // Doi sang hinh nen cua preset khi dang dung hinh mac dinh cua preset khac
    // hoac kieu sai (Crystal ma dang video, Thunder ma dang anh), de giu hinh nen cung kieu ban tu chon.
    function applyWallpaper() {
        let s = styles[preset];
        if (!s || !Caching.zoneCDir) return;
        let target = Caching.zoneCDir + "/assets/wallpapers/" + s.wallpaper;
        let current = Wallpaper.getWallpaperPath("");
        if (current === target) return;
        // Hinh nen mac dinh cua preset khac -> luon doi; hinh ban tu chon cung kieu -> giu
        let builtin = current.indexOf("/assets/wallpapers/") !== -1;
        if (current !== "" && !builtin && isVideo(current) === s.animated) return;
        Wallpaper.setWallpaper("all", target, "fade");
    }

    // Bo cuc bar/dock/launcher di kem preset (chi preset co "layout", vd Zone Frost).
    // Vao preset do: luu bo cuc hien tai vao zoneStyle.savedLayout roi ap bo cuc cua preset.
    // Sang preset khac (Crystal, Thunder, Nord...): tra lai dung bo cuc da luu -> theme cu khong bi doi.
    readonly property var layoutKeys: ["bar.style", "dock.floating", "bar.modules", "launcher.position"]

    function applyLayout() {
        let s = styles[preset];
        let saved = Config.getSetting("zoneStyle.savedLayout", null);
        let upd = {};
        if (s && s.layout) {
            if (!saved) {
                let cur = {};
                for (let k of layoutKeys) cur[k] = Config.getSetting(k, null);
                upd["zoneStyle.savedLayout"] = cur;
            }
            for (let k in s.layout) upd[k] = s.layout[k];
        } else if (saved) {
            for (let k of layoutKeys) {
                if (saved[k] !== null && saved[k] !== undefined) upd[k] = saved[k];
            }
            upd["zoneStyle.savedLayout"] = null;
        } else {
            return;
        }
        Config.updateJsonBulk(upd);
    }

    // Bang mau cua preset theo che do hien tai (ThemeTab dung khi ap preset)
    function presetColors(name, fallback) {
        let st = styles[name];
        if (!st || !st.palettes) return fallback;
        let t = Config.getSetting("theme", {});
        return st.palettes[(t && t.mode === "light") ? "light" : "dark"] || fallback;
    }

    // Doi che do: "dark" | "light" | "toggle"
    function setMode(m) {
        if (m === "toggle") m = isLight ? "dark" : "light";
        if (m !== "dark" && m !== "light") return;
        let upd = { "theme.mode": m };
        let st = styles[preset];
        if (st && st.palettes) upd["theme.colors"] = st.palettes[m];
        Config.updateJsonBulk(upd);
        syncExternal(m);
    }

    // App ngoai shell: GTK/libadwaita (Files, Chrome) qua color-scheme; foot qua tin hieu + initial-color-theme
    function syncExternal(m) {
        let scheme = m === "light" ? "prefer-light" : "prefer-dark";
        let sig = m === "light" ? "USR2" : "USR1";
        Quickshell.execDetached(["bash", "-c",
            "gsettings set org.gnome.desktop.interface color-scheme " + scheme + "; " +
            "f=\"$HOME/.config/foot/foot.ini\"; [ -f \"$f\" ] && { " +
            "if grep -q '^initial-color-theme=' \"$f\"; then sed -i 's/^initial-color-theme=.*/initial-color-theme=" + m + "/' \"$f\"; " +
            "else sed -i '1i initial-color-theme=" + m + "' \"$f\"; fi; }; " +
            "pkill -" + sig + " -x foot; true"]);
    }

    // Man dang nhap SDDM + mau terminal theo theme dang dung (scripts/sddm_sync.sh, scripts/term_sync.sh).
    // Goi khi doi preset, doi che do sang/toi, doi hinh nen va luc khoi dong; gop cac lan goi sat nhau.
    function syncSddm() { sddmSyncTimer.restart(); }
    Timer {
        id: sddmSyncTimer
        interval: 2000
        onTriggered: {
            if (!Caching.zoneCDir) return;
            Quickshell.execDetached(["bash", Caching.zoneCDir + "/scripts/sddm_sync.sh", Wallpaper.getWallpaperPath("")]);
            Quickshell.execDetached(["bash", Caching.zoneCDir + "/scripts/term_sync.sh"]);
        }
    }
    Connections {
        target: Wallpaper
        function onWallpaperChanged(screenName, path, transition) { root.syncSddm(); }
    }
    Connections {
        target: ThemeBackend
        function onBaseChanged() { root.syncSddm(); }
    }

    IpcHandler {
        target: "zonetheme"
        function mode(m: string): void { root.setMode(m); }
        function getMode(): string { return root.mode; }
    }

    // Bo qua lan nap dau (luc mo shell) -> khong doi hinh nen khi khoi dong
    onPresetChanged: {
        if (!_ready) {
            _ready = preset !== "";
            return;
        }
        // Chay sau khi binding on dinh (ghi settings ngay trong luc preset doi gay binding loop)
        Qt.callLater(root.onPresetSwitched);
    }

    function onPresetSwitched() {
        applyWallpaper();
        applyLayout();
        // Vao/ra preset co che do sang: dong bo app ngoai theo che do thuc te
        // (roi sang Crystal/Thunder khi dang light -> tra Files/foot ve toi). Theme cu khong dung den thi bo qua.
        let t = Config.getSetting("theme", {});
        if (hasModes || (t && t.mode === "light")) syncExternal(mode);
    }

    Component.onCompleted: {
        _ready = preset !== "";
        syncSddm();
    }
}
