.pragma library

// Ranks desktop entries for the launcher. Pure on purpose: the service hands in
// plain objects { name, comment, keywords, categories } and gets a sorted list back,
// so the ranking can be tested without a desktop entry database.

function normalise(value) {
    return String(value === undefined || value === null ? "" : value).toLowerCase();
}

// How scattered `query` is inside `text` when read as a subsequence, or -1 when it
// is not one. This is the last resort, so that "fox" still finds "Firefox".
function subsequenceGap(text, query) {
    var gap = 0;
    var at = -1;
    for (var i = 0; i < query.length; i++) {
        var next = text.indexOf(query[i], at + 1);
        if (next < 0)
            return -1;
        if (at >= 0)
            gap += next - at - 1;
        at = next;
    }
    return gap;
}

function anyContains(values, query) {
    return (values || []).some(function (value) {
        return normalise(value).indexOf(query) >= 0;
    });
}

// Higher is a better match; -1 means the entry should be left out entirely.
// Shorter names win ties so that "Files" beats "Recent Files" for "files".
function score(entry, query) {
    if (query === "")
        return 0;

    var name = normalise(entry.name);
    if (name === query)
        return 1000;
    if (name.indexOf(query) === 0)
        return 900 - name.length;

    var words = name.split(/[\s\-_.]+/);
    var startsWord = words.some(function (word) {
        return word.indexOf(query) === 0;
    });
    if (startsWord)
        return 800 - name.length;
    if (name.indexOf(query) >= 0)
        return 700 - name.length;

    if (anyContains(entry.keywords, query))
        return 600;
    if (anyContains(entry.categories, query))
        return 500;
    if (normalise(entry.comment).indexOf(query) >= 0)
        return 400;

    var gap = subsequenceGap(name, query);
    return gap >= 0 ? 300 - gap : -1;
}

// Matching entries, best first, alphabetical within the same score.
function search(entries, rawQuery, limit) {
    var query = normalise(rawQuery).trim();
    var scored = [];

    (entries || []).forEach(function (entry) {
        var value = score(entry, query);
        if (value >= 0)
            scored.push({ entry: entry, score: value, key: normalise(entry.name) });
    });

    scored.sort(function (a, b) {
        if (b.score !== a.score)
            return b.score - a.score;
        if (a.key === b.key)
            return 0;
        return a.key < b.key ? -1 : 1;
    });

    var max = limit > 0 ? limit : scored.length;
    return scored.slice(0, max).map(function (item) {
        return item.entry;
    });
}

// Keeps the highlighted row inside the list while it shrinks or the user scrolls
// past either end.
function clampIndex(index, count) {
    if (count <= 0)
        return 0;
    return ((index % count) + count) % count;
}
