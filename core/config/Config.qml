pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "ConfigValidator.js" as Validator
import "CoreSchema.js" as CoreSchema

// Typed access to ~/.config/zone-c/shell.json.
// The file is optional; anything missing or invalid falls back to defaults.
Singleton {
    id: root

    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/zone-c"
    readonly property string path: dir + "/shell.json"

    // Parsed user JSON, unvalidated. Only this file reads it directly.
    property var raw: ({})

    readonly property var core: validate(CoreSchema.fields, raw, "")
    readonly property var general: core.general
    readonly property var theme: core.theme
    readonly property var bar: core.bar
    readonly property var weather: core.weather
    readonly property var enabled: core.enabled

    // Validated settings of one feature, stored under "features.<name>".
    function feature(name: string, fields: var): var {
        const all = root.raw && typeof root.raw.features === "object" && root.raw.features !== null ? root.raw.features : {};
        return validate(fields, all[name], "features." + name);
    }

    function validate(fields: var, input: var, path: string): var {
        const result = Validator.validateSection(fields, input, path);
        for (const warning of result.warnings)
            console.warn("[zone-c config]", warning);
        return result.value;
    }

    FileView {
        path: root.path
        watchChanges: true
        printErrors: false

        onFileChanged: reload()

        onLoaded: {
            const parsed = Validator.parse(text());
            if (parsed.ok) {
                root.raw = parsed.data;
            } else {
                console.warn("[zone-c config]", root.path, "is not valid JSON:", parsed.error, "- using defaults");
                root.raw = {};
            }
        }

        onLoadFailed: root.raw = {}
    }
}
