import QtQuick
import qs.core.theme

// A Nerd Font glyph.
Text {
    color: Colours.text
    font.family: Tokens.font.icon
    font.pixelSize: Tokens.font.size.icon
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
