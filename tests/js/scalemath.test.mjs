import test from "node:test";
import assert from "node:assert/strict";
import { loadQmlJs } from "./load.mjs";

const M = loadQmlJs("core/state/ScaleMath.js");

test("1920x1080 is the reference scale", () => {
    assert.equal(M.getScale(1920, 1080, 1), 1);
});

test("smaller screens shrink with exponent 0.85 and a 0.35 floor", () => {
    assert.ok(Math.abs(M.getScale(1366, 768, 1) - Math.pow(768 / 1080, 0.85)) < 1e-9);
    assert.equal(M.getScale(100, 100, 1), 0.35);
});

test("larger screens grow with exponent 0.5", () => {
    assert.ok(Math.abs(M.getScale(3840, 2160, 1) - Math.SQRT2) < 1e-9);
});

test("user scale multiplies the base scale", () => {
    assert.equal(M.getScale(1920, 1080, 1.5), 1.5);
});

test("invalid sizes return the user scale", () => {
    assert.equal(M.getScale(0, 1080, 1.25), 1.25);
});

test("s rounds scaled values", () => {
    assert.equal(M.s(48, 1), 48);
    assert.equal(M.s(48, 0.9), 43);
});
