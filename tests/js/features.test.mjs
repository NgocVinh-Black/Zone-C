// Every feature folder must fulfil the feature contract (rule R6).
import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { ROOT } from "./load.mjs";

const featuresDir = path.join(ROOT, "features");
const folders = fs.readdirSync(featuresDir, { withFileTypes: true }).filter(d => d.isDirectory()).map(d => d.name);

test("there are features", () => {
    assert.ok(folders.length > 0);
});

for (const folder of folders) {
    test(`feature "${folder}" fulfils the contract`, () => {
        assert.match(folder, /^[a-z][a-z0-9_]*$/, "folder name must be a simple identifier");

        const declPath = path.join(featuresDir, folder, "feature.qml");
        assert.ok(fs.existsSync(declPath), "feature.qml is missing");

        const decl = fs.readFileSync(declPath, "utf8");
        assert.match(decl, /^\s*Feature\s*\{/m, "feature.qml must declare a Feature");
        assert.match(decl, new RegExp(`name:\\s*"${folder}"`), "name must match the folder");

        for (const match of decl.matchAll(/Qt\.resolvedUrl\("([^"]+)"\)/g)) {
            assert.ok(fs.existsSync(path.join(featuresDir, folder, match[1])), `${match[1]} does not exist`);
        }
    });
}
