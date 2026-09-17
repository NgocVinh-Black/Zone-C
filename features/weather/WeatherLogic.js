.pragma library

// WMO weather interpretation codes, as returned by Open-Meteo.

function glyph(codePoint) {
    return String.fromCodePoint(codePoint);
}

function icon(code, isDay) {
    if (code === 0) return glyph(isDay ? 0xF0599 : 0xF0594);
    if (code === 1 || code === 2) return glyph(isDay ? 0xF0595 : 0xF0F31);
    if (code === 3) return glyph(0xF0590);
    if (code === 45 || code === 48) return glyph(0xF0591);
    if (code === 65 || code === 67 || code === 82) return glyph(0xF0596);
    if ((code >= 51 && code <= 64) || code === 66 || code === 80 || code === 81) return glyph(0xF0597);
    if ((code >= 71 && code <= 77) || code === 85 || code === 86) return glyph(0xF0598);
    if (code >= 95 && code <= 99) return glyph(0xF0593);
    return glyph(0xF0590);
}

// Palette colour name used to tint the icon.
function tone(code) {
    if (code <= 2) return "yellow";
    if (code >= 51 && code <= 82) return "blue";
    if (code >= 95) return "mauve";
    return "overlay2";
}

function forecastUrl(latitude, longitude, unit) {
    return "https://api.open-meteo.com/v1/forecast"
        + "?latitude=" + latitude
        + "&longitude=" + longitude
        + "&current=temperature_2m,weather_code,is_day"
        + "&temperature_unit=" + (unit === "imperial" ? "fahrenheit" : "celsius");
}

function formatTemp(value) {
    return Math.round(value) + "°";
}
