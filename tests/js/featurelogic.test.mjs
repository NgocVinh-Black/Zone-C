import test from "node:test";
import assert from "node:assert/strict";
import { loadQmlJs } from "./load.mjs";

const cp = s => s.codePointAt(0).toString(16);

test("battery icon follows level and charging state", () => {
    const B = loadQmlJs("features/battery/BatteryLogic.js");
    assert.equal(cp(B.icon(95, false)), "f0079");
    assert.equal(cp(B.icon(45, false)), "f007e");
    assert.equal(cp(B.icon(5, false)), "f007a");
    assert.equal(cp(B.icon(95, true)), "f0085");
    assert.equal(cp(B.icon(10, true)), "f089c");
});

test("battery tone follows charge level, green while charging", () => {
    const B = loadQmlJs("features/battery/BatteryLogic.js");
    assert.equal(B.tone(10, true), "green");
    assert.equal(B.tone(70, false), "blue");
    assert.equal(B.tone(69, false), "yellow");
    assert.equal(B.tone(30, false), "yellow");
    assert.equal(B.tone(29, false), "red");
    assert.equal(B.secondaryTone(90, false), "mauve");
    assert.equal(B.secondaryTone(10, true), "sapphire");
});

test("battery pill fills only when charging or at 20% or less", () => {
    const B = loadQmlJs("features/battery/BatteryLogic.js");
    assert.equal(B.filled(90, true), true);
    assert.equal(B.filled(20, false), true);
    assert.equal(B.filled(21, false), false);
});

test("power profile tones and uptime parsing", () => {
    const B = loadQmlJs("features/battery/BatteryLogic.js");
    assert.equal(B.profileTone("performance"), "red");
    assert.equal(B.profileTone("power-saver"), "green");
    assert.equal(B.profileTone("balanced"), "blue");
    assert.deepEqual({ ...B.parseUptime("10805.52 40000.1\n") }, { hours: 3, minutes: 0 });
    assert.deepEqual({ ...B.parseUptime("3599 1") }, { hours: 0, minutes: 59 });
    assert.deepEqual({ ...B.parseUptime("") }, { hours: 0, minutes: 0 });
    assert.equal(B.twoDigits(7), "07");
});

test("volume icon follows level and mute", () => {
    const V = loadQmlJs("features/volume/VolumeLogic.js");
    assert.equal(cp(V.icon(0.5, true)), "f075f");
    assert.equal(cp(V.icon(0, false)), "f075f");
    assert.equal(cp(V.icon(0.2, false)), "f057f");
    assert.equal(cp(V.icon(0.5, false)), "f0580");
    assert.equal(cp(V.icon(0.9, false)), "f057e");
});

test("volume step clamps between 0 and 1", () => {
    const V = loadQmlJs("features/volume/VolumeLogic.js");
    assert.equal(V.step(0.98, 1, 0.05), 1);
    assert.equal(V.step(0.02, -1, 0.05), 0);
    assert.ok(Math.abs(V.step(0.5, 1, 0.05) - 0.55) < 1e-9);
});

test("wifi icon follows signal strength", () => {
    const N = loadQmlJs("features/network/NetworkLogic.js");
    assert.equal(cp(N.wifiIcon(false, 90)), "f092e");
    assert.equal(cp(N.wifiIcon(true, 80)), "f0928");
    assert.equal(cp(N.wifiIcon(true, 60)), "f0925");
    assert.equal(cp(N.wifiIcon(true, 30)), "f0922");
    assert.equal(cp(N.wifiIcon(true, 10)), "f091f");
    assert.equal(cp(N.wifiIcon(true, 0)), "f092f");
});

test("nmcli terse fields respect escaped colons", () => {
    const N = loadQmlJs("features/network/NetworkLogic.js");
    assert.deepEqual([...N.splitTerse("wifi:connected:My\\:Net")], ["wifi", "connected", "My:Net"]);
    assert.deepEqual([...N.splitTerse("a\\\\b:c")], ["a\\b", "c"]);
});

test("nmcli status prefers ethernet, then wifi, then none", () => {
    const N = loadQmlJs("features/network/NetworkLogic.js");
    const devices = "wlan0:wifi:connected:Home\nenp1s0:ethernet:unavailable:\nlo:loopback:connected (externally):lo";
    const wifi = "*:72:WPA2:5180 MHz:Home\n :40:--:2412 MHz:Other";
    const s1 = N.parseStatus(devices, wifi, "enabled", "192.168.1.5/24\n");
    assert.equal(s1.kind, "wifi");
    assert.equal(s1.name, "Home");
    assert.equal(s1.strength, 72);
    assert.equal(s1.security, "WPA2");
    assert.equal(s1.freq, "5180 MHz");
    assert.equal(s1.ip, "192.168.1.5");
    assert.equal(s1.wifiDevice, "wlan0");
    assert.equal(s1.wifiEnabled, true);

    const s2 = N.parseStatus("enp1s0:ethernet:connected:Wired 1\nwlan0:wifi:connected:Home", wifi, "enabled", "");
    assert.equal(s2.kind, "ethernet");
    assert.equal(s2.name, "Wired 1");

    const s3 = N.parseStatus("wlan0:wifi:disconnected:", "", "disabled", "");
    assert.equal(s3.kind, "none");
    assert.equal(s3.wifiEnabled, false);
    assert.equal(s3.networks.length, 0);
});

