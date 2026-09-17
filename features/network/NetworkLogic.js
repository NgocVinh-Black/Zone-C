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

// devicesText: `nmcli -t -f TYPE,STATE,CONNECTION device status`
// wifiText:    `nmcli -t -f ACTIVE,SIGNAL,SSID device wifi list --rescan no`
// radioText:   `nmcli radio wifi`
function parseStatus(devicesText, wifiText, radioText) {
    const devices = lines(devicesText).map(splitTerse);
    const connected = function (type) {
        return devices.find(function (d) {
            return d[0] === type && d[1] === "connected";
        });
    };

    const wifiEnabled = (radioText || "").trim() === "enabled";
    const ethernet = connected("ethernet");
    if (ethernet)
        return { kind: "ethernet", name: ethernet[2] || "", strength: 100, wifiEnabled: wifiEnabled };

    const wifi = connected("wifi");
    if (wifi) {
        const active = lines(wifiText).map(splitTerse).find(function (w) {
            return w[0] === "yes";
        });
        return {
            kind: "wifi",
            name: active ? active[2] : (wifi[2] || ""),
            strength: active ? (parseInt(active[1], 10) || 0) : 0,
            wifiEnabled: wifiEnabled
        };
    }

    return { kind: "none", name: "", strength: 0, wifiEnabled: wifiEnabled };
}
