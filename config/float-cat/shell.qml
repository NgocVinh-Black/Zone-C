// Zone-C AI bot: a click-through overlay pinned on every workspace, shown while Claude Code runs.
// Drawn after the "Icon bot" Lottie: a round helmet with an antenna and ear pods, a visor ring around
// a dark face with two pill eyes, and a collar arc that lights up. Coloured with the Frost palette.
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

            // ---------- the bot, drawn in the Lottie's 32-unit grid scaled by u ----------
            Item {
                id: bot
                readonly property real u: 4
                width: 32 * u; height: 36 * u
                x: 116
                y: 134 - 8 * win.lift - 40 * win.hop
                transform: Rotation { origin.x: bot.width / 2; origin.y: bot.height; angle: win.tilt }

                RectangularShadow {
                    x: 2 * bot.u; y: 6 * bot.u; width: 28 * bot.u; height: 26 * bot.u
                    radius: width / 2; blur: 16; offset.y: 5
                    color: win.cShadow
                }

                // antenna: stem + ball
                Rectangle { x: 15.25 * bot.u; y: 2.4 * bot.u; width: 1.5 * bot.u; height: 3.2 * bot.u; color: win.cBody }
                Rectangle { x: 14 * bot.u; y: 4.6 * bot.u; width: 4 * bot.u; height: 1.6 * bot.u; radius: 0.6 * bot.u; color: win.cBody }
                Rectangle {
                    id: ball
                    width: 3.4 * bot.u; height: width; radius: width / 2
                    x: 16 * bot.u - width / 2; y: 1.6 * bot.u - height / 2
                    color: win.led
                    border.width: 1; border.color: win.cRim
                    Behavior on color { ColorAnimation { duration: 250 } }
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * 2.2; height: width; radius: width / 2
                        color: win.led; opacity: ledPulse.v * 0.3
                        QtObject { id: ledPulse; property real v: 0.5 }
                    }
                }

                // ear pods
                Rectangle { x: 0; y: 15.1 * bot.u; width: 7 * bot.u; height: 6.7 * bot.u; radius: 3.35 * bot.u; color: win.cBody; border.width: 1; border.color: win.cRim }
                Rectangle { x: 25 * bot.u; y: 15.1 * bot.u; width: 7 * bot.u; height: 6.7 * bot.u; radius: 3.35 * bot.u; color: win.cBody; border.width: 1; border.color: win.cRim }

                // helmet: a disc cut flat at y = 24
                Item {
                    x: 0; y: 0; width: bot.width; height: 24 * bot.u
                    clip: true
                    Rectangle {
                        width: 28.44 * bot.u; height: width; radius: width / 2
                        x: 16 * bot.u - width / 2; y: 18.44 * bot.u - height / 2 + 0.3 * bot.u
                        color: win.cBody; border.width: 1; border.color: win.cRim
                    }
                }
                // visor ring, then the face inside it
                Rectangle {
                    width: 24.9 * bot.u; height: 20.7 * bot.u; radius: height / 2
                    x: 16 * bot.u - width / 2; y: 19.67 * bot.u - height / 2
                    color: win.cVisor
                }
                Rectangle {
                    id: face
                    width: 21.33 * bot.u; height: 17.33 * bot.u; radius: height / 2
                    x: 16 * bot.u - width / 2; y: 20.1 * bot.u - height / 2
                    color: win.cBody
                    // glare across the top of the face
                    Rectangle {
                        x: parent.width * 0.22; y: parent.height * 0.1; width: parent.width * 0.56; height: 1.2 * bot.u; radius: height / 2
                        color: Qt.rgba(1, 1, 1, 0.06)
                    }
                }

                // eyes: pills (3.56 x 5.33) that squint to slits (3 x 2), blink, glance and grow
                Repeater {
                    model: [11.56, 20.44]
                    delegate: Item {
                        id: eye
                        required property real modelData
                        readonly property real cx: (modelData + win.lookX) * bot.u
                        readonly property real cy: (20 + win.lookY) * bot.u
                        readonly property bool happy: win.mode === "done"
                        readonly property bool shut: win.sleepy
                        Rectangle {
                            visible: !eye.happy && !eye.shut
                            readonly property real w: (3.56 - 0.56 * win.squint) * bot.u * win.eyeScale
                            readonly property real h: Math.max(0.5, (5.33 - 3.33 * win.squint) * (1 - 0.88 * win.blink)) * bot.u * win.eyeScale
                            width: w; height: h; radius: Math.min(w, h) / 2
                            x: eye.cx - w / 2; y: eye.cy - h / 2
                            color: win.cGlow
                            // soft glow around the pill
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + 0.9 * bot.u; height: parent.height + 0.9 * bot.u; radius: Math.min(width, height) / 2
                                color: "transparent"; border.width: 0.45 * bot.u
                                border.color: Qt.rgba(win.cGlow.r, win.cGlow.g, win.cGlow.b, 0.22)
                            }
                        }
                        // happy ^ and sleeping _ eyes
                        Canvas {
                            visible: eye.happy || eye.shut
                            width: 5 * bot.u; height: 4 * bot.u
                            x: eye.cx - width / 2; y: eye.cy - height / 2
                            onVisibleChanged: requestPaint()
                            onPaint: {
                                const c = getContext("2d"); c.reset()
                                c.strokeStyle = win.cGlow; c.lineWidth = 1.1 * bot.u; c.lineCap = "round"
                                c.beginPath()
                                if (eye.happy) { c.moveTo(0.6 * bot.u, 3.2 * bot.u); c.quadraticCurveTo(2.5 * bot.u, -0.6 * bot.u, 4.4 * bot.u, 3.2 * bot.u) }
                                else { c.moveTo(0.6 * bot.u, 2 * bot.u); c.quadraticCurveTo(2.5 * bot.u, 3.2 * bot.u, 4.4 * bot.u, 2 * bot.u) }
                                c.stroke()
                            }
                        }
                    }
                }

                // collar arc under the face (layer "Subtract" 2 in the Lottie), lit and swept by a light
                Canvas {
                    id: collar
                    x: 4 * bot.u; y: 28.6 * bot.u; width: 24 * bot.u; height: 7 * bot.u
                    readonly property color base: Qt.tint(win.cCollar, Qt.rgba(win.cGlow.r, win.cGlow.g, win.cGlow.b, win.collarLit))
                    readonly property color tip: win.mode === "done" ? win.cGreen : win.mode === "ask" ? win.cYellow : win.cGlow
                    onBaseChanged: requestPaint()
                    onTipChanged: requestPaint()
                    Connections { target: win; function onSweepChanged() { if (win.mode === "thinking") collar.requestPaint() } }
                    onPaint: {
                        const c = getContext("2d"); c.reset()
                        const u = bot.u, w = width
                        // crescent: outer arc down to y 6.22, inner arc to y 4.44 (in units, from the top of this box)
                        c.beginPath()
                        c.moveTo(0, 0.3 * u); c.quadraticCurveTo(w / 2, 12.4 * u, w, 0.3 * u)
                        c.lineTo(w - 1.66 * u, 0.3 * u); c.quadraticCurveTo(w / 2, 8.8 * u, 1.66 * u, 0.3 * u)
                        c.closePath()
                        c.fillStyle = (win.mode === "done" || win.mode === "ask") ? tip : base
                        c.fill()
                        if (win.mode === "thinking") {
                            // a bright segment runs along the arc
                            c.save(); c.clip()
                            const t = win.sweep, px = w * t, py = (0.3 + 2 * t * (1 - t) * 11.4) * u
                            const g = c.createRadialGradient(px, py, 0, px, py, 5 * u)
                            g.addColorStop(0, win.cGlow); g.addColorStop(1, "transparent")
                            c.fillStyle = g; c.fillRect(0, 0, w, height)
                            c.restore()
                        }
                    }
                }
            }

            // thought bubble: three dots typing while Claude works
            Item {
                id: thought
                x: bot.x + bot.width - 52; y: bot.y - 42
                width: 58; height: 44
                opacity: win.mode === "thinking" ? 1 : 0
                scale: win.mode === "thinking" ? 1 : 0.5
                transformOrigin: Item.BottomLeft
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                Rectangle { x: 2; y: 36; width: 6; height: 6; radius: 3; color: win.cBubble; border.color: win.cRim; border.width: 1 }
                Rectangle { x: 9; y: 26; width: 9; height: 9; radius: 4.5; color: win.cBubble; border.color: win.cRim; border.width: 1 }
                Rectangle {
                    x: 14; y: 0; width: 44; height: 24; radius: 12
                    color: win.cBubble; border.color: win.cRim; border.width: 1
                    Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Repeater {
                            model: 3
                            delegate: Rectangle {
                                id: dot
                                required property int index
                                width: 6; height: 6; radius: 3
                                color: win.cGlow
                                SequentialAnimation on y {
                                    loops: Animation.Infinite; running: thought.visible
                                    PauseAnimation { duration: dot.index * 140 }
                                    NumberAnimation { to: -4; duration: 200; easing.type: Easing.OutQuad }
                                    NumberAnimation { to: 0; duration: 240; easing.type: Easing.InQuad }
                                    PauseAnimation { duration: 560 - dot.index * 140 }
                                }
                            }
                        }
                    }
                }
            }

            // "z Z" while dozing
            Repeater {
                model: 2
                delegate: Text {
                    id: zz
                    required property int index
                    text: index === 0 ? "z" : "Z"
                    color: win.cGlow
                    font.family: "Geist"; font.pixelSize: 15 + index * 5; font.weight: Font.DemiBold
                    property real p: 0
                    x: bot.x + bot.width - 14 + 16 * p
                    y: bot.y + 10 - 34 * p
                    opacity: win.sleepy ? Math.sin(p * Math.PI) : 0
                    SequentialAnimation on p {
                        loops: Animation.Infinite; running: win.sleepy
                        PauseAnimation { duration: zz.index * 1300 }
                        NumberAnimation { from: 0; to: 1; duration: 2600; easing.type: Easing.OutQuad }
                    }
                }
            }

            // confetti when done
            Repeater {
                model: [
                    { dx: -70, dy: -40, c: 0 }, { dx: 64, dy: -46, c: 1 }, { dx: -40, dy: -70, c: 2 },
                    { dx: 40, dy: -74, c: 0 }, { dx: -86, dy: 6, c: 1 }, { dx: 84, dy: -4, c: 2 },
                    { dx: -12, dy: -84, c: 1 }, { dx: 18, dy: -86, c: 2 }
                ]
                delegate: Rectangle {
                    id: bit
                    required property var modelData
                    required property int index
                    property real p: 0
                    width: index % 3 === 0 ? 6 : 5; height: index % 3 === 0 ? 6 : 9; radius: index % 3 === 0 ? 3 : 1.5
                    color: [win.cGlow, win.cYellow, win.cGreen][modelData.c]
                    x: bot.x + bot.width / 2 + modelData.dx * p
                    y: bot.y + 10 + modelData.dy * p + 30 * p * p
                    rotation: 260 * p * (index % 2 ? 1 : -1)
                    opacity: p > 0 && p < 1 ? 1 - p * p : 0
                    NumberAnimation { id: fly; target: bit; property: "p"; from: 0; to: 1; duration: 1200; easing.type: Easing.OutCubic }
                    Connections { target: doneAnim; function onStarted() { fly.restart() } }
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
                    radius: bubbleBox.radius; blur: 12; offset.y: 4
                    color: win.cShadow
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
                    color: win.cBubble
                    border.color: win.cRim; border.width: 1
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
        SequentialAnimation {
            loops: Animation.Infinite; running: true
            NumberAnimation { target: ledPulse; property: "v"; to: 1; duration: win.mode === "thinking" || win.mode === "ask" ? 380 : 1400; easing.type: Easing.InOutSine }
            NumberAnimation { target: ledPulse; property: "v"; to: 0; duration: win.mode === "thinking" || win.mode === "ask" ? 380 : 1400; easing.type: Easing.InOutSine }
        }

        // ---------- working: eyes narrow and dart about, the collar light runs back and forth ----------
        SequentialAnimation {
            running: win.mode === "thinking"
            loops: Animation.Infinite
            onRunningChanged: { win.squint = running ? 0.45 : 0; win.collarLit = running ? 0.25 : 0 }
            NumberAnimation { target: win; property: "sweep"; from: 0; to: 1; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { target: win; property: "sweep"; from: 1; to: 0; duration: 900; easing.type: Easing.InOutSine }
        }
        Timer {
            interval: 700; repeat: true; running: win.mode === "thinking"
            onTriggered: {
                // glance up and to the sides as if reading
                lookAnim.toX = win.rnd(-1.4, 1.4); lookAnim.toY = win.rnd(-1.2, 0.2)
                lookAnim.restart()
                interval = win.rnd(500, 1000)
            }
        }
        ParallelAnimation {
            id: lookAnim
            property real toX: 0
            property real toY: 0
            NumberAnimation { target: win; property: "lookX"; to: lookAnim.toX; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: win; property: "lookY"; to: lookAnim.toY; duration: 220; easing.type: Easing.OutCubic }
        }

        // ---------- Claude Code reactions ----------
        // done: happy eyes, collar green, a bouncy double hop and confetti
        SequentialAnimation {
            id: doneAnim
            NumberAnimation { target: win; property: "hop"; to: 1; duration: 230; easing.type: Easing.OutQuad }
            NumberAnimation { target: win; property: "hop"; to: 0; duration: 420; easing.type: Easing.OutBounce }
            PauseAnimation { duration: 200 }
            NumberAnimation { target: win; property: "hop"; to: 0.5; duration: 180; easing.type: Easing.OutQuad }
            NumberAnimation { target: win; property: "hop"; to: 0; duration: 360; easing.type: Easing.OutBounce }
        }
        // ask: tilt, big eyes, a little hop
        SequentialAnimation {
            id: askAnim
            ParallelAnimation {
                NumberAnimation { target: win; property: "tilt"; to: -9; duration: 280; easing.type: Easing.OutBack }
                NumberAnimation { target: win; property: "eyeScale"; to: 1.22; duration: 280; easing.type: Easing.OutBack }
            }
            NumberAnimation { target: win; property: "hop"; to: 0.3; duration: 150; easing.type: Easing.OutQuad }
            NumberAnimation { target: win; property: "hop"; to: 0; duration: 300; easing.type: Easing.OutBounce }
            PauseAnimation { duration: 1800 }
            ParallelAnimation {
                NumberAnimation { target: win; property: "tilt"; to: 0; duration: 400; easing.type: Easing.InOutSine }
                NumberAnimation { target: win; property: "eyeScale"; to: 1; duration: 400; easing.type: Easing.InOutSine }
            }
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
        SequentialAnimation {
            id: tiltAnim
            property real to: 7
            NumberAnimation { target: win; property: "tilt"; to: tiltAnim.to; duration: 300; easing.type: Easing.OutBack }
            PauseAnimation { duration: 900 }
            NumberAnimation { target: win; property: "tilt"; to: 0; duration: 380; easing.type: Easing.InOutSine }
        }
        SequentialAnimation {
            id: idleHop
            NumberAnimation { target: win; property: "hop"; to: 0.35; duration: 170; easing.type: Easing.OutQuad }
            NumberAnimation { target: win; property: "hop"; to: 0; duration: 340; easing.type: Easing.OutBounce }
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
                if (r < 0.45) { glanceAnim.toX = win.rnd(-1.5, 1.5); glanceAnim.toY = win.rnd(-1, 0.6); glanceAnim.restart() }
                else if (r < 0.7) { tiltAnim.to = Math.random() < 0.5 ? -7 : 7; tiltAnim.restart() }
                else if (r < 0.85) idleHop.restart()
                interval = win.rnd(3200, 6000)
            }
        }
    }
}
