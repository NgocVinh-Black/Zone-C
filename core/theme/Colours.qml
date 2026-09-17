pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.config
import qs.core.state

// Colour palette. Defaults to Catppuccin Mocha (as in Serpantinum v1).
// With theme.matugen enabled, colours are read from a flat JSON file
// { "base": "#1e1e2e", ... }; missing or invalid entries keep the default.
Singleton {
    id: root

    readonly property var defaults: ({
            rosewater: "#f5e0dc",
            flamingo: "#f2cdcd",
            pink: "#f5c2e7",
            mauve: "#cba6f7",
            red: "#f38ba8",
            maroon: "#eba0ac",
            peach: "#fab387",
            yellow: "#f9e2af",
            green: "#a6e3a1",
            teal: "#94e2d5",
            sky: "#89dceb",
            sapphire: "#74c7ec",
            blue: "#89b4fa",
            lavender: "#b4befe",
            text: "#cdd6f4",
            subtext1: "#bac2de",
            subtext0: "#a6adc8",
            overlay2: "#9399b2",
            overlay1: "#7f849c",
            overlay0: "#6c7086",
            surface2: "#585b70",
            surface1: "#45475a",
            surface0: "#313244",
            base: "#1e1e2e",
            mantle: "#181825",
            crust: "#11111b"
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
