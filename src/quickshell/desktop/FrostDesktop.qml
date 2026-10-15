import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"
import "../frost"
import "faces"

// Desktop widgets of the Frost design: the Dashboard layout of the Desktop artboard by default,
// two more presets (Media station, Minimal) and the editor drawn in the Widgets artboard.
Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            readonly property string monitor: modelData.name || "screen"

            WlrLayershell.namespace: "qs-desktop"
            WlrLayershell.layer: editing ? WlrLayer.Overlay : WlrLayer.Bottom
            WlrLayershell.keyboardFocus: editing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            // Outside the editor only the widgets take clicks; the rest of the desktop stays reachable.
            // The desktop layer sits under every window, so it can take the whole screen:
            // widgets get their clicks and the empty desktop gets the right-click menu.
            mask: Region { item: fullMask; intersection: Intersection.Combine }
            Item { id: fullMask; anchors.fill: parent }
            Item { id: widgetMask; x: 0; y: 0; width: 0; height: 0 }

            property bool editing: false
            onEditingChanged: {
                Desk.editingScreen = editing ? monitor : (Desk.editingScreen === monitor ? "" : Desk.editingScreen);
                if (!editing) { selectedId = ""; save(); }
                else if (widgets.length) selectedId = widgets[0].id;
            }
            property string selectedId: ""
            property string preset: "dash"
            property var widgets: []
            property var customPresets: ({})

            // ---------- types and presets ----------
            readonly property var types: ({
                hero:           { comp: heroC,     tag: "Đồng hồ · Dashboard" },
                material:       { comp: materialC, tag: "Đồng hồ · Material" },
                analog:         { comp: analogC,   tag: "Đồng hồ · kim" },
                lumen:          { comp: lumenC,    tag: "Đồng hồ · Lumen" },
                weatherFull:    { comp: wFullC,    tag: "Thời tiết · đầy đủ" },
                weatherCompact: { comp: wCompC,    tag: "Thời tiết · gọn" },
                musicFull:      { comp: mFullC,    tag: "Nhạc · đầy đủ" },
                musicRound:     { comp: mRoundC,   tag: "Nhạc · tròn" },
                viz:            { comp: vizC,      tag: "Visualizer · cava" },
                battery:        { comp: batC,      tag: "Pin" },
                resources:      { comp: resC,      tag: "Tài nguyên" },
                user:           { comp: userC,     tag: "Người dùng" },
                image:          { comp: imageC,    tag: "Khung ảnh" },
                today:          { comp: todayC,    tag: "Hôm nay" }
            })
            // Positions in design pixels; ax "r" measures x from the right edge (the Desktop artboard's right column).
            readonly property var builtinPresets: ({
                dash: [
                    { type: "hero", ax: "l", x: 60, y: 96 },
                    { type: "musicFull", ax: "l", x: 60, y: 424 },
                    { type: "weatherFull", ax: "r", x: 32, y: 76 },
                    { type: "resources", ax: "r", x: 32, y: 362 },
                    { type: "today", ax: "r", x: 32, y: 498 }
                ],
                media: [
                    { type: "material", ax: "l", x: 70, y: 120 },
                    { type: "weatherCompact", ax: "l", x: 70, y: 420 },
                    { type: "musicRound", ax: "l", x: 410, y: 420 },
                    { type: "viz", ax: "l", x: 70, y: 650 }
                ],
                min: [ { type: "material", ax: "l", x: 70, y: 120 } ]
            })
            readonly property var presetNames: [["dash", "Dashboard"], ["media", "Media station"], ["min", "Minimal"]]

            function withIds(list) {
                return list.map((w, i) => Object.assign({ id: String(Date.now()) + "-" + i, scale: 1 }, w));
            }
            function applyPreset(name) {
                preset = name;
                widgets = withIds(customPresets[name] || builtinPresets[name] || []);
                selectedId = "";
                save();
            }
            function update(id, patch) {
                widgets = widgets.map(w => w.id === id ? Object.assign({}, w, patch) : w);
            }
            function selected() { return widgets.find(w => w.id === selectedId) || null; }
            function addWidget(type) {
                let n = widgets.length;
                let w = { id: String(Date.now()), type: type, ax: "l", x: 120 + (n % 5) * 32, y: 140 + (n % 5) * 32, scale: 1 };
                widgets = widgets.concat([w]);
                selectedId = w.id;
                if (type === "image") picker.open(w.id);
            }

            // ---------- persistence: <state>/desktop/<monitor>.json ----------
            readonly property string stateFile: Caching.stateDir ? Caching.stateDir + "/desktop/" + monitor + ".json" : ""
            FileView {
                id: store
                path: win.stateFile
                onLoaded: {
                    try {
                        let v = JSON.parse(text());
                        win.customPresets = v.custom || {};
                        win.preset = v.preset || "dash";
                        win.widgets = Array.isArray(v.widgets) ? v.widgets : win.withIds(win.builtinPresets[win.preset]);
                    } catch (e) { win.applyPreset("dash"); }
                }
                onLoadFailed: win.applyPreset("dash")
            }
            function save() {
                if (!stateFile) return;
                let data = JSON.stringify({ preset: preset, widgets: widgets, custom: customPresets });
                Quickshell.execDetached(["bash", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "_", stateFile, data]);
            }

            IpcHandler {
                target: "widgets-" + win.monitor.replace(/[^A-Za-z0-9_-]/g, "_")
                function setRedactMode(active: string): string { win.editing = (active === "true" || active === "1"); return "ok"; }
                function save(): string { win.save(); return "ok"; }
                function preset(name: string): string { win.applyPreset(name); return "ok"; }
            }
            IpcHandler {
                target: "desktop"
                function edit(): void { if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name !== win.monitor) return; win.editing = !win.editing; }
            }

            // `.scrim` over the wallpaper, as on every desktop artboard
            Rectangle { anchors.fill: parent; color: Fz.scrim; visible: !win.editing }

            // ---------- desktop right-click menu (TrayMenu artboard) ----------
            MouseArea {
                anchors.fill: parent
                enabled: !win.editing
                acceptedButtons: Qt.RightButton | Qt.LeftButton
                onClicked: (e) => {
                    if (e.button !== Qt.RightButton) { deskMenu.visible = false; return; }
                    deskMenu.x = Math.min(e.x, win.width - deskMenu.width - 8);
                    deskMenu.y = Math.min(e.y, win.height - deskMenu.height - 8);
                    deskMenu.visible = true;
                }
            }

            // ---------- editor backdrop: grid (Widgets artboard) ----------
            Rectangle {
                anchors.fill: parent
                visible: win.editing
                color: Fz.scrim
                MouseArea { anchors.fill: parent; onClicked: win.selectedId = "" }
                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        let c = getContext("2d"); c.reset();
                        c.strokeStyle = Fz.fg(0.06); c.lineWidth = 1;
                        c.beginPath();
                        for (let x = 0.5; x < width; x += 40) { c.moveTo(x, 0); c.lineTo(x, height); }
                        for (let y = 0.5; y < height; y += 40) { c.moveTo(0, y); c.lineTo(width, y); }
                        c.stroke();
                    }
                    Connections { target: Fz; function onLightChanged() { parent.requestPaint(); } }
                }
            }

            // ---------- widgets ----------
            Repeater {
                id: rep
                model: win.widgets
                delegate: Item {
                    id: slot
                    required property var modelData
                    readonly property var info: win.types[modelData.type] || null
                    readonly property bool sel: win.editing && win.selectedId === modelData.id
                    readonly property real sc: modelData.scale || 1
                    width: face.item ? face.item.implicitWidth * sc : 0
                    height: face.item ? face.item.implicitHeight * sc : 0
                    x: modelData.ax === "r" ? win.width - Fz.px(modelData.x) - width : Fz.px(modelData.x)
                    y: Fz.px(modelData.y)
                    z: sel ? 10 : 1

                    // `.wd` outline (dashed) and `.wd.sel` (solid, with the .sel box the canvas draws behind it)
                    Rectangle {
                        visible: slot.sel
                        anchors.fill: parent
                        radius: 11; color: Fz.base; border.width: 1; border.color: Fz.line2
                    }
                    Canvas {
                        visible: win.editing
                        anchors.fill: parent; anchors.margins: -7.5
                        property bool s: slot.sel
                        onSChanged: requestPaint()
                        onWidthChanged: requestPaint(); onHeightChanged: requestPaint()
                        onPaint: {
                            let c = getContext("2d"); c.reset();
                            let r = slot.modelData.type === "musicRound" || slot.modelData.type === "analog" ? width / 2 : 28;
                            c.lineWidth = s ? 2 : 1.5;
                            c.strokeStyle = s ? Fz.acc : Fz.accA(0.55);
                            c.setLineDash(s ? [] : [4, 3]);
                            c.beginPath(); c.roundedRect(1, 1, width - 2, height - 2, r, r); c.stroke();
                        }
                    }
                    Loader {
                        id: face
                        sourceComponent: slot.info ? slot.info.comp : null
                        scale: slot.sc
                        transformOrigin: Item.TopLeft
                        onLoaded: if (slot.modelData.type === "image") item.path = Qt.binding(() => slot.modelData.path || "")
                    }
                    // `.wd .tag`
                    Rectangle {
                        visible: win.editing
                        y: -34
                        x: slot.modelData.type === "musicRound" ? 40 : 0
                        width: tagT.implicitWidth + 16; height: tagT.implicitHeight + 8; radius: 7
                        color: Fz.acc
                        FText { id: tagT; anchors.centerIn: parent; text: slot.info ? slot.info.tag : ""; color: Fz.ink; px: 11.5; weight: Font.DemiBold }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: win.editing
                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        drag.target: slot
                        drag.threshold: 2
                        onPressed: win.selectedId = slot.modelData.id
                        onReleased: {
                            if (!drag.active) return;
                            let nx = slot.modelData.ax === "r" ? win.width - slot.x - slot.width : slot.x;
                            win.update(slot.modelData.id, { x: Math.round(nx / Fz.px(1)), y: Math.round(slot.y / Fz.px(1)) });
                        }
                    }
                }
            }

            // Input region outside the editor: the union of the widgets' boxes.
            onWidgetsChanged: maskTimer.restart()
            Timer {
                id: maskTimer
                interval: 50
                onTriggered: {
                    let x0 = 1e9, y0 = 1e9, x1 = 0, y1 = 0;
                    for (let i = 0; i < rep.count; i++) {
                        let it = rep.itemAt(i);
                        if (!it || it.width === 0) continue;
                        x0 = Math.min(x0, it.x); y0 = Math.min(y0, it.y);
                        x1 = Math.max(x1, it.x + it.width); y1 = Math.max(y1, it.y + it.height);
                    }
                    if (x1 === 0) { widgetMask.width = 0; widgetMask.height = 0; return; }
                    widgetMask.x = x0; widgetMask.y = y0; widgetMask.width = x1 - x0; widgetMask.height = y1 - y0;
                }
            }

            // ---------- editor toolbar ----------
            Glass {
                visible: win.editing
                z: 20
                radius: 18
                anchors.horizontalCenter: parent.horizontalCenter
                y: 14
                width: toolbar.implicitWidth + 16
                height: toolbar.implicitHeight + 16
                Row {
                    id: toolbar
                    x: 8; y: 8
                    spacing: 8
                    FText { anchors.verticalCenter: parent.verticalCenter; leftPadding: 10; rightPadding: 10; text: "Chỉnh widget · " + win.monitor; px: 13.5; weight: Font.DemiBold }
                    FSeg {
                        anchors.verticalCenter: parent.verticalCenter
                        options: win.presetNames.map(p => p[1])
                        current: win.presetNames.findIndex(p => p[0] === win.preset)
                        onPicked: (i) => win.applyPreset(win.presetNames[i][0])
                    }
                    FBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "w-save"; text: "Lưu preset"
                        onClicked: {
                            let c = Object.assign({}, win.customPresets);
                            c[win.preset] = win.widgets.map(w => { let o = Object.assign({}, w); delete o.id; return o; });
                            win.customPresets = c;
                            win.save();
                        }
                    }
                    FBtn { anchors.verticalCenter: parent.verticalCenter; kind: "pri"; text: "Xong"; onClicked: win.editing = false }
                }
            }

            // ---------- "Thêm tiện ích" panel ----------
            Glass {
                id: aside
                visible: win.editing
                z: 20
                anchors.right: parent.right; anchors.rightMargin: 16
                anchors.top: parent.top; anchors.topMargin: 80
                anchors.bottom: parent.bottom; anchors.bottomMargin: 16
                width: 360

                Column {
                    x: 16; y: 16
                    width: parent.width - 32
                    spacing: 12
                    Item {
                        width: parent.width; height: 22
                        FText { anchors.verticalCenter: parent.verticalCenter; text: "Thêm tiện ích"; px: 16; weight: Font.DemiBold }
                        FChip { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: "kéo thả vào màn hình" }
                    }
                    Grid {
                        columns: 2
                        columnSpacing: 8; rowSpacing: 8
                        Repeater {
                            model: [
                                { t: "material", l: "Đồng hồ số", pv: "digital" }, { t: "analog", l: "Đồng hồ kim", pv: "analog" },
                                { t: "lumen", l: "Material Lumen", pv: "lumen" }, { t: "weatherFull", l: "Thời tiết đầy đủ", pv: "w-cloud" },
                                { t: "musicFull", l: "Nhạc", pv: "w-music" }, { t: "viz", l: "Visualizer", pv: "w-wave" },
                                { t: "battery", l: "Pin", pv: "w-bat" }, { t: "resources", l: "Tài nguyên", pv: "w-cpu" },
                                { t: "user", l: "Người dùng", pv: "w-user" }, { t: "image", l: "Khung ảnh", pv: "w-image" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                width: (aside.width - 32 - 8) / 2
                                height: 64 + 20 + 8 + 16
                                radius: 16
                                color: Fz.fg(giMouse.containsMouse ? 0.08 : 0.04)
                                border.width: 1; border.color: Fz.fg(0.08)
                                Column {
                                    x: 10; y: 10
                                    width: parent.width - 20
                                    spacing: 8
                                    Rectangle {
                                        width: parent.width; height: 64; radius: 11
                                        color: Fz.crust
                                        FText { visible: modelData.pv === "digital"; anchors.centerIn: parent; text: "09:41"; color: Fz.acc; px: 26; weight: Font.Light }
                                        Row { visible: modelData.pv === "lumen"; anchors.centerIn: parent
                                            FText { text: "09"; color: Fz.acc; px: 20; weight: Font.DemiBold; font.letterSpacing: -1 }
                                            FText { text: ":"; color: Fz.acc; opacity: 0.5; px: 20; weight: Font.DemiBold }
                                            FText { text: "41"; color: Fz.acc; px: 20; weight: Font.DemiBold; font.letterSpacing: -1 } }
                                        Item {
                                            visible: modelData.pv === "analog"; anchors.centerIn: parent; width: 46; height: 46
                                            Rectangle { anchors.fill: parent; anchors.margins: 46 * 3 / 40; radius: width / 2; color: "transparent"; border.width: 1.5 * 46 / 40; border.color: Fz.acc }
                                            Rectangle { x: 23 - 1.15; y: 23 - 12.65; width: 2.3; height: 12.65 + 1.15; radius: 1.15; color: Fz.acc }
                                            Rectangle { x: 23 - 1.15; y: 23 - 1.15; width: 2.3; height: 9.3 + 1.15; radius: 1.15; color: Fz.acc; transform: Rotation { origin.x: 1.15; origin.y: 1.15; angle: -60.3 } }
                                        }
                                        FIcon { visible: modelData.pv.indexOf("w-") === 0; anchors.centerIn: parent; name: modelData.pv; size: 28; color: Fz.acc }
                                    }
                                    FText { text: modelData.l; px: 12.5 }
                                }
                                MouseArea { id: giMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.addWidget(modelData.t) }
                            }
                        }
                    }
                }

                // inspector of the selected widget
                Card {
                    visible: win.selectedId !== ""
                    anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                    anchors.margins: 16
                    height: insp.implicitHeight + 24
                    readonly property var w: win.selected()
                    Column {
                        id: insp
                        x: 12; y: 12
                        width: parent.width - 24
                        spacing: 10
                        FText { text: parent.parent.w && win.types[parent.parent.w.type] ? win.types[parent.parent.w.type].tag : ""; px: 13; weight: Font.DemiBold }
                        Row {
                            width: parent.width
                            spacing: 10
                            FText { width: parent.width - 150 - 10 - 44 - 10; text: "Kích thước"; color: Fz.sub; px: 12.5; anchors.verticalCenter: parent.verticalCenter }
                            FSlider {
                                width: 150; anchors.verticalCenter: parent.verticalCenter
                                from: 50; to: 200
                                value: insp.parent.w ? Math.round((insp.parent.w.scale || 1) * 100) : 100
                                onMoved: (v) => win.update(win.selectedId, { scale: v / 100 })
                            }
                            FText { width: 44; mono: true; text: (insp.parent.w ? Math.round((insp.parent.w.scale || 1) * 100) : 100) + "%"; color: Fz.sub; px: 12.5; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignRight }
                        }
                        FBtn {
                            visible: insp.parent.w !== null && insp.parent.w.type === "image"
                            width: parent.width; icon: "w-image"; text: "Chọn ảnh"; iconSize: 14
                            onClicked: picker.open(win.selectedId)
                        }
                        Row {
                            width: parent.width
                            spacing: 6
                            FBtn { width: (parent.width - 6) / 2; icon: "w-move"; iconSize: 14; text: "Căn lưới"
                                onClicked: { let w = win.selected(); if (w) win.update(w.id, { x: Math.round(w.x / 40) * 40, y: Math.round(w.y / 40) * 40 }); } }
                            FBtn { width: (parent.width - 6) / 2; kind: "danger"; icon: "w-x"; iconSize: 14; text: "Gỡ"
                                onClicked: { win.widgets = win.widgets.filter(x => x.id !== win.selectedId); win.selectedId = ""; } }
                        }
                    }
                }
            }

            FMenu {
                id: deskMenu
                visible: false
                z: 50
                FMenuItem { icon: "t-image"; text: "Đổi hình nền"; hint: "Super Shift W"; onTriggered: { deskMenu.visible = false; Fz.open("wallpaper"); } }
                FMenuItem { icon: "t-widgets"; text: "Chỉnh widget"; onTriggered: { deskMenu.visible = false; win.editing = true; } }
                FMenuItem { icon: "t-display"; text: "Cài đặt màn hình"; onTriggered: { deskMenu.visible = false; Fz.open("guide", "display"); } }
                FMenuSep {}
                FMenuItem { icon: "t-terminal"; text: "Mở terminal"; hint: "Super T"; onTriggered: { deskMenu.visible = false; Quickshell.execDetached(["bash", "-c", "kitty || foot"]); } }
                FMenuItem { icon: "t-moon"; text: Fz.light ? "Chuyển sang chế độ tối" : "Chuyển sang chế độ sáng"; chevron: true; onTriggered: { deskMenu.visible = false; ZoneStyle.setMode("toggle"); } }
                FMenuSep {}
                FMenuItem { icon: "t-gear"; text: "Cài đặt Zone-C"; hint: "Super I"; onTriggered: { deskMenu.visible = false; Fz.open("guide"); } }
            }

            FFilePicker {
                id: picker
                z: 30
                property string targetId: ""
                function open(id) { targetId = id; show("Chọn ảnh cho khung ảnh", ["png", "jpg", "jpeg", "webp", "gif"], Quickshell.env("HOME") + "/Pictures"); }
                onAccepted: (path) => win.update(targetId, { path: path })
            }

            Shortcut { sequence: "Escape"; enabled: win.editing; onActivated: win.editing = false }
            Shortcut { sequence: "Delete"; enabled: win.editing && win.selectedId !== ""; onActivated: { win.widgets = win.widgets.filter(x => x.id !== win.selectedId); win.selectedId = ""; } }

            Component { id: heroC; HeroClock {} }
            Component { id: materialC; MaterialClock {} }
            Component { id: analogC; AnalogClock {} }
            Component { id: lumenC; LumenClock {} }
            Component { id: wFullC; WeatherFull {} }
            Component { id: wCompC; WeatherCompact {} }
            Component { id: mFullC; MusicFull {} }
            Component { id: mRoundC; MusicRound {} }
            Component { id: vizC; Visualizer {} }
            Component { id: batC; Battery {} }
            Component { id: resC; Resources {} }
            Component { id: userC; User {} }
            Component { id: imageC; ImageFrame {} }
            Component { id: todayC; Today {} }
        }
    }
}
