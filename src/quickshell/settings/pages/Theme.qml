import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../../"
import "../../frost"

// Theme & giao diện: light/dark, accent, Matugen, colour presets, font, radius, focus border, wallpaper.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    readonly property var accents: [["#D6E6EC", Fz.tr("Băng giá")], ["#BFE3F5", Fz.tr("Bầu trời")], ["#CFE4D8", Fz.tr("Bạc hà")], ["#E3DCCF", Fz.tr("Cát")], ["#DCD3EE", Fz.tr("Oải hương")], ["#F0D3DA", Fz.tr("Hồng phấn")]]
    readonly property string accent: Config.getSetting("theme.accent", "") || "#D6E6EC"
    readonly property string activePreset: Config.getSetting("theme.activePreset", "Zone Frost")
    readonly property bool matugen: Config.getSetting("theme.matugen", false) === true
    property var presets: []
    property bool naming: false
    property bool showAll: false
    readonly property var featured: ["Zone Frost", "Zone Thunder", "Zone Crystal", "Nord", "Tokyo Storm", "Mocha", "Rose Pine", "Gruvbox", "Everforest", "Kanagawa", "Dracula", "Obsidian"]

    Process {
        running: true
        command: ["python3", Caching.qsDir + "/settings/scripts/theme_sorter.py", Caching.zoneCDir + "/assets/themes", Caching.stateDir + "/themes", Caching.getCacheDir("themes") + "/theme_sort_cache.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let seen = {}, all = JSON.parse(this.text).filter(p => !p.isDivider && !p.isMatugen && p.colors && !seen[p.name] && (seen[p.name] = true));
                    let rank = n => { let i = page.featured.indexOf(n); return i === -1 ? 100 : i; };
                    page.presets = all.sort((a, b) => rank(a.name) - rank(b.name));
                } catch (e) {}
            }
        }
    }
    function apply(p) {
        let cur = Config.getSetting("theme", {});
        cur.activePreset = p.name;
        cur.matugen = false;
        cur.colors = ZoneStyle.presetColors(p.name, p.colors);
        Config.setSetting("theme", cur);
        ThemeBackend.applyColorObject(cur.colors);
        if (typeof Matugen.generateFromStatic === "function") Matugen.generateFromStatic(cur.colors, cur.mode || "dark");
    }
    function setMatugen(on) {
        let cur = Config.getSetting("theme", {});
        cur.matugen = on;
        if (on) cur.activePreset = "Matugen";
        Config.setSetting("theme", cur);
        if (on) {
            let wp = Wallpaper.getWallpaperPath("");
            if (wp) Matugen.generate(wp, cur.mode || "dark", cur.schemeType);
            else ThemeBackend.applyMatugenColors();
        } else {
            let p = presets.find(x => x.name === "Zone Frost") || presets[0];
            if (p) apply(p);
        }
    }
    function saveCurrent(name) {
        let n = name.replace(/[^a-zA-Z0-9_\- ]/g, "").trim() || Fz.tr("Chủ đề của tôi");
        let obj = { name: n, isCustom: true, category: "user", colors: Config.getSetting("theme.colors", {}) };
        Quickshell.execDetached(["bash", "-c", "mkdir -p \"$1\" && printf '%s' \"$2\" > \"$1/$3.json\"", "_", Caching.stateDir + "/themes", JSON.stringify(obj, null, 2), n]);
        presets = presets.concat([obj]);
    }

    Grp {
        width: parent.width
        SRow {
            title: Fz.tr("Chế độ"); sub: Fz.tr("Zone Frost có bảng màu tối và sáng")
            FSeg { options: [Fz.tr("Tối"), Fz.tr("Sáng")]; current: ZoneStyle.isLight ? 1 : 0; onPicked: (i) => ZoneStyle.setMode(i === 1 ? "light" : "dark") }
        }
        SRow {
            title: Fz.tr("Màu nhấn"); sub: (page.accents.find(a => a[0].toLowerCase() === page.accent.toLowerCase()) || ["", Fz.tr("Tùy chỉnh")])[1]
            Row {
                spacing: 10
                Repeater {
                    model: page.accents
                    delegate: Item {
                        required property var modelData
                        readonly property bool on: page.accent.toLowerCase() === modelData[0].toLowerCase()
                        width: 34; height: 34
                        Rectangle { visible: parent.on; anchors.fill: parent; anchors.margins: -4; radius: 21; color: Fz.acc
                                    Rectangle { anchors.fill: parent; anchors.margins: 2; radius: 19; color: Fz.mantle } }
                        Rectangle { anchors.fill: parent; radius: 17; color: modelData[0] }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Config.setSetting("theme.accent", modelData[0] === "#D6E6EC" ? "" : modelData[0]) }
                        Accessible.role: Accessible.Button
                        Accessible.name: modelData[1]
                    }
                }
            }
        }
        SRow {
            title: Fz.tr("Lấy màu từ hình nền"); sub: Fz.tr("Matugen · tạo bảng màu tự động")
            FToggle { on: page.matugen; onToggled: (v) => page.setMatugen(v) }
        }
    }

    H3 { text: Fz.tr("Chủ đề màu sắc") }
    Grid {
        width: parent.width
        columns: 4; spacing: 10
        Repeater {
            model: page.showAll ? page.presets : page.presets.slice(0, 12)
            delegate: Rectangle {
                id: pc
                required property var modelData
                readonly property bool on: !page.matugen && page.activePreset === modelData.name
                width: (page.width - 30) / 4; height: 8 + 34 + 8 + pcName.implicitHeight + 8
                radius: 14
                color: Fz.fg(pcMouse.containsMouse ? 0.06 : 0.03)
                border.width: on ? 2 : 1; border.color: on ? Fz.acc : Fz.fg(0.08)
                Rectangle {
                    x: 8; y: 8; width: parent.width - 16; height: 34; radius: 9; clip: true
                    Row {
                        anchors.fill: parent
                        Repeater {
                            model: [pc.modelData.colors.base, pc.modelData.colors.blue || pc.modelData.colors.mauve, pc.modelData.colors.sapphire || pc.modelData.colors.teal, pc.modelData.colors.text]
                            delegate: Rectangle { required property var modelData; width: (pc.width - 16) / 4; height: 34; color: modelData || "transparent" }
                        }
                    }
                }
                FText { id: pcName; x: 8; y: 8 + 34 + 8; width: parent.width - 16; elide: Text.ElideRight; text: pc.modelData.name; px: 12.5; weight: Font.Medium }
                MouseArea { id: pcMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.apply(pc.modelData) }
            }
        }
    }
    Item { width: 1; height: 10 }
    Row {
        spacing: 8
        FBtn { visible: !page.naming; icon: "s-plus"; iconSize: 14; text: Fz.tr("Tạo chủ đề mới"); onClicked: { page.naming = true; nameField.text = ""; nameField.input.forceActiveFocus(); } }
        FInput { id: nameField; visible: page.naming; width: 240; height: 36; placeholder: Fz.tr("Tên chủ đề (lưu màu hiện tại)"); onAccepted: { page.saveCurrent(text); page.naming = false; } }
        FBtn { visible: page.naming; kind: "pri"; text: Fz.tr("Lưu"); onClicked: { page.saveCurrent(nameField.text); page.naming = false; } }
        FText {
            anchors.verticalCenter: parent.verticalCenter
            text: page.showAll ? Fz.tr("Thu gọn") : page.presets.length + Fz.tr(" chủ đề có sẵn"); px: 13.5; color: tm.containsMouse ? Fz.tx : Fz.sub
            MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.showAll = !page.showAll }
        }
    }

    H3 { text: Fz.tr("Kiểu chữ & hình dạng") }
    Grp {
        width: parent.width
        SRow {
            title: Fz.tr("Phông chữ"); sub: Fz.tr("Phông mặc định cho zone-c")
            CfgSelect {
                key: "theme.frostFont"; def: "Geist"
                readonly property var installed: ["Geist", "Google Sans", "Inter Display", "Inter", "Noto Sans", "Roboto", "Cantarell"].filter(f => f === "Geist" || Qt.fontFamilies().indexOf(f) !== -1)
                options: installed; values: installed
            }
        }
        SRow {
            title: Fz.tr("Bán kính viền"); sub: Fz.tr("Góc bo của thành phần giao diện")
            CfgRange { key: "theme.borderRadius"; from: 0; to: 24; def: 14; unit: "px"; sliderWidth: 200 }
        }
        SRow {
            title: Fz.tr("Hiệu ứng viền focus"); sub: Fz.tr("Viền sáng quanh cửa sổ đang dùng")
            FSeg {
                options: [Fz.tr("Tĩnh"), Fz.tr("Tia điện"), Fz.tr("Tắt")]
                current: ZoneStyle.borderOff ? 2 : ZoneStyle.plainBorder ? 0 : 1
                onPicked: (i) => Config.setSetting("theme.focusBorder", ["still", "bolt", "off"][i])
            }
        }
        SRow {
            title: Fz.tr("Thư mục hình nền"); subMono: true
            sub: { let d = Config.getSetting("wallpaperDir", "") || Config.getSetting("wallpaper_dir", "") || "~/Pictures/Wallpapers"; let h = Quickshell.env("HOME"); return d.indexOf(h) === 0 ? "~" + d.slice(h.length) : d; }
            FBtn { text: Fz.tr("Chọn hình nền"); onClicked: Fz.open("wallpaper") }
        }
    }
}
