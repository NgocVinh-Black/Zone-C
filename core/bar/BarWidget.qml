import QtQuick
import qs.core.feature
import qs.core.state

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

    visible: shown

    readonly property bool hasPopup: !!FeatureLoader.features[featureName]?.popup
    readonly property bool compact: (barWindow?.width ?? 0) < 1920

    function openPopup(): void {
        if (!hasPopup)
            return;
        const pos = root.mapToItem(null, 0, 0);
        ShellState.toggle(featureName, screen, {
            x: pos.x + (barWindow?.margins.left ?? 0),
            y: pos.y + (barWindow?.margins.top ?? 0),
            width: root.width,
            height: root.height
        });
    }
}
