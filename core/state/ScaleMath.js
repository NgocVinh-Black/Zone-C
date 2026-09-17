.pragma library

// Screen-size scaling, referenced to a 1920x1080 display.

function getScale(width, height, userScale) {
    const user = userScale === undefined ? 1 : userScale;
    if (!(width > 0) || !(height > 0))
        return user;

    const ratio = Math.min(width / 1920, height / 1080);
    const base = ratio <= 1 ? Math.max(0.35, Math.pow(ratio, 0.85)) : Math.pow(ratio, 0.5);
    return base * user;
}

function s(value, scale) {
    return Math.round(value * scale);
}
