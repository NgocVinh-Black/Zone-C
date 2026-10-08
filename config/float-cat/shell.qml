// Zone-C cat: a click-through overlay pinned on every workspace.
// The picture is split into layers (src/build-layers.sh) so the cloud, head, ears,
// whiskers, mouth, hand, cape and bolts each move on their own.
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

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
                earLTwitch.restart(); earRTwitch.restart()
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
        function clampPos() {
            const sw = win.screen ? win.screen.width : 1920, sh = win.screen ? win.screen.height : 1080
            posRight = Math.max(0, Math.min(posRight, sw - implicitWidth))
            posBottom = Math.max(0, Math.min(posBottom, sh - implicitHeight))
        }

        // drag: the window covers the screen while grabbed, so only the box moves (no surface re-layout per step)
        MouseArea {
            anchors.fill: parent
            enabled: win.grab
            hoverEnabled: win.grab
            property real ox: 0
            property real oy: 0
            property bool onCat: false
            cursorShape: pressed && onCat ? Qt.ClosedHandCursor
                       : (containsMouse && mouseX >= stage.x && mouseX <= stage.x + stage.width && mouseY >= stage.y && mouseY <= stage.y + stage.height) ? Qt.OpenHandCursor : Qt.ArrowCursor
            onPressed: mouse => {
                onCat = mouse.x >= stage.x && mouse.x <= stage.x + stage.width && mouse.y >= stage.y && mouse.y <= stage.y + stage.height
                if (!onCat) { win.setGrab(false); return }   // click elsewhere: cancel
                ox = mouse.x - stage.x; oy = mouse.y - stage.y
                grabSafety.stop(); grabbedAnim.restart()
            }
            onPositionChanged: mouse => {
                if (!pressed || !onCat) return
                win.dragX = Math.max(0, Math.min(mouse.x - ox, width - stage.width))
                win.dragY = Math.max(0, Math.min(mouse.y - oy, height - stage.height))
            }
            onReleased: {
                if (!onCat) return
                win.posRight = width - win.dragX - stage.width
                win.posBottom = height - win.dragY - stage.height
                win.savePos()
                win.setGrab(false)
            }
        }

        // move mode ends by itself if the cat is never picked up
        Timer {
            id: grabSafety
            interval: 8000
            running: win.grab
            onTriggered: win.setGrab(false)
        }


        // ---------- theme: zone-c colours -> tinted layers (src/tint.py) ----------
        property string layerDir: ""
        property color cOutline: "#3f5b67"
        property color cMid: "#8eb3c1"
        property color cAccent: "#b6d8e4"
        property color cLight: "#eef8fb"
        property color cShadow: "#252f34"

        FileView {
            id: themeFile
            path: Quickshell.env("HOME") + "/.local/state/zone-c/qs_colors.json"
            watchChanges: true
            printErrors: false
            onFileChanged: tintProc.running = true
            onLoaded: tintProc.running = true
            onLoadFailed: tintProc.running = true
        }
        Process {
            id: tintProc
            command: ["python3", "-I", Quickshell.env("HOME") + "/.local/share/float-cat/src/tint.py"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        const t = JSON.parse(this.text)
                        win.cOutline = t.outline; win.cMid = t.mid; win.cAccent = t.accent
                        win.cLight = t.light; win.cShadow = t.shadow
                        win.layerDir = t.dir
                    } catch (e) {}
                }
            }
        }

        // ---------- shared state ----------
        property real lift: 0          // cloud + cat float, 0..1
        property real breath: 0        // cat breathing, 0..1
        property string face: "open"   // open | blink | wink
        property string mode: "idle"   // idle | thinking | done | ask  (set by Claude Code hooks)
        property real hop: 0           // extra jump, 0..1

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
            if (s === "done") { doneAnim.restart(); doneTimer.restart() }
            else if (s === "ask") askAnim.restart()
        }
        Timer { id: doneTimer; interval: 6000; onTriggered: if (win.mode === "done") win.mode = "idle" }

        function rnd(a, b) { return a + Math.random() * (b - a) }

        SequentialAnimation on lift {
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: 1; duration: 1500; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1; to: 0; duration: 1500; easing.type: Easing.InOutSine }
        }
        SequentialAnimation on breath {
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: 1; duration: 1700; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1; to: 0; duration: 2100; easing.type: Easing.InOutSine }
        }

        // ---------- everything visible, in one 270x300 box: moves inside the full-screen window while dragged ----------
        Item {
            id: stage
            width: 270; height: 300
            x: win.grab ? win.dragX : 0
            y: win.grab ? win.dragY : 0

            // ---------- ground shadow ----------
            Rectangle {
                width: 120 - 30 * win.lift
                height: 12 - 3 * win.lift
                radius: height / 2
                x: art.x + 80 - width / 2
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4
                color: win.cShadow
                opacity: 0.5 - 0.22 * win.lift
            }

            // ---------- the picture, in source pixels (256x255) scaled to 160 ----------
            Item {
                id: art
                width: 256; height: 255
                x: 95 + cloud.drift * 0.625
                y: 115 - 22 * win.lift - 34 * win.hop
                scale: 0.625
                transformOrigin: Item.TopLeft

                component Layer: Image {
                    property string name
                    width: 256; height: 255
                    smooth: true; mipmap: true
                    source: win.layerDir ? "file://" + win.layerDir + "/" + name + ".png" : ""
                }

                // whole-cloud tilt
                transform: Rotation {
                    origin.x: 128; origin.y: 195
                    angle: cloudTilt.value
                }
                QtObject { id: cloudTilt; property real value: 0 }
                SequentialAnimation {
                    running: true; loops: Animation.Infinite
                    NumberAnimation { target: cloudTilt; property: "value"; to: 1.4; duration: 2600; easing.type: Easing.InOutSine }
                    NumberAnimation { target: cloudTilt; property: "value"; to: -1.4; duration: 2900; easing.type: Easing.InOutSine }
                }

                // ----- lightning sword behind the head -----
                Layer {
                    id: boltBig
                    name: "l-boltBig"
                    transform: Rotation { id: boltBigRot; origin.x: 70; origin.y: 62; angle: 0 }
                    SequentialAnimation {
                        running: true; loops: Animation.Infinite
                        NumberAnimation { target: boltBigRot; property: "angle"; to: 2.5; duration: 1900; easing.type: Easing.InOutSine }
                        NumberAnimation { target: boltBigRot; property: "angle"; to: -1.5; duration: 2300; easing.type: Easing.InOutSine }
                    }
                }
                // small bolts by the sword: drift and flicker
                Layer {
                    id: boltS1; name: "l-boltS1"
                    SequentialAnimation on y {
                        loops: Animation.Infinite
                        NumberAnimation { to: -5; duration: 1100; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0; duration: 1300; easing.type: Easing.InOutSine }
                    }
                }
                Layer {
                    id: boltS2; name: "l-boltS2"
                    SequentialAnimation on y {
                        loops: Animation.Infinite
                        NumberAnimation { to: 4; duration: 1400; easing.type: Easing.InOutSine }
                        NumberAnimation { to: -2; duration: 1200; easing.type: Easing.InOutSine }
                    }
                }

                // ----- cape: two layered flutters -----
                Item {
                    width: 256; height: 255
                    transform: [
                        Rotation { id: capeA; origin.x: 80; origin.y: 142; angle: 0 },
                        Rotation { id: capeB; origin.x: 80; origin.y: 142; angle: 0 }
                    ]
                    SequentialAnimation {
                        running: true; loops: Animation.Infinite
                        NumberAnimation { target: capeA; property: "angle"; to: 3.5; duration: 1100; easing.type: Easing.InOutSine }
                        NumberAnimation { target: capeA; property: "angle"; to: -2.5; duration: 1200; easing.type: Easing.InOutSine }
                    }
                    SequentialAnimation {
                        running: true; loops: Animation.Infinite
                        NumberAnimation { target: capeB; property: "angle"; to: 1.2; duration: 430; easing.type: Easing.InOutSine }
                        NumberAnimation { target: capeB; property: "angle"; to: -1.2; duration: 470; easing.type: Easing.InOutSine }
                    }
                    Layer { name: "l-cape" }
                }

                // ----- cat (head + body + hand), breathing from the cloud line -----
                Item {
                    id: catBody
                    width: 256; height: 255
                    transform: Scale { origin.x: 128; origin.y: 168; yScale: 1 + 0.018 * win.breath; xScale: 1 - 0.006 * win.breath }

                    Layer { name: "l-body" }

                    // head group: tilts about the neck
                    Item {
                        id: head
                        width: 256; height: 255
                        property real tilt: 0
                        property real sway: 0
                        property real nod: 0
                        transform: [
                            Rotation { origin.x: 129; origin.y: 138; angle: head.tilt + head.sway },
                            Translate { y: head.nod }
                        ]
                        SequentialAnimation {
                            running: true; loops: Animation.Infinite
                            NumberAnimation { target: head; property: "sway"; to: 1.6; duration: 2300; easing.type: Easing.InOutSine }
                            NumberAnimation { target: head; property: "sway"; to: -1.6; duration: 2600; easing.type: Easing.InOutSine }
                        }

                        Layer { name: "l-head" }

                        // ears
                        Layer {
                            name: "l-earL"
                            transform: Rotation { id: earLRot; origin.x: 88; origin.y: 58; angle: 0 }
                        }
                        Layer {
                            name: "l-earR"
                            transform: Rotation { id: earRRot; origin.x: 170; origin.y: 58; angle: 0 }
                        }

                        // whiskers: idle quiver at different rates
                        Layer {
                            name: "l-whiskL"
                            transform: Rotation { id: whiskLRot; origin.x: 59; origin.y: 111; angle: 0 }
                            SequentialAnimation {
                                running: true; loops: Animation.Infinite
                                NumberAnimation { target: whiskLRot; property: "angle"; to: 4; duration: 900; easing.type: Easing.InOutSine }
                                NumberAnimation { target: whiskLRot; property: "angle"; to: -3; duration: 1100; easing.type: Easing.InOutSine }
                            }
                        }
                        Layer {
                            name: "l-whiskR"
                            transform: Rotation { id: whiskRRot; origin.x: 198; origin.y: 110; angle: 0 }
                            SequentialAnimation {
                                running: true; loops: Animation.Infinite
                                NumberAnimation { target: whiskRRot; property: "angle"; to: -4; duration: 1050; easing.type: Easing.InOutSine }
                                NumberAnimation { target: whiskRRot; property: "angle"; to: 3; duration: 950; easing.type: Easing.InOutSine }
                            }
                        }

                        // mouth: the swab bobs as if chewed
                        Layer {
                            name: "l-swab"
                            transform: Rotation { id: swabRot; origin.x: 141; origin.y: 116; angle: 0 }
                            SequentialAnimation {
                                running: true; loops: Animation.Infinite
                                NumberAnimation { target: swabRot; property: "angle"; to: 5; duration: 800; easing.type: Easing.InOutSine }
                                NumberAnimation { target: swabRot; property: "angle"; to: -3; duration: 900; easing.type: Easing.InOutSine }
                            }
                        }

                        // eyes
                        Layer { name: "l-blink"; visible: win.face === "blink" }
                        Layer { name: "l-wink"; visible: win.face === "wink" }
                    }

                    // hand + sword
                    Layer {
                        name: "l-hand"
                        transform: Rotation { id: handRot; origin.x: 186; origin.y: 163; angle: 0 }
                        SequentialAnimation {
                            id: handIdle
                            running: true; loops: Animation.Infinite
                            NumberAnimation { target: handRot; property: "angle"; to: -3; duration: 1600; easing.type: Easing.InOutSine }
                            NumberAnimation { target: handRot; property: "angle"; to: 2; duration: 1800; easing.type: Easing.InOutSine }
                        }
                    }
                }

                // ----- cloud: jelly squash, drift, mist puffs, lightning strikes -----
                Item {
                    id: cloud
                    width: 256; height: 255
                    property real jelly: 0
                    property real drift: 0
                    property real jolt: 0
                    transform: [
                        Scale { origin.x: 128; origin.y: 205; xScale: 1 + 0.025 * cloud.jelly; yScale: 1 - 0.03 * cloud.jelly },
                        Translate { y: cloud.jolt }
                    ]
                    SequentialAnimation on jelly {
                        loops: Animation.Infinite
                        NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
                        NumberAnimation { to: -1; duration: 1000; easing.type: Easing.InOutSine }
                    }
                    SequentialAnimation on drift {
                        loops: Animation.Infinite
                        NumberAnimation { to: 4; duration: 2700; easing.type: Easing.InOutSine }
                        NumberAnimation { to: -4; duration: 3100; easing.type: Easing.InOutSine }
                    }

                    // mist puffs breaking off the cloud's edges
                    Repeater {
                        model: [
                            { x: 22, y: 196, dx: -26, dy: -10, r: 13, t: 2600, d: 0 },
                            { x: 30, y: 214, dx: -22, dy: 8, r: 10, t: 3100, d: 900 },
                            { x: 228, y: 200, dx: 26, dy: -8, r: 12, t: 2800, d: 400 },
                            { x: 218, y: 218, dx: 22, dy: 10, r: 9, t: 3300, d: 1600 },
                            { x: 90, y: 226, dx: -6, dy: 18, r: 9, t: 2900, d: 2100 },
                            { x: 160, y: 228, dx: 8, dy: 18, r: 10, t: 2700, d: 1200 }
                        ]
                        delegate: Rectangle {
                            id: puff
                            required property var modelData
                            property real p: 0
                            width: modelData.r * 2 * (0.6 + 0.8 * p); height: width; radius: width / 2
                            x: modelData.x + modelData.dx * p - width / 2
                            y: modelData.y + modelData.dy * p - height / 2
                            color: win.cLight
                            border.color: win.cAccent; border.width: 1
                            opacity: p < 0.12 ? p / 0.12 : Math.pow(1 - (p - 0.12) / 0.88, 1.6)
                            SequentialAnimation on p {
                                loops: Animation.Infinite
                                PauseAnimation { duration: puff.modelData.d }
                                NumberAnimation { from: 0; to: 1; duration: puff.modelData.t; easing.type: Easing.OutQuad }
                            }
                        }
                    }

                    Layer { name: "l-cloud" }
                    Layer {
                        id: boltB1; name: "l-boltB1"; height: 268
                        transform: Scale { id: boltB1S; origin.x: 77; origin.y: 228; yScale: 1; xScale: 1 }
                    }
                    Layer {
                        id: boltB2; name: "l-boltB2"; height: 268
                        transform: Scale { id: boltB2S; origin.x: 183; origin.y: 228; yScale: 1; xScale: 1 }
                    }
                }
            }

            // thought bubble: scalloped cloud + trailing circles + bouncing dots
            Item {
                id: thought
                x: 8; y: 18
                width: 150; height: 112
                transformOrigin: Item.BottomRight
                property bool on: win.mode === "thinking"
                opacity: on ? 1 : 0
                scale: on ? 1 : 0.4
                Behavior on opacity { NumberAnimation { duration: 220 } }
                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }
                visible: opacity > 0

                // gentle float of its own
                SequentialAnimation on y {
                    loops: Animation.Infinite; running: thought.visible
                    NumberAnimation { to: 12; duration: 1300; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 18; duration: 1300; easing.type: Easing.InOutSine }
                }

                property var blobs: [
                    { x: 22, y: 30, r: 18 }, { x: 48, y: 18, r: 20 }, { x: 78, y: 16, r: 20 }, { x: 104, y: 26, r: 18 },
                    { x: 112, y: 48, r: 16 }, { x: 92, y: 62, r: 18 }, { x: 60, y: 64, r: 19 }, { x: 30, y: 56, r: 17 }
                ]
                Repeater { model: thought.blobs; delegate: Puff { required property var modelData; outline: true; r: modelData.r; x: modelData.x - r; y: modelData.y - r } }
                Puff { r: 36; x: 68 - r; y: 40 - r }
                Puff { outline: true; r: 7; x: 124 - r; y: 86 - r }
                Puff { outline: true; r: 4.5; x: 138 - r; y: 102 - r }
                Repeater { model: thought.blobs; delegate: Puff { required property var modelData; r: modelData.r; x: modelData.x - r; y: modelData.y - r } }
                Puff { r: 7; x: 124 - r; y: 86 - r }
                Puff { r: 4.5; x: 138 - r; y: 102 - r }

                Row {
                    x: 66 - width / 2; y: 34
                    spacing: 9
                    Repeater {
                        model: 3
                        delegate: Rectangle {
                            id: dot
                            required property int index
                            width: 11; height: 11; radius: 5.5
                            color: win.cOutline
                            SequentialAnimation on y {
                                loops: Animation.Infinite; running: thought.visible
                                PauseAnimation { duration: dot.index * 160 }
                                NumberAnimation { to: -8; duration: 220; easing.type: Easing.OutQuad }
                                NumberAnimation { to: 0; duration: 260; easing.type: Easing.InQuad }
                                PauseAnimation { duration: 600 - dot.index * 160 }
                            }
                        }
                    }
                }
            }

            // speech bubble: a check mark drawn in when done, "Cần bạn nè!" when Claude waits on you
            Item {
                id: speech
                x: 14; y: 40
                width: 150; height: 70
                transformOrigin: Item.BottomRight
                property bool on: win.mode === "done" || win.mode === "ask"
                property bool isDone: win.mode === "done"
                opacity: on ? 1 : 0
                scale: on ? 1 : 0.3
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 360; easing.type: Easing.OutBack } }
                visible: opacity > 0
                rotation: isDone ? -4 : 3
                Behavior on rotation { NumberAnimation { duration: 300 } }

                // tail toward the cat
                Canvas {
                    id: tail
                    x: 96; y: 40; width: 50; height: 46
                    Connections { target: win; function onCLightChanged() { tail.requestPaint() } function onCOutlineChanged() { tail.requestPaint() } }
                    onPaint: {
                        const c = getContext("2d"); c.reset()
                        c.beginPath(); c.moveTo(4, 6); c.lineTo(44, 40); c.lineTo(26, 4); c.closePath()
                        c.fillStyle = win.cLight; c.strokeStyle = win.cOutline; c.lineWidth = 3; c.lineJoin = "round"
                        c.fill(); c.stroke()
                    }
                }
                Rectangle {
                    id: bubbleBox
                    width: speech.isDone ? 70 : 140
                    x: 140 - width
                    height: 50; radius: 22
                    color: win.cLight; border.color: win.cOutline; border.width: 3

                    Text {
                        anchors.centerIn: parent
                        visible: !speech.isDone
                        text: "Cần bạn nè!"
                        color: win.cOutline
                        font.pixelSize: 19; font.bold: true
                    }

                    // check mark, drawn stroke by stroke
                    Canvas {
                        id: check
                        anchors.centerIn: parent
                        width: 44; height: 36
                        visible: speech.isDone
                        property real p: 0
                        onPChanged: requestPaint()
                        Connections { target: win; function onCOutlineChanged() { check.requestPaint() } }
                        onPaint: {
                            const c = getContext("2d"); c.reset()
                            const pts = [[6, 19], [17, 30], [38, 7]]
                            const l1 = Math.hypot(11, 11), l2 = Math.hypot(21, 23), total = (l1 + l2) * p
                            c.lineCap = "round"; c.lineJoin = "round"
                            c.strokeStyle = win.cOutline; c.lineWidth = 7
                            c.beginPath(); c.moveTo(pts[0][0], pts[0][1])
                            if (total <= l1) {
                                const t = total / l1
                                c.lineTo(pts[0][0] + 11 * t, pts[0][1] + 11 * t)
                            } else {
                                const t = (total - l1) / l2
                                c.lineTo(pts[1][0], pts[1][1])
                                c.lineTo(pts[1][0] + 21 * t, pts[1][1] - 23 * t)
                            }
                            c.stroke()
                        }
                        SequentialAnimation {
                            running: speech.isDone
                            PropertyAction { target: check; property: "p"; value: 0 }
                            PauseAnimation { duration: 180 }
                            NumberAnimation { target: check; property: "p"; to: 1; duration: 380; easing.type: Easing.OutCubic }
                            NumberAnimation { target: check; property: "scale"; to: 1.25; duration: 120 }
                            NumberAnimation { target: check; property: "scale"; to: 1; duration: 260; easing.type: Easing.OutBack }
                        }
                    }
                }
                // cover the tail's joint so it reads as one shape
                Rectangle { x: 100; y: 38; width: 26; height: 9; color: win.cLight }
            }

            // sparkles when done
            Repeater {
                model: [
                    { x: 98, y: 120, d: 0 }, { x: 236, y: 112, d: 120 }, { x: 250, y: 190, d: 260 },
                    { x: 90, y: 200, d: 380 }, { x: 170, y: 96, d: 200 }
                ]
                delegate: Text {
                    id: spark
                    required property var modelData
                    text: "✦"
                    color: win.cLight
                    style: Text.Outline; styleColor: win.cOutline
                    font.pixelSize: 20
                    x: modelData.x; y: modelData.y
                    property real p: 0
                    opacity: win.mode === "done" ? Math.sin(p * Math.PI) : 0
                    scale: 0.5 + p
                    rotation: p * 90
                    SequentialAnimation on p {
                        loops: Animation.Infinite; running: win.mode === "done"
                        PauseAnimation { duration: spark.modelData.d }
                        NumberAnimation { from: 0; to: 1; duration: 800; easing.type: Easing.OutQuad }
                        PauseAnimation { duration: 300 }
                    }
                }
            }

            // shows the cat can be moved
            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 24
                color: Qt.alpha(win.cLight, 0.12)
                border.color: win.cAccent; border.width: 2
                opacity: win.grab ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }



        // lightning strike: the bolt shoots down, the cloud jolts
        SequentialAnimation {
            id: strike1
            ParallelAnimation {
                NumberAnimation { target: boltB1S; property: "yScale"; to: 1.6; duration: 90; easing.type: Easing.OutQuad }
                NumberAnimation { target: boltB1S; property: "xScale"; to: 1.25; duration: 90 }
                NumberAnimation { target: cloud; property: "jolt"; to: -4; duration: 90 }
            }
            ParallelAnimation {
                NumberAnimation { target: boltB1S; property: "yScale"; to: 1; duration: 350; easing.type: Easing.OutElastic }
                NumberAnimation { target: boltB1S; property: "xScale"; to: 1; duration: 350 }
                NumberAnimation { target: cloud; property: "jolt"; to: 0; duration: 450; easing.type: Easing.OutBounce }
            }
        }
        SequentialAnimation {
            id: strike2
            ParallelAnimation {
                NumberAnimation { target: boltB2S; property: "yScale"; to: 1.6; duration: 90; easing.type: Easing.OutQuad }
                NumberAnimation { target: boltB2S; property: "xScale"; to: 1.25; duration: 90 }
                NumberAnimation { target: cloud; property: "jolt"; to: -4; duration: 90 }
            }
            ParallelAnimation {
                NumberAnimation { target: boltB2S; property: "yScale"; to: 1; duration: 350; easing.type: Easing.OutElastic }
                NumberAnimation { target: boltB2S; property: "xScale"; to: 1; duration: 350 }
                NumberAnimation { target: cloud; property: "jolt"; to: 0; duration: 450; easing.type: Easing.OutBounce }
            }
        }
        Timer {
            interval: 3500; running: true; repeat: true
            onTriggered: {
                (Math.random() < 0.5 ? strike1 : strike2).start()
                if (Math.random() < 0.3) earLTwitch.start()
                interval = win.rnd(3500, 7000)
            }
        }

        // ---------- Claude Code reactions ----------
        // done: jump, wink, flourish, ears up
        SequentialAnimation {
            id: doneAnim
            ScriptAction { script: { earLTwitch.restart(); earRTwitch.restart(); flourishAnim.restart() } }
            NumberAnimation { target: win; property: "hop"; to: 1; duration: 220; easing.type: Easing.OutQuad }
            NumberAnimation { target: win; property: "hop"; to: 0; duration: 420; easing.type: Easing.OutBounce }
            ScriptAction { script: winkAnim.restart() }
            PauseAnimation { duration: 900 }
            NumberAnimation { target: win; property: "hop"; to: 0.55; duration: 180; easing.type: Easing.OutQuad }
            NumberAnimation { target: win; property: "hop"; to: 0; duration: 360; easing.type: Easing.OutBounce }
        }
        // picked up: a startled little hop
        SequentialAnimation {
            id: grabbedAnim
            ScriptAction { script: { whiskTwitch.restart(); doubleBlinkAnim.restart() } }
            NumberAnimation { target: win; property: "hop"; to: 0.35; duration: 120; easing.type: Easing.OutQuad }
            NumberAnimation { target: win; property: "hop"; to: 0; duration: 300; easing.type: Easing.OutBounce }
        }
        // ask: curious head tilt and a twitch
        SequentialAnimation {
            id: askAnim
            ScriptAction { script: { curiousAnim.restart(); whiskTwitch.restart() } }
            NumberAnimation { target: win; property: "hop"; to: 0.3; duration: 150; easing.type: Easing.OutQuad }
            NumberAnimation { target: win; property: "hop"; to: 0; duration: 300; easing.type: Easing.OutBounce }
        }
        // while thinking, chew on the swab now and then
        Timer {
            interval: 2200; running: win.mode === "thinking"; repeat: true
            onTriggered: if (Math.random() < 0.5) chewAnim.restart(); else nodAnim.restart()
        }

        // ---------- comic bubbles ----------
        component Puff: Item {
            // a circle with a comic outline: outline disc behind, fill disc in front (drawn by parent order)
            property real r: 10
            property bool outline: false
            width: r * 2; height: r * 2
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + (parent.outline ? 6 : 0); height: width; radius: width / 2
                color: parent.outline ? win.cOutline : win.cLight
            }
        }




        // ---------- moods (one-shot animations) ----------
        SequentialAnimation {
            id: blinkAnim
            PropertyAction { target: win; property: "face"; value: "blink" }
            PauseAnimation { duration: 120 }
            PropertyAction { target: win; property: "face"; value: "open" }
        }
        SequentialAnimation {
            id: doubleBlinkAnim
            PropertyAction { target: win; property: "face"; value: "blink" }
            PauseAnimation { duration: 100 }
            PropertyAction { target: win; property: "face"; value: "open" }
            PauseAnimation { duration: 150 }
            PropertyAction { target: win; property: "face"; value: "blink" }
            PauseAnimation { duration: 100 }
            PropertyAction { target: win; property: "face"; value: "open" }
        }
        SequentialAnimation {
            id: winkAnim
            PropertyAction { target: win; property: "face"; value: "wink" }
            NumberAnimation { target: head; property: "tilt"; to: -5; duration: 180; easing.type: Easing.OutQuad }
            PauseAnimation { duration: 550 }
            NumberAnimation { target: head; property: "tilt"; to: 0; duration: 260; easing.type: Easing.InOutQuad }
            PropertyAction { target: win; property: "face"; value: "open" }
        }
        SequentialAnimation {
            id: curiousAnim
            NumberAnimation { target: head; property: "tilt"; to: 6; duration: 260; easing.type: Easing.OutBack }
            ScriptAction { script: earRTwitch.start() }
            PauseAnimation { duration: 900 }
            NumberAnimation { target: head; property: "tilt"; to: 0; duration: 380; easing.type: Easing.InOutSine }
        }
        SequentialAnimation {
            id: nodAnim
            NumberAnimation { target: head; property: "nod"; to: 3; duration: 140; easing.type: Easing.OutQuad }
            NumberAnimation { target: head; property: "nod"; to: 0; duration: 160; easing.type: Easing.InQuad }
            NumberAnimation { target: head; property: "nod"; to: 3; duration: 140; easing.type: Easing.OutQuad }
            NumberAnimation { target: head; property: "nod"; to: 0; duration: 180; easing.type: Easing.InQuad }
        }
        SequentialAnimation {
            id: earLTwitch
            NumberAnimation { target: earLRot; property: "angle"; to: -12; duration: 70 }
            NumberAnimation { target: earLRot; property: "angle"; to: 0; duration: 110 }
            NumberAnimation { target: earLRot; property: "angle"; to: -9; duration: 70 }
            NumberAnimation { target: earLRot; property: "angle"; to: 0; duration: 150; easing.type: Easing.OutQuad }
        }
        SequentialAnimation {
            id: earRTwitch
            NumberAnimation { target: earRRot; property: "angle"; to: 12; duration: 70 }
            NumberAnimation { target: earRRot; property: "angle"; to: 0; duration: 110 }
            NumberAnimation { target: earRRot; property: "angle"; to: 9; duration: 70 }
            NumberAnimation { target: earRRot; property: "angle"; to: 0; duration: 150; easing.type: Easing.OutQuad }
        }
        SequentialAnimation {
            id: whiskTwitch
            ParallelAnimation {
                NumberAnimation { target: whiskLRot; property: "angle"; to: 9; duration: 60 }
                NumberAnimation { target: whiskRRot; property: "angle"; to: -9; duration: 60 }
            }
            ParallelAnimation {
                NumberAnimation { target: whiskLRot; property: "angle"; to: -5; duration: 80 }
                NumberAnimation { target: whiskRRot; property: "angle"; to: 5; duration: 80 }
            }
            ParallelAnimation {
                NumberAnimation { target: whiskLRot; property: "angle"; to: 0; duration: 120 }
                NumberAnimation { target: whiskRRot; property: "angle"; to: 0; duration: 120 }
            }
        }
        SequentialAnimation {
            id: chewAnim
            NumberAnimation { target: swabRot; property: "angle"; to: 9; duration: 90 }
            NumberAnimation { target: swabRot; property: "angle"; to: -6; duration: 110 }
            NumberAnimation { target: swabRot; property: "angle"; to: 8; duration: 90 }
            NumberAnimation { target: swabRot; property: "angle"; to: -4; duration: 110 }
            NumberAnimation { target: swabRot; property: "angle"; to: 0; duration: 140 }
        }
        SequentialAnimation {
            id: flourishAnim
            ScriptAction { script: handIdle.pause() }
            NumberAnimation { target: handRot; property: "angle"; to: -8; duration: 200; easing.type: Easing.OutQuad }
            NumberAnimation { target: handRot; property: "angle"; to: 5; duration: 260; easing.type: Easing.OutBack }
            NumberAnimation { target: handRot; property: "angle"; to: 0; duration: 300; easing.type: Easing.InOutSine }
            ScriptAction { script: handIdle.resume() }
        }

        // eyes: their own rhythm
        Timer {
            interval: 3000; running: true; repeat: true
            onTriggered: {
                if (win.face === "open") (Math.random() < 0.25 ? doubleBlinkAnim : blinkAnim).start()
                interval = win.rnd(2200, 5500)
            }
        }
        // ears and whiskers twitch now and then
        Timer {
            interval: 2500; running: true; repeat: true
            onTriggered: {
                const r = Math.random()
                if (r < 0.35) earLTwitch.start()
                else if (r < 0.7) earRTwitch.start()
                else whiskTwitch.start()
                interval = win.rnd(1800, 4500)
            }
        }
        // bigger moods every 3-5 s
        Timer {
            interval: 4000; running: true; repeat: true
            onTriggered: {
                const r = Math.random()
                if (r < 0.2) winkAnim.start()
                else if (r < 0.4) curiousAnim.start()
                else if (r < 0.55) nodAnim.start()
                else if (r < 0.75) chewAnim.start()
                else flourishAnim.start()
                interval = win.rnd(3000, 5000)
            }
        }
        // bolts flicker
        Timer {
            interval: 140; running: true; repeat: true
            onTriggered: {
                boltB1.opacity = Math.random() < 0.12 ? 0.25 : 1
                boltB2.opacity = Math.random() < 0.12 ? 0.25 : 1
                boltS1.opacity = Math.random() < 0.1 ? 0.2 : 1
                boltS2.opacity = Math.random() < 0.1 ? 0.2 : 1
                boltBig.opacity = Math.random() < 0.05 ? 0.7 : 1
            }
        }
    }
}
