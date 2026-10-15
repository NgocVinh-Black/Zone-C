import QtQuick

// Body text in Geist, coloured like `.z` (var(--tx)).
Text {
    id: root
    property bool mono: false
    // Design sizes include halves (11.5px, 12.5px); pixelSize only takes integers, pointSize is exact at 96 dpi.
    property real px: 13
    // Geist ships as a variable font: the weight is applied on the wght axis as well.
    property int weight: Font.Normal
    // CSS line-height (a multiple of the font size). Qt's proportional lineHeight multiplies the
    // font's own line spacing (~1.2 em for Geist), which made design text taller than the artboards.
    property real css: 0
    lineHeightMode: css > 0 ? Text.FixedHeight : Text.ProportionalHeight
    lineHeight: css > 0 ? Math.round(px * css * Fz.textScale) : 1
    // FixedHeight alone doesn't shrink a single line below the font's own height: size the box too,
    // with the glyphs centred in it as CSS does
    height: css > 0 ? Math.max(1, lineCount) * Math.round(px * css * Fz.textScale) + topPadding + bottomPadding : implicitHeight
    verticalAlignment: css > 0 ? Text.AlignVCenter : Text.AlignTop
    color: Fz.tx
    font.family: mono ? Fz.mono : Fz.font
    font.pointSize: px * 0.75 * Fz.textScale
    font.weight: weight
    font.variableAxes: ({ "wght": weight })
    renderType: Text.NativeRendering
    elide: Text.ElideNone
}
