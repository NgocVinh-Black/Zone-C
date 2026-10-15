import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../"
import "../../"
import "../../frost"

// Pin & nguồn: battery level, time left, health and cycles, the last 24 hours (UPower history),
// power profile, lid / power-button actions (logind drop-in via polkit), auto saver, charge limit.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    readonly property var dev: UPower.displayDevice
    readonly property bool hasBat: dev.ready && dev.isLaptopBattery
    readonly property int pct: hasBat ? Math.round(dev.percentage * 100) : 0
    readonly property bool charging: dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.FullyCharged || dev.state === UPowerDeviceState.PendingCharge
    function hm(s) { let h = Math.floor(s / 3600), m = Math.round(s % 3600 / 60); return h > 0 ? h + " giờ " + m + " phút" : m + " phút"; }
    property var sys: ({})            // cycles, limit, lid, key, bat
    property var hist: []             // 24 × { v, c }

    Process {
        id: probe
        running: true
        command: ["bash", "-c", "b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1); echo \"bat=${b##*/}\"; echo \"cycles=$(cat $b/cycle_count 2>/dev/null)\"; echo \"limit=$(cat $b/charge_control_end_threshold 2>/dev/null)\";"
            + "echo \"lid=$(busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager HandleLidSwitch 2>/dev/null | cut -d'\"' -f2)\";"
            + "echo \"key=$(busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager HandlePowerKey 2>/dev/null | cut -d'\"' -f2)\";"
            + "echo \"hist=$(busctl call org.freedesktop.UPower /org/freedesktop/UPower/devices/battery_${b##*/} org.freedesktop.UPower.Device GetHistory suu charge 86400 200 2>/dev/null)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let o = {};
                this.text.split("\n").forEach(l => { let i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1); });
                page.sys = o;
                let t = (o.hist || "").split(" ").slice(2).map(Number), pts = [];
                for (let i = 0; i + 2 < t.length; i += 3) pts.push({ t: t[i], v: t[i + 1], s: t[i + 2] });
                pts.sort((a, b) => a.t - b.t);
                let now = Date.now() / 1000, out = [];
                for (let h = 23; h >= 0; h--) {
                    let end = now - h * 3600, last = null;
                    for (const p of pts) if (p.t <= end && p.v > 0) last = p;
                    out.push(last ? { v: last.v, c: last.s === 1 || last.s === 4 } : { v: 0, c: false });
                }
                page.hist = out;
            }
        }
    }
    Process { id: act; onExited: probe.running = true }
    function logind(key, value) {
        act.command = ["pkexec", "bash", "-c", "f=/etc/systemd/logind.conf.d/50-zone-c.conf; mkdir -p /etc/systemd/logind.conf.d; touch $f; grep -q '^\\[Login\\]' $f || echo '[Login]' >> $f; sed -i \"/^$1=/d\" $f; echo \"$1=$2\" >> $f; systemctl kill -s HUP systemd-logind", "_", key, value];
        act.running = true;
    }

    Grp {
        width: parent.width
        Item {
            width: parent.width; height: 18 + 44 + 14 + 80 + 18
            Row {
                x: 20; y: 18
                width: parent.width - 40
                spacing: 16
                FText { text: page.hasBat ? page.pct + "%" : "AC"; px: 44; weight: Font.Light; anchors.bottom: parent.bottom }
                FText {
                    width: parent.width - 120 - 160 - 32; anchors.bottom: parent.bottom; anchors.bottomMargin: 6
                    text: !page.hasBat ? "Máy dùng nguồn điện trực tiếp" : page.dev.state === UPowerDeviceState.FullyCharged ? "Đã sạc đầy" : page.dev.state === UPowerDeviceState.PendingCharge ? "Đã cắm sạc · tạm ngừng sạc" : page.charging ? (page.dev.timeToFull > 0 ? "Đang sạc · đầy sau khoảng " + page.hm(page.dev.timeToFull) : "Đang sạc")
                          : "Đang dùng pin" + (page.dev.timeToEmpty > 0 ? " · còn khoảng " + page.hm(page.dev.timeToEmpty) : "")
                    px: 13.5; color: Fz.sub; wrapMode: Text.Wrap
                }
                Column {
                    width: 160; anchors.bottom: parent.bottom
                    FText { anchors.right: parent.right; textFormat: Text.StyledText; text: "Tình trạng pin <b><font color=\"" + Fz.tx + "\">" + (page.dev.healthSupported ? Math.round(page.dev.healthPercentage) + "%" : "–") + "</font></b>"; px: 12.5; color: Fz.sub }
                    FText { anchors.right: parent.right; text: page.sys.cycles ? page.sys.cycles + " chu kỳ" : ""; px: 12.5; color: Fz.sub }
                }
            }
            Row {
                x: 20; y: 18 + 44 + 14
                width: parent.width - 40; height: 80
                spacing: 4
                Repeater {
                    model: page.hist
                    delegate: Item {
                        required property var modelData
                        width: (parent.width - 23 * 4) / 24; height: 80
                        Rectangle {
                            anchors.bottom: parent.bottom; width: parent.width; radius: 3
                            height: Math.max(2, modelData.v / 100 * 80)
                            color: modelData.c ? Fz.glow : Fz.acc; opacity: modelData.c ? 1 : 0.85
                        }
                    }
                }
            }
        }
    }

    H3 { text: "Chế độ nguồn" }
    Grp {
        width: parent.width
        SRow {
            title: "Cấu hình hiệu năng"; sub: "power-profiles-daemon"
            FSeg {
                readonly property var values: [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
                options: PowerProfiles.hasPerformanceProfile ? ["Tiết kiệm", "Cân bằng", "Hiệu năng"] : ["Tiết kiệm", "Cân bằng"]
                current: Math.max(0, values.indexOf(PowerProfiles.profile))
                onPicked: (i) => PowerProfiles.profile = values[i]
            }
        }
    }

    H3 { text: "Tiết kiệm năng lượng" }
    Grp {
        width: parent.width
        SRow {
            title: "Khi gập máy"
            FSelect {
                options: ["Ngủ", "Ngủ đông", "Không làm gì"]
                readonly property var values: ["suspend", "hibernate", "ignore"]
                current: Math.max(0, values.indexOf(page.sys.lid || "suspend"))
                onPicked: (i) => page.logind("HandleLidSwitch", values[i])
            }
        }
        SRow {
            title: "Nút nguồn"
            FSelect {
                options: ["Hiện menu nguồn", "Ngủ", "Tắt máy"]
                readonly property var values: ["ignore", "suspend", "poweroff"]
                current: Math.max(0, values.indexOf(page.sys.key || "poweroff"))
                onPicked: (i) => page.logind("HandlePowerKey", values[i])
            }
        }
        SRow { title: "Tự tiết kiệm pin dưới 20%"; CfgToggle { key: "power.autoSaver"; def: true } }
        SRow {
            title: "Giới hạn sạc 80%"; sub: page.sys.limit ? "Kéo dài tuổi thọ pin · hiện " + page.sys.limit + "%" : "Máy không hỗ trợ giới hạn sạc"
            FToggle {
                enabled: !!page.sys.limit; opacity: enabled ? 1 : 0.5
                on: page.sys.limit !== undefined && Number(page.sys.limit) <= 80
                onToggled: (v) => { act.command = ["pkexec", "bash", "-c", "echo $1 > /sys/class/power_supply/$2/charge_control_end_threshold", "_", v ? "80" : "100", page.sys.bat]; act.running = true; }
            }
        }
    }
    Item { width: 1; height: 10 }
    Row {
        spacing: 4
        FText { text: "Thời gian chờ màn hình và ngủ được đặt trong"; px: 13.5; color: Fz.sub }
        FText { text: "Chờ & khóa"; px: 13.5; color: Fz.glow; font.underline: true
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.app.page = "idle" } }
        FText { text: "."; px: 13.5; color: Fz.sub }
    }
}
