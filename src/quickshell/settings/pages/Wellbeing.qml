import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../../"
import "../../frost"

// Sức khỏe số: screen time today and this week, most-used apps (focus daemon database), focus mode, eye breaks.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0
    property var stats: null

    Process {
        running: true
        command: ["python3", Caching.qsDir + "/guide/wellbeing/get_stats.py", "--db-dir", Caching.getStateDir("focustime")]
        stdout: StdioCollector { onStreamFinished: { try { page.stats = JSON.parse(this.text); } catch (e) {} } }
    }
    function dur(s) { let h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60); return h > 0 ? h + " giờ " + String(m).padStart(2, "0") + " phút" : m + " phút"; }
    readonly property var week: stats ? stats.week : []
    readonly property real weekMax: Math.max(3600, ...week.map(w => w.total))
    readonly property int total: stats ? stats.total : 0
    readonly property int yesterday: stats ? stats.yesterday : 0
    readonly property var dayVi: Fz.en ? ({ Mon: "Mon", Tue: "Tue", Wed: "Wed", Thu: "Thu", Fri: "Fri", Sat: "Sat", Sun: "Sun" }) : ({ Mon: "T2", Tue: "T3", Wed: "T4", Thu: "T5", Fri: "T6", Sat: "T7", Sun: "CN" })
    readonly property var topApps: stats ? stats.apps.slice(0, 4) : []

    Grp {
        width: parent.width
        Item {
            width: parent.width; height: 20 + 72 + 14 + 120 + 20
            Row {
                x: 20; y: 20
                spacing: 14
                Column {
                    FText { text: "Thời gian dùng hôm nay"; px: 13.5; color: Fz.sub }
                    FText { text: page.dur(page.total); px: 40; weight: Font.Light; font.letterSpacing: -1 }
                }
                FChip {
                    visible: page.yesterday > 0
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 10
                    readonly property int pct: Math.round((page.total - page.yesterday) / page.yesterday * 100)
                    kind: pct <= 0 ? "ok" : "warn"
                    text: (pct <= 0 ? "−" : "+") + Math.abs(pct) + "% so với hôm qua"
                }
            }
            Row {
                x: 20; y: 20 + 72 + 14
                width: parent.width - 40; height: 120
                spacing: 12
                Repeater {
                    model: page.week
                    delegate: Column {
                        required property var modelData
                        width: (parent.width - 72) / 7; height: 120
                        spacing: 6
                        Item {
                            width: parent.width; height: 120 - 6 - 15
                            Rectangle {
                                anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                                width: Math.min(38, parent.width); radius: 8
                                height: Math.max(4, modelData.total / page.weekMax * parent.height)
                                color: modelData.is_target ? Fz.acc : Fz.fg(0.16)
                            }
                        }
                        FText { anchors.horizontalCenter: parent.horizontalCenter; text: page.dayVi[modelData.day] || modelData.day; px: 11.5; color: Fz.sub }
                    }
                }
            }
        }
    }

    H3 { text: "Ứng dụng dùng nhiều" }
    Grp {
        width: parent.width
        Repeater {
            model: page.topApps
            delegate: Item {
                required property var modelData
                width: parent.width; height: 64
                Column {
                    x: 16; anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 32
                    spacing: 6
                    Item {
                        width: parent.width; height: 18
                        FText { text: modelData.name; px: 13.5; weight: Font.Medium }
                        FText { anchors.right: parent.right; text: page.dur(modelData.seconds); mono: true; px: 13.5; color: Fz.sub }
                    }
                    FBar { width: parent.width; value: Math.min(1, modelData.percent / 100 * 2.4) }
                }
            }
        }
        SRow { visible: page.topApps.length === 0; title: "Chưa có dữ liệu"; sub: "Thời gian dùng được ghi lại khi bạn làm việc" }
    }

    H3 { text: "Tập trung" }
    Grp {
        width: parent.width
        SRow { title: "Chế độ tập trung"; sub: "Bật Không làm phiền trong giờ làm"; CfgToggle { key: "wellbeing.focus" } }
        SRow { title: "Nhắc nghỉ mắt"; sub: "20-20-20"; CfgToggle { key: "wellbeing.eyes"; def: true } }
    }
}
