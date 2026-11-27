// Zone-C AI bot: a click-through overlay pinned on every workspace, shown while Claude Code runs.
// A boxy 2.5D robot: chamfered head with a dark screen (square eyes, a line mouth), a gem antenna,
// an ear ring and ice-cyan seams on graphite faces, a two-block body on a base plate. Frost palette.
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
        property string accentHex: ""
        // navy helmet and face, ice visor, ice-cyan glow (navy / white / cyan in the Lottie)
        readonly property color cBody: light ? "#213845" : "#1d2b36"
        // the boxy robot: graphite faces lit from the top-left, a near-black screen, ice-cyan seams
        readonly property color cHead: light ? "#5b676e" : "#3d464c"
        readonly property color cHeadTop: light ? "#6f7c83" : "#4c565d"
        readonly property color cHeadSide: light ? "#465157" : "#2b3237"
        readonly property color cBody2: light ? "#545f66" : "#363e44"
        readonly property color cBodySide: light ? "#414b51" : "#262c31"
        readonly property color cBaseTop: light ? "#3c464c" : "#20272b"
        readonly property color cBaseSide: light ? "#2f383d" : "#171c1f"
        readonly property color cScreen: light ? "#1a2226" : "#12181b"
        readonly property color cScreenRim: light ? "#2a3338" : "#1f262a"
        readonly property color cGap: light ? "#2d363b" : "#1b2125"
        readonly property color cRim: light ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(237 / 255, 243 / 255, 246 / 255, 0.22)
        readonly property color cVisor: accentHex && !light ? accentHex : (light ? "#eef4f7" : "#d6e6ec")
        readonly property color cGlow: light ? "#7fdcef" : "#8fe3f2"
        readonly property color cCollar: light ? "#2b4656" : "#3d5565"
        readonly property color cGreen: light ? "#8fd6ad" : "#a6dcbc"
        readonly property color cYellow: light ? "#f0d98c" : "#ecdcaa"
        readonly property color cText: light ? "#1f2d35" : "#edf3f6"
        readonly property color cBubble: light ? "#f4f8fa" : "#232d32"
        readonly property color cShadow: light ? Qt.rgba(31 / 255, 45 / 255, 53 / 255, 0.25) : Qt.rgba(0, 0, 0, 0.5)

        function readTheme() {
            let s = {}, c = {}
            try { s = JSON.parse(settingsFile.text()) } catch (e) {}
            try { c = JSON.parse(colorsFile.text()) } catch (e) {}
            const t = s.theme || {}, base = String((c.colors || c).base || "")
            // light only when the applied palette really is light (presets without one stay dark)
            const lum = /^#[0-9a-fA-F]{6}$/.test(base) ? (parseInt(base.slice(1, 3), 16) * 0.3 + parseInt(base.slice(3, 5), 16) * 0.59 + parseInt(base.slice(5, 7), 16) * 0.11) / 255 : 0
            light = t.mode === "light" && lum > 0.5
            accentHex = typeof t.accent === "string" && /^#[0-9a-fA-F]{6}$/.test(t.accent) ? t.accent : ""
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
        property bool sleepy: false    // idle for a long while
        property real lift: 0          // slow float, 0..1
        property real hop: 0           // jump, 0..1
        property real tilt: 0
        property real squint: 0        // the Lottie's loop: pill eyes ease into short slits, 0..1
        property real blink: 0         // quick full close, 0..1
        property real lookX: 0         // eyes glance, in icon units
        property real lookY: 0
        property real eyeScale: 1
        property real collarLit: 0     // collar arc: dark .. glowing, follows the squint like the Lottie
        property real sweep: 0         // light running along the collar while working, 0..1
        readonly property bool working: mode === "thinking" && !sleepy
        property int beat: 0           // working: ticks the equalizer bars
        readonly property color led: mode === "done" ? cGreen : mode === "ask" ? cYellow : sleepy ? cCollar : cGlow   // antenna ball

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
            mode = s
            sleepy = false
            dozeTimer.restart()
            tilt = 0; lookX = 0; lookY = 0
            if (s === "done") { doneAnim.restart(); doneTimer.restart() }
            else if (s === "ask") askAnim.restart()
        }
        Timer { id: doneTimer; interval: 6000; onTriggered: if (win.mode === "done") win.mode = "idle" }
        // nods off after a minute and a half with nothing to do
        Timer { id: dozeTimer; interval: 90000; running: win.mode === "idle"; onTriggered: win.sleepy = true }

        function rnd(a, b) { return a + Math.random() * (b - a) }

        SequentialAnimation on lift {
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: 1; duration: win.sleepy ? 2800 : 1700; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1; to: 0; duration: win.sleepy ? 2800 : 1700; easing.type: Easing.InOutSine }
        }
        // the Lottie's 3 s loop: hold, ease the eyes into slits while the collar lights, ease back
        SequentialAnimation {
            running: win.mode === "idle" && !win.sleepy
            loops: Animation.Infinite
            onRunningChanged: if (!running) { win.squint = 0; win.collarLit = 0 }
            PauseAnimation { duration: 1000 }
            ParallelAnimation {
                NumberAnimation { target: win; property: "squint"; to: 1; duration: 1000; easing.type: Easing.OutCubic }
                NumberAnimation { target: win; property: "collarLit"; to: 1; duration: 1000; easing.type: Easing.OutCubic }
            }
            ParallelAnimation {
                NumberAnimation { target: win; property: "squint"; to: 0; duration: 900; easing.type: Easing.InOutCubic }
                NumberAnimation { target: win; property: "collarLit"; to: 0; duration: 900; easing.type: Easing.InOutCubic }
            }
            PauseAnimation { duration: 1400 }
        }

        // ---------- everything visible, in one 270x300 box: moves inside the full-screen window while dragged ----------
        Item {
            id: stage
            width: 270; height: 300
            x: win.grab ? win.dragX : 0
            y: win.grab ? win.dragY : 0

            // ground shadow
            Rectangle {
                width: 96 - 22 * win.lift - 30 * win.hop
                height: 9
                radius: height / 2
                x: bot.x + bot.width / 2 - width / 2
                y: 286
                color: win.cShadow
                opacity: 0.7 - 0.25 * win.lift - 0.3 * win.hop
            }

            // ---------- the bot: a boxy 2.5D robot (front, top and right faces) in a 32-unit grid scaled by u ----------
            Item {
                id: bot
                readonly property real u: 4
                width: 32 * u; height: 36 * u
                x: 116
                y: 134 - 8 * win.lift - 40 * win.hop
                transform: Rotation { origin.x: bot.width / 2; origin.y: bot.height; angle: win.tilt }

                // the screen in the head's front face, where the eyes / equalizer live (units)
                readonly property real scrX: 5.2
                readonly property real scrY: 10.2
                readonly property real scrW: 17.6
                readonly property real scrH: 11
                readonly property real midX: scrX + scrW / 2

                RectangularShadow {
                    x: 3 * bot.u; y: 9 * bot.u; width: 26 * bot.u; height: 25 * bot.u
                    radius: 2 * bot.u; blur: 18; offset.y: 6
                    color: win.cShadow
                }

                // body, head and base: flat faces with chamfered corners; the glowing seams follow the state
                Canvas {
                    id: shell
                    anchors.fill: parent
                    readonly property real glow: win.mode === "thinking" ? 0.55 + 0.45 * Math.abs(Math.sin(win.sweep * Math.PI))
                                                                        : 0.5 + 0.5 * win.collarLit
                    onGlowChanged: requestPaint()
                    Connections { target: win; function onCHeadChanged() { shell.requestPaint() } function onLedChanged() { shell.requestPaint() } }
                    onPaint: {
                        const c = getContext("2d"); c.reset()
                        const u = bot.u, d = 4.4, dy = 1.8
                        function poly(pts, fill, stroke, lw) {
                            c.beginPath(); c.moveTo(pts[0][0] * u, pts[0][1] * u)
                            for (let i = 1; i < pts.length; i++) c.lineTo(pts[i][0] * u, pts[i][1] * u)
                            c.closePath()
                            if (fill) { c.fillStyle = fill; c.fill() }
                            if (stroke) { c.strokeStyle = stroke; c.lineWidth = (lw || 0.35) * u; c.stroke() }
                        }
                        function cham(x0, y0, x1, y1, k) {
                            return [[x0 + k, y0], [x1 - k, y0], [x1, y0 + k], [x1, y1 - k], [x1 - k, y1], [x0 + k, y1], [x0, y1 - k], [x0, y0 + k]]
                        }
                        function shift(pts) { return pts.map(p => [p[0] + d, p[1] - dy]) }
                        // a chamfered box: back silhouette (side colour), top band, front face
                        function box(x0, y0, x1, y1, k, top, side, front, rim) {
                            const f = cham(x0, y0, x1, y1, k)
                            poly(shift(f), side, rim, 0.3)
                            poly([[x1, y0 + k], [x1 + d, y0 + k - dy], [x1 + d, y1 - k - dy], [x1, y1 - k]], side)
                            poly([[x0 + k, y0], [x1 - k, y0], [x1 - k + d, y0 - dy], [x0 + k + d, y0 - dy]], top)
                            poly([[x1 - k, y0], [x1, y0 + k], [x1 + d, y0 + k - dy], [x1 - k + d, y0 - dy]], top)
                            poly(f, front, rim, 0.3)
                        }
                        function line(x0, y0, x1, y1, col, w) {
                            c.beginPath(); c.moveTo(x0 * u, y0 * u); c.lineTo(x1 * u, y1 * u)
                            c.strokeStyle = col; c.lineWidth = w * u; c.lineCap = "round"; c.stroke()
                        }
                        const seam = Qt.rgba(win.cGlow.r, win.cGlow.g, win.cGlow.b, shell.glow)

                        // base plate
                        poly([[1.5, 33.4], [27.5, 33.4], [31, 31.9], [5, 31.9]], win.cBaseTop, win.cRim, 0.3)
                        poly([[1.5, 33.4], [27.5, 33.4], [27.5, 34.6], [1.5, 34.6]], win.cBaseSide)
                        poly([[27.5, 33.4], [31, 31.9], [31, 33.1], [27.5, 34.6]], win.cBaseSide)

                        // body: two blocks with a seam between them
                        box(5, 23.4, 23, 32.8, 1.3, win.cHeadTop, win.cBodySide, win.cBody2, win.cRim)
                        line(14, 23.9, 14, 32.4, win.cGap, 0.5)
                        line(14, 24.4, 14, 31.9, seam, 0.28)
                        line(23 + d * 0.45, 24 - dy * 0.45, 23 + d * 0.45, 32 - dy * 0.45, seam, 0.24)

                        // head
                        box(3, 8, 25, 23, 1.8, win.cHeadTop, win.cHeadSide, win.cHead, win.cRim)
                        // seams on the side face: a vertical one near the front edge, a horizontal one through the ear
                        line(25 + 0.9, 8.6, 25 + 0.9, 22.4, seam, 0.26)
                        line(25 + 0.9, 15.5 - dy * 0.9 / d, 25 + d * 0.62 - 1.7, 15.5 - dy * (0.62 - 1.7 / d), seam, 0.26)
                        // ear: a ring on the side face
                        const ex = 25 + d * 0.62, ey = 15.5 - dy * 0.62
                        c.beginPath(); c.ellipse((ex - 1.7) * u, (ey - 3.1) * u, 3.4 * u, 6.2 * u)
                        c.fillStyle = win.cHeadSide; c.fill(); c.strokeStyle = win.cRim; c.lineWidth = 0.35 * u; c.stroke()
                        c.beginPath(); c.ellipse((ex - 1) * u, (ey - 1.9) * u, 2 * u, 3.8 * u)
                        c.strokeStyle = seam; c.lineWidth = 0.3 * u; c.stroke()

                        // screen
                        poly(cham(bot.scrX, bot.scrY, bot.scrX + bot.scrW, bot.scrY + bot.scrH, 1.1), win.cScreen, win.cScreenRim, 0.4)

                        // antenna: plate, stem and a faceted gem lit by the state colour
                        const ax = 14 + d / 2, ay = 8 - dy / 2
                        poly([[ax - 2.2, ay - 0.2], [ax + 2.2, ay - 0.2], [ax + 2.2, ay + 0.5], [ax - 2.2, ay + 0.5]], win.cHeadSide, win.cRim, 0.2)
                        line(ax, ay - 0.2, ax, ay - 3.4, win.cHeadSide, 0.8)
                        const gy = ay - 5
                        poly([[ax, gy - 1.9], [ax + 1.7, gy], [ax, gy + 1.9], [ax - 1.7, gy]], win.led, win.cRim, 0.2)
                        poly([[ax, gy - 1.9], [ax + 1.7, gy], [ax, gy]], Qt.lighter(win.led, 1.25))
                        poly([[ax, gy], [ax + 1.7, gy], [ax, gy + 1.9]], Qt.darker(win.led, 1.35))
                    }
                }

                // eyes: square, they blink, glance, squint and grow; hidden while working (the equalizer shows)
                Repeater {
                    model: [-3.4, 3.4]
                    delegate: Item {
                        id: eye
                        required property real modelData
                        readonly property real cx: (bot.midX + modelData + win.lookX * 0.8) * bot.u
                        readonly property real cy: (bot.scrY + 4.3 + win.lookY * 0.6) * bot.u
                        readonly property bool happy: win.mode === "done"
                        readonly property bool shut: win.sleepy
                        Rectangle {
                            visible: !eye.happy && !eye.shut && !win.working
                            readonly property real w: 2.9 * bot.u * win.eyeScale
                            readonly property real h: Math.max(0.4 * bot.u, 2.9 * (1 - 0.6 * win.squint) * (1 - 0.88 * win.blink) * bot.u * win.eyeScale)
                            width: w; height: h; radius: 0.5 * bot.u
                            x: eye.cx - w / 2; y: eye.cy - h / 2
                            color: win.cGlow
                        }
                        // happy ^ and sleeping _ eyes
                        Canvas {
                            visible: eye.happy || eye.shut
                            width: 4 * bot.u; height: 3 * bot.u
                            x: eye.cx - width / 2; y: eye.cy - height / 2
                            onVisibleChanged: requestPaint()
                            onPaint: {
                                const c = getContext("2d"); c.reset()
                                const u = bot.u
                                c.strokeStyle = win.cGlow; c.lineWidth = 0.8 * u; c.lineCap = "square"; c.lineJoin = "miter"
                                c.beginPath()
                                if (eye.happy) { c.moveTo(0.5 * u, 2.4 * u); c.lineTo(2 * u, 0.8 * u); c.lineTo(3.5 * u, 2.4 * u) }
                                else { c.moveTo(0.5 * u, 1.8 * u); c.lineTo(3.5 * u, 1.8 * u) }
                                c.stroke()
                            }
                        }
                    }
                }
                // mouth: a short line; a wider one when done, an "o" when it needs you
                Rectangle {
                    visible: !win.working && !win.sleepy
                    readonly property bool ask: win.mode === "ask"
                    width: (ask ? 1.8 : win.mode === "done" ? 5.4 : 4.2) * bot.u
                    height: (ask ? 1.8 : 0.55) * bot.u
                    radius: ask ? width / 2 : 0.2 * bot.u
                    color: ask ? "transparent" : win.cGlow
                    border.width: ask ? 0.45 * bot.u : 0; border.color: win.cGlow
                    x: (bot.midX + win.lookX * 0.5) * bot.u - width / 2
                    y: (bot.scrY + 8.2) * bot.u - height / 2
                    Behavior on width { NumberAnimation { duration: 160 } }
                }

                // working: the face becomes an equalizer, glowing bars dancing like a music visualiser
                Item {
                    id: eq
                    visible: opacity > 0
                    opacity: win.working ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    readonly property real bw: 1.45 * bot.u
                    readonly property real gap: 0.85 * bot.u
                    width: 6 * bw + 5 * gap; height: 8.4 * bot.u
                    x: bot.midX * bot.u - width / 2; y: (bot.scrY + bot.scrH / 2) * bot.u - height / 2
                    Repeater {
                        model: 6
                        delegate: Rectangle {
                            id: bar
                            required property int index
                            property real level: 0.3
                            width: eq.bw; radius: 0.3 * bot.u
                            height: Math.max(width, eq.height * (0.16 + 0.84 * level))
                            x: index * (eq.bw + eq.gap); y: (eq.height - height) / 2
                            color: win.cGlow
                            opacity: 0.7 + 0.3 * level
                            Behavior on level { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                            Connections {
                                target: win
                                function onBeatChanged() { bar.level = win.working ? win.rnd(0.15, [0.6, 0.85, 1, 1, 0.85, 0.6][bar.index]) : 0.3 }
                            }
                        }
                    }
                }
            }

            // speech bubble: a check mark drawn in when done, "Cần bạn nè!" when Claude waits on you
            Item {
                id: speech
                x: 6; y: 82
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
                    radius: 2; blur: 12; offset.y: 4
                    color: win.cShadow
                }
                // a slanted, sharp-cornered box with a tail dropping toward the bot
                Canvas {
                    id: bubbleShape
                    x: bubbleBox.x - 10; y: bubbleBox.y; width: bubbleBox.width + 20; height: bubbleBox.height + 16
                    onWidthChanged: requestPaint()
                    Connections { target: win; function onCBubbleChanged() { bubbleShape.requestPaint() } }
                    onPaint: {
                        const c = getContext("2d"); c.reset()
                        const w = width, h = bubbleBox.height, sk = 10
                        c.beginPath()
                        c.moveTo(sk + 0.5, 0.5); c.lineTo(w - 0.5, 0.5); c.lineTo(w - sk - 0.5, h)
                        c.lineTo(w - 22, h); c.lineTo(w - 20, h + 14); c.lineTo(w - 36, h)
                        c.lineTo(0.5, h); c.closePath()
                        c.fillStyle = win.cBubble; c.fill()
                        c.strokeStyle = win.cRim; c.lineWidth = 1; c.stroke()
                    }
                }
                Rectangle {
                    id: bubbleBox
                    width: speech.isDone ? 64 : Math.max(96, label.implicitWidth + 32)
                    x: speech.width - width
                    height: 42; radius: 0
                    color: "transparent"
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
                        onPaint: {
                            const c = getContext("2d"); c.reset()
                            const l1 = Math.hypot(7, 7), l2 = Math.hypot(14, 15), total = (l1 + l2) * p
                            c.lineCap = "round"; c.lineJoin = "round"
                            c.strokeStyle = win.cGreen; c.lineWidth = 4
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
                color: Qt.rgba(win.cGlow.r, win.cGlow.g, win.cGlow.b, 0.08)
                border.color: Qt.rgba(win.cGlow.r, win.cGlow.g, win.cGlow.b, 0.6); border.width: 2
                opacity: win.grab ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        // ---------- antenna light: colour and pulse by state ----------

        // ---------- working: an equalizer in place of the eyes, the collar light runs back and forth ----------
        SequentialAnimation {
            running: win.mode === "thinking"
            loops: Animation.Infinite
            onRunningChanged: { win.squint = 0; win.collarLit = running ? 0.25 : 0; win.sweep = 0.5 }
            NumberAnimation { target: win; property: "sweep"; from: 0.5; to: 1; duration: 450; easing.type: Easing.OutSine }
            NumberAnimation { target: win; property: "sweep"; from: 1; to: 0; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { target: win; property: "sweep"; from: 0; to: 0.5; duration: 450; easing.type: Easing.InSine }
        }
        Timer { interval: 140; repeat: true; running: win.working; triggeredOnStart: true; onTriggered: win.beat++ }

        // ---------- Claude Code reactions ----------
        // done: happy eyes, collar green, one small hop
        SequentialAnimation {
            id: doneAnim
            NumberAnimation { target: win; property: "hop"; to: 0.5; duration: 200; easing.type: Easing.OutQuad }
            NumberAnimation { target: win; property: "hop"; to: 0; duration: 380; easing.type: Easing.OutBounce }
        }
        // ask: big eyes
        SequentialAnimation {
            id: askAnim
            NumberAnimation { target: win; property: "eyeScale"; to: 1.22; duration: 280; easing.type: Easing.OutBack }
            PauseAnimation { duration: 2200 }
            NumberAnimation { target: win; property: "eyeScale"; to: 1; duration: 400; easing.type: Easing.InOutSine }
        }
        // picked up: a startled little hop and a double blink
        SequentialAnimation {
            id: grabbedAnim
            ScriptAction { script: doubleBlink.restart() }
            NumberAnimation { target: win; property: "hop"; to: 0.35; duration: 120; easing.type: Easing.OutQuad }
            NumberAnimation { target: win; property: "hop"; to: 0; duration: 300; easing.type: Easing.OutBounce }
        }

        // ---------- idle life ----------
        SequentialAnimation {
            id: blinkAnim
            NumberAnimation { target: win; property: "blink"; to: 1; duration: 70; easing.type: Easing.InQuad }
            NumberAnimation { target: win; property: "blink"; to: 0; duration: 130; easing.type: Easing.OutQuad }
        }
        SequentialAnimation {
            id: doubleBlink
            NumberAnimation { target: win; property: "blink"; to: 1; duration: 60 }
            NumberAnimation { target: win; property: "blink"; to: 0; duration: 100 }
            PauseAnimation { duration: 110 }
            NumberAnimation { target: win; property: "blink"; to: 1; duration: 60 }
            NumberAnimation { target: win; property: "blink"; to: 0; duration: 120 }
        }
        SequentialAnimation {
            id: glanceAnim
            property real toX: 1
            property real toY: 0
            ParallelAnimation {
                NumberAnimation { target: win; property: "lookX"; to: glanceAnim.toX; duration: 240; easing.type: Easing.OutCubic }
                NumberAnimation { target: win; property: "lookY"; to: glanceAnim.toY; duration: 240; easing.type: Easing.OutCubic }
            }
            PauseAnimation { duration: 1000 }
            ParallelAnimation {
                NumberAnimation { target: win; property: "lookX"; to: 0; duration: 300; easing.type: Easing.InOutCubic }
                NumberAnimation { target: win; property: "lookY"; to: 0; duration: 300; easing.type: Easing.InOutCubic }
            }
        }

        // eyes: their own rhythm
        Timer {
            interval: 2800; repeat: true; running: !win.sleepy && win.mode !== "done"
            onTriggered: {
                (Math.random() < 0.25 ? doubleBlink : blinkAnim).start()
                interval = win.rnd(2200, 5200)
            }
        }
        // a glance, a head tilt or a little hop now and then
        Timer {
            interval: 4200; repeat: true; running: win.mode === "idle" && !win.sleepy
            onTriggered: {
                const r = Math.random()
                if (r < 0.5) { glanceAnim.toX = Math.random() < 0.5 ? -1.4 : 1.4; glanceAnim.toY = 0; glanceAnim.restart() }
                interval = win.rnd(3200, 6000)
            }
        }
    }
}
