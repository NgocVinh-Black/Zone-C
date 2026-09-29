pragma Singleton
import QtQuick
import Quickshell
import "../../"

// Zone-C: kieu hieu ung di kem preset mau.
//   Zone Thunder -> hinh nen video + vien dien chay (dong)
//   Zone Crystal -> hinh nen anh tinh + vien dung yen (tinh)
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
        }
    })

    readonly property string preset: {
        let t = Config.getSetting("theme", {});
        return (t && t.activePreset) ? t.activePreset : "";
    }
    readonly property var style: styles[preset] || styles["Zone Thunder"]

    readonly property bool animated: style.animated
    readonly property color borderGlow: style.glow
    readonly property color borderBolt: style.bolt
    readonly property color borderCore: style.core
    readonly property real borderAmplitude: style.amp

    property bool _ready: false

    function isVideo(p) {
        let lp = (p || "").toLowerCase();
        return lp.endsWith(".mp4") || lp.endsWith(".mkv") || lp.endsWith(".mov") || lp.endsWith(".webm");
    }

    // Chi doi hinh nen khi kieu hien tai sai (Crystal ma dang video, Thunder ma dang anh),
    // de giu hinh nen cung kieu ban tu chon.
    function applyWallpaper() {
        let s = styles[preset];
        if (!s || !Caching.zoneCDir) return;
        let current = Wallpaper.getWallpaperPath("");
        if (current !== "" && isVideo(current) === s.animated) return;
        Wallpaper.setWallpaper("all", Caching.zoneCDir + "/assets/wallpapers/" + s.wallpaper, "fade");
    }

    // Bo qua lan nap dau (luc mo shell) -> khong doi hinh nen khi khoi dong
    onPresetChanged: {
        if (!_ready) {
            _ready = preset !== "";
            return;
        }
        applyWallpaper();
    }

    Component.onCompleted: _ready = preset !== ""
}
