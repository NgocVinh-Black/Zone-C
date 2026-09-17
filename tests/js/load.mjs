// Loads a QML JavaScript library (".pragma library" file) into a plain object
// so its top-level `var`s and functions can be tested with node:test.
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";

export const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");

export function loadQmlJs(relPath) {
    const source = fs
        .readFileSync(path.join(ROOT, relPath), "utf8")
        .replace(/^\s*\.pragma\s+library\s*$/m, "")
        .replace(/^\s*\.import\s.*$/gm, "");
    const context = { console };
    vm.createContext(context);
    vm.runInContext(source, context, { filename: relPath });
    return context;
}
