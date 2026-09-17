.pragma library

// Schema for the shared part of ~/.config/zone-c/shell.json.
// Feature-specific settings live under "features.<name>" and are validated
// by each feature's own schema.js.

function isStringList(value) {
    return value.every(function (item) {
        return typeof item === "string" && item.length > 0;
    });
}

// A bar zone is a list of groups; each group is a non-empty list of feature names
// drawn inside one block.
function isGroupList(value) {
    return value.every(function (group) {
        return Array.isArray(group) && group.length > 0 && isStringList(group);
    });
}

var fields = {
    general: {
        type: "section",
        fields: {
            uiScale: { type: "number", default: 1, min: 0.5, max: 3 }
        }
    },
    theme: {
        type: "section",
        fields: {
            matugen: { type: "boolean", default: false },
            colorsPath: { type: "string", default: "" }
        }
    },
    bar: {
        type: "section",
        fields: {
            left: { type: "array", default: [["workspaces"], ["media"]], check: isGroupList },
            center: { type: "array", default: [["clock", "weather"]], check: isGroupList },
            right: {
                type: "array",
                default: [["tray"], ["keyboard", "network", "bluetooth", "volume", "battery"]],
                check: isGroupList
            }
        }
    },
    enabled: { type: "array", default: [], check: isStringList },
    features: { type: "object", default: {} }
};