test("wifi list keeps the strongest entry per SSID, sorted by name", () => {
    const N = loadQmlJs("features/network/NetworkLogic.js");
    const list = N.parseWifiList(" :30:WPA2:2412 MHz:Zeta\n :80:WPA2:5180 MHz:Zeta\n :50:--:2437 MHz:Alpha\n :90:WPA2:2412 MHz:\n*:20:WPA3:5500 MHz:Alpha");
    const plain = JSON.parse(JSON.stringify(list));
    assert.deepEqual(plain.map(n => n.ssid), ["Alpha", "Zeta"]);
    assert.equal(plain[0].active, true);
    assert.equal(plain[0].signal, 20);
    assert.equal(plain[1].signal, 80);
    assert.equal(N.parseWifiList(" :50:--:2437 MHz:Cafe")[0].security, "Open");
});

test("bluetooth icon reflects power and connection", () => {
    const BT = loadQmlJs("features/bluetooth/BluetoothLogic.js");
    assert.equal(cp(BT.icon(false, false)), "f00b2");
    assert.equal(cp(BT.icon(true, false)), "f00af");
    assert.equal(cp(BT.icon(true, true)), "f00b1");
});

test("keyboard label is the language's first two letters", () => {
    const K = loadQmlJs("features/keyboard/KeyboardLogic.js");
    assert.equal(K.label("English (US)"), "EN");
    assert.equal(K.label("Vietnamese"), "VI");
    assert.equal(K.label(""), "??");
});

test("weather codes map to icon, tone and description", () => {
    const W = loadQmlJs("core/services/WeatherLogic.js");
    assert.equal(W.describe(0), "Clear Sky");
    assert.equal(W.describe(63), "Rain");
    assert.equal(W.describe(96), "Thunderstorm");
    assert.equal(cp(W.icon(0, true)), "f0599");
    assert.equal(cp(W.icon(0, false)), "f0594");
    assert.equal(cp(W.icon(2, true)), "f0595");
    assert.equal(cp(W.icon(63, true)), "f0597");
    assert.equal(cp(W.icon(65, true)), "f0596");
    assert.equal(cp(W.icon(73, true)), "f0598");
    assert.equal(cp(W.icon(95, true)), "f0593");
    assert.equal(cp(W.icon(999, true)), "f0590");
    assert.equal(W.tone(0), "yellow");
    assert.equal(W.tone(61), "blue");
    assert.equal(W.tone(95), "mauve");
});

test("weather url and temperature formatting", () => {
    const W = loadQmlJs("core/services/WeatherLogic.js");
    assert.match(W.forecastUrl(1, 2, "metric"), /daily=weather_code/);
    assert.match(W.forecastUrl(1, 2, "metric"), /wind_speed_unit=ms/);
    const url = W.forecastUrl(10.8, 106.6, "imperial");
    assert.match(url, /latitude=10\.8/);
    assert.match(url, /temperature_unit=fahrenheit/);
    assert.match(W.forecastUrl(1, 2, "metric"), /temperature_unit=celsius/);
    assert.equal(W.formatTemp(23.6), "24°");
});

test("forecast is built per day with hourly entries every three hours", () => {
    const W = loadQmlJs("core/services/WeatherLogic.js");
    const hours = [];
    const temps = [];
    for (const day of ["2026-04-07", "2026-04-08"]) {
        for (let h = 0; h < 24; h++) {
            hours.push(`${day}T${String(h).padStart(2, "0")}:00`);
            temps.push(h);
        }
    }
    const data = {
        daily: {
            time: ["2026-04-07", "2026-04-08"],
            weather_code: [0, 61],
            temperature_2m_max: [11.4, 8.6],
            apparent_temperature_max: [8.62, 6],
            wind_speed_10m_max: [5.8, 3],
            precipitation_probability_max: [0, 70],
            relative_humidity_2m_mean: [58.4, 80]
        },
        hourly: { time: hours, temperature_2m: temps, weather_code: temps.map(() => 1), is_day: temps.map(() => 1) }
    };
    const days = JSON.parse(JSON.stringify(W.buildForecast(data)));
    assert.equal(days.length, 2);
    assert.equal(days[0].max, 11);
    assert.equal(days[0].feelsLike, 8.6);
    assert.equal(days[0].wind, 6);
    assert.equal(days[0].humidity, 58);
    assert.equal(days[0].desc, "Clear Sky");
    assert.equal(days[1].tone, "blue");
    assert.deepEqual(days[0].hourly.map(h => h.time), ["02:00", "05:00", "08:00", "11:00", "14:00", "17:00", "20:00", "23:00"]);
    assert.equal(days[0].hourly[1].temp, 5);
    assert.equal(W.nearestHour(days[0].hourly, 12), 3);
    assert.equal(W.nearestHour([], 12), -1);
    assert.equal(W.buildForecast({}).length, 0);
});

