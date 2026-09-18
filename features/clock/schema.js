.pragma library

// Settings under features.clock in shell.json. Formats use Qt date format strings.
var fields = {
    timeFormat: { type: "string", default: "hh:mm:ss AP" },
    dateFormat: { type: "string", default: "dddd, MMMM dd" },
    // Optional command printing a schedule for the calendar popup as JSON:
    // { "header": "Wednesday, 08 Apr (Tomorrow)", "link": "https://…",
    //   "lessons": [{ "title": "EE", "start": <epoch s>, "end": <epoch s>, "location": "…" }] }
    // Empty: the popup has no schedule strip.
    scheduleCommand: { type: "array", default: [], check: isCommand },
    scheduleIntervalMinutes: { type: "number", int: true, default: 15, min: 1, max: 1440 }
};

function isCommand(value) {
    return value.every(function (part) {
        return typeof part === "string" && part.length > 0;
    });
}
