.pragma library

// Computes where a popup sits on a screen. All values are in pixels,
// already scaled. `marginTop` keeps top-anchored popups below the bar and
// `edge` is the gap to the left/right screen border.

function place(anchor, width, height, screenWidth, screenHeight, marginTop, edge) {
    const w = Math.min(width, screenWidth - edge * 2);
    const h = Math.min(height, screenHeight - marginTop - edge);
    let x;
    let y = marginTop;

    switch (anchor) {
    case "top-left":
        x = edge;
        break;
    case "top-right":
        x = screenWidth - w - edge;
        break;
    case "top-center":
        x = (screenWidth - w) / 2;
        break;
    case "center":
        x = (screenWidth - w) / 2;
        y = (screenHeight - h) / 2;
        break;
    default:
        return null;
    }

    return { x: Math.floor(x), y: Math.floor(y), width: w, height: h };
}
