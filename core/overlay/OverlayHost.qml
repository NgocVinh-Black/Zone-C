import QtQuick
import Quickshell
import qs.core.feature

// Loads the `overlay` component of every loaded feature, once per screen.
// Unlike a popup, an overlay is always present and draws its own window, so it
// can sit wherever it likes and take only the input it needs: notification
// toasts in a corner, the volume OSD near the bottom edge.
// Knows nothing about specific features; it only follows the contract.
Scope {
    id: host

    property var screen: null

    readonly property var overlays: Object.keys(FeatureLoader.features).filter(name => String(FeatureLoader.features[name]?.overlay ?? "") !== "").map(name => ({
                name: name,
                source: String(FeatureLoader.features[name].overlay)
            }))

    Variants {
        model: host.overlays

        delegate: Component {
            Scope {
                id: slot

                required property var modelData

                LazyLoader {
                    id: loader

                    active: true
                    source: slot.modelData.source

                    onItemChanged: {
                        if (!item)
                            return;
                        if ("screen" in item)
                            item.screen = Qt.binding(() => host.screen);
                    }
                }

                Component.onCompleted: Qt.callLater(() => {
                    if (!loader.item)
                        console.warn(`[zone-c overlay] "${slot.modelData.name}" failed to load`);
                })
            }
        }
    }
}
