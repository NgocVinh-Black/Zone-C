.pragma library

var ANCHORS = ["top-left", "top-right", "top-center", "center"];
var KEYBOARD_MODES = ["ondemand", "exclusive"];

function isValidName(name) {
    return typeof name === "string" && /^[a-z][a-z0-9_]*$/.test(name);
}

// Returns a list of problems with a feature declaration (empty when valid).
function check(decl, folderName) {
    const errors = [];
    if (!decl || typeof decl !== "object")
        return ["declaration is missing"];

    if (decl.name !== folderName)
        errors.push("name \"" + decl.name + "\" does not match folder \"" + folderName + "\"");

    const popup = decl.popup;
    if (popup) {
        if (!popup.component || String(popup.component) === "")
            errors.push("popup.component is missing");
        if (ANCHORS.indexOf(popup.anchor) < 0)
            errors.push("popup.anchor \"" + popup.anchor + "\" must be one of " + ANCHORS.join(", "));
        if (!(popup.width > 0) || !(popup.height > 0))
            errors.push("popup.width and popup.height must be greater than 0");
        if (popup.keyboard !== undefined && KEYBOARD_MODES.indexOf(popup.keyboard) < 0)
            errors.push("popup.keyboard \"" + popup.keyboard + "\" must be one of " + KEYBOARD_MODES.join(", "));
    }
    return errors;
}

// Whether a popup should hold the keyboard as soon as it opens.
function wantsExclusiveKeyboard(popup) {
    return !!popup && popup.keyboard === "exclusive";
}

// Feature names to load: every name placed on the bar (in order), then `enabled`.
function namesFromConfig(bar, enabled) {
    const names = [];
    const add = function (name) {
        if (names.indexOf(name) < 0)
            names.push(name);
    };
    ["left", "center", "right"].forEach(function (zone) {
        (bar[zone] || []).forEach(function (group) {
            group.forEach(add);
        });
    });
    (enabled || []).forEach(add);
    return names;
}
