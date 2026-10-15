import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../../"
import "../../frost"

// Ngày & giờ: live clock, NTP and time zone (timedatectl, polkit asks when needed), 24-hour format
// and the first day of the week.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    property var d: ({})
    property var zones: []
    Process {
        id: probe
        running: true
        command: ["bash", "-c", "timedatectl show 2>/dev/null; echo '#'; timedatectl list-timezones 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = this.text.split("#\n"), o = {};
                p[0].split("\n").forEach(l => { let i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1); });
                page.d = o;
                page.zones = (p[1] || "").trim().split("\n").filter(z => z);
            }
        }
    }
    Process { id: run; onExited: probe.running = true }
    readonly property string zone: d.Timezone || "UTC"
    readonly property string offset: { let m = -new Date().getTimezoneOffset(); return "GMT" + (m >= 0 ? "+" : "−") + Math.floor(Math.abs(m) / 60) + (Math.abs(m) % 60 ? ":" + String(Math.abs(m) % 60).padStart(2, "0") : ""); }
    readonly property bool h24: !DateTime.is12Hour
    // the zone list is long: show the current one, the common ones, then the rest
    readonly property var zoneList: { let top = [zone, "Asia/Ho_Chi_Minh", "Asia/Bangkok", "Asia/Tokyo", "Asia/Singapore", "Europe/London", "Europe/Berlin", "America/New_York", "America/Los_Angeles", "UTC"]; let seen = {}; return top.concat(zones).filter(z => !seen[z] && (seen[z] = true)); }

    Grp {
        width: parent.width
        Row {
            x: 20; topPadding: 20; bottomPadding: 20
            spacing: 20
            FText { text: Qt.formatDateTime(DateTime.now, page.h24 ? "HH:mm:ss" : "hh:mm:ss AP"); mono: true; px: 46; font.letterSpacing: -1.5; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                FText { text: Fz.dateLong(DateTime.now) + ", " + DateTime.now.getFullYear(); px: 15; weight: Font.Medium }
                FText { text: page.zone + " · " + page.offset; px: 13; color: Fz.sub }
            }
        }
    }

    H3 { text: Fz.tr("Đồng bộ") }
    Grp {
        width: parent.width
        SRow {
            title: Fz.tr("Tự động đặt giờ"); sub: "systemd-timesyncd" + (page.d.NTPSynchronized === "yes" ? Fz.tr(" · đã đồng bộ") : "")
            FToggle { on: page.d.NTP === "yes"; onToggled: (v) => { run.command = ["timedatectl", "set-ntp", v ? "true" : "false"]; run.running = true; } }
        }
        SRow {
            title: Fz.tr("Múi giờ")
            FSelect {
                width: 260
                options: page.zoneList.map(z => z === page.zone ? z + " (" + page.offset + ")" : z)
                current: 0
                onPicked: (i) => { run.command = ["timedatectl", "set-timezone", page.zoneList[i]]; run.running = true; }
            }
        }
    }

    H3 { text: Fz.tr("Hiển thị") }
    Grp {
        width: parent.width
        SRow {
            title: Fz.tr("Định dạng 24 giờ")
            FToggle {
                on: page.h24
                onToggled: (v) => {
                    let f = Config.getSetting("bar.time.format", "HH:mm:ss");
                    f = v ? f.replace(/hh?/g, "HH").replace(/\s*[aA][pP]/, "") : f.replace(/HH?/g, "hh") + (/[aA][pP]/.test(f) ? "" : " AP");
                    Config.setSetting("bar.time.format", f);
                }
            }
        }
        SRow { title: Fz.tr("Tuần bắt đầu vào"); CfgSelect { key: "datetime.weekStart"; def: 1; options: [Fz.tr("Thứ Hai"), Fz.tr("Chủ Nhật")]; values: [1, 0] } }
    }
}
