import QtQuick
import "../../"
import "../../frost"

// Desktop weather card (Main.dc.html): place, big temperature, next hours, wind / humidity / feels-like chips.
Glass {
    id: root
    implicitWidth: 348
    implicitHeight: col.implicitHeight + 40
    readonly property var today: (Weather.forecast && Weather.forecast.length) ? Weather.forecast[0] : null
    readonly property string city: (Weather.activeLocation && Weather.activeLocation.city) ? Weather.activeLocation.city : ""
    readonly property var hours: {
        let out = [{ t: Fz.tr("Bây giờ"), i: Weather.currentIcon, v: Weather.currentTemp, cur: true }];
        let fc = Weather.forecast || [], nowH = DateTime.now.getHours();
        for (let d = 0; d < fc.length && out.length < 6; d++) {
            let hs = fc[d].hourly || [];
            for (let i = 0; i < hs.length && out.length < 6; i++) {
                let h = parseInt(hs[i].time);
                if (d === 0 && h <= nowH) continue;
                out.push({ t: hs[i].time, i: hs[i].icon, v: hs[i].temp, cur: false });
            }
        }
        return out;
    }

    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Fz.open("calendar") }

    Column {
        id: col
        x: 20; y: 20
        width: root.width - 40
        spacing: 16

        Item {
            width: parent.width
            height: info.implicitHeight
            Column {
                id: info
                FText { text: (root.city ? root.city + " · " : "") + Fz.weekdays[DateTime.now.getDay()]; color: Fz.sub; px: 13 }
                FText { topPadding: 6; text: Fz.deg(Weather.currentTemp); px: 56; weight: Font.Light; font.letterSpacing: -2; lineHeight: 1 }
                FText { topPadding: 6; text: Fz.weatherDesc(Weather.currentIcon) + (root.today ? Fz.tr(" · Cao ") + Fz.deg(root.today.max) + Fz.tr(" Thấp ") + Fz.deg(root.today.min) : ""); color: Fz.sub2; px: 13.5 }
            }
            FIcon { anchors.right: parent.right; name: Fz.weatherIcon(Weather.currentIcon); size: 52; strokeWidth: 1.2; color: Fz.acc }
        }

        Row {
            width: parent.width
            spacing: 4
            Repeater {
                model: root.hours
                delegate: Rectangle {
                    required property var modelData
                    width: (col.width - 20) / 6
                    height: 64
                    radius: 12
                    color: modelData.cur ? Fz.acc : Fz.fg(0.05)
                    Column {
                        anchors.centerIn: parent
                        spacing: 5
                        FText { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.t; px: 11; color: modelData.cur ? Fz.ink : Fz.sub2 }
                        FIcon { anchors.horizontalCenter: parent.horizontalCenter; name: Fz.weatherIcon(modelData.i); size: 15; color: modelData.cur ? Fz.ink : Fz.sub2 }
                        FText { anchors.horizontalCenter: parent.horizontalCenter; text: Fz.deg(modelData.v); px: 13; weight: Font.DemiBold; color: modelData.cur ? Fz.ink : Fz.sub2 }
                    }
                }
            }
        }

        Row {
            spacing: 8
            FChip { icon: "m-wind"; text: (root.today ? Math.round(Number(root.today.wind)) : "--") + " km/h" }
            FChip { icon: "m-drop"; text: (root.today ? root.today.humidity : "--") + "%" }
            FChip { text: Fz.tr("Cảm giác ") + (root.today ? Fz.deg(root.today.feels_like) : "--°") }
        }
    }
}
