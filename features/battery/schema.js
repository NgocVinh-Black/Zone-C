.pragma library

// Settings under features.battery in shell.json: the session actions in the popup.
var fields = {
    lockCommand: { type: "array", default: ["loginctl", "lock-session"], check: isCommand },
    suspendCommand: { type: "array", default: ["systemctl", "suspend"], check: isCommand },
    rebootCommand: { type: "array", default: ["systemctl", "reboot"], check: isCommand },
    poweroffCommand: { type: "array", default: ["systemctl", "poweroff"], check: isCommand },
    logoutCommand: { type: "array", default: ["loginctl", "terminate-session", "self"], check: isCommand }
};

function isCommand(value) {
    return value.length > 0 && value.every(function (part) {
        return typeof part === "string" && part.length > 0;
    });
}
