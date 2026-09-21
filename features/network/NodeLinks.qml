import QtQuick
import qs.core.state
import qs.core.theme

// Crackling energy strands from each core to the info cards around it.
Canvas {
    id: root

    // [{ from: Item (core), to: Item (card) }]
    property var links: []
    property color accent: Colours.mauve
    property bool active: false

    opacity: active ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: 500 }
    }

    Timer {
        interval: 45
        running: root.opacity > 0.01
        repeat: true
        onTriggered: root.requestPaint()
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (!active)
            return;

        const time = Date.now() / 1000;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.strokeStyle = accent.toString();

        for (const link of links) {
            if (!link.from || !link.to || link.to.opacity < 0.05)
                continue;
            const a = link.from.mapToItem(root, link.from.width / 2, link.from.height / 2);
            const b = link.to.mapToItem(root, link.to.width / 2, link.to.height / 2);
            const dx = b.x - a.x;
            const dy = b.y - a.y;
            const dist = Math.sqrt(dx * dx + dy * dy);
            const start = link.from.width / 2 + UiScale.s(5);
            const reach = dist - start - UiScale.s(30);
            if (reach < UiScale.s(10))
                continue;

            const cos = dx / dist;
            const sin = dy / dist;
            const sx = a.x + cos * start;
            const sy = a.y + sin * start;
            const steps = Math.max(6, Math.round(reach / UiScale.s(12)));

            // Two strands: a wide soft wave and a thin jittery core.
            for (let strand = 0; strand < 2; strand++) {
                ctx.beginPath();
                ctx.moveTo(sx, sy);
                for (let k = 1; k <= steps; k++) {
                    const t = k / steps;
                    const envelope = Math.sin(t * Math.PI);
                    const wave = strand === 0 ? Math.sin(time * 2.5 + t * 6) * UiScale.s(10) : Math.cos(-time * 1.5 + t * 8) * UiScale.s(6);
                    const jitter = strand === 1 ? (Math.random() - 0.5) * UiScale.s(3) : 0;
                    const offset = (wave + jitter) * envelope;
                    ctx.lineTo(sx + cos * reach * t - sin * offset, sy + sin * reach * t + cos * offset);
                }
                ctx.lineWidth = strand === 0 ? UiScale.s(3) : UiScale.s(1.5);
                ctx.globalAlpha = strand === 0 ? 0.15 : 0.45;
                ctx.stroke();
            }
        }
    }
}
