.pragma library

// Kept here rather than shared with the volume feature: a feature never imports
// another feature (rule R4).

// Nerd Font speaker glyph for a 0-1 volume.
function icon(volume, muted) {
    if (muted || volume <= 0)
        return String.fromCodePoint(0xF075F);
    if (volume < 1 / 3)
        return String.fromCodePoint(0xF057F);
    if (volume < 2 / 3)
        return String.fromCodePoint(0xF0580);
    return String.fromCodePoint(0xF057E);
}

function percent(volume) {
    return Math.max(0, Math.min(100, Math.round(volume * 100)));
}

// Volume can go past 1; the bar fills to 100% and the number keeps counting.
function fill(volume) {
    return Math.max(0, Math.min(1, volume));
}
