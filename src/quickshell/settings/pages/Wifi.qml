import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "../"
import "../../"
import "../../frost"

// Wi-Fi: radio, the network in use, available networks (the password is asked in network/WifiDialog.qml), hidden networks,
// auto-join for the current network, MAC randomisation and a hotspot (NetworkManager).
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    readonly property var dev: { let ds = Networking.devices ? (Networking.devices.values || []) : []; return ds.find(d => d && d.type === DeviceType.Wifi) || null; }
    readonly property var nets: dev && dev.networks ? (dev.networks.values || []) : []
    readonly property var current: nets.find(n => n && n.connected) || null
    readonly property var others: nets.filter(n => n && !n.connected && n.name).sort((a, b) => (b.signalStrength || 0) - (a.signalStrength || 0)).slice(0, 12)
    property var info: ({})               // ip, rate, freq, autoconnect, mac, hotspot
    property bool hiddenOpen: false
    function sec(n) { return ({ 0: Fz.tr("Mạng mở"), 1: "WEP", 2: "WPA", 3: "WPA2", 4: "WPA3", 5: "WPA2/WPA3", 6: "WPA2-Enterprise", 7: "OWE" })[n ? n.security : 0] || ""; }
    function strength(n) { let s = n ? (n.signalStrength || 0) : 0; return s > 1 ? s / 100 : s; }

    Process {
        id: probe
        running: true
        command: ["bash", "-c", "d=$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2==\"wifi\"{print $1; exit}'); c=$(nmcli -t -g GENERAL.CONNECTION device show \"$d\" 2>/dev/null);"
            + "echo \"ip=$(nmcli -t -g IP4.ADDRESS device show \"$d\" 2>/dev/null | head -1 | cut -d/ -f1)\";"
            + "nmcli -t -f ACTIVE,FREQ,RATE dev wifi list ifname \"$d\" --rescan no 2>/dev/null | awk -F: '$1==\"yes\"{print \"freq=\"$2; print \"rate=\"$3}';"
            + "[ -n \"$c\" ] && echo \"auto=$(nmcli -t -g connection.autoconnect connection show \"$c\")\" && echo \"mac=$(nmcli -t -g 802-11-wireless.cloned-mac-address connection show \"$c\")\";"
            + "echo \"hotspot=$(nmcli -t -f NAME,TYPE connection show --active | grep -c '^Hotspot')\"; echo \"conn=$c\""]
        stdout: StdioCollector { onStreamFinished: { let o = {}; this.text.split("\n").forEach(l => { let i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1); }); page.info = o; } }
    }
    Timer { interval: 5000; repeat: true; running: true; onTriggered: probe.running = true }
    Process { id: nm; onExited: probe.running = true }
    function run(args) { nm.command = ["nmcli"].concat(args); nm.running = true; }

    Grp {
        width: parent.width
        SRow {
            icon: "s-wifi"; iconOn: Networking.wifiEnabled; title: "Wi-Fi"
            sub: !Networking.wifiEnabled ? Fz.tr("Đang tắt") : page.current ? Fz.tr("Đã kết nối với ") + page.current.name : Fz.tr("Chưa kết nối")
            FToggle { on: Networking.wifiEnabled; onToggled: (v) => Networking.wifiEnabled = v }
        }
    }

    H3 { visible: page.current !== null; text: Fz.tr("Đang dùng") }
    Grp {
        visible: page.current !== null
        width: parent.width
        SRow {
            title: page.current ? page.current.name : ""
            sub: [page.sec(page.current), page.info.freq ? (parseInt(page.info.freq) >= 4900 ? "5 GHz" : "2.4 GHz") : "", page.info.rate ? page.info.rate.replace(" Mbit/s", " Mb/s") : "", page.info.ip || ""].filter(x => x).join(" · ")
            FIcon { name: "s-wifi"; color: Fz.acc; anchors.verticalCenter: parent.verticalCenter }
            FChip { kind: "ok"; text: Fz.tr("Đã kết nối"); anchors.verticalCenter: parent.verticalCenter }
            FBtn { text: Fz.tr("Ngắt"); onClicked: page.current.disconnect() }
        }
    }

    H3 { visible: Networking.wifiEnabled; text: Fz.tr("Mạng khả dụng") }
    Grp {
        visible: Networking.wifiEnabled
        width: parent.width
        Repeater {
            model: page.others
            delegate: Column {
                id: nr
                required property var modelData
                readonly property bool locked: modelData.security > 0 && modelData.security !== 7 && !modelData.known
                width: parent.width
                SRow {
                    title: nr.modelData.name; sub: page.sec(nr.modelData) + (nr.modelData.known ? Fz.tr(" · đã lưu") : "")
                    FIcon { name: "s-wifi"; color: Fz.acc; opacity: 0.4 + 0.6 * page.strength(nr.modelData); anchors.verticalCenter: parent.verticalCenter }
                    FBtn { text: Fz.tr("Kết nối"); onClicked: { if (nr.locked) Fz.askWifi(nr.modelData); else nr.modelData.connect(); } }
                }
            }
        }
        Column {
            width: parent.width
            Item {
                width: parent.width; height: hidRow.height
                SRow {
                    id: hidRow
                    icon: "s-plus"; title: Fz.tr("Kết nối mạng ẩn…")
                    FIcon { name: "s-chev"; color: Fz.sub; rotation: page.hiddenOpen ? 90 : 0; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.hiddenOpen = !page.hiddenOpen }
            }
            Row {
                visible: page.hiddenOpen
                x: 16; spacing: 8; bottomPadding: 12
                FInput { id: hidSsid; width: 200; height: 36; placeholder: Fz.tr("Tên mạng (SSID)") }
                FInput { id: hidPw; width: 200; height: 36; password: true; placeholder: Fz.tr("Mật khẩu (nếu có)") }
                FBtn { kind: "pri"; text: Fz.tr("Kết nối"); onClicked: { page.run(["device", "wifi", "connect", hidSsid.text, "hidden", "yes"].concat(hidPw.text ? ["password", hidPw.text] : [])); page.hiddenOpen = false; } }
            }
        }
    }

    H3 { text: Fz.tr("Tùy chọn") }
    Grp {
        width: parent.width
        SRow {
            title: Fz.tr("Tự kết nối mạng đã biết"); sub: page.info.conn ? Fz.tr("Áp dụng cho ") + page.info.conn : ""
            FToggle { on: page.info.auto !== "no"; onToggled: (v) => { if (page.info.conn) page.run(["connection", "modify", page.info.conn, "connection.autoconnect", v ? "yes" : "no"]); } }
        }
        SRow {
            title: Fz.tr("Địa chỉ MAC ngẫu nhiên")
            FSelect {
                options: [Fz.tr("Riêng cho từng mạng"), Fz.tr("Đổi mỗi lần kết nối"), Fz.tr("Dùng MAC thật")]
                readonly property var values: ["stable", "random", "permanent"]
                current: Math.max(0, values.indexOf(page.info.mac || "permanent"))
                onPicked: (i) => { if (page.info.conn) page.run(["connection", "modify", page.info.conn, "802-11-wireless.cloned-mac-address", values[i]]); }
            }
        }
        SRow {
            title: Fz.tr("Điểm phát sóng"); sub: "“zone-c-hotspot”"
            FToggle {
                on: page.info.hotspot === "1"
                onToggled: (v) => page.run(v ? ["device", "wifi", "hotspot", "ssid", "zone-c-hotspot", "password", "zonec-" + Quickshell.env("USER")] : ["connection", "down", "Hotspot"])
            }
        }
    }
}
