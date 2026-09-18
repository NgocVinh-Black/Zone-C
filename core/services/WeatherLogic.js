.pragma library

// Open-Meteo requests and WMO weather code mapping (pure, tested).

var DAY_HOURS = [2, 5, 8, 11, 14, 17, 20, 23];

function glyph(codePoint) {
    return String.fromCodePoint(codePoint);
}

function icon(code, isDay) {
    if (code === 0) return glyph(isDay ? 0xF0599 : 0xF0594);
    if (code === 1 || code === 2) return glyph(isDay ? 0xF0595 : 0xF0F31);
    if (code === 3) return glyph(0xF0590);
    if (code === 45 || code === 48) return glyph(0xF0591);
    if (code === 65 || code === 67 || code === 82) return glyph(0xF0596);
    if ((code >= 51 && code <= 64) || code === 66 || code === 80 || code === 81) return glyph(0xF0597);
    if ((code >= 71 && code <= 77) || code === 85 || code === 86) return glyph(0xF0598);
    if (code >= 95 && code <= 99) return glyph(0xF0593);
    return glyph(0xF0590);
}

// Palette colour name used to tint weather icons.
function tone(code) {
    if (code <= 2) return "yellow";
    if (code >= 51 && code <= 82) return "blue";
    if (code >= 95) return "mauve";
    return "overlay2";
}

function describe(code) {
    if (code === 0) return "Clear Sky";
    if (code === 1) return "Mainly Clear";
    if (code === 2) return "Partly Cloudy";
    if (code === 3) return "Overcast";
    if (code === 45 || code === 48) return "Fog";
    if (code >= 51 && code <= 57) return "Drizzle";
    if (code >= 61 && code <= 67) return "Rain";
    if (code >= 71 && code <= 77) return "Snow";
    if (code >= 80 && code <= 82) return "Showers";
    if (code === 85 || code === 86) return "Snow Showers";
    if (code >= 95) return "Thunderstorm";
    return "Unknown";
}

function forecastUrl(latitude, longitude, unit) {
    return "https://api.open-meteo.com/v1/forecast"
        + "?latitude=" + latitude
        + "&longitude=" + longitude
        + "&current=temperature_2m,weather_code,is_day"
        + "&hourly=temperature_2m,weather_code,is_day"
        + "&daily=weather_code,temperature_2m_max,apparent_temperature_max,wind_speed_10m_max,precipitation_probability_max,relative_humidity_2m_mean"
        + "&wind_speed_unit=ms&timezone=auto&forecast_days=5"
        + "&temperature_unit=" + (unit === "imperial" ? "fahrenheit" : "celsius");
}

function formatTemp(value) {
    return Math.round(value) + "°";
}

function pad(n) {
    return (n < 10 ? "0" : "") + n;
}

function at(list, index, fallback) {
    return list && list[index] !== undefined && list[index] !== null ? list[index] : fallback;
}

// Turns an Open-Meteo response into up to five days:
// { date, max, feelsLike, wind, humidity, pop, code, icon, tone, desc,
//   hourly: [{ time, temp, code, icon, tone }] } with hourly at DAY_HOURS.
function buildForecast(data) {
    const daily = data && data.daily ? data.daily : {};
    const hourly = data && data.hourly ? data.hourly : {};
    const days = [];
    const dates = daily.time || [];

    for (let d = 0; d < dates.length && d < 5; d++) {
        const code = at(daily.weather_code, d, 0);
        const hours = [];
        for (const h of DAY_HOURS) {
            const index = (hourly.time || []).indexOf(dates[d] + "T" + pad(h) + ":00");
            if (index < 0)
                continue;
            const hourCode = at(hourly.weather_code, index, code);
            const isDay = at(hourly.is_day, index, 1) === 1;
            hours.push({
                time: pad(h) + ":00",
                temp: Math.round(at(hourly.temperature_2m, index, 0) * 10) / 10,
                code: hourCode,
                icon: icon(hourCode, isDay),
                tone: tone(hourCode)
            });
        }
        days.push({
            date: dates[d],
            max: Math.round(at(daily.temperature_2m_max, d, 0)),
            feelsLike: Math.round(at(daily.apparent_temperature_max, d, 0) * 10) / 10,
            wind: Math.round(at(daily.wind_speed_10m_max, d, 0)),
            humidity: Math.round(at(daily.relative_humidity_2m_mean, d, 0)),
            pop: Math.round(at(daily.precipitation_probability_max, d, 0)),
            code: code,
            icon: icon(code, true),
            tone: tone(code),
            desc: describe(code),
            hourly: hours
        });
    }
    return days;
}

// Index of the entry whose "HH:00" time is closest to `hour`.
function nearestHour(hours, hour) {
    let best = -1;
    let bestDiff = 99;
    for (let i = 0; i < hours.length; i++) {
        const diff = Math.abs(parseInt(hours[i].time, 10) - hour);
        if (diff < bestDiff) {
            bestDiff = diff;
            best = i;
        }
    }
    return best;
}
