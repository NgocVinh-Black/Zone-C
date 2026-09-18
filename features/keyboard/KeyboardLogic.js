.pragma library

var ICON = String.fromCodePoint(0xF030C);

// Short label for a Hyprland keymap name, as in v1: the language's first two letters.
// "English (US)" -> "EN", "Vietnamese" -> "VI".
function label(keymap) {
    const name = (keymap || "").trim();
    if (name === "")
        return "??";
    return name.slice(0, 2).toUpperCase();
}
