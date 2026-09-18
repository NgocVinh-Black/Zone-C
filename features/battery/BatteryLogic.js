.pragma library

function glyph(codePoint) {
    return String.fromCodePoint(codePoint);
}

// Nerd Font battery glyph for a 0-100 percentage.
function icon(percent, charging) {
    if (charging) {
        if (percent >= 90) return glyph(0xF0085);
        if (percent >= 80) return glyph(0xF008B);
        if (percent >= 60) return glyph(0xF008A);
        if (percent >= 40) return glyph(0xF089E);
        if (percent >= 20) return glyph(0xF0086);
        return glyph(0xF089C);
    }
    const levels = [0xF007A, 0xF007B, 0xF007C, 0xF007D, 0xF007E, 0xF007F, 0xF0080, 0xF0081, 0xF0082, 0xF0079];
    const index = Math.max(0, Math.min(9, Math.floor(percent / 10)));
    return glyph(levels[index]);
}

// Palette colour name for the battery level: green while charging, then blue,
// yellow and red as it drains.
function tone(percent, charging) {
    if (charging)
        return "green";
    if (percent >= 70)
        return "blue";
    if (percent >= 30)
        return "yellow";
    return "red";
}

// The bar pill is filled only when charging or low; otherwise just its content is tinted.
function filled(percent, charging) {
    return charging || percent <= 20;
}

// Second ambient colour paired with `tone`.
function secondaryTone(percent, charging) {
    if (charging)
        return "sapphire";
    if (percent >= 70)
        return "mauve";
    if (percent >= 30)
        return "peach";
    return "maroon";
}

// Palette colour name for a power profile.
function profileTone(profile) {
    if (profile === "performance")
        return "red";
    if (profile === "power-saver")
        return "green";
    return "blue";
}

// "/proc/uptime" contents → { hours, minutes }.
function parseUptime(text) {
    const seconds = parseFloat(String(text || "").split(" ")[0]);
    if (isNaN(seconds))
        return { hours: 0, minutes: 0 };
    return { hours: Math.floor(seconds / 3600), minutes: Math.floor(seconds % 3600 / 60) };
}

function twoDigits(n) {
    return (n < 10 ? "0" : "") + n;
}
