.pragma library

// Settings under features.weather in shell.json.
// Leave latitude/longitude out to locate by IP address.
var fields = {
    unit: { type: "string", default: "metric", enum: ["metric", "imperial"] },
    latitude: { type: "number", default: null, min: -90, max: 90 },
    longitude: { type: "number", default: null, min: -180, max: 180 },
    intervalMinutes: { type: "number", int: true, default: 30, min: 5, max: 720 }
};
