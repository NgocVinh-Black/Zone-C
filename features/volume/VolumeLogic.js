.pragma library

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

// New volume after one scroll step in `direction` (+1 up, -1 down).
function step(volume, direction, amount) {
    const next = Math.round((volume + direction * amount) * 100) / 100;
    return Math.max(0, Math.min(1, next));
}
