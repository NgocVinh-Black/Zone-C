.pragma library

// Settings under features.clipboard in shell.json.
// cliphist stores the history; the shell only reads and replays it.
var fields = {
    maxEntries: { type: "number", int: true, default: 200, min: 1, max: 1000 },
    placeholder: { type: "string", default: "Search clipboard" }
};
