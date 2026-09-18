.pragma library

// Settings under features.launcher in shell.json.
// The built-in launcher popup comes in a later stage; until then an external one runs.
var fields = {
    command: { type: "array", default: ["rofi", "-show", "drun"], check: isCommand }
};

function isCommand(value) {
    return value.length > 0 && value.every(function (part) {
        return typeof part === "string" && part.length > 0;
    });
}
