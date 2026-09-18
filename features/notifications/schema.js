.pragma library

// Settings under features.notifications in shell.json.
// The built-in notification center comes in a later stage; until then these
// commands drive an external daemon (swaync by default).
var fields = {
    toggleCommand: { type: "array", default: ["swaync-client", "-t", "-sw"], check: isCommand },
    dndCommand: { type: "array", default: ["swaync-client", "-d", "-sw"], check: isCommand }
};

function isCommand(value) {
    return value.length > 0 && value.every(function (part) {
        return typeof part === "string" && part.length > 0;
    });
}
