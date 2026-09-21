.pragma library

// Settings under features.osd in shell.json.
var fields = {
    timeoutMs: { type: "number", int: true, default: 1600, min: 300, max: 10000 },
    marginBottom: { type: "number", int: true, default: 90, min: 0, max: 600 }
};
