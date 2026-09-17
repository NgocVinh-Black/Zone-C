import test from "node:test";
import assert from "node:assert/strict";
import { loadQmlJs } from "./load.mjs";

const V = loadQmlJs("core/config/ConfigValidator.js");
const S = loadQmlJs("core/config/CoreSchema.js");

test("default bar layout matches the v1 look", () => {
    const r = V.validateSection(S.fields, {}, "");
    assert.equal(r.warnings.length, 0);
    const bar = JSON.parse(JSON.stringify(r.value.bar));
    assert.deepEqual(bar, {
        left: [["workspaces"], ["media"]],
        center: [["clock", "weather"]],
        right: [["tray"], ["keyboard", "network", "bluetooth", "volume", "battery"]],
    });
});

test("bar zones must be arrays of string groups", () => {
    for (const bad of [["workspaces"], [[1]], [[]], "x"]) {
        const r = V.validateSection(S.fields, { bar: { left: bad } }, "");
        assert.equal(r.warnings.length, 1, JSON.stringify(bad));
    }
    const ok = V.validateSection(S.fields, { bar: { left: [["a", "b"], ["c"]], center: [] } }, "");
    assert.equal(ok.warnings.length, 0);
});

test("enabled must be a list of strings", () => {
    assert.equal(V.validateSection(S.fields, { enabled: ["lock"] }, "").warnings.length, 0);
    assert.equal(V.validateSection(S.fields, { enabled: [3] }, "").warnings.length, 1);
});

test("feature settings live under features and are not validated here", () => {
    const r = V.validateSection(S.fields, { features: { workspaces: { count: 5 } } }, "");
    assert.equal(r.warnings.length, 0);
    assert.equal(r.value.features.workspaces.count, 5);
});
