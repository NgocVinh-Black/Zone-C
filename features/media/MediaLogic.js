.pragma library

// Track time formatting and equalizer presets (pure, tested).

// 83 → "01:23", 3725 → "1:02:05".
function formatTime(seconds) {
    const total = Math.max(0, Math.floor(seconds || 0));
    const h = Math.floor(total / 3600);
    const m = Math.floor((total % 3600) / 60);
    const s = total % 60;
    const two = function (n) {
        return (n < 10 ? "0" : "") + n;
    };
    return h > 0 ? h + ":" + two(m) + ":" + two(s) : two(m) + ":" + two(s);
}

var BANDS = [31, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];

var PRESETS = {
    Flat: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    Bass: [5, 7, 5, 2, 1, 0, 0, 0, 1, 2],
    Treble: [-2, -1, 0, 1, 2, 3, 4, 5, 6, 6],
    Vocal: [-2, -1, 1, 3, 5, 5, 4, 2, 1, 0],
    Pop: [2, 4, 2, 0, 1, 2, 4, 2, 1, 2],
    Rock: [5, 4, 2, -1, -2, -1, 2, 4, 5, 6],
    Jazz: [3, 3, 1, 1, 1, 1, 2, 1, 2, 3],
    Classic: [0, 1, 2, 2, 2, 2, 1, 2, 3, 4]
};

var PRESET_ORDER = ["Flat", "Bass", "Treble", "Vocal", "Pop", "Rock", "Jazz", "Classic"];

function bandLabel(hz) {
    return hz >= 1000 ? (hz / 1000) + "k" : String(hz);
}

// Parses saved equalizer state, falling back to Flat for anything invalid.
function parseState(text) {
    const flat = { gains: PRESETS.Flat.slice(), preset: "Flat" };
    let data;
    try {
        data = JSON.parse(text);
    } catch (e) {
        return flat;
    }
    if (!data || !Array.isArray(data.gains) || data.gains.length !== BANDS.length)
        return flat;
    const gains = data.gains.map(function (g) {
        const n = Math.round(Number(g));
        return isNaN(n) ? 0 : Math.max(-12, Math.min(12, n));
    });
    return { gains: gains, preset: typeof data.preset === "string" ? data.preset : "Custom" };
}

// EasyEffects output preset with one bell band per slider
// (the preset layout v1 used successfully with `easyeffects -l`).
function easyEffectsPreset(gains) {
    const bands = {};
    for (let i = 0; i < BANDS.length; i++) {
        bands["band" + i] = {
            frequency: BANDS[i],
            gain: gains[i] || 0,
            mode: "Bell",
            mute: false,
            q: 1.0,
            slope: "x1",
            solo: false,
            width: 1.0
        };
    }
    return {
        output: {
            blocklist: [],
            plugins_order: ["equalizer"],
            equalizer: {
                bypass: false,
                "input-gain": 0.0,
                "output-gain": 0.0,
                mode: "IIR",
                "num-bands": BANDS.length,
                "split-channels": false,
                left: bands,
                right: bands
            }
        }
    };
}
