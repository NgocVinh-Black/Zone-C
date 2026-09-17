import test from "node:test";
import assert from "node:assert/strict";
import { loadQmlJs } from "./load.mjs";

const V = loadQmlJs("core/config/ConfigValidator.js");

const schema = {
    general: {
        type: "section",
        fields: {
            uiScale: { type: "number", default: 1, min: 0.5, max: 3 },
            name: { type: "string", default: "zone" },
        },
    },
    count: { type: "number", int: true, default: 8, min: 1, max: 20 },
    mode: { type: "string", default: "a", enum: ["a", "b"] },
    list: { type: "array", default: ["x"], check: v => v.every(i => typeof i === "string") },
    extra: { type: "object", default: {} },
};

test("missing input returns all defaults without warnings", () => {
    const r = V.validateSection(schema, undefined, "");
    assert.deepEqual(JSON.parse(JSON.stringify(r.value)), {
        general: { uiScale: 1, name: "zone" },
        count: 8,
        mode: "a",
        list: ["x"],
        extra: {},
    });
    assert.equal(r.warnings.length, 0);
});

test("valid values are kept", () => {
    const r = V.validateSection(schema, { general: { uiScale: 1.5 }, count: 4, mode: "b", list: ["q"] }, "");
    assert.equal(r.value.general.uiScale, 1.5);
    assert.equal(r.value.count, 4);
    assert.equal(r.value.mode, "b");
    assert.deepEqual([...r.value.list], ["q"]);
    assert.equal(r.warnings.length, 0);
});

test("wrong type falls back to default with a warning naming the path", () => {
    const r = V.validateSection(schema, { general: { uiScale: "big" } }, "");
    assert.equal(r.value.general.uiScale, 1);
    assert.equal(r.warnings.length, 1);
    assert.match(r.warnings[0], /general\.uiScale/);
});

test("out of range, non-integer, bad enum and failed check fall back", () => {
    const r = V.validateSection(schema, { count: 2.5, mode: "z", list: [1], general: { uiScale: 9 } }, "");
    assert.equal(r.value.count, 8);
    assert.equal(r.value.mode, "a");
    assert.deepEqual([...r.value.list], ["x"]);
    assert.equal(r.value.general.uiScale, 1);
    assert.equal(r.warnings.length, 4);
});

test("unknown keys are reported and dropped", () => {
    const r = V.validateSection(schema, { nope: 1 }, "features.demo");
    assert.equal("nope" in r.value, false);
    assert.equal(r.warnings.length, 1);
    assert.match(r.warnings[0], /features\.demo\.nope/);
});

test("non-object section input uses defaults with a warning", () => {
    const r = V.validateSection(schema, { general: 5 }, "");
    assert.equal(r.value.general.uiScale, 1);
    assert.equal(r.warnings.length, 1);
});

test("defaults are copied, not shared", () => {
    const a = V.validateSection(schema, undefined, "");
    a.value.list.push("mutated");
    const b = V.validateSection(schema, undefined, "");
    assert.deepEqual([...b.value.list], ["x"]);
});

test("a null default marks an optional value that is validated when set", () => {
    const optional = { lat: { type: "number", default: null, min: -90, max: 90 } };
    assert.equal(V.validateSection(optional, {}, "").value.lat, null);
    assert.equal(V.validateSection(optional, { lat: 10 }, "").value.lat, 10);
    const bad = V.validateSection(optional, { lat: 200 }, "");
    assert.equal(bad.value.lat, null);
    assert.equal(bad.warnings.length, 1);
});

test("parse reports invalid JSON instead of throwing", () => {
    assert.equal(V.parse('{"a":1}').ok, true);
    const bad = V.parse("{oops");
    assert.equal(bad.ok, false);
    assert.equal(typeof bad.error, "string");
});
