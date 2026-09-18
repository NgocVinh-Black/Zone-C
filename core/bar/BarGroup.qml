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

    // Bumped when slots load, so the widget scans below re-run.
    property int revision: 0

    // Block styling comes from the widgets: the first one decides padding and border,
    // and a block with an interactive widget lightens and grows while hovered.
    readonly property var widgets: {
        revision;
        const list = [];
        for (let i = 0; i < slots.count; i++) {
            const item = slots.itemAt(i)?.item;
            if (item)
                list.push(item);
        }
        return list;
    }
    readonly property var lead: widgets.length > 0 ? widgets[0] : null
    readonly property var interactiveWidget: widgets.find(w => w.blockInteractive) ?? null
    readonly property bool interactive: interactiveWidget !== null
    readonly property bool hovered: interactive && blockHover.hovered
    readonly property int padding: lead ? lead.blockPadding : Tokens.block.paddingX

    function recount(): void {
        revision++;
        let count = 0;
        for (let i = 0; i < slots.count; i++) {
            if (slots.itemAt(i)?.slotShown)
                count++;
        }
        shownCount = count;
    }

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: Tokens.bar.height
    width: implicitWidth
    height: implicitHeight
    visible: shownCount > 0
    clip: !interactive

    color: hovered ? Colours.alpha(Colours.surface1, Tokens.block.hoverOpacity) : Colours.alpha(Colours.base, Tokens.block.opacity)
    border.color: Colours.alpha(Colours.text, hovered ? Tokens.block.borderAlphaHover : (lead ? lead.blockBorderAlpha : Tokens.block.borderAlphaStatic))
    scale: hovered ? interactiveWidget.blockHoverScale : 1

    Behavior on implicitWidth {
        Anim {
            duration: Tokens.anim.medium
            easing.type: Easing.OutExpo
        }
    }

    Behavior on scale {
        Anim {
            duration: 300
            easing.type: Easing.OutExpo
        }
    }

    Behavior on color {
        ColorAnim {
            duration: 200
        }
    }

    HoverHandler {
        id: blockHover
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
                onLoaded: Qt.callLater(root.recount)
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