test("track times format as mm:ss or h:mm:ss", () => {
    const M = loadQmlJs("features/media/MediaLogic.js");
    assert.equal(M.formatTime(0), "00:00");
    assert.equal(M.formatTime(83.9), "01:23");
    assert.equal(M.formatTime(3725), "1:02:05");
    assert.equal(M.formatTime(undefined), "00:00");
});

test("equalizer presets, state parsing and EasyEffects preset", () => {
    const M = loadQmlJs("features/media/MediaLogic.js");
    assert.equal(M.PRESET_ORDER.length, 8);
    for (const name of M.PRESET_ORDER)
        assert.equal(M.PRESETS[name].length, M.BANDS.length, name);
    assert.equal(M.bandLabel(63), "63");
    assert.equal(M.bandLabel(16000), "16k");

    assert.deepEqual(JSON.parse(JSON.stringify(M.parseState("nope"))), { gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0], preset: "Flat" });
    const state = JSON.parse(JSON.stringify(M.parseState('{"gains":[20,-20,1.4,0,0,0,0,0,0,"x"],"preset":"Custom"}')));
    assert.deepEqual(state.gains, [12, -12, 1, 0, 0, 0, 0, 0, 0, 0]);
    assert.equal(state.preset, "Custom");

    const preset = JSON.parse(JSON.stringify(M.easyEffectsPreset(M.PRESETS.Rock)));
    const eq = preset.output.equalizer;
    assert.equal(eq["num-bands"], 10);
    assert.equal(eq.left.band0.frequency, 31);
    assert.equal(eq.left.band9.gain, 6);
});

test("calendar month grid is 6 weeks starting on Monday", () => {
    const C = loadQmlJs("features/clock/CalendarLogic.js");
    const today = new Date(2026, 3, 7);
    const april = C.monthGrid(today, 0);
    assert.equal(april.cells.length, 42);
    // April 2026 starts on a Wednesday: two days of March lead.
    assert.deepEqual(JSON.parse(JSON.stringify(april.cells.slice(0, 3))), [
        { day: 30, currentMonth: false, today: false },
        { day: 31, currentMonth: false, today: false },
        { day: 1, currentMonth: true, today: false }
    ]);
    assert.equal(april.cells.filter(c => c.today).length, 1);
    assert.equal(april.cells.find(c => c.today).day, 7);

    const may = C.monthGrid(today, 1);
    assert.equal(may.first.getMonth(), 4);
    assert.equal(may.cells.filter(c => c.today).length, 0);
    assert.equal(C.monthGrid(today, -4).first.getFullYear(), 2025);
});

test("time of day tones and relative day names", () => {
    const C = loadQmlJs("features/clock/CalendarLogic.js");
    assert.deepEqual([...C.timeTones(8)], ["peach", "yellow"]);
    assert.deepEqual([...C.timeTones(13)], ["sapphire", "teal"]);
    assert.deepEqual([...C.timeTones(18)], ["mauve", "pink"]);
    assert.deepEqual([...C.timeTones(23)], ["blue", "mauve"]);
    const today = new Date(2026, 3, 7, 22);
    assert.equal(C.relativeDay(new Date(2026, 3, 8, 1), today), "Tomorrow");
    assert.equal(C.relativeDay(new Date(2026, 3, 7), today), "Today");
    assert.equal(C.relativeDay(new Date(2026, 3, 12), today), "");
});

