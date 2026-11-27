import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../../"
import "../../frost"

// Mạng & VPN: wired devices, VPN / WireGuard connections (toggle, import a .conf), DNS servers,
// DNS over TLS (needs systemd-resolved) and the desktop proxy mode (gsettings).
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    property var eth: []          // { dev, state, conn }
    property var vpns: []         // { name, type, active, ip }
    property var st: ({})         // conn, dns, auto, dot, resolved, proxy
    property bool adding: false
    property bool dnsEdit: false

    Process {
        id: probe
        running: true
        command: ["bash", "-c",
            "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device | awk -F: '$2==\"ethernet\"{print \"E\\t\"$1\"\\t\"$3\"\\t\"$4}';"
            + "nmcli -t -f NAME,TYPE,ACTIVE connection show | awk -F: '$2==\"wireguard\"||$2==\"vpn\"{print \"V\\t\"$1\"\\t\"$2\"\\t\"$3}';"
            + "c=$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2!=\"lo\" && $2!=\"\"{print $1; exit}'); echo \"S\\tconn\\t$c\";"
            + "[ -n \"$c\" ] && { echo \"S\\tdns\\t$(nmcli -t -g ipv4.dns connection show \"$c\")\"; echo \"S\\tauto\\t$(nmcli -t -g ipv4.ignore-auto-dns connection show \"$c\")\"; echo \"S\\tdot\\t$(nmcli -t -g connection.dns-over-tls connection show \"$c\")\";"
            + " echo \"S\\tcurdns\\t$(nmcli -t -g IP4.DNS connection show \"$c\" | tr '\\n' ' ')\"; };"
            + "echo \"S\\tresolved\\t$(systemctl is-active systemd-resolved 2>/dev/null)\";"
            + "command -v gsettings >/dev/null && echo \"S\\tproxy\\t$(gsettings get org.gnome.system.proxy mode 2>/dev/null | tr -d \"'\")\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let e = [], v = [], s = {};
                this.text.split("\n").forEach(l => {
                    let c = l.split("\t");
                    if (c[0] === "E") e.push({ dev: c[1], state: c[2], conn: c[3] });
                    else if (c[0] === "V") v.push({ name: c[1], type: c[2], active: c[3] === "yes" });
                    else if (c[0] === "S") s[c[1]] = c[2] || "";
                });
                page.eth = e; page.vpns = v; page.st = s;
            }
        }
    }
    Process { id: run; onExited: probe.running = true }
    function nm(args) { run.command = ["nmcli"].concat(args); run.running = true; }

    H3 { first: true; text: Fz.tr("Có dây") }
    Grp {
        width: parent.width
        Repeater {
            model: page.eth
            delegate: SRow {
                required property var modelData
                readonly property bool up: modelData.state === "connected"
                icon: "s-eth"; title: "Ethernet (" + modelData.dev + ")"
                sub: up ? Fz.tr("Đã kết nối · ") + modelData.conn : modelData.state === "unavailable" ? Fz.tr("Chưa cắm cáp") : Fz.tr("Ngắt")
                FChip { kind: up ? "ok" : ""; text: up ? Fz.tr("Đã kết nối") : Fz.tr("Ngắt"); anchors.verticalCenter: parent.verticalCenter }
            }
        }
        SRow { visible: page.eth.length === 0; icon: "s-eth"; title: Fz.tr("Không có cổng Ethernet") }
    }

    H3 { text: "VPN" }
    Grp {
        width: parent.width
        Repeater {
            model: page.vpns
            delegate: SRow {
                required property var modelData
                icon: "s-lock"; title: modelData.name; sub: (modelData.type === "wireguard" ? "WireGuard" : "VPN") + (modelData.active ? Fz.tr(" · đang bật") : "")
                FToggle { on: modelData.active; onToggled: (v) => page.nm(["connection", v ? "up" : "down", modelData.name]) }
            }
        }
        Column {
            width: parent.width
            SRow {
                title: Fz.tr("Thêm VPN…"); sub: Fz.tr("WireGuard, OpenVPN, nhập .conf")
                FBtn { icon: "s-plus"; iconSize: 14; text: Fz.tr("Thêm"); onClicked: page.adding = !page.adding }
            }
            Row {
                visible: page.adding
                x: 16; spacing: 8; bottomPadding: 12
                FInput { id: confPath; width: 320; height: 36; placeholder: Fz.tr("Đường dẫn tệp .conf hoặc .ovpn") }
                FBtn {
                    kind: "pri"; text: Fz.tr("Nhập")
                    onClicked: {
                        let p = confPath.text.trim().replace(/^~/, Quickshell.env("HOME"));
                        if (p) page.nm(["connection", "import", "type", p.endsWith(".ovpn") ? "openvpn" : "wireguard", "file", p]);
                        page.adding = false;
                    }
                }
            }
        }
    }

    H3 { text: "DNS & Proxy" }
    Grp {
        width: parent.width
        Column {
            width: parent.width
            SRow {
                title: Fz.tr("Máy chủ DNS"); subMono: true
                sub: (page.st.dns || page.st.curdns || "").replace(/,/g, ", ").trim() || Fz.tr("Tự động")
                FSelect {
                    options: [Fz.tr("Tự động (DHCP)"), Fz.tr("Tùy chỉnh")]
                    current: page.st.auto === "yes" ? 1 : 0
                    onPicked: (i) => {
                        if (!page.st.conn) return;
                        if (i === 0) { run.command = ["bash", "-c", "nmcli connection modify \"$1\" ipv4.ignore-auto-dns no ipv4.dns '' && nmcli connection up \"$1\"", "_", page.st.conn]; run.running = true; }
                        else page.dnsEdit = true;
                    }
                }
            }
            Row {
                visible: page.dnsEdit
                x: 16; spacing: 8; bottomPadding: 12
                FInput { id: dnsField; width: 260; height: 36; text: "1.1.1.1, 9.9.9.9"; placeholder: "1.1.1.1, 9.9.9.9" }
                FBtn {
                    kind: "pri"; text: Fz.tr("Áp dụng")
                    onClicked: {
                        let servers = dnsField.text.split(/[ ,]+/).filter(x => x).join(" ");
                        run.command = ["bash", "-c", "nmcli connection modify \"$1\" ipv4.ignore-auto-dns yes ipv4.dns \"$2\" && nmcli connection up \"$1\"", "_", page.st.conn, servers];
                        run.running = true; page.dnsEdit = false;
                    }
                }
            }
        }
        SRow {
            title: "DNS over TLS"; sub: page.st.resolved === "active" ? "systemd-resolved" : Fz.tr("Cần bật systemd-resolved")
            FToggle {
                enabled: page.st.resolved === "active"; opacity: enabled ? 1 : 0.5
                on: page.st.dot === "2" || page.st.dot === "yes"
                onToggled: (v) => { if (!page.st.conn) return; run.command = ["bash", "-c", "nmcli connection modify \"$1\" connection.dns-over-tls \"$2\" && nmcli connection up \"$1\"", "_", page.st.conn, v ? "2" : "0"]; run.running = true; }
            }
        }
        SRow {
            title: "Proxy"
            FSelect {
                options: [Fz.tr("Không dùng"), Fz.tr("Thủ công"), Fz.tr("Tự động (PAC)")]
                readonly property var values: ["none", "manual", "auto"]
                current: Math.max(0, values.indexOf(page.st.proxy || "none"))
                onPicked: (i) => { run.command = ["gsettings", "set", "org.gnome.system.proxy", "mode", values[i]]; run.running = true; }
            }
        }
    }
}
