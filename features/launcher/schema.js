.pragma library

// Settings under features.launcher in shell.json.
var fields = {
    maxResults: { type: "number", int: true, default: 40, min: 1, max: 200 },
    // Used for desktop entries that ask to run in a terminal.
    terminal: { type: "array", default: ["kitty", "-e"], check: isCommand },
    placeholder: { type: "string", default: "Search applications" }
};

function isCommand(value) {
    return value.length > 0 && value.every(function (part) {
        return typeof part === "string" && part.length > 0;
    });
}
