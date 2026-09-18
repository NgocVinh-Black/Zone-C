.pragma library

// Computes where a popup sits on a screen. All values are in pixels,
// already scaled. `marginTop` keeps top-anchored popups below the bar;
// `edgeLeft` / `edgeRight` are the gaps to the left and right screen borders.

function place(anchor, width, height, screenWidth, screenHeight, marginTop, edgeLeft, edgeRight) {
    const w = Math.min(width, screenWidth - edgeLeft - edgeRight);
    const h = Math.min(height, screenHeight - marginTop - edgeRight);
    let x;
    let y = marginTop;

    switch (anchor) {
    case "top-left":
        x = edgeLeft;
        break;
    case "top-right":
        x = screenWidth - w - edgeRight;
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