test("launcher ranks exact, prefix, word and fuzzy matches in that order", () => {
    const L = loadQmlJs("features/launcher/LauncherLogic.js");
    const entries = [
        { name: "Files", comment: "Browse the file system", keywords: ["manager"], categories: ["Utility"] },
        { name: "Recent Files", comment: "", keywords: [], categories: [] },
        { name: "Firefox", comment: "Browse the web", keywords: ["www"], categories: ["Network"] },
        { name: "Text Editor", comment: "", keywords: [], categories: ["Development"] }
    ];

    assert.deepEqual([...L.search(entries, "files", 0)].map(e => e.name), ["Files", "Recent Files"]);
    // "fox" matches Firefox only as a subsequence, and still finds it.
    assert.deepEqual([...L.search(entries, "fox", 0)].map(e => e.name), ["Firefox"]);
    // Keywords and categories match when the name does not.
    assert.deepEqual([...L.search(entries, "www", 0)].map(e => e.name), ["Firefox"]);
    assert.deepEqual([...L.search(entries, "development", 0)].map(e => e.name), ["Text Editor"]);
    assert.deepEqual([...L.search(entries, "zzz", 0)], []);
    // An empty query keeps everything, alphabetically.
    assert.deepEqual([...L.search(entries, "", 0)].map(e => e.name), ["Files", "Firefox", "Recent Files", "Text Editor"]);
    assert.equal(L.search(entries, "", 2).length, 2);
});

test("launcher index wraps at both ends and survives an empty list", () => {
    const L = loadQmlJs("features/launcher/LauncherLogic.js");
    assert.equal(L.clampIndex(0, 3), 0);
    assert.equal(L.clampIndex(3, 3), 0);
    assert.equal(L.clampIndex(-1, 3), 2);
    assert.equal(L.clampIndex(5, 0), 0);
});

test("clipboard parses cliphist lines and recognises images", () => {
    const C = loadQmlJs("features/clipboard/ClipboardLogic.js");
    const entries = C.parse("3\thello  world\n2\t[[ binary data 12 KiB png 300x200 ]]\n1\tline\n\n");
    assert.equal(entries.length, 3);
    assert.deepEqual({ ...entries[0] }, {
        id: "3",
        line: "3\thello  world",
        preview: "hello  world",
        image: false,
        label: "hello world"
    });
    assert.equal(entries[1].image, true);
    assert.equal(entries[1].label, "png 300x200 · 12 KiB");
    // The whole line goes back to cliphist, so it must survive parsing untouched.
    assert.equal(entries[1].line, "2\t[[ binary data 12 KiB png 300x200 ]]");
});

test("clipboard search is a case-insensitive substring match", () => {
    const C = loadQmlJs("features/clipboard/ClipboardLogic.js");
    const entries = C.parse("2\tpacman -Syu\n1\tHello There");
    assert.deepEqual([...C.filter(entries, "HELLO")].map(e => e.id), ["1"]);
    assert.deepEqual([...C.filter(entries, "")].map(e => e.id), ["2", "1"]);
    assert.deepEqual([...C.filter(entries, "nope")], []);
});

test("notification urgency picks a tone and critical sorts to the top", () => {
    const N = loadQmlJs("features/notifications/NotificationsLogic.js");
    assert.equal(N.tone(0), "subtext0");
    assert.equal(N.tone(1), "blue");
    assert.equal(N.tone(2), "red");
    const ordered = N.order([
        { id: "old", urgency: 1, time: 100 },
        { id: "new", urgency: 1, time: 300 },
        { id: "crit", urgency: 2, time: 200 }
    ]);
    assert.deepEqual([...ordered].map(e => e.id), ["crit", "new", "old"]);
});

test("notification age, markup stripping and source fallback", () => {
    const N = loadQmlJs("features/notifications/NotificationsLogic.js");
    const now = 1_000_000_000;
    assert.equal(N.age(now, now - 10_000), "now");
    assert.equal(N.age(now, now - 5 * 60_000), "5m");
    assert.equal(N.age(now, now - 3 * 3_600_000), "3h");
    assert.equal(N.age(now, now - 2 * 86_400_000), "2d");
    assert.equal(N.plain("<b>Bold</b><br/>next &amp; last"), "Bold\nnext & last");
    assert.equal(N.source("Firefox", "org.mozilla.firefox"), "Firefox");
    assert.equal(N.source("", "org.mozilla.firefox"), "Firefox");
    assert.equal(N.source("", ""), "Notification");
    assert.equal(N.countLabel(7), "7");
    assert.equal(N.countLabel(120), "99+");
});

test("osd volume glyphs, percentage and clamped fill", () => {
    const O = loadQmlJs("features/osd/OsdLogic.js");
    assert.equal(cp(O.icon(0.5, true)), "f075f");
    assert.equal(cp(O.icon(0, false)), "f075f");
    assert.equal(cp(O.icon(0.2, false)), "f057f");
    assert.equal(cp(O.icon(0.5, false)), "f0580");
    assert.equal(cp(O.icon(0.9, false)), "f057e");
    assert.equal(O.percent(0.925), 93);
    assert.equal(O.percent(1.4), 100);
    assert.equal(O.fill(1.4), 1);
    assert.equal(O.fill(-1), 0);
});
