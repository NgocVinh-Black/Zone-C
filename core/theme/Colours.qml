pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.config
import qs.core.state

// Colour palette. With theme.matugen enabled, colours are read from a flat JSON file
// { "base": "#1e1e2e", ... }; missing or invalid entries keep the default.
Singleton {
    id: root

    // Dark palette sampled from the Serpantinum v1 screenshots (matugen output for
    // a sky wallpaper). Names follow Catppuccin, the way v1 maps matugen roles.
    readonly property var defaults: ({
            rosewater: "#dee3e8",
            flamingo: "#ffb4ab",
            pink: "#454364",
            mauve: "#8fcef3",
            red: "#ffb4ab",
            maroon: "#93000a",
            peach: "#c6c2ea",
            yellow: "#36495a",
            green: "#b5c9d7",
            teal: "#b5c9d7",
            sky: "#8fcef3",
            sapphire: "#004c69",
            blue: "#8fcef3",
            lavender: "#8fcef3",
            text: "#dee3e8",
            subtext1: "#8a9198",
            subtext0: "#c0c7ce",
            overlay2: "#dee3e8",
            overlay1: "#dee3e8",
            overlay0: "#dee3e8",
            surface2: "#30363a",
            surface1: "#252b2f",
            surface0: "#1b2024",
            base: "#0b0f12",
            mantle: "#151a1e",
            crust: "#0f1417"
        })

    property var loaded: ({})

    // Returns a "#rrggbb" string; the typed colour properties below convert it.
    function pick(name) {
        const value = loaded[name];
        return typeof value === "string" && /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value) ? value : defaults[name];
    }

    function alpha(c: color, a: real): color {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // Neutral overlays used for glass surfaces; not part of the theme.
    readonly property color white: "#ffffff"
    readonly property color black: "#000000"

    readonly property color rosewater: pick("rosewater")
    readonly property color flamingo: pick("flamingo")
    readonly property color pink: pick("pink")
    readonly property color mauve: pick("mauve")
    readonly property color red: pick("red")
    readonly property color maroon: pick("maroon")
    readonly property color peach: pick("peach")
    readonly property color yellow: pick("yellow")
    readonly property color green: pick("green")
    readonly property color teal: pick("teal")
    readonly property color sky: pick("sky")
    readonly property color sapphire: pick("sapphire")
    readonly property color blue: pick("blue")
    readonly property color lavender: pick("lavender")
    readonly property color text: pick("text")
    readonly property color subtext1: pick("subtext1")
    readonly property color subtext0: pick("subtext0")
    readonly property color overlay2: pick("overlay2")
    readonly property color overlay1: pick("overlay1")
    readonly property color overlay0: pick("overlay0")
    readonly property color surface2: pick("surface2")
    readonly property color surface1: pick("surface1")
    readonly property color surface0: pick("surface0")
    readonly property color base: pick("base")
    readonly property color mantle: pick("mantle")
    readonly property color crust: pick("crust")

    FileView {
        path: Config.theme.matugen ? (Config.theme.colorsPath || Paths.cacheDir + "/colors.json") : ""
        watchChanges: true
        printErrors: false

        onPathChanged: {
            if (path === "")
                root.loaded = {};
        }

        onFileChanged: reload()

        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.loaded = data && typeof data === "object" ? data : {};
            } catch (e) {
                console.warn("[zone-c theme]", path, "is not valid JSON, using default colours");
                root.loaded = {};
            }
        }

        onLoadFailed: root.loaded = {}
    }
}
