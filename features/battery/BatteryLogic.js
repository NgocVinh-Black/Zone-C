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

// Palette colour name for the pill gradient.
function tone(percent, charging) {
    if (charging)
        return "green";
    if (percent <= 20)
        return "red";
    return "text";
}
