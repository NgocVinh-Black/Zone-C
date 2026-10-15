import QtQuick

// Body text in Geist, coloured like `.z` (var(--tx)).
Text {
    id: root
    property bool mono: false
    // Design sizes include halves (11.5px, 12.5px); pixelSize only takes integers, pointSize is exact at 96 dpi.
    property real px: 13
    // Geist ships as a variable font: the weight is applied on the wght axis as well.
    property int weight: Font.Normal
    color: Fz.tx
    font.family: mono ? Fz.mono : Fz.font
    font.pointSize: px * 0.75 * Fz.textScale
    font.weight: weight
    font.variableAxes: ({ "wght": weight })
    renderType: Text.NativeRendering
    elide: Text.ElideNone
}
