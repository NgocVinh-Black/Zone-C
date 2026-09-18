import QtQuick
import qs.core.feature
import qs.core.state
import qs.core.theme

// Base type for a feature's bar widget. The bar sets these properties when loading it.
Item {
    id: root

    property string featureName: ""
    property var screen: null
    property var barWindow: null

    // Order within its group, for staggered entrance animations.
    property int indexInGroup: 0

    // Whether the widget has something to show. Set this instead of `visible`:
    // the bar hides the slot (and the whole group when all slots are hidden).
    property bool shown: true

    // How the surrounding block looks. A block holding an interactive widget lightens
    // and grows while hovered, like v1's clock and search blocks.
    property bool blockInteractive: false
    property real blockHoverScale: Tokens.iconBlock.hoverScale
    property real blockBorderAlpha: Tokens.block.borderAlpha
    property int blockPadding: Tokens.block.paddingX

    visible: shown

    readonly property bool hasPopup: !!FeatureLoader.features[featureName]?.popup
    // Narrow screens get condensed widgets.
    readonly property bool compact: (screen?.width ?? 0) > 0 && screen.width < 1920

    // Opens this feature's popup, or another feature's popup by name.
    // `arg` is handed to the popup (e.g. a tab); see ShellState.toggle.
    function openPopup(name, arg) {
        const target = name || featureName;
        if (!FeatureLoader.features[target]?.popup)
            return;
        ShellState.toggle(target, screen, arg ?? "");
    }
}
