import test from "node:test";
import assert from "node:assert/strict";
import { loadQmlJs } from "./load.mjs";

const L = loadQmlJs("core/popup/PopupLayout.js");
const plain = v => JSON.parse(JSON.stringify(v));

test("top-right sits under the bar against the right edge", () => {
    assert.deepEqual(plain(L.place("top-right", 801, 760, 1920, 1080, 60, 4)), { x: 1115, y: 60, width: 801, height: 760 });
});

test("top-left sits under the bar against the left edge", () => {
    assert.deepEqual(plain(L.place("top-left", 700, 650, 1920, 1080, 60, 4)), { x: 4, y: 60, width: 700, height: 650 });
});

test("top-center is horizontally centered", () => {
    assert.deepEqual(plain(L.place("top-center", 1450, 750, 1920, 1080, 60, 4)), { x: 235, y: 60, width: 1450, height: 750 });
});

test("center is centered on both axes", () => {
    assert.deepEqual(plain(L.place("center", 800, 700, 1920, 1080, 60, 4)), { x: 560, y: 190, width: 800, height: 700 });
});

test("popups larger than the screen are clamped", () => {
    assert.deepEqual(plain(L.place("top-right", 3000, 3000, 1366, 768, 60, 4)), { x: 4, y: 60, width: 1358, height: 704 });
});

test("unknown anchor returns null", () => {
    assert.equal(L.place("bottom", 10, 10, 100, 100, 0, 0), null);
});
