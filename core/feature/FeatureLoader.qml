pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import "FeatureContract.js" as Contract

// Loads features/<name>/feature.qml for every feature named in the config.
// Core never references a feature by name; it only follows the config.
Singleton {
    id: root

    readonly property var names: Contract.namesFromConfig(Config.bar, Config.enabled)

    // name -> Feature object
    property var features: ({})

    onNamesChanged: sync()
    Component.onCompleted: sync()

    function get(name: string): var {
        return features[name] ?? null;
    }

    function sync(): void {
        const previous = features;
        const next = {};
        for (const name of names)
            next[name] = previous[name] ?? create(name);
        for (const name in next) {
            if (!next[name])
                delete next[name];
        }
        features = next;

        const stale = Object.keys(previous).filter(name => !next[name]);
        Qt.callLater(() => stale.forEach(name => previous[name].destroy()));
    }

    function create(name: string): var {
        if (!Contract.isValidName(name)) {
            console.warn(`[zone-c feature] "${name}" is not a valid feature name, skipped`);
            return null;
        }

        const component = Qt.createComponent(Qt.resolvedUrl(`../../features/${name}/feature.qml`));
        if (component.status !== Component.Ready) {
            console.warn(`[zone-c feature] "${name}" could not be loaded, skipped:`, component.errorString());
            return null;
        }

        const feature = component.createObject(root);
        if (!feature) {
            console.warn(`[zone-c feature] "${name}" could not be created, skipped`);
            return null;
        }

        const errors = Contract.check({
            name: feature.name,
            popup: feature.popup
        }, name);
        if (errors.length > 0) {
            for (const error of errors)
                console.warn(`[zone-c feature] "${name}": ${error}`);
            feature.destroy();
            return null;
        }
        return feature;
    }
}
