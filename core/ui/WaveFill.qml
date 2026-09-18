import QtQuick
import qs.core.state

// Liquid fill used by v1's hold-to-confirm controls: a gradient that rises (or slides
// right) to `level`, with a wobbling edge while it is partly full.
Canvas {
    id: root

    // 0 (empty) to 1 (full).
    property real level: 0
    // "up" fills from the bottom, "right" fills from the left.
    property string direction: "up"
    // "rect" uses `radius`; "circle" clips to a circle.
    property string shape: "rect"
    property real radius: Scale.s(14)
    property color colorStart: "white"
    property color colorEnd: colorStart
    property real waveAmplitude: Scale.s(10)

    property real phase: 0

    NumberAnimation on phase {
        running: root.level > 0 && root.level < 1
        loops: Animation.Infinite
        from: 0
        to: Math.PI * 2
        duration: 800
    }

    onPhaseChanged: requestPaint()
    onLevelChanged: requestPaint()
    onColorStartChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function clipShape(ctx: var): void {
        ctx.beginPath();
        if (shape === "circle") {
            ctx.arc(width / 2, height / 2, Math.min(width, height) / 2, 0, 2 * Math.PI);
        } else {
            const r = Math.min(radius, width / 2, height / 2);
            ctx.moveTo(r, 0);
            ctx.lineTo(width - r, 0);
            ctx.arcTo(width, 0, width, r, r);
            ctx.lineTo(width, height - r);
            ctx.arcTo(width, height, width - r, height, r);
            ctx.lineTo(r, height);
            ctx.arcTo(0, height, 0, height - r, r);
            ctx.lineTo(0, r);
            ctx.arcTo(0, 0, r, 0, r);
        }
        ctx.closePath();
        ctx.clip();
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (level <= 0.001)
            return;

        ctx.save();
        clipShape(ctx);

        const amp = level < 0.99 ? waveAmplitude * Math.sin(level * Math.PI) : 0;
        ctx.beginPath();
        let grad;
        if (direction === "right") {
            const edge = width * level;
            ctx.moveTo(0, 0);
            ctx.lineTo(edge, 0);
            ctx.bezierCurveTo(edge + Math.cos(phase + Math.PI) * amp, height * 0.33, edge + Math.sin(phase) * amp, height * 0.66, edge, height);
            ctx.lineTo(0, height);
            grad = ctx.createLinearGradient(0, 0, Math.max(1, edge), 0);
        } else {
            const edge = height * (1 - level);
            ctx.moveTo(0, edge);
            ctx.bezierCurveTo(width * 0.33, edge + Math.cos(phase + Math.PI) * amp, width * 0.66, edge + Math.sin(phase) * amp, width, edge);
            ctx.lineTo(width, height);
            ctx.lineTo(0, height);
            grad = ctx.createLinearGradient(0, 0, 0, height);
        }
        ctx.closePath();
        grad.addColorStop(0, colorStart.toString());
        grad.addColorStop(1, colorEnd.toString());
        ctx.fillStyle = grad;
        ctx.fill();
        ctx.restore();
    }
}
