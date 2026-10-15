import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../"
import "../frost"

// Wallpaper picker of the Frost design (Wallpaper.dc.html): image/video tabs, colour filter,
// a 3D carousel with the current pick in front, a thumbnail strip, Enter to apply.
Item {
    id: root
    focus: true

    readonly property string srcDir: Config.getSetting("wallpaperDir", "") || Quickshell.env("WALLPAPER_DIR") || (Quickshell.env("HOME") + "/Pictures/Wallpapers")
    property var all: []
    property bool videos: false
    property string color: "all"
    property int idx: 0
    property bool recentFirst: false
    property bool gridView: false
    property var history: []

    // design swatches -> colour buckets of scripts/wallpaper/indexer.py (navy = dark blues)
    readonly property var swatches: [
        { k: "all", l: "Tất cả", c: Fz.s2 }, { k: "white", l: "Trắng", c: Fz.tx }, { k: "blue", l: "Xanh băng", c: Fz.glow },
        { k: "navy", l: "Xanh đậm", c: "#2F5D72" }, { k: "green", l: "Xanh lá", c: "#6FAE8A" }, { k: "amber", l: "Hổ phách", c: "#D8A65A" },
        { k: "red", l: "Đỏ", c: "#D46A6A" }, { k: "violet", l: "Tím", c: "#8C7BC0" }
    ]
    function lum(hex) { let h = (hex || "#808080").replace("#", ""); return (parseInt(h.substr(0, 2), 16) * 0.299 + parseInt(h.substr(2, 2), 16) * 0.587 + parseInt(h.substr(4, 2), 16) * 0.114) / 255; }
    function matches(it) {
        if (!!it.isVideo !== videos) return false;
        let b = it.bucket;
        switch (color) {
            case "white": return b === "Monochrome";
            case "blue": return b === "Blue" && lum(it.hex) >= 0.4;
            case "navy": return b === "Blue" && lum(it.hex) < 0.4;
            case "green": return b === "Green";
            case "amber": return b === "Orange" || b === "Yellow";
            case "red": return b === "Red" || b === "Pink";
            case "violet": return b === "Purple";
        }
        return true;
    }
    readonly property var list: {
        let l = all.filter(matches);
        if (recentFirst) l = l.slice().sort((a, b) => (history.indexOf(a.filePath) === -1 ? 1e9 : history.indexOf(a.filePath)) - (history.indexOf(b.filePath) === -1 ? 1e9 : history.indexOf(b.filePath)));
        return l;
    }
    onListChanged: if (idx >= list.length) idx = 0
    readonly property var cur: list.length ? list[idx] : null
    function at(k) { return list.length ? list[((k % list.length) + list.length) % list.length] : null; }
    function src(it) { return !it ? "" : (it.isVideo ? (it.posterUrl || "") : it.fileUrl); }
    function size(b) { return b > 1048576 ? (b / 1048576).toFixed(1) + " MB" : Math.round(b / 1024) + " KB"; }

    Process {
        id: indexer
        command: ["python3", Caching.zoneCDir + "/scripts/wallpaper/indexer.py", root.srcDir, Caching.getCacheDir("wallpaper"), Caching.getRunDir("wallpaper")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(this.text.trim());
                    let items = (d.items || []).slice().sort((a, b) => a.fileName.localeCompare(b.fileName));
                    root.all = items;
                    let curPath = Wallpaper.getWallpaperPath("");
                    let i = root.list.findIndex(x => x.filePath === curPath);
                    root.idx = i >= 0 ? i : 0;
                } catch (e) {}
            }
        }
    }
    Process {
        id: hist
        command: ["cat", Caching.getCacheDir("wallpaper") + "/history.txt"]
        stdout: StdioCollector { onStreamFinished: root.history = this.text.split("\n").filter(s => s !== "").reverse() }
    }
    onVisibleChanged: if (visible) { indexer.running = true; hist.running = true; forceActiveFocus(); }
    Component.onCompleted: { indexer.running = true; hist.running = true; }

    function apply() {
        let it = cur;
        if (!it) return;
        Wallpaper.setWallpaper("all", it.filePath, "fade");
        if (typeof Matugen !== "undefined" && typeof Matugen.generate === "function") Matugen.generate(it.isVideo && it.posterPath ? it.posterPath : it.filePath);
        Quickshell.execDetached(["bash", "-c", "f=\"$1\"; h=\"$2\"; mkdir -p \"$(dirname \"$h\")\"; grep -vxF \"$f\" \"$h\" 2>/dev/null > \"$h.tmp\"; echo \"$f\" >> \"$h.tmp\"; mv \"$h.tmp\" \"$h\"", "_", it.filePath, Caching.getCacheDir("wallpaper") + "/history.txt"]);
        Quickshell.execDetached(["bash", Caching.zoneCDir + "/scripts/qs_manager.sh", "close"]);
    }

    Keys.onPressed: (e) => {
        if (e.key === Qt.Key_Left) { idx = (idx + list.length - 1) % Math.max(1, list.length); e.accepted = true; }
        else if (e.key === Qt.Key_Right) { idx = (idx + 1) % Math.max(1, list.length); e.accepted = true; }
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { apply(); e.accepted = true; }
    }

    // `.wall.blur` + `.scrim.deep`
    Image {
        anchors.fill: parent; anchors.margins: -60; anchors.topMargin: -112
        source: root.src(root.cur) || ("file://" + Wallpaper.getWallpaperPath(""))
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: 960
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64; blurMultiplier: 1.6; saturation: 0.1 }
    }
    Rectangle { anchors.fill: parent; color: Fz.scrimDeep }
    MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", Caching.zoneCDir + "/scripts/qs_manager.sh", "close"]) }

    // ---------- toolbar ----------
    Glass {
        x: (parent.width - width) / 2
        y: 88 - 52
        radius: 18
        width: tools.implicitWidth + 16
        height: tools.implicitHeight + 16
        Row {
            id: tools
            x: 8; y: 8
            spacing: 6
            FSeg {
                options: ["Ảnh", "Video"]
                current: root.videos ? 1 : 0
                anchors.verticalCenter: parent.verticalCenter
                onPicked: (i) => { root.videos = i === 1; root.idx = 0; }
            }
            FIconBtn { icon: "g-grid"; label: "Dạng lưới"; on: root.gridView; onClicked: root.gridView = !root.gridView; anchors.verticalCenter: parent.verticalCenter }
            FIconBtn {
                icon: "g-clock"; label: "Gần đây"; on: root.recentFirst
                anchors.verticalCenter: parent.verticalCenter
                onClicked: { root.recentFirst = !root.recentFirst; root.idx = 0; }
            }
            Rectangle { width: 1; height: 24; color: Fz.line2; anchors.verticalCenter: parent.verticalCenter }
            Repeater {
                model: root.swatches
                delegate: Item {
                    required property var modelData
                    width: 30; height: 30
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {   // `.sw.on`: ink ring then accent ring
                        visible: root.color === modelData.k
                        anchors.fill: parent; anchors.margins: -4; radius: 13; color: Fz.acc
                        Rectangle { anchors.fill: parent; anchors.margins: 2; radius: 11; color: Fz.ink }
                    }
                    Rectangle { anchors.fill: parent; radius: 9; color: modelData.c }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.color = modelData.k; root.idx = 0; } }
                    Accessible.name: modelData.l
                }
            }
            Rectangle { width: 1; height: 24; color: Fz.line2; anchors.verticalCenter: parent.verticalCenter }
            FIconBtn { icon: "g-folder"; label: "Thư mục"; onClicked: Quickshell.execDetached(["xdg-open", root.srcDir]); anchors.verticalCenter: parent.verticalCenter }
            FIconBtn { icon: "g-search"; label: "Tìm hình nền"; onClicked: Fz.open("guide", "theme"); anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // ---------- carousel ----------
    Item {
        id: stage
        visible: !root.gridView
        x: (parent.width - 1440) / 2
        y: 176 - 52
        width: 1440; height: 440

        component Card3: Item {
            id: c3
            property var item
            property real tilt: 0
            Rectangle {
                id: frame
                anchors.fill: parent
                radius: 24; color: Fz.crust
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Qt.rgba(0, 0, 0, 0.45); shadowBlur: 1; shadowVerticalOffset: 30; blurMax: 60 }
                RoundImage { anchors.fill: parent; radius: 24; source: root.src(c3.item); sourceSize: Qt.size(1200, 800) }
            }
            transform: Rotation { origin.x: c3.width / 2; origin.y: c3.height / 2; axis { x: 0; y: 1; z: 0 } angle: c3.tilt }
        }

        Card3 { x: 170; y: 40; width: 420; height: 320; tilt: 28; opacity: 0.55; item: root.at(root.idx - 1)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.idx = (root.idx + root.list.length - 1) % Math.max(1, root.list.length) } }
        Card3 { x: 850; y: 40; width: 420; height: 320; tilt: -28; opacity: 0.55; item: root.at(root.idx + 1)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.idx = (root.idx + 1) % Math.max(1, root.list.length) } }
        Card3 {
            id: center
            x: 420; width: 600; height: 400; item: root.cur
            z: 2
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 78
                radius: 24
                color: Fz.surf(0.62)
                Rectangle { width: parent.width; height: 24; color: parent.color }
                Column {
                    x: 22; anchors.bottom: parent.bottom; anchors.bottomMargin: 18
                    FText { text: root.cur ? root.cur.fileName : "Chưa có hình nền"; px: 18; weight: Font.DemiBold; width: 380; elide: Text.ElideMiddle }
                    FText {
                        text: !root.cur ? root.srcDir : (sizer.status === Image.Ready ? sizer.implicitWidth + "×" + sizer.implicitHeight + " · " : "") + root.size(root.cur.size) + (root.cur.isVideo ? " · video" : "")
                        mono: true; px: 12; color: Fz.sub2
                    }
                }
                FBtn { anchors.right: parent.right; anchors.rightMargin: 22; anchors.bottom: parent.bottom; anchors.bottomMargin: 18
                       kind: "pri"; icon: "g-check"; iconSize: 15; text: "Đặt làm hình nền"; onClicked: root.apply() }
            }
            Image { id: sizer; visible: false; source: root.cur && !root.cur.isVideo ? root.cur.fileUrl : ""; sourceSize: Qt.size(-1, -1); asynchronous: true }
        }
    }
    FIconBtn { visible: !root.gridView; x: (parent.width - 1440) / 2 + 200; y: 374 - 52; width: 46; height: 46; radius: 23; icon: "g-l"; label: "Hình trước"
               onClicked: root.idx = (root.idx + root.list.length - 1) % Math.max(1, root.list.length) }
    FIconBtn { visible: !root.gridView; x: (parent.width + 1440) / 2 - 200 - 46; y: 374 - 52; width: 46; height: 46; radius: 23; icon: "g-r"; label: "Hình sau"
               onClicked: root.idx = (root.idx + 1) % Math.max(1, root.list.length) }

    // ---------- grid view ----------
    GridView {
        visible: root.gridView
        x: (parent.width - width) / 2; y: 176 - 52
        width: Math.min(parent.width - 120, 1200); height: parent.height - 176 - 140
        cellWidth: width / 5; cellHeight: cellWidth * 2 / 3
        clip: true
        model: root.list
        delegate: Item {
            required property var modelData
            required property int index
            width: GridView.view.cellWidth; height: GridView.view.cellHeight
            Rectangle { anchors.fill: parent; anchors.margins: 6; radius: 14; color: "transparent"; border.width: index === root.idx ? 2 : 0; border.color: Fz.acc
                RoundImage { anchors.fill: parent; anchors.margins: 3; radius: 12; source: root.src(modelData); sourceSize: Qt.size(400, 260) } }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.idx = index; onDoubleClicked: { root.idx = index; root.apply(); } }
        }
    }

    // ---------- strip ----------
    Glass {
        visible: root.list.length > 0
        radius: 20
        x: (parent.width - width) / 2
        y: parent.height - 60 - height
        width: strip.implicitWidth + 20
        height: 60 + 20
        Row {
            id: strip
            x: 10; y: 10
            spacing: 8
            Repeater {
                model: root.list.slice(0, 11)
                delegate: Item {
                    required property var modelData
                    required property int index
                    width: 96; height: 60
                    opacity: index === root.idx ? 1 : 0.6
                    Rectangle { visible: index === root.idx; anchors.fill: parent; anchors.margins: -2; radius: 14; color: Fz.acc }
                    RoundImage { anchors.fill: parent; radius: 12; source: root.src(modelData); sourceSize: Qt.size(192, 120) }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.idx = index; onDoubleClicked: root.apply() }
                }
            }
        }
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - 30 - 18
        spacing: 6
        FKbd { text: "←" } FKbd { text: "→" }
        FText { text: "duyệt ·"; px: 12.5; color: Fz.sub2; anchors.verticalCenter: parent.verticalCenter }
        FKbd { text: "Enter" }
        FText { text: "áp dụng · màu nhấn tự lấy từ hình (matugen)"; px: 12.5; color: Fz.sub2; anchors.verticalCenter: parent.verticalCenter }
    }
}
