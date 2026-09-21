.pragma library

// Urgency follows the desktop notification spec: 0 low, 1 normal, 2 critical.
function tone(urgency) {
    if (urgency >= 2)
        return "red";
    if (urgency <= 0)
        return "subtext0";
    return "blue";
}

// "now", "3m", "2h", "4d" for two timestamps in milliseconds.
function age(nowMs, thenMs) {
    var seconds = Math.max(0, Math.floor((nowMs - thenMs) / 1000));
    if (seconds < 45)
        return "now";
    var minutes = Math.floor(seconds / 60);
    if (minutes < 60)
        return Math.max(1, minutes) + "m";
    var hours = Math.floor(minutes / 60);
    if (hours < 24)
        return hours + "h";
    return Math.floor(hours / 24) + "d";
}

// Bodies may carry a little HTML. The cards draw plain text, so the markup is
// unwrapped instead of being shown as-is.
function plain(body) {
    return String(body === undefined || body === null ? "" : body)
        .replace(/<br\s*\/?>/gi, "\n")
        .replace(/<\/p>/gi, "\n")
        .replace(/<[^>]+>/g, "")
        .replace(/&lt;/g, "<")
        .replace(/&gt;/g, ">")
        .replace(/&quot;/g, "\"")
        .replace(/&apos;/g, "'")
        .replace(/&amp;/g, "&")
        .replace(/\n{3,}/g, "\n\n")
        .trim();
}

// What to print above the summary. Some senders leave appName empty and only set
// the desktop entry, others the other way round.
function source(appName, desktopEntry) {
    var name = String(appName === undefined || appName === null ? "" : appName).trim();
    if (name !== "")
        return name;
    var entry = String(desktopEntry === undefined || desktopEntry === null ? "" : desktopEntry).trim();
    if (entry === "")
        return "Notification";
    var last = entry.split(".").pop();
    return last.charAt(0).toUpperCase() + last.slice(1);
}

// Badge on the bar button.
function countLabel(count) {
    return count > 99 ? "99+" : String(count);
}

// Newest first, and critical notifications ahead of the rest.
function order(entries) {
    return (entries || []).slice().sort(function (a, b) {
        var critical = (b.urgency >= 2 ? 1 : 0) - (a.urgency >= 2 ? 1 : 0);
        if (critical !== 0)
            return critical;
        return b.time - a.time;
    });
}
