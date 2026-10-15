// Zone-C AI bot: a click-through overlay pinned on every workspace, shown while Claude Code runs.
// Drawn after the "AI bot Midas – talking start" Lottie: squircle frame, screen face with pill eyes,
// a sound-wave mouth while working and pixels drifting off the top. Coloured with the Frost palette.
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Effects

ShellRoot {
    PanelWindow {
        id: win
        anchors { bottom: true; right: true; top: win.grab; left: win.grab }
        margins { bottom: win.grab ? 0 : win.posBottom; right: win.grab ? 0 : win.posRight }
        implicitWidth: 270
        implicitHeight: 300
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "float-cat"
        // click-through, except while the move key is held
        property Region noInput: Region {}
        mask: grab ? null : noInput

        // ---------- position: dragged while grabbed, remembered across runs ----------
        property bool grab: false
        property real posRight: 24
        property real posBottom: 24
        property real dragX: 0
        property real dragY: 0

        function setGrab(on) {
            if (on === grab) return
            if (on) {
                const sw = win.screen ? win.screen.width : 1920, sh = win.screen ? win.screen.height : 1080
                dragX = sw - posRight - 270
                dragY = sh - posBottom - 300
            }
            grab = on
        }

        FileView {
            id: posFile
            path: Quickshell.env("HOME") + "/.local/state/float-cat/pos.json"
            blockLoading: true
            printErrors: false
            onLoaded: {
                try {
                    const p = JSON.parse(text())
                    if (typeof p.right === "number") win.posRight = p.right
                    if (typeof p.bottom === "number") win.posBottom = p.bottom
                } catch (e) {}
            }
        }
        function savePos() {
            posFile.setText(JSON.stringify({ right: Math.round(posRight), bottom: Math.round(posBottom) }))
        }

        // drag: the window covers the screen while grabbed, so only the box moves (no surface re-layout per step)
        MouseArea {
            anchors.fill: parent
            enabled: win.grab
            hoverEnabled: win.grab
            property real ox: 0
            property real oy: 0
            property bool onBot: false
            cursorShape: pressed && onBot ? Qt.ClosedHandCursor
                       : (containsMouse && mouseX >= stage.x && mouseX <= stage.x + stage.width && mouseY >= stage.y && mouseY <= stage.y + stage.height) ? Qt.OpenHandCursor : Qt.ArrowCursor
            onPressed: mouse => {
                onBot = mouse.x >= stage.x && mouse.x <= stage.x + stage.width && mouse.y >= stage.y && mouse.y <= stage.y + stage.height
                if (!onBot) { win.setGrab(false); return }   // click elsewhere: cancel
                ox = mouse.x - stage.x; oy = mouse.y - stage.y
                grabSafety.stop(); grabbedAnim.restart()
            }
            onPositionChanged: mouse => {
                if (!pressed || !onBot) return
                win.dragX = Math.max(0, Math.min(mouse.x - ox, width - stage.width))
                win.dragY = Math.max(0, Math.min(mouse.y - oy, height - stage.height))
            }
            onReleased: {
                if (!onBot) return
                win.posRight = width - win.dragX - stage.width
                win.posBottom = height - win.dragY - stage.height
                win.savePos()
                win.setGrab(false)
            }
        }

        // move mode ends by itself if the bot is never picked up
        Timer {
            id: grabSafety
            interval: 8000
            running: win.grab
            onTriggered: win.setGrab(false)
        }

        // ---------- theme: the Frost palette of zone-c (frost/Fz.qml), dark or light, with the chosen accent ----------
        property bool light: false
        property bool en: false
        property color accent: light ? "#2f5d72" : "#d6e6ec"
        readonly property color cCrust: light ? "#d6e2e8" : "#1c2428"
        readonly property color cBg: light ? "#e4ecf0" : "#151c20"
        readonly property color cText: light ? "#1f2d35" : "#edf3f6"
        readonly property color cGlow: light ? "#2f5d72" : "#9fd3e0"
        // frame stroke: bright at the top left, deeper at the bottom right (gold in the Lottie)
        readonly property color frameHi: light ? Qt.lighter(accent, 1.35) : Qt.lighter(accent, 1.12)
        readonly property color frameLo: light ? Qt.darker(accent, 1.25) : Qt.tint(cGlow, Qt.rgba(accent.r, accent.g, accent.b, 0.35))
        // screen: a warm-to-dark wash of the accent (brown-gold in the Lottie)
        readonly property color screenTop: Qt.tint(cCrust, Qt.rgba(accent.r, accent.g, accent.b, light ? 0.22 : 0.26))
        readonly property color screenBottom: Qt.tint(cBg, Qt.rgba(accent.r, accent.g, accent.b, light ? 0.08 : 0.07))

        function readTheme() {
            let s = {}, c = {}
            try { s = JSON.parse(settingsFile.text()) } catch (e) {}
            try { c = JSON.parse(colorsFile.text()) } catch (e) {}
            const t = s.theme || {}, base = String((c.colors || c).base || "")
            // light only when the applied palette really is light (presets without one stay dark)
            const lum = /^#[0-9a-fA-F]{6}$/.test(base) ? (parseInt(base.slice(1, 3), 16) * 0.3 + parseInt(base.slice(3, 5), 16) * 0.59 + parseInt(base.slice(5, 7), 16) * 0.11) / 255 : 0
            light = t.mode === "light" && lum > 0.5
            const a = typeof t.accent === "string" && /^#[0-9a-fA-F]{6}$/.test(t.accent) ? t.accent : ""
            accent = light ? "#2f5d72" : (a || "#d6e6ec")
            en = ((s.general || {}).language || "vi") !== "vi"
        }
        FileView {
            id: settingsFile
            path: Quickshell.env("HOME") + "/.config/zone-c/settings.json"
            watchChanges: true; printErrors: false
            onFileChanged: reload()
            onLoaded: win.readTheme()
        }
        FileView {
            id: colorsFile
            path: Quickshell.env("HOME") + "/.local/state/zone-c/qs_colors.json"
            watchChanges: true; printErrors: false
            onFileChanged: reload()
            onLoaded: win.readTheme()
        }

        // ---------- shared state ----------
        property string mode: "idle"   // idle | thinking | done | ask  (set by Claude Code hooks)
        property real lift: 0          // slow float, 0..1
        property real hop: 0           // jump, 0..1
        property real squash: 1        // y scale from the bottom, the Lottie's 100 -> 104.5 -> 90 -> 100 bounce
        property real talk: 0          // 0 = face with eyes, 1 = screen off and sound wave on
        property real closed: 0        // eyes: 0 open pills .. 1 flat dashes
        property real winkL: 0         // left eye alone, for a wink
        property real look: 0          // eyes glance left/right, -1..1
        property real tilt: 0

        // `qs ipc -p <this file> call cat state thinking|done|ask|idle`
        IpcHandler {
            target: "cat"
            function state(s: string): void { win.setMode(s) }
            function grab(on: string): void {
                win.setGrab(on === "toggle" ? !win.grab : on === "on")
            }
        }

        function setMode(s) {
            if (s === mode && s !== "done") return
            const was = mode
            mode = s
            if (s === "thinking") { stopTalk.stop(); startTalk.restart() }
            else {
                if (was === "thinking" || talk > 0) { startTalk.stop(); stopTalk.restart() }
                if (s === "done") { doneAnim.restart(); doneTimer.restart(); burst.restart() }
                else if (s === "ask") askAnim.restart()
            }
        }
        Timer { id: doneTimer; interval: 6000; onTriggered: if (win.mode === "done") win.mode = "idle" }

        function rnd(a, b) { return a + Math.random() * (b - a) }

        SequentialAnimation on lift {
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: 1; duration: 1600; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1; to: 0; duration: 1600; easing.type: Easing.InOutSine }
        }

        // ---------- everything visible, in one 270x300 box: moves inside the full-screen window while dragged ----------
        Item {
            id: stage
            width: 270; height: 300
            x: win.grab ? win.dragX : 0
            y: win.grab ? win.dragY : 0

            // ---------- ground shadow ----------
            Rectangle {
                width: 104 - 22 * win.lift - 30 * win.hop
                height: 10 - 2 * win.lift
                radius: height / 2
                x: bot.x + bot.width / 2 - width / 2
                y: 284
                color: win.light ? Qt.rgba(31 / 255, 45 / 255, 53 / 255, 1) : "#000000"
                opacity: (win.light ? 0.12 : 0.26) - 0.08 * win.lift - 0.1 * win.hop
            }

            // ---------- the bot: 150 x 141, the Lottie frame's proportions ----------
            Item {
                id: bot
                width: 150; height: 141
                x: 108
                y: 132 - 8 * win.lift - 44 * win.hop
                transform: [
                    Scale { origin.x: 75; origin.y: 141; yScale: win.squash; xScale: 1 + (1 - win.squash) * 0.35 },
                    Rotation { origin.x: 75; origin.y: 141; angle: win.tilt }
                ]

                // soft shadow + glass body behind the frame, so it reads on any wallpaper
                RectangularShadow {
                    anchors.fill: body
                    radius: body.radius; blur: 18; spread: 0; offset.y: 6
                    color: win.light ? Qt.rgba(31 / 255, 45 / 255, 53 / 255, 0.22) : Qt.rgba(0, 0, 0, 0.45)
                }
                Rectangle {
                    id: body
                    anchors.fill: parent; anchors.margins: 3
                    radius: 44
                    color: win.light ? Qt.rgba(244 / 255, 248 / 255, 250 / 255, 0.94) : Qt.rgba(21 / 255, 28 / 255, 32 / 255, 0.94)
                }

                // screen: fades out while the wave plays
                Rectangle {
                    id: screen
                    x: 21; y: 15; width: 108; height: 92
                    radius: 30
                    opacity: 1 - win.talk
                    gradient: Gradient {
                        GradientStop { position: 0; color: win.screenTop }
                        GradientStop { position: 1; color: win.screenBottom }
                    }
                    // faint glare on the top edge
                    Rectangle {
                        x: 14; y: 3; width: parent.width - 28; height: 1.5; radius: 1
                        color: Qt.rgba(1, 1, 1, win.light ? 0.5 : 0.08)
                    }
                }

                // squircle frame (the Lottie's hand-drawn outline), stroked with an accent gradient
                Canvas {
                    id: frame
                    anchors.fill: parent
                    antialiasing: true
                    onPaint: {
                        const c = getContext("2d"); c.reset()
                        const lw = 5.6, cx = width / 2, cy = height / 2, a = width / 2 - lw / 2 - 1, b = height / 2 - lw / 2 - 1, n = 4.2
                        c.beginPath()
                        // superellipse in polar form, so the points stay evenly spaced round the curve
                        for (let i = 0; i < 360; i++) {
                            const t = (i + 0.5) / 360 * Math.PI * 2, co = Math.cos(t), si = Math.sin(t)
                            const r = Math.pow(Math.pow(Math.abs(co / a), n) + Math.pow(Math.abs(si / b), n), -1 / n)
                            // a touch wider at the top, like the original drawing
                            const k = 1 + 0.012 * -si
                            const px = cx + r * co * k, py = cy + r * si
                            i === 0 ? c.moveTo(px, py) : c.lineTo(px, py)
                        }
                        c.closePath()
                        const g = c.createLinearGradient(0, 0, width, height)
                        g.addColorStop(0, win.frameHi); g.addColorStop(0.55, win.accent); g.addColorStop(1, win.frameLo)
                        c.strokeStyle = g; c.lineWidth = lw; c.lineJoin = "miter"   // round joins leave hairline nicks on the flat top
                        c.stroke()
                    }
                    Connections {
                        target: win
                        function onAccentChanged() { frame.requestPaint() }
                        function onLightChanged() { frame.requestPaint() }
                    }
                }

                // eyes: hollow pills that squeeze into dashes (blink, and before the wave starts)
                Repeater {
                    model: [-1, 1]
                    delegate: Rectangle {
                        id: eye
                        required property int modelData
                        readonly property real c: Math.max(win.closed, modelData < 0 ? win.winkL : 0)
                        readonly property real bw: 6
                        width: 25 + 14 * c
                        height: Math.max(bw + 1, 39 - 32 * c)
                        radius: Math.min(width, height) / 2
                        x: 75 + modelData * 30 - width / 2 + 4 * win.look
                        y: 58 - height / 2
                        color: c > 0.85 ? win.accent : "transparent"
                        border.width: bw; border.color: win.accent
                        opacity: 1 - Math.min(1, win.talk * 2)
                        visible: opacity > 0
                    }
                }

                // sound wave: bars bounce while working, then settle into a dotted line
                Row {
                    id: wave
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 58
                    spacing: 3.4
                    opacity: Math.min(1, win.talk * 1.6)
                    visible: opacity > 0
                    property real amp: 0      // 0 = flat dots, 1 = full bars
                    Repeater {
                        id: bars
                        model: 15
                        delegate: Rectangle {
                            required property int index
                            // tallest in the middle, like the Lottie's waveform
                            readonly property real env: 0.35 + 0.65 * Math.pow(Math.cos((index - 7) / 7 * Math.PI / 2), 1.4)
                            property real level: 0.4
                            width: 4.2
                            height: width + (38 * env * level) * wave.amp
                            y: -height / 2
                            radius: width / 2
                            color: win.accent
                            Behavior on level { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                        }
                    }
                    Timer {
                        interval: 130; repeat: true
                        running: wave.visible && win.mode === "thinking"
                        onTriggered: {
                            // a few loud peaks over a quieter bed
                            for (let i = 0; i < bars.count; i++) {
                                const it = bars.itemAt(i)
                                if (it) it.level = Math.random() < 0.18 ? win.rnd(0.75, 1) : win.rnd(0.12, 0.6)
                            }
                        }
                    }
                }
            }

            // pixels drifting up off the top of the bot while it works (and once when it is done)
            Repeater {
                model: 12
                delegate: Rectangle {
                    id: px
                    required property int index
                    property real p: 0
                    property real sx: 0
                    property real dx: 0
                    property real sz: 4
                    width: sz; height: sz * (index % 3 === 0 ? 0.55 : 1)
                    x: bot.x + sx + dx * p
                    y: bot.y + 8 - 64 * p
                    color: win.accent
                    opacity: (p < 0.15 ? p / 0.15 : 1 - (p - 0.15) / 0.85) * 0.75
                    visible: p > 0 && p < 1
                    function reseed() { sx = win.rnd(34, 116); dx = win.rnd(-14, 14); sz = win.rnd(3, 10) }
                    SequentialAnimation {
                        id: rise
                        loops: Animation.Infinite
                        running: win.mode === "thinking" && win.talk > 0.5
                        onRunningChanged: if (!running) px.p = 0
                        PauseAnimation { duration: px.index * 140 + win.rnd(0, 500) }
                        ScriptAction { script: px.reseed() }
                        NumberAnimation { target: px; property: "p"; from: 0; to: 1; duration: win.rnd(1100, 1700); easing.type: Easing.OutQuad }
                    }
                    Connections {
                        target: burst
                        function onStarted() { if (!rise.running) { px.reseed(); burstOne.restart() } }
                    }
                    SequentialAnimation {
                        id: burstOne
                        PauseAnimation { duration: px.index * 40 }
                        NumberAnimation { target: px; property: "p"; from: 0; to: 1; duration: 900; easing.type: Easing.OutQuad }
                        PropertyAction { target: px; property: "p"; value: 0 }
                    }
                }
            }
            SequentialAnimation { id: burst; PauseAnimation { duration: 1 } }

            // speech bubble: a check mark drawn in when done, "Cần bạn nè!" when Claude waits on you
            Item {
                id: speech
                x: 12; y: 66
                width: 140; height: 64
                transformOrigin: Item.BottomRight
                property bool on: win.mode === "done" || win.mode === "ask"
                property bool isDone: win.mode === "done"
                opacity: on ? 1 : 0
                scale: on ? 1 : 0.4
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 340; easing.type: Easing.OutBack } }
                visible: opacity > 0

                RectangularShadow {
                    anchors.fill: bubbleBox
                    radius: bubbleBox.radius; blur: 12; offset.y: 4
                    color: win.light ? Qt.rgba(31 / 255, 45 / 255, 53 / 255, 0.18) : Qt.rgba(0, 0, 0, 0.4)
                }
                // tail toward the bot
                Rectangle {
                    x: bubbleBox.x + bubbleBox.width - 22; y: 30
                    width: 14; height: 14; rotation: 45
                    color: bubbleBox.color; border.color: bubbleBox.border.color; border.width: 1
                }
                Rectangle {
                    id: bubbleBox
                    width: speech.isDone ? 64 : Math.max(96, label.implicitWidth + 32)
                    x: speech.width - width
                    height: 42; radius: 21
                    color: win.light ? "#f4f8fa" : "#232d32"
                    border.color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.45); border.width: 1
                    Behavior on width { NumberAnimation { duration: 200 } }

                    Text {
                        id: label
                        anchors.centerIn: parent
                        visible: !speech.isDone
                        text: win.en ? "Need you!" : "Cần bạn nè!"
                        color: win.cText
                        font.family: "Geist"; font.pixelSize: 15; font.weight: Font.DemiBold
                    }

                    // check mark, drawn stroke by stroke
                    Canvas {
                        id: check
                        anchors.centerIn: parent
                        width: 30; height: 24
                        visible: speech.isDone
                        property real p: 0
                        onPChanged: requestPaint()
                        Connections { target: win; function onAccentChanged() { check.requestPaint() } }
                        onPaint: {
                            const c = getContext("2d"); c.reset()
                            const l1 = Math.hypot(7, 7), l2 = Math.hypot(14, 15), total = (l1 + l2) * p
                            c.lineCap = "round"; c.lineJoin = "round"
                            c.strokeStyle = win.accent; c.lineWidth = 4
                            c.beginPath(); c.moveTo(5, 12)
                            if (total <= l1) c.lineTo(5 + 7 * total / l1, 12 + 7 * total / l1)
                            else { const t = (total - l1) / l2; c.lineTo(12, 19); c.lineTo(12 + 14 * t, 19 - 15 * t) }
                            c.stroke()
                        }
                        SequentialAnimation {
                            running: speech.isDone
                            PropertyAction { target: check; property: "p"; value: 0 }
                            PauseAnimation { duration: 180 }
                            NumberAnimation { target: check; property: "p"; to: 1; duration: 380; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }

            // shows the bot can be moved
            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 24
                color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.08)
                border.color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.6); border.width: 2
                opacity: win.grab ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        // ---------- the Lottie's moves ----------
        // body bounce: 100 -> 104.5 -> 90 -> 100 (5 frames each at 30 fps)
        SequentialAnimation {
            id: bounce
            NumberAnimation { target: win; property: "squash"; to: 1.045; duration: 165; easing.type: Easing.OutQuad }
            NumberAnimation { target: win; property: "squash"; to: 0.9; duration: 165; easing.type: Easing.InOutQuad }
            NumberAnimation { target: win; property: "squash"; to: 1; duration: 200; easing.type: Easing.OutBack }
        }
        // talking start: eyes squeeze to dashes, bounce, the screen goes dark and the wave rises out of the dashes
        SequentialAnimation {
            id: startTalk
            ScriptAction { script: { blinkAnim.stop(); bounce.restart() } }
            NumberAnimation { target: win; property: "closed"; to: 1; duration: 230; easing.type: Easing.InOutQuad }
            ParallelAnimation {
                NumberAnimation { target: win; property: "talk"; to: 1; duration: 260; easing.type: Easing.InOutQuad }
                NumberAnimation { target: wave; property: "amp"; from: 0; to: 1; duration: 420; easing.type: Easing.OutBack }
            }
        }
        // talking end: the wave flattens to a dotted line, the screen returns and the eyes open again
        SequentialAnimation {
            id: stopTalk
            NumberAnimation { target: wave; property: "amp"; to: 0; duration: 260; easing.type: Easing.InQuad }
            PauseAnimation { duration: 120 }
            NumberAnimation { target: win; property: "talk"; to: 0; duration: 260; easing.type: Easing.InOutQuad }
            ScriptAction { script: bounce.restart() }
            NumberAnimation { target: win; property: "closed"; to: 0; duration: 260; easing.type: Easing.OutBack }
        }
        // the Lottie keeps bouncing while it talks: 100 <-> 104.5 every 6 frames
        SequentialAnimation {
            running: win.mode === "thinking" && win.talk > 0.9
            loops: Animation.Infinite
            NumberAnimation { target: win; property: "squash"; to: 1.045; duration: 200; easing.type: Easing.InOutSine }
            NumberAnimation { target: win; property: "squash"; to: 1; duration: 200; easing.type: Easing.InOutSine }
            onRunningChanged: if (!running && !bounce.running) win.squash = 1
        }

        // ---------- Claude Code reactions ----------
        // done: a happy hop and a wink
        SequentialAnimation {
            id: doneAnim
            PauseAnimation { duration: win.talk > 0 ? 900 : 0 }
            NumberAnimation { target: win; property: "hop"; to: 1; duration: 220; easing.type: Easing.OutQuad }
            NumberAnimation { target: win; property: "hop"; to: 0; duration: 420; easing.type: Easing.OutBounce }
            ScriptAction { script: { bounce.restart(); winkAnim.restart() } }
            PauseAnimation { duration: 700 }
            NumberAnimation { target: win; property: "hop"; to: 0.5; duration: 180; easing.type: Easing.OutQuad }
            NumberAnimation { target: win; property: "hop"; to: 0; duration: 360; easing.type: Easing.OutBounce }
        }
        // ask: curious tilt and a double blink
        SequentialAnimation {
            id: askAnim
            PauseAnimation { duration: win.talk > 0 ? 900 : 0 }
            ScriptAction { script: doubleBlinkAnim.restart() }
            NumberAnimation { target: win; property: "hop"; to: 0.3; duration: 150; easing.type: Easing.OutQuad }
            NumberAnimation { target: win; property: "hop"; to: 0; duration: 300; easing.type: Easing.OutBounce }
            NumberAnimation { target: win; property: "tilt"; to: 7; duration: 260; easing.type: Easing.OutBack }
            PauseAnimation { duration: 1100 }
            NumberAnimation { target: win; property: "tilt"; to: 0; duration: 380; easing.type: Easing.InOutSine }
        }
        // picked up: a startled little hop
        SequentialAnimation {
            id: grabbedAnim
            ScriptAction { script: doubleBlinkAnim.restart() }
            NumberAnimation { target: win; property: "hop"; to: 0.35; duration: 120; easing.type: Easing.OutQuad }
            NumberAnimation { target: win; property: "hop"; to: 0; duration: 300; easing.type: Easing.OutBounce }
        }

        // ---------- idle life ----------
        SequentialAnimation {
            id: blinkAnim
            NumberAnimation { target: win; property: "closed"; to: 1; duration: 80; easing.type: Easing.InQuad }
            NumberAnimation { target: win; property: "closed"; to: 0; duration: 140; easing.type: Easing.OutQuad }
        }
        SequentialAnimation {
            id: doubleBlinkAnim
            NumberAnimation { target: win; property: "closed"; to: 1; duration: 70 }
            NumberAnimation { target: win; property: "closed"; to: 0; duration: 110 }
            PauseAnimation { duration: 120 }
            NumberAnimation { target: win; property: "closed"; to: 1; duration: 70 }
            NumberAnimation { target: win; property: "closed"; to: 0; duration: 130 }
        }
        SequentialAnimation {
            id: winkAnim
            NumberAnimation { target: win; property: "winkL"; to: 1; duration: 110 }
            PauseAnimation { duration: 600 }
            NumberAnimation { target: win; property: "winkL"; to: 0; duration: 180 }
        }
        SequentialAnimation {
            id: lookAnim
            property real to: 1
            NumberAnimation { target: win; property: "look"; to: lookAnim.to; duration: 220; easing.type: Easing.OutQuad }
            PauseAnimation { duration: 900 }
            NumberAnimation { target: win; property: "look"; to: 0; duration: 260; easing.type: Easing.InOutQuad }
        }

        // eyes: their own rhythm (only while the face shows)
        Timer {
            interval: 3000; running: win.talk === 0; repeat: true
            onTriggered: {
                if (!startTalk.running && !stopTalk.running)
                    (Math.random() < 0.25 ? doubleBlinkAnim : blinkAnim).start()
                interval = win.rnd(2200, 5500)
            }
        }
        // a glance or a little bounce now and then
        Timer {
            interval: 4500; running: win.talk === 0 && win.mode === "idle"; repeat: true
            onTriggered: {
                const r = Math.random()
                if (r < 0.45) { lookAnim.to = Math.random() < 0.5 ? -1 : 1; lookAnim.restart() }
                else if (r < 0.65) bounce.restart()
                else if (r < 0.75) winkAnim.restart()
                interval = win.rnd(3500, 6500)
            }
        }
    }
}
