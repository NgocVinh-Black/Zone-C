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

test("battery tone is green when charging, red at 20% or less, else text", () => {
    const B = loadQmlJs("features/battery/BatteryLogic.js");
    assert.equal(B.tone(10, true), "green");
    assert.equal(B.tone(20, false), "red");
    assert.equal(B.tone(21, false), "text");
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
    const devices = "wifi:connected:Home\nethernet:unavailable:\nloopback:connected (externally):lo";
    const wifi = "yes:72:Home\nno:40:Other";
    const s1 = N.parseStatus(devices, wifi, "enabled");
    assert.deepEqual({ ...s1 }, { kind: "wifi", name: "Home", strength: 72, wifiEnabled: true });

    const s2 = N.parseStatus("ethernet:connected:Wired 1\nwifi:connected:Home", wifi, "enabled");
    assert.equal(s2.kind, "ethernet");

    const s3 = N.parseStatus("wifi:disconnected:", "", "disabled");
    assert.deepEqual({ ...s3 }, { kind: "none", name: "", strength: 0, wifiEnabled: false });
});

test("bluetooth icon reflects power and connection", () => {
    const BT = loadQmlJs("features/bluetooth/BluetoothLogic.js");
    assert.equal(cp(BT.icon(false, false)), "f00b2");
    assert.equal(cp(BT.icon(true, false)), "f00af");
    assert.equal(cp(BT.icon(true, true)), "f00b1");
});

test("keyboard label uses the parenthesised code or the first two letters", () => {
    const K = loadQmlJs("features/keyboard/KeyboardLogic.js");
    assert.equal(K.label("English (US)"), "US");
    assert.equal(K.label("Vietnamese"), "VI");
    assert.equal(K.label(""), "??");
});

test("weather codes map to icon and tone", () => {
    const W = loadQmlJs("features/weather/WeatherLogic.js");
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
    const W = loadQmlJs("features/weather/WeatherLogic.js");
    const url = W.forecastUrl(10.8, 106.6, "imperial");
    assert.match(url, /latitude=10\.8/);
    assert.match(url, /temperature_unit=fahrenheit/);
    assert.match(W.forecastUrl(1, 2, "metric"), /temperature_unit=celsius/);
    assert.equal(W.formatTemp(23.6), "24°");
});
