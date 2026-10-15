import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import "../"
import "../frost"

// Wi-Fi / Bluetooth panel of the Frost design (Network.dc.html, Bluetooth.dc.html).
Item {
    id: root
    focus: true

    property string activeMode: "wifi"
    function gotoTab(t) { activeMode = (t === "bt") ? "bt" : "wifi"; }
    readonly property bool isWifi: activeMode !== "bt"

    // Main.qml sizes the popup to the content
    readonly property real fitHeight: panelCol.implicitHeight + 28

    // ---------- Wi-Fi ----------
    readonly property var wifiDev: {
        let ds = Networking.devices ? (Networking.devices.values || []) : [];
        for (let i = 0; i < ds.length; i++) if (ds[i] && ds[i].type === DeviceType.Wifi) return ds[i];
        return null;
    }
    readonly property var nets: wifiDev && wifiDev.networks ? (wifiDev.networks.values || []) : []
    readonly property var current: nets.find(n => n && n.connected) || null
    readonly property var others: nets.filter(n => n && !n.connected && n.name).sort((a, b) => (b.signalStrength || 0) - (a.signalStrength || 0))
    property string openNet: ""
    property var meta: ({})          // ssid -> { freq, sec }
    property string ip: ""
    property real rx: 0
    property real tx: 0
    property int ping: -1

    function secName(n) {
        let s = n ? n.security : 0;
        return ({ 1: "WEP", 2: "WPA", 3: "WPA2", 4: "WPA3", 5: "WPA2/WPA3", 6: "WPA2-Enterprise", 7: "OWE" })[s] || "";
    }
    function band(ssid) {
        let m = meta[ssid];
        if (!m || !m.freq) return "";
        let f = parseInt(m.freq);
        return f >= 5900 ? "6 GHz" : f >= 4900 ? "5 GHz" : "2.4 GHz";
    }
    function bars(n) { let s = n ? (n.signalStrength || 0) : 0; if (s > 1) s /= 100; return s >= 0.75 ? 4 : s >= 0.5 ? 3 : s >= 0.25 ? 2 : 1; }
    function connect(n, pw) { if (pw) n.connectWithPsk(pw); else n.connect(); openNet = ""; }

    Process {
        id: scanMeta
        command: ["bash", "-c", "nmcli -t -f SSID,FREQ,SECURITY dev wifi list 2>/dev/null; echo ---; nmcli -g IP4.ADDRESS dev show " + (root.wifiDev ? root.wifiDev.name : "wlan0") + " 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.split("---"), m = {};
                parts[0].trim().split("\n").forEach(l => {
                    let c = l.replace(/\\:/g, "\u0001").split(":").map(x => x.replace(/\u0001/g, ":"));
                    if (c[0] && !m[c[0]]) m[c[0]] = { freq: c[1], sec: c[2] };
                });
                root.meta = m;
                root.ip = (parts[1] || "").trim().replace(/\/\d+$/, "");
            }
        }
    }
    Process {
        id: speed
        property real lastRx: 0
        property real lastTx: 0
        property real lastT: 0
        command: ["bash", "-c", "d=/sys/class/net/" + (root.wifiDev ? root.wifiDev.name : "wlan0") + "/statistics; echo $(cat $d/rx_bytes) $(cat $d/tx_bytes)"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = this.text.trim().split(" ").map(Number), t = Date.now();
                if (speed.lastT > 0 && p.length === 2) {
                    let dt = (t - speed.lastT) / 1000;
                    root.rx = Math.max(0, (p[0] - speed.lastRx) * 8 / 1e6 / dt);
                    root.tx = Math.max(0, (p[1] - speed.lastTx) * 8 / 1e6 / dt);
                }
                speed.lastRx = p[0]; speed.lastTx = p[1]; speed.lastT = t;
            }
        }
    }
    Process {
        id: pinger
        command: ["bash", "-c", "ping -c1 -W1 1.1.1.1 2>/dev/null | sed -n 's/.*time=\\([0-9.]*\\).*/\\1/p'"]
        stdout: StdioCollector { onStreamFinished: { let v = parseFloat(this.text); root.ping = isNaN(v) ? -1 : Math.round(v); } }
    }
    Timer {
        interval: 1000; repeat: true; triggeredOnStart: true
        running: root.visible && root.isWifi && root.current !== null
        onTriggered: { speed.running = true; if (!pinger.running) pinger.running = true; }
    }
    onVisibleChanged: if (visible) { scanMeta.running = true; if (wifiDev) wifiDev.scannerEnabled = true; }
    Component.onCompleted: scanMeta.running = true

    // ---------- Bluetooth ----------
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btDevs: adapter && adapter.devices ? (adapter.devices.values || []) : []
    readonly property var paired: btDevs.filter(d => d.paired || d.bonded)
    // devices that only advertise their address (shown as "76-CB-92-…") are left out, like the design's list
    readonly property var nearby: btDevs.filter(d => !d.paired && !d.bonded && d.name && !/^([0-9A-F]{2}[-:]){5}[0-9A-F]{2}$/i.test(d.name))
    Binding { target: root.adapter; property: "discovering"; value: root.visible && !root.isWifi && root.adapter && root.adapter.enabled; when: root.adapter !== null }
    function btIcon(d) {
        let i = (d.icon || "").toLowerCase();
        if (i.indexOf("headset") !== -1 || i.indexOf("headphone") !== -1) return "n-head";
        if (i.indexOf("mouse") !== -1) return "n-mouse";
        if (i.indexOf("keyboard") !== -1) return "n-kbd";
        if (i.indexOf("phone") !== -1) return "n-phone";
        if (i.indexOf("audio") !== -1 || i.indexOf("speaker") !== -1) return "n-spk";
        return "n-bt";
    }
    function btKind(d) {
        return ({ "n-head": "Tai nghe", "n-mouse": "Chuột", "n-kbd": "Bàn phím", "n-phone": "Điện thoại", "n-spk": "Loa" })[btIcon(d)] || "Thiết bị";
    }

    Glass {
        anchors.fill: parent
        radius: 24

        Column {
            id: panelCol
            x: 14; y: 14
            width: parent.width - 28
            spacing: 12

            FSeg {
                width: parent.width
                btnWidth: (parent.width - 6 - 2) / 2
                options: [{ label: "Wi-Fi", icon: "n-wifi" }, { label: "Bluetooth", icon: "n-bt" }]
                current: root.isWifi ? 0 : 1
                onPicked: (i) => root.activeMode = i === 0 ? "wifi" : "bt"
            }

            // ======== Wi-Fi ========
            Item {
                visible: root.isWifi
                width: parent.width; height: 40
                Lbl { x: 4; width: parent.width - 4 - 36 - 44 - 24; anchors.verticalCenter: parent.verticalCenter
                      title: "Wi-Fi"; sub: (root.wifiDev ? root.wifiDev.name : "wlan0") + " · NetworkManager" }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    FIconBtn { ghost: true; icon: "n-refresh"; label: "Quét lại"; anchors.verticalCenter: parent.verticalCenter
                        onClicked: { if (root.wifiDev) { root.wifiDev.scannerEnabled = false; root.wifiDev.scannerEnabled = true; } scanMeta.running = true; } }
                    FToggle { on: Networking.wifiEnabled; onToggled: (v) => Networking.wifiEnabled = v; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            Rectangle {
                visible: root.isWifi && root.current !== null
                width: parent.width
                height: curCol.implicitHeight + 28
                radius: 18
                color: Fz.acc
                Column {
                    id: curCol
                    x: 16; y: 14
                    width: parent.width - 32
                    spacing: 10
                    Item {
                        width: parent.width; height: 36
                        Row {
                            spacing: 12
                            anchors.verticalCenter: parent.verticalCenter
                            FIcon { name: "n-wifi"; size: 22; color: Fz.ink; anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                FText { text: root.current ? root.current.name : ""; px: 15; weight: Font.Bold; color: Fz.ink }
                                FText {
                                    text: ["Đã kết nối", root.secName(root.current), root.current ? root.band(root.current.name) : "", root.ip].filter(s => s !== "").join(" · ")
                                    px: 12; weight: Font.Medium; color: Fz.ink; opacity: 0.75
                                }
                            }
                        }
                        Rectangle {
                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            width: discT.implicitWidth + 28; height: 30; radius: 11
                            color: Fz.surf(discMouse.containsMouse ? 0.2 : 0.1)
                            border.width: 1; border.color: Fz.surf(0.18)
                            FText { id: discT; anchors.centerIn: parent; text: "Ngắt"; px: 12; weight: Font.Medium; color: Fz.ink }
                            MouseArea { id: discMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.current) root.current.disconnect() }
                        }
                    }
                    Row {
                        spacing: 16
                        Row { spacing: 4; FIcon { name: "n-down"; size: 13; color: Fz.ink; anchors.verticalCenter: parent.verticalCenter }
                              FText { mono: true; text: root.rx.toFixed(1) + " Mb/s"; px: 12.5; weight: Font.Medium; color: Fz.ink } }
                        Row { spacing: 4; FIcon { name: "n-up"; size: 13; color: Fz.ink; anchors.verticalCenter: parent.verticalCenter }
                              FText { mono: true; text: root.tx.toFixed(1) + " Mb/s"; px: 12.5; weight: Font.Medium; color: Fz.ink } }
                        FText { mono: true; text: "ping " + (root.ping >= 0 ? root.ping + " ms" : "--"); px: 12.5; weight: Font.Medium; color: Fz.ink }
                    }
                }
            }

            Caps { visible: root.isWifi && Networking.wifiEnabled && root.others.length > 0; px: 11; leftPadding: 4; topPadding: 4; text: "Mạng khả dụng" }
            EmptyState {
                visible: root.isWifi && (!Networking.wifiEnabled || (root.others.length === 0 && root.current === null))
                width: parent.width
                icon: "x-wifioff"; iconColor: Fz.red; iconBg: Fz.redA(0.12)
                title: Networking.wifiEnabled ? "Không tìm thấy mạng nào" : "Wi-Fi đang tắt"
                message: Networking.wifiEnabled ? "Không có mạng Wi-Fi trong vùng phủ sóng. Thử lại hoặc cắm cáp Ethernet." : "Bật Wi-Fi để tìm mạng gần đây."
                button: Networking.wifiEnabled ? "Quét lại" : "Bật Wi-Fi"
                onClicked: { if (!Networking.wifiEnabled) Networking.wifiEnabled = true; else if (root.wifiDev) root.wifiDev.scannerEnabled = true; }
            }

            Column {
                visible: root.isWifi && Networking.wifiEnabled
                width: parent.width
                spacing: 2
                Repeater {
                    model: root.others.slice(0, 6)
                    delegate: Column {
                        id: netRow
                        required property var modelData
                        readonly property bool open: root.openNet === modelData.name
                        readonly property bool locked: modelData.security > 0 && modelData.security !== 7
                        width: parent.width
                        Rectangle {
                            width: parent.width
                            height: 60
                            radius: 14
                            color: netRow.open ? Fz.fg(0.07) : (nwMouse.containsMouse ? Fz.fg(0.06) : "transparent")
                            Row {
                                x: 12; anchors.verticalCenter: parent.verticalCenter
                                spacing: 12
                                Row {
                                    spacing: 2; height: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                    Repeater {
                                        model: 4
                                        delegate: Rectangle {
                                            required property int index
                                            width: 4; radius: 1
                                            height: 16 * (index + 1) / 4
                                            anchors.bottom: parent.bottom
                                            color: index < root.bars(netRow.modelData) ? Fz.acc : Fz.fg(0.18)
                                        }
                                    }
                                }
                                Lbl {
                                    width: netRow.width - 24 - 18 - 12 - 26
                                    anchors.verticalCenter: parent.verticalCenter
                                    title: netRow.modelData.name
                                    sub: [netRow.locked ? root.secName(netRow.modelData) : "Mạng mở", root.band(netRow.modelData.name)].filter(s => s !== "").join(" · ") + (netRow.modelData.known ? " · Đã lưu" : "")
                                }
                                FIcon { visible: netRow.locked; name: "n-lock"; size: 14; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea {
                                id: nwMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!netRow.locked || netRow.modelData.known) { root.connect(netRow.modelData, ""); return; }
                                    root.openNet = netRow.open ? "" : netRow.modelData.name;
                                }
                            }
                        }
                        Row {
                            visible: netRow.open
                            x: 12
                            width: parent.width - 24
                            topPadding: 4; bottomPadding: 10
                            spacing: 8
                            FInput { id: pw; width: parent.width - 8 - connectBtn.width; height: 36; password: true; placeholder: "Mật khẩu"
                                onAccepted: root.connect(netRow.modelData, text) }
                            FBtn { id: connectBtn; kind: "pri"; text: "Kết nối"; onClicked: root.connect(netRow.modelData, pw.text) }
                        }
                    }
                }
            }

            // ======== Bluetooth ========
            EmptyState {
                visible: !root.isWifi && root.adapter === null
                width: parent.width
                icon: "x-btoff"
                title: "Không tìm thấy bộ điều hợp Bluetooth"
                message: "Máy chưa có USB Bluetooth hoặc thiết bị đang bị chặn bởi rfkill."
                code: "rfkill unblock bluetooth"
                button: "Khởi động lại bluetooth.service"; buttonPrimary: false
                onClicked: Quickshell.execDetached(["bash", "-c", "rfkill unblock bluetooth; systemctl restart bluetooth.service"])
            }
            Item {
                visible: !root.isWifi && root.adapter !== null
                width: parent.width; height: 40
                Lbl { x: 4; width: parent.width - 60; anchors.verticalCenter: parent.verticalCenter
                      title: "Bluetooth"; sub: "Hiển thị với tên “" + (root.adapter ? (root.adapter.name || SystemInfo.hostname) : SystemInfo.hostname) + "”" }
                FToggle { anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter
                          on: root.adapter ? root.adapter.enabled : false; onToggled: (v) => { if (root.adapter) root.adapter.enabled = v; } }
            }
            Caps { visible: !root.isWifi && root.paired.length > 0; px: 11; leftPadding: 4; topPadding: 4; text: "Đã ghép nối" }
            Grp {
                visible: !root.isWifi && root.paired.length > 0
                width: parent.width
                Repeater {
                    model: root.paired
                    delegate: GRow {
                        id: br
                        required property var modelData
                        readonly property int bat: modelData.batteryAvailable ? Math.round(modelData.battery * 100) : -1
                        Ico { icon: root.btIcon(br.modelData); on: br.modelData.connected; anchors.verticalCenter: parent.verticalCenter }
                        Lbl {
                            width: br.width - 32 - 36 - 28 - 76
                            anchors.verticalCenter: parent.verticalCenter
                            title: br.modelData.name || br.modelData.address
                            sub: br.modelData.state === BluetoothDeviceState.Connecting ? "Đang kết nối…" : (br.modelData.connected ? "Đã kết nối" : "Chưa kết nối")
                        }
                        Item {
                            width: 76; height: 30
                            anchors.verticalCenter: parent.verticalCenter
                            FChip { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; visible: br.modelData.connected && br.bat >= 0
                                    text: br.bat + "%"; kind: br.bat >= 60 ? "ok" : (br.bat >= 20 ? "warn" : "bad") }
                            FBtn { anchors.right: parent.right; visible: !br.modelData.connected || br.bat < 0; height: 30; fontSize: 12; padX: 12
                                   text: br.modelData.connected ? "Ngắt" : "Kết nối"
                                   onClicked: { br.modelData.trusted = true; if (br.modelData.connected) br.modelData.disconnect(); else br.modelData.connect(); } }
                        }
                    }
                }
            }
            Item {
                visible: !root.isWifi
                width: parent.width; height: 20
                Caps { x: 4; px: 11; anchors.bottom: parent.bottom; text: "Thiết bị lân cận" }
                FText { anchors.right: parent.right; anchors.rightMargin: 4; anchors.bottom: parent.bottom
                        text: root.adapter && root.adapter.discovering ? "Đang quét…" : ""; px: 12; color: Fz.sub }
            }
            Grp {
                visible: !root.isWifi && root.nearby.length > 0
                width: parent.width
                Repeater {
                    model: root.nearby.slice(0, 5)
                    delegate: GRow {
                        id: nr
                        required property var modelData
                        Ico { icon: root.btIcon(nr.modelData); anchors.verticalCenter: parent.verticalCenter }
                        Lbl { width: nr.width - 32 - 36 - 28 - 86; anchors.verticalCenter: parent.verticalCenter; title: nr.modelData.name; sub: root.btKind(nr.modelData) }
                        FBtn { height: 30; fontSize: 12; padX: 12; kind: "pri"; text: nr.modelData.pairing ? "Đang ghép…" : "Ghép nối"; anchors.verticalCenter: parent.verticalCenter
                               onClicked: { nr.modelData.trusted = true; nr.modelData.pair(); } }
                    }
                }
            }
            FText {
                visible: !root.isWifi && root.nearby.length === 0
                leftPadding: 4
                text: root.adapter && root.adapter.enabled ? "Chưa tìm thấy thiết bị nào gần đây" : "Bật Bluetooth để tìm thiết bị"
                color: Fz.sub; px: 13
            }

            FBtn {
                width: parent.width
                icon: "n-gear"; iconSize: 15
                text: "Cài đặt mạng nâng cao"
                onClicked: Fz.open("guide", root.isWifi ? "wifi" : "bt")
            }
        }
    }
}
