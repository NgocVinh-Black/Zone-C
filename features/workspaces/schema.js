.pragma library

// Settings under features.workspaces in shell.json.
var fields = {
    // Workspaces always shown. The active one is shown too when it is beyond this.
    count: { type: "number", int: true, default: 8, min: 1, max: 20 }
};
