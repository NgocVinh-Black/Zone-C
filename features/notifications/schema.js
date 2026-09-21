.pragma library

// Settings under features.notifications in shell.json.
// The shell is the notification daemon itself, so there is no external command here.
var fields = {
    maxToasts: { type: "number", int: true, default: 4, min: 1, max: 10 },
    timeoutMs: { type: "number", int: true, default: 6000, min: 1000, max: 60000 },
    // Critical notifications stay on screen until they are dealt with.
    keepCritical: { type: "boolean", default: true }
};
