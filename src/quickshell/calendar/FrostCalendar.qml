import QtQuick
import "../"
import "../frost"

// Calendar and weather panel of the Frost design (Calendar.dc.html).
Item {
    id: root
    focus: true

    // ---------- calendar ----------
    property date shown: new Date(DateTime.now.getFullYear(), DateTime.now.getMonth(), 1)
    property date selected: DateTime.now
    property bool adding: false
    readonly property int weekStart: Number(Config.getSetting("datetime.weekStart", 1)) === 0 ? 0 : 1
    readonly property var cells: {
        let first = new Date(shown.getFullYear(), shown.getMonth(), 1);
        let lead = (first.getDay() + 7 - weekStart) % 7;   // Settings → Ngày & giờ: Monday (T2) or Sunday (CN)
        let out = [];
        for (let i = lead; i > 0; i--) out.push({ d: new Date(first.getFullYear(), first.getMonth(), 1 - i), mute: true });
        let days = new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate();
        for (let d = 1; d <= days; d++) out.push({ d: new Date(first.getFullYear(), first.getMonth(), d), mute: false });
        let k = 1;
        while (out.length % 7 !== 0) out.push({ d: new Date(first.getFullYear(), first.getMonth() + 1, k++), mute: true });
        return out;
    }
    function same(a, b) { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate(); }
    function hasEvents(d) { let k = Agenda.key(d); return Agenda.events.some(e => e.date === k); }
    readonly property var dayEvents: { let _ = Agenda.events.length; return Agenda.on(selected); }
    function isoWeek(d) {
        let t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        let n = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - n);
        let y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - y0) / 86400000 + 1) / 7);
    }

    // ---------- weather ----------
    readonly property var fc: Weather.forecast || []
    readonly property var today: fc.length ? fc[0] : null
    readonly property string city: (Weather.activeLocation && Weather.activeLocation.city) ? Weather.activeLocation.city : ""
    readonly property var hourly: today && today.hourly ? today.hourly : []
    readonly property var dayNames: ({ Mon: "T2", Tue: "T3", Wed: "T4", Thu: "T5", Fri: "T6", Sat: "T7", Sun: "CN" })
    readonly property string skyLine: {
        let d = Fz.weatherDesc(Weather.currentIcon);
        let laterRain = hourly.some(h => parseInt(h.time) > DateTime.now.getHours() && Fz.weatherIcon(h.icon) === "rain");
        return laterRain && Fz.weatherIcon(Weather.currentIcon) !== "rain" ? d + " · mưa rào " + (DateTime.now.getHours() < 12 ? "chiều" : "tối") : d;
    }

    Glass {
        anchors.fill: parent
        radius: 24

        // ======== left: month ========
        Column {
            id: left
            x: 26; y: 26
            width: 340
            height: parent.height - 52
            spacing: 14

            Row {
                width: parent.width
                spacing: 8
                FIconBtn { icon: "c-l"; label: "Tháng trước"; onClicked: root.shown = new Date(root.shown.getFullYear(), root.shown.getMonth() - 1, 1) }
                FText { width: parent.width - 36 * 2 - 16; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter
                        text: "Tháng " + (root.shown.getMonth() + 1) + ", " + root.shown.getFullYear(); px: 16; weight: Font.DemiBold; font.letterSpacing: 16 * 0.02 }
                FIconBtn { icon: "c-r"; label: "Tháng sau"; onClicked: root.shown = new Date(root.shown.getFullYear(), root.shown.getMonth() + 1, 1) }
            }
            Grid {
                id: grid
                columns: 7
                columnSpacing: 3; rowSpacing: 3
                readonly property real cw: (left.width - 18) / 7
                Repeater {
                    model: root.weekStart === 0 ? ["CN", "T2", "T3", "T4", "T5", "T6", "T7"] : ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
                    delegate: Item {
                        required property var modelData
                        width: grid.cw; height: 26
                        FText { anchors.centerIn: parent; text: modelData; px: 11.5; weight: Font.DemiBold; color: Fz.sub }
                    }
                }
                Repeater {
                    model: root.cells
                    delegate: Rectangle {
                        id: cell
                        required property var modelData
                        readonly property bool sel: root.same(modelData.d, root.selected)
                        readonly property bool isToday: root.same(modelData.d, DateTime.now)
                        readonly property bool ev: root.hasEvents(modelData.d)
                        width: grid.cw; height: 38; radius: 12
                        color: sel ? Fz.acc : (cdMouse.containsMouse ? Fz.fg(0.07) : "transparent")
                        border.width: isToday && !sel ? 1.5 : 0
                        border.color: Fz.acc
                        FText { anchors.centerIn: parent; text: cell.modelData.d.getDate(); px: 13.5; weight: Font.Medium
                                color: cell.sel ? Fz.ink : (cell.modelData.mute ? Fz.dim : Fz.tx) }
                        Rectangle { visible: cell.ev; width: 4; height: 4; radius: 2; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 5
                                    color: cell.sel ? Fz.ink : Fz.glow }
                        MouseArea { id: cdMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { root.selected = cell.modelData.d; if (cell.modelData.mute) root.shown = new Date(cell.modelData.d.getFullYear(), cell.modelData.d.getMonth(), 1); } }
                    }
                }
            }
        }
        Card {
            id: evCard
            x: 26
            width: 340
            y: parent.height - 26 - height
            height: evCol.implicitHeight + 24
            Column {
                id: evCol
                x: 14; y: 12
                width: parent.width - 28
                spacing: 8
                Item {
                    width: parent.width; height: 28
                    Caps { anchors.verticalCenter: parent.verticalCenter; px: 11
                           text: root.same(root.selected, DateTime.now) ? "Hôm nay · " + root.selected.getDate() + "/" + (root.selected.getMonth() + 1)
                                                                       : "Ngày " + root.selected.getDate() + "/" + (root.selected.getMonth() + 1) }
                    FIconBtn { anchors.right: parent.right; width: 28; height: 28; ghost: true; icon: "c-plus"; iconSize: 15; label: "Thêm sự kiện"
                               onClicked: { root.adding = !root.adding; if (root.adding) newTime.input.forceActiveFocus(); } }
                }
                Repeater {
                    model: root.dayEvents
                    delegate: Row {
                        required property var modelData
                        spacing: 10
                        FText { width: 40; mono: true; text: modelData.time || "—"; px: 12; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter }
                        Rectangle { width: 3; height: 24; radius: 2; color: Fz.acc; anchors.verticalCenter: parent.verticalCenter }
                        FText { width: evCol.width - 40 - 3 - 20 - 24; elide: Text.ElideRight; text: modelData.title; px: 13; anchors.verticalCenter: parent.verticalCenter }
                        FIconBtn { width: 24; height: 24; ghost: true; icon: "x"; iconSize: 12; label: "Xóa sự kiện"; anchors.verticalCenter: parent.verticalCenter
                                   onClicked: Agenda.remove(modelData.id) }
                    }
                }
                FText { visible: root.dayEvents.length === 0 && !root.adding; text: "Không có sự kiện."; px: 13; color: Fz.sub }
                Row {
                    visible: root.adding
                    width: parent.width
                    spacing: 6
                    FInput { id: newTime; width: 66; height: 34; fontSize: 13; placeholder: "10:30"; onAccepted: newTitle.input.forceActiveFocus() }
                    FInput { id: newTitle; width: parent.width - 66 - 6 - 6 - saveBtn.width; height: 34; fontSize: 13; placeholder: "Tên sự kiện"
                             onAccepted: saveBtn.clicked() }
                    FBtn {
                        id: saveBtn; height: 34; kind: "pri"; text: "Lưu"
                        onClicked: {
                            if (newTitle.text.trim() === "") return;
                            let tm = newTime.text.trim().replace(/^(\d{1,2})[h.:]?(\d{2})?$/, (m, h, mm) => String(h).padStart(2, "0") + ":" + (mm || "00"));
                            Agenda.add(Agenda.key(root.selected), tm, newTitle.text.trim(), "");
                            newTime.text = ""; newTitle.text = ""; root.adding = false;
                        }
                    }
                }
            }
        }

        // ======== middle: clock + temperature curve ========
        Item {
            id: mid
            x: 26 + 340 + 26
            y: 26
            width: parent.width - 52 - 340 - 330 - 52
            height: parent.height - 52
            Rectangle { width: 1; height: parent.height; color: Fz.line }
            Rectangle { x: parent.width - 1; width: 1; height: parent.height; color: Fz.line }
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 18
                spacing: 6
                FText { anchors.horizontalCenter: parent.horizontalCenter; mono: true; text: DateTime.timeLong; px: 92; font.letterSpacing: -4 }
                FText { anchors.horizontalCenter: parent.horizontalCenter
                        text: Fz.dateLong(DateTime.now) + ", " + DateTime.now.getFullYear() + " · Tuần " + root.isoWeek(DateTime.now); px: 17; color: Fz.sub2 }
            }
            Canvas {
                id: chart
                x: 20; width: parent.width - 40
                height: 190
                anchors.bottom: parent.bottom
                property var pts: root.hourly
                onPtsChanged: requestPaint()
                Connections { target: Fz; function onLightChanged() { chart.requestPaint(); } }
                Connections { target: DateTime; function onNowChanged() { if (DateTime.now.getSeconds() === 0) chart.requestPaint(); } }
                onPaint: {
                    let c = getContext("2d"); c.reset();
                    let p = pts; if (!p || p.length < 2) return;
                    // the design's viewBox is 560 x 170 with the curve between y 66 and 120
                    let s = Math.min(width / 560, height / 170), ox = (width - 560 * s) / 2, oy = (height - 170 * s) / 2;
                    c.translate(ox, oy); c.scale(s, s);
                    let temps = p.map(h => Number(h.temp)), lo = Math.min.apply(null, temps), hi = Math.max.apply(null, temps);
                    let X = i => 20 + i * (520 / (p.length - 1));
                    let Y = v => hi === lo ? 93 : 120 - (v - lo) / (hi - lo) * 54;
                    c.beginPath(); for (let i = 0; i < p.length; i++) { i ? c.lineTo(X(i), Y(temps[i])) : c.moveTo(X(i), Y(temps[i])); }
                    c.lineTo(540, 150); c.lineTo(20, 150); c.closePath(); c.fillStyle = Fz.accA(0.07); c.fill();
                    c.beginPath(); for (let i = 0; i < p.length; i++) { i ? c.lineTo(X(i), Y(temps[i])) : c.moveTo(X(i), Y(temps[i])); }
                    c.strokeStyle = Fz.acc; c.lineWidth = 2.5; c.lineJoin = "round"; c.lineCap = "round"; c.stroke();
                    // current hour, warmest and coolest point
                    let nowH = DateTime.now.getHours(), cur = 0;
                    for (let i = 0; i < p.length; i++) if (parseInt(p[i].time) <= nowH) cur = i;
                    let iMax = temps.indexOf(hi), iMin = temps.lastIndexOf(lo);
                    c.textAlign = "center";
                    c.font = "13px 'Geist'"; c.fillStyle = Fz.sub2;
                    if (iMax !== cur) { c.beginPath(); c.arc(X(iMax), Y(hi), 4, 0, Math.PI * 2); c.fillStyle = Fz.acc; c.fill(); c.fillStyle = Fz.sub2; c.fillText(Math.round(hi) + "°", X(iMax), Y(hi) - 14); }
                    if (iMin !== cur && iMin !== iMax) c.fillText(Math.round(lo) + "°", X(iMin), Y(lo) - 14);
                    c.beginPath(); c.arc(X(cur), Y(temps[cur]), 6, 0, Math.PI * 2); c.fillStyle = Fz.ink; c.fill(); c.strokeStyle = Fz.acc; c.lineWidth = 2.5; c.stroke();
                    c.font = "600 14px 'Geist'"; c.fillStyle = Fz.tx; c.fillText(Math.round(temps[cur]) + "°", X(cur), Y(temps[cur]) - 16);
                    // hour labels
                    c.font = "12px 'Geist Mono'"; c.fillStyle = Fz.sub;
                    for (let i = 0; i < p.length; i++) c.fillText(String(parseInt(p[i].time)).padStart(2, "0"), X(i), 170);
                    // chance of rain on the first rainy hour
                    for (let i = 0; i < p.length; i++) {
                        if (Fz.weatherIcon(p[i].icon) !== "rain" || !root.today) continue;
                        c.fillStyle = Fz.glowA(0.18); c.beginPath(); c.roundedRect(X(i) - 16, 128, 32, 18, 6, 6); c.fill();
                        c.font = "11px 'Geist'"; c.fillStyle = Fz.glow; c.fillText(root.today.pop + "%", X(i), 141);
                        break;
                    }
                }
            }
        }

        // ======== right: today's weather ========
        Item {
            id: right
            x: parent.width - 26 - 330
            y: 26
            width: 330
            height: parent.height - 52

            Item {
                id: wtop
                width: parent.width; height: wcol.implicitHeight
                Column {
                    id: wcol
                    Caps { px: 11; text: "Hôm nay" }
                    FText { topPadding: 8; text: Fz.deg(Weather.currentTemp); px: 72; weight: Font.Light; font.letterSpacing: -3 }
                    FText { topPadding: 8; text: root.city; px: 15; weight: Font.DemiBold }
                    FText { text: root.skyLine; px: 13.5; color: Fz.sub2 }
                }
                FIcon { anchors.right: parent.right; name: Fz.weatherIcon(Weather.currentIcon); size: 60; strokeWidth: 1.2; color: Fz.acc }
            }
            Grid {
                y: wtop.height + 14
                columns: 2
                columnSpacing: 8; rowSpacing: 8
                Repeater {
                    model: [
                        { i: "c-wind", v: (root.today ? Math.round(Number(root.today.wind)) : "--") + " km/h", l: "Gió" },
                        { i: "c-drop", v: (root.today ? root.today.humidity : "--") + "%", l: "Độ ẩm" },
                        { i: "c-umb", v: (root.today ? root.today.pop : "--") + "%", l: "Khả năng mưa" },
                        { i: "c-therm", v: root.today ? Fz.deg(root.today.feels_like) : "--°", l: "Cảm giác" }
                    ]
                    delegate: Card {
                        required property var modelData
                        width: (330 - 8) / 2; height: 58
                        Row {
                            x: 12; anchors.verticalCenter: parent.verticalCenter
                            spacing: 10
                            FIcon { name: modelData.i; color: Fz.acc; anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                FText { text: modelData.v; px: 14; weight: Font.DemiBold }
                                FText { text: modelData.l; px: 11.5; color: Fz.sub }
                            }
                        }
                    }
                }
            }
            Row {
                anchors.bottom: parent.bottom
                width: parent.width
                spacing: 4
                Repeater {
                    model: root.fc.slice(0, 5)
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: (330 - 16) / 5
                        height: dcol.implicitHeight + 20
                        radius: 14
                        color: index === 0 ? Fz.accA(0.12) : "transparent"
                        Column {
                            id: dcol
                            anchors.centerIn: parent
                            spacing: 6
                            FText { anchors.horizontalCenter: parent.horizontalCenter; text: index === 0 ? "Hôm nay" : (root.dayNames[modelData.day] || modelData.day); px: 12; color: index === 0 ? Fz.tx : Fz.sub2 }
                            FIcon { anchors.horizontalCenter: parent.horizontalCenter; name: Fz.weatherIcon(modelData.icon); color: index === 0 ? Fz.tx : Fz.sub2 }
                            FText { anchors.horizontalCenter: parent.horizontalCenter; text: Fz.deg(modelData.max); px: 12; weight: Font.DemiBold }
                            FText { anchors.horizontalCenter: parent.horizontalCenter; text: Fz.deg(modelData.min); px: 12; color: Fz.sub }
                        }
                    }
                }
            }
        }
    }
}
