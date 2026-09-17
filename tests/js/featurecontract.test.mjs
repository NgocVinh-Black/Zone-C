import test from "node:test";
import assert from "node:assert/strict";
import { loadQmlJs } from "./load.mjs";

const C = loadQmlJs("core/feature/FeatureContract.js");

test("valid declaration has no errors", () => {
    assert.equal(C.check({ name: "battery", popup: null }, "battery").length, 0);
    const popup = { component: "file:///x.qml", anchor: "top-right", width: 10, height: 10 };
    assert.equal(C.check({ name: "battery", popup }, "battery").length, 0);
});

test("name must match folder", () => {
    assert.equal(C.check({ name: "bat", popup: null }, "battery").length, 1);
});

test("popup needs component, valid anchor and positive size", () => {
    const errors = C.check({ name: "a", popup: { anchor: "left", width: 0, height: 5 } }, "a");
    assert.equal(errors.length, 3);
});

test("feature names must be simple identifiers", () => {
    assert.equal(C.isValidName("battery"), true);
    assert.equal(C.isValidName("my_widget2"), true);
    assert.equal(C.isValidName("../etc"), false);
    assert.equal(C.isValidName("Bad-Name"), false);
});

test("namesFromConfig collects unique names in bar order, then enabled", () => {
    const bar = { left: [["workspaces"], ["media"]], center: [["clock", "weather"]], right: [["media", "battery"]] };
    assert.deepEqual([...C.namesFromConfig(bar, ["lock", "clock"])], ["workspaces", "media", "clock", "weather", "battery", "lock"]);
});
