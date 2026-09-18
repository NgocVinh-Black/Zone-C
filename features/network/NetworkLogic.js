.pragma library

var ETHERNET_ICON = String.fromCodePoint(0xF0200);

// Nerd Font wifi glyph for a 0-100 signal strength.
function wifiIcon(enabled, strength) {
    if (!enabled)
        return String.fromCodePoint(0xF092E);
    if (strength >= 75) return String.fromCodePoint(0xF0928);
    if (strength >= 50) return String.fromCodePoint(0xF0925);
    if (strength >= 25) return String.fromCodePoint(0xF0922);
    if (strength > 0) return String.fromCodePoint(0xF091F);
    return String.fromCodePoint(0xF092F);
}

// Splits one line of `nmcli -t` output. nmcli escapes ':' and '\' with a backslash.
function splitTerse(line) {
    const fields = [];
    let current = "";
    for (let i = 0; i < line.length; i++) {
        const ch = line[i];
        if (ch === "\\" && i + 1 < line.length) {
            current += line[++i];
        } else if (ch === ":") {
            fields.push(current);
            current = "";
        } else {
            current += ch;
        }
    }
    fields.push(current);
    return fields;
}

function lines(text) {
    return (text || "").split("\n").filter(function (l) {
        return l.length > 0;
    });
}

// Strongest entry per SSID from `nmcli -t -f IN-USE,SIGNAL,SECURITY,FREQ,SSID device wifi list`,
// sorted by name: { ssid, signal, security, freq, active }.
function parseWifiList(text) {
    const best = {};
    lines(text).map(splitTerse).forEach(function (f) {
        const ssid = f[4] || "";
        if (ssid === "")
            return;
        const entry = {
            ssid: ssid,
            signal: parseInt(f[1], 10) || 0,
            security: f[2] && f[2] !== "--" ? f[2] : "Open",
            freq: f[3] || "",
            active: f[0] === "*"
        };
        const seen = best[ssid];
        if (!seen || entry.active || (!seen.active && entry.signal > seen.signal))
            best[ssid] = entry;
    });
    return Object.keys(best).sort(function (a, b) {
        return a.localeCompare(b);
    }).map(function (k) {
        return best[k];
    });
}

// devicesText: `nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status`
// wifiText:    `nmcli -t -f IN-USE,SIGNAL,SECURITY,FREQ,SSID device wifi list --rescan no`
// radioText:   `nmcli radio wifi`
// ipText:      `nmcli -g IP4.ADDRESS device show <wifi device>`
function parseStatus(devicesText, wifiText, radioText, ipText) {
    const devices = lines(devicesText).map(splitTerse);
    const connected = function (type) {
        return devices.find(function (d) {
            return d[1] === type && d[2] === "connected";
        });
    };
    const wifiDevice = devices.find(function (d) {
        return d[1] === "wifi";
    });

    const networks = parseWifiList(wifiText);
    const active = networks.find(function (n) {
        return n.active;
    });
    const result = {
        kind: "none",
        name: "",
        strength: 0,
        security: "",
        freq: "",
        ip: (ipText || "").trim().split("\n")[0].split("/")[0],
        wifiEnabled: (radioText || "").trim() === "enabled",
        wifiDevice: wifiDevice ? wifiDevice[0] : "",
        networks: networks
    };

    const ethernet = connected("ethernet");
    const wifi = connected("wifi");
    if (ethernet) {
        result.kind = "ethernet";
        result.name = ethernet[3] || "";
        result.strength = 100;
    } else if (wifi) {
        result.kind = "wifi";
        result.name = active ? active.ssid : (wifi[3] || "");
        result.strength = active ? active.signal : 0;
        result.security = active ? active.security : "";
        result.freq = active ? active.freq : "";
    }
    return result;
}
