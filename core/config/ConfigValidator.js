.pragma library

// Validates plain JSON against a schema and fills in defaults.
//
// Schema entry shapes:
//   { type: "section", fields: { ...schema } }
//   { type: "number" | "string" | "boolean" | "array" | "object",
//     default, min?, max?, int?, enum?, check?(value) }
//
// Never throws: invalid values fall back to defaults and produce warnings.

function typeOf(value) {
    if (Array.isArray(value))
        return "array";
    if (value === null)
        return "null";
    return typeof value;
}

function copy(value) {
    return value === undefined ? undefined : JSON.parse(JSON.stringify(value));
}

function validateValue(spec, value, path, warnings) {
    if (value === undefined)
        return copy(spec.default);

    const actual = typeOf(value);
    let problem = "";

    if (actual !== spec.type)
        problem = "expected " + spec.type + ", got " + actual;
    else if (spec.type === "number" && spec.int && !Number.isInteger(value))
        problem = "expected an integer, got " + value;
    else if (spec.type === "number" && spec.min !== undefined && value < spec.min)
        problem = value + " is below minimum " + spec.min;
    else if (spec.type === "number" && spec.max !== undefined && value > spec.max)
        problem = value + " is above maximum " + spec.max;
    else if (spec.enum && spec.enum.indexOf(value) < 0)
        problem = JSON.stringify(value) + " is not one of " + JSON.stringify(spec.enum);
    else if (spec.check && !spec.check(value))
        problem = "invalid value " + JSON.stringify(value);

    if (problem) {
        warnings.push(path + ": " + problem + ", using default");
        return copy(spec.default);
    }
    return copy(value);
}

function validateInto(fields, input, path, warnings) {
    const result = {};
    let source = input;

    if (input !== undefined && typeOf(input) !== "object") {
        warnings.push((path || "<root>") + ": expected object, got " + typeOf(input) + ", using defaults");
        source = undefined;
    }
    source = source || {};

    for (const key in fields) {
        const spec = fields[key];
        const childPath = path ? path + "." + key : key;
        if (spec.type === "section")
            result[key] = validateInto(spec.fields, source[key], childPath, warnings);
        else
            result[key] = validateValue(spec, source[key], childPath, warnings);
    }

    for (const key in source) {
        if (!(key in fields))
            warnings.push((path ? path + "." + key : key) + ": unknown key, ignored");
    }

    return result;
}

function validateSection(fields, input, path) {
    const warnings = [];
    const value = validateInto(fields, input, path, warnings);
    return { value: value, warnings: warnings };
}

function parse(text) {
    try {
        return { ok: true, data: JSON.parse(text) };
    } catch (e) {
        return { ok: false, error: String(e.message) };
    }
}
