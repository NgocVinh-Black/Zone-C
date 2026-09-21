.pragma library

// Parses and filters `cliphist list`. Each line is "<id>\t<preview>", and an image
// arrives as a placeholder like "[[ binary data 12 KiB png 300x200 ]]".

function isImage(preview) {
    return /^\s*\[\[\s*binary data/.test(String(preview));
}

// "png 300x200 · 12 KiB" out of cliphist's binary placeholder, or "binary data".
function imageLabel(preview) {
    var match = /binary data\s+([0-9.]+\s*\w+)\s+(\w+)\s+([0-9]+x[0-9]+)/.exec(String(preview));
    if (!match)
        return "binary data";
    return match[2] + " " + match[3] + " · " + match[1];
}

function parse(text) {
    var entries = [];
    String(text === undefined || text === null ? "" : text).split("\n").forEach(function (line) {
        if (line === "")
            return;
        var tab = line.indexOf("\t");
        if (tab <= 0)
            return;
        var preview = line.slice(tab + 1);
        var image = isImage(preview);
        entries.push({
            id: line.slice(0, tab),
            // The whole line is what `cliphist decode` and `cliphist delete` expect back.
            line: line,
            preview: preview,
            image: image,
            label: image ? imageLabel(preview) : collapse(preview)
        });
    });
    return entries;
}

// Clipboard text often carries newlines and runs of spaces; a row shows one line.
function collapse(preview) {
    return String(preview).replace(/\s+/g, " ").trim();
}

function filter(entries, rawQuery) {
    var query = String(rawQuery === undefined || rawQuery === null ? "" : rawQuery).toLowerCase().trim();
    if (query === "")
        return entries.slice();
    return (entries || []).filter(function (entry) {
        return entry.label.toLowerCase().indexOf(query) >= 0;
    });
}

// Keeps the highlighted row inside the list while it shrinks or the user scrolls
// past either end.
function clampIndex(index, count) {
    if (count <= 0)
        return 0;
    return ((index % count) + count) % count;
}
