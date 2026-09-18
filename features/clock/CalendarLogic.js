.pragma library

// Month grid and time-of-day accents for the calendar popup (pure, tested).

// 42 cells (6 weeks, Monday first) for the month `offset` months from `today`:
// { day, currentMonth, today }. Also returns the month's first day.
function monthGrid(today, offset) {
    const first = new Date(today.getFullYear(), today.getMonth() + offset, 1);
    const year = first.getFullYear();
    const month = first.getMonth();
    const lead = (first.getDay() + 6) % 7;
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const daysInPrev = new Date(year, month, 0).getDate();
    const isThisMonth = today.getFullYear() === year && today.getMonth() === month;

    const cells = [];
    for (let i = lead - 1; i >= 0; i--)
        cells.push({ day: daysInPrev - i, currentMonth: false, today: false });
    for (let d = 1; d <= daysInMonth; d++)
        cells.push({ day: d, currentMonth: true, today: isThisMonth && d === today.getDate() });
    for (let d = 1; cells.length < 42; d++)
        cells.push({ day: d, currentMonth: false, today: false });

    return { first: first, cells: cells };
}

// Palette colour names for the hour: [main, accent].
function timeTones(hour) {
    if (hour >= 5 && hour < 12)
        return ["peach", "yellow"];
    if (hour >= 12 && hour < 17)
        return ["sapphire", "teal"];
    if (hour >= 17 && hour < 21)
        return ["mauve", "pink"];
    return ["blue", "mauve"];
}

// "Wednesday, 08 Apr (Tomorrow)"-style header for a date relative to today.
function relativeDay(date, today) {
    const start = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const that = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    const diff = Math.round((that - start) / 86400000);
    if (diff === 0)
        return "Today";
    if (diff === 1)
        return "Tomorrow";
    if (diff === -1)
        return "Yesterday";
    return "";
}
