import QtQuick
import qs.core.theme

// The floating translucent container used for every bar group (v1 style).
Rectangle {
    color: Colours.alpha(Colours.base, Tokens.block.opacity)
    radius: Tokens.block.radius
    border.width: Tokens.block.borderWidth
    border.color: Colours.alpha(Colours.text, Tokens.block.borderAlpha)
}
