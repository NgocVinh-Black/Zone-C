import QtQuick
import qs.core.feature
import qs.core.theme
import qs.core.ui

// One floating block holding the bar widgets of one or more features.
// Hidden when none of its widgets have anything to show.
Block {
    id: root

    required property var names
    required property var screen
    required property var barWindow

    // Counted from each widget's `shown` flag rather than from layout sizes,
    // so a hidden group can become visible again.
    property int shownCount: 0

    function recount(): void {
        let count = 0;
        for (let i = 0; i < slots.count; i++) {
            if (slots.itemAt(i)?.slotShown)
                count++;
        }
        shownCount = count;
    }

    implicitWidth: row.implicitWidth + Tokens.block.paddingX * 2
    implicitHeight: Tokens.bar.height
    width: implicitWidth
    height: implicitHeight
    visible: shownCount > 0
    clip: true

    Behavior on implicitWidth {
        Anim {
            duration: Tokens.anim.slow
            easing.type: Easing.OutExpo
        }
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.block.itemGap

        Repeater {
            id: slots

            model: root.names
            onItemAdded: Qt.callLater(root.recount)
            onItemRemoved: Qt.callLater(root.recount)

            delegate: Loader {
                id: slot

                required property string modelData
                required property int index
                readonly property var feature: FeatureLoader.features[modelData] ?? null
                readonly property string widgetUrl: feature ? feature.barWidget.toString() : ""
                readonly property bool slotShown: status === Loader.Ready && item.shown === true

                anchors.verticalCenter: parent.verticalCenter
                visible: slotShown

                onSlotShownChanged: root.recount()
                onWidgetUrlChanged: load()
                Component.onCompleted: load()

                function load(): void {
                    if (widgetUrl === "") {
                        source = "";
                        return;
                    }
                    setSource(widgetUrl, {
                        featureName: modelData,
                        screen: root.screen,
                        barWindow: root.barWindow,
                        indexInGroup: index
                    });
                }

                onStatusChanged: {
                    if (status === Loader.Error)
                        console.warn(`[zone-c bar] widget of "${modelData}" failed to load`);
                }
            }
        }
    }
}
