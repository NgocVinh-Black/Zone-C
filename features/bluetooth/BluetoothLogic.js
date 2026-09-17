.pragma library

function icon(enabled, connected) {
    if (!enabled)
        return String.fromCodePoint(0xF00B2);
    return String.fromCodePoint(connected ? 0xF00B1 : 0xF00AF);
}
