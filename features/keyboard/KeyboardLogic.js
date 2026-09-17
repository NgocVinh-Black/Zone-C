.pragma library

var ICON = String.fromCodePoint(0xF030C);

// Short label for a Hyprland keymap name: "English (US)" -> "US", "Vietnamese" -> "VI".
function label(keymap) {
    if (!keymap)
        return "??";
    const code = /\(([^)]+)\)/.exec(keymap);
    if (code)
        return code[1].toUpperCase();
    return keymap.slice(0, 2).toUpperCase();
}
