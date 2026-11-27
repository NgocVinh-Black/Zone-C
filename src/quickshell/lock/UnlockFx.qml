import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import "../"
import "../frost"

// Vault-gate unlock drawn above FrostLockScreen, driven by its fly / turn / open:
//   fly   the logo leaves the avatar slot, flies to the centre and grows; the lock screen dims behind it
//   turn  the logo turns like a vault wheel while the HUD rings lock on around it
//   open  the whole picture (lock screen + logo) splits down the middle and both halves slide out sideways
// Locking plays the same values backwards: the halves slide in, meet, the wheel turns back.
// The lock screen is shown through a live snapshot (stage) so the two gate halves can carry it.
Item {
    id: fx
    property var lock                     // FrostLockScreen: fly, turn, open, avatarCenter, avatar
    readonly property real fly: lock ? lock.fly : 0
    readonly property real turn: lock ? lock.turn : 0
    readonly property real open: lock ? lock.open : 0
    readonly property bool active: fly > 0
    visible: active

    // logo at full size in the middle of the screen
    readonly property real big: Math.round(Math.min(width, height) * 0.36)
    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real ax: lock ? lock.avatarCenter.x : cx
    readonly property real ay: lock ? lock.avatarCenter.y : cy
    // HUD visible once the logo has landed, gone when the gate starts moving
    readonly property real hud: Math.min(1, fly * 1.4) * Math.max(0, 1 - open * 4)

    // free-running spin for the HUD rings
    property real spin: 0
    NumberAnimation on spin { running: fx.active; from: 0; to: 360; duration: 2400; loops: Animation.Infinite }

    component Arc: ShapePath {
        property real r
        property real start
        property real sweep
        fillColor: "transparent"
        capStyle: ShapePath.FlatCap
        PathAngleArc { centerX: fx.cx; centerY: fx.cy; radiusX: r; radiusY: r; startAngle: start; sweepAngle: sweep }
    }

    // ---------- stage: lock screen snapshot + the big logo (only ever seen through the gate halves) ----------
    Item {
        id: stage
        anchors.fill: parent
        ShaderEffectSource {
            anchors.fill: parent
            sourceItem: fx.lock
            hideSource: fx.active
            live: true
            layer.enabled: fx.active
            layer.effect: MultiEffect { blurEnabled: true; blur: fx.fly * 0.7; blurMax: 48; autoPaddingEnabled: false }
        }
        Rectangle { anchors.fill: parent; color: Fz.bg0; opacity: fx.fly * 0.55 }

        // HUD around the landed logo
        readonly property real r0: fx.big / 2
        Shape {
            anchors.fill: parent
            opacity: fx.hud
            preferredRendererType: Shape.CurveRenderer
            // locking bolts: three heavy segments turning with the wheel
            Arc { r: stage.r0 + 16; start: fx.turn * 270 + 0; sweep: 70; strokeWidth: 5; strokeColor: Fz.acc }
            Arc { r: stage.r0 + 16; start: fx.turn * 270 + 120; sweep: 70; strokeWidth: 5; strokeColor: Fz.acc }
            Arc { r: stage.r0 + 16; start: fx.turn * 270 + 240; sweep: 70; strokeWidth: 5; strokeColor: Fz.acc }
            // dial filling clockwise from the top while the wheel turns
            Arc { r: stage.r0 + 34; start: -90; sweep: 360; strokeWidth: 1; strokeColor: Fz.glowA(0.2) }
            Arc { r: stage.r0 + 34; start: -90; sweep: 360 * fx.turn; strokeWidth: 2.5; strokeColor: Fz.glow }
            // outer counter-rotating arcs
            Arc { r: stage.r0 + 62; start: -fx.spin + 20; sweep: 120; strokeWidth: 1.2; strokeColor: Fz.accA(0.6) }
            Arc { r: stage.r0 + 62; start: -fx.spin + 200; sweep: 120; strokeWidth: 1.2; strokeColor: Fz.accA(0.6) }
            Arc { r: stage.r0 + 72; start: fx.spin * 0.5 + 70; sweep: 22; strokeWidth: 5; strokeColor: Fz.glowA(0.5) }
            Arc { r: stage.r0 + 72; start: fx.spin * 0.5 + 250; sweep: 22; strokeWidth: 5; strokeColor: Fz.glowA(0.5) }
        }
        // tick ring: lights up behind the dial
        Repeater {
            model: 72
            delegate: Item {
                required property int index
                x: fx.cx; y: fx.cy
                rotation: index * 5
                opacity: fx.hud * (index / 72 < fx.turn ? 1 : 0.2)
                Rectangle { x: -0.75; y: -(stage.r0 + 50); width: 1.5; height: index % 6 === 0 ? 9 : 5; radius: 0.75; color: index % 6 === 0 ? Fz.acc : Fz.glow }
            }
        }
        // spark on the dial's leading edge
        Item {
            x: fx.cx; y: fx.cy
            rotation: 360 * fx.turn
            opacity: fx.hud * (fx.turn > 0 && fx.turn < 1 ? 1 : 0)
            Rectangle { x: -5; y: -(stage.r0 + 34) - 5; width: 10; height: 10; radius: 5; color: Fz.hi }
            Rectangle { x: -12; y: -(stage.r0 + 34) - 12; width: 24; height: 24; radius: 12; color: Fz.glowA(0.35) }
        }
        FText {
            x: fx.cx - width / 2; y: fx.cy - stage.r0 - 118
            text: Fz.tr("ĐÃ XÁC THỰC") + "  ·  " + Math.round(fx.turn * 100) + "%"
            font.family: Fz.mono; px: 13; weight: Font.DemiBold; font.letterSpacing: 4
            color: Fz.glow
            opacity: fx.hud
        }

        // the logo: flies from the avatar slot (88 px) to the centre, then turns like a wheel
        Item {
            id: logo
            width: fx.big; height: fx.big
            x: fx.ax + (fx.cx - fx.ax) * fx.fly - width / 2
            y: fx.ay + (fx.cy - fx.ay) * fx.fly - height / 2
            scale: (88 + (fx.big - 88) * fx.fly) / fx.big
            rotation: fx.turn * 360 + fx.open * 120
            RectangularShadow { anchors.fill: rim; radius: width / 2; blur: 40; spread: 4; color: Fz.glowA(0.45 * fx.fly) }
            Rectangle { id: rim; anchors.fill: parent; anchors.margins: -fx.big * 0.035; radius: width / 2; color: Fz.acc }
            RoundImage {
                id: logoImg
                anchors.fill: parent; radius: width / 2
                source: fx.lock ? fx.lock.avatar : ""
                sourceSize: Qt.size(1024, 1024)
                visible: ready
            }
            Rectangle {
                anchors.fill: parent; radius: width / 2; color: Fz.acc; visible: !logoImg.ready
                FIcon { anchors.centerIn: parent; name: "zc"; size: fx.big * 0.55; color: Fz.ink }
            }
            // flash when the wheel finishes its turn
            Rectangle {
                readonly property real k: Math.max(0, (fx.turn - 0.8) / 0.2) * Math.max(0, 1 - fx.open * 5)
                anchors.centerIn: parent
                width: parent.width * (1.08 + 0.25 * k); height: width; radius: width / 2
                color: "transparent"; border.width: 3; border.color: Fz.hi
                opacity: k
            }
        }
    }

    // ---------- gate: two halves of the stage slide apart ----------
    // each half slides straight out to its side (and in again when locking)
    readonly property real slide: open * (width / 2 + 40)
    Item {
        id: leftDoor
        x: -fx.slide; y: 0
        width: Math.ceil(fx.width / 2); height: fx.height
        clip: true
        ShaderEffectSource { x: 0; width: fx.width; height: fx.height; sourceItem: stage; hideSource: true; live: true }
        // glowing cut edge
        Rectangle { anchors.right: parent.right; width: 3; height: parent.height; color: Fz.acc; opacity: Math.min(1, fx.open * 6) }
        Rectangle { anchors.right: parent.right; width: 16; height: parent.height; opacity: Math.min(1, fx.open * 6)
                    gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: Fz.glowA(0.45) } } }
    }
    Item {
        id: rightDoor
        x: Math.floor(fx.width / 2) + fx.slide; y: 0
        width: fx.width - Math.floor(fx.width / 2); height: fx.height
        clip: true
        ShaderEffectSource { x: -Math.floor(fx.width / 2); width: fx.width; height: fx.height; sourceItem: stage; hideSource: true; live: true }
        Rectangle { anchors.left: parent.left; width: 3; height: parent.height; color: Fz.acc; opacity: Math.min(1, fx.open * 6) }
        Rectangle { anchors.left: parent.left; width: 16; height: parent.height; opacity: Math.min(1, fx.open * 6)
                    gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Fz.glowA(0.45) } GradientStop { position: 1; color: "transparent" } } }
    }
    // seam flash the moment the gate cracks open (or slams shut)
    Rectangle {
        readonly property real k: Math.sin(Math.min(1, fx.open * 2.5) * Math.PI)
        x: fx.cx - width / 2; y: 0
        width: 2 + 30 * k; height: fx.height
        opacity: k
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.5; color: Fz.hi }
            GradientStop { position: 1; color: "transparent" } }
    }
}
