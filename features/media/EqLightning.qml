import QtQuick
import QtQuick.Effects
import qs.core.state
import qs.core.theme
import qs.features.media

// Crackling arcs drawn through the band handles while a strike sweeps across them.
Canvas {
    id: root

    property real strike: 0
    property real strikeFade: 1

    opacity: 1 - strikeFade
    renderTarget: Canvas.FramebufferObject
    layer.enabled: opacity > 0.01
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Colours.mauve
        shadowBlur: 1
        shadowOpacity: 0.6
    }

    Timer {
        interval: 16
        running: root.strikeFade < 1 && root.strike > 0
        repeat: true
        onTriggered: root.requestPaint()
    }

    function handlePoints(): var {
        const count = EqualizerService.bands.length;
        const points = [];
        for (let i = 0; i < count; i++) {
            const gain = EqualizerService.gains[i] ?? 0;
            const t = (12 - gain) / 24;
            // Matches the handle position inside EqSlider.
            const top = Scale.s(9);
            const trackHeight = height - Scale.s(18) - Scale.s(20);
            points.push({
                x: (i + 0.5) * width / count,
                y: top + t * trackHeight
            });
        }
        return points;
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (strike <= 0 || strikeFade >= 1)
            return;

        const time = Date.now() / 1000;
        const points = handlePoints();
        const energy = 1 - strikeFade;
        const strands = [
            { width: Scale.s(20), colour: Colours.mauve, alpha: 0.2 },
            { width: Scale.s(8), colour: Colours.pink, alpha: 0.45 },
            { width: Scale.s(3.5), colour: Colours.lavender, alpha: 0.85 },
            { width: Scale.s(1), colour: Colours.white, alpha: 0.1 }
        ];

        ctx.lineJoin = "round";
        ctx.lineCap = "round";

        for (let s = 0; s < strands.length; s++) {
            ctx.beginPath();
            ctx.moveTo(points[0].x, points[0].y);

            for (let i = 0; i < points.length - 1 && i <= strike; i++) {
                const a = points[i];
                const b = points[i + 1];
                const reach = Math.min(1, strike - i);
                const steps = s === 3 ? 6 : 8;

                for (let j = 1; j <= steps; j++) {
                    const t = Math.min(j / steps, reach);
                    const envelope = Math.sin(t * Math.PI);
                    const noise = s === 3 ? 1 : (4 - s) * 4;
                    const sweepX = s < 2 ? Math.sin(time * 3 + i + j + s) * Scale.s(10) * envelope : 0;
                    const sweepY = s < 2 ? Math.cos(time * 2.5 + i - j - s) * Scale.s(15) * envelope : 0;
                    const crackX = Math.sin(time * (10 + s) + i + j) * Math.cos(time * 8 - i + j) * noise * envelope * energy;
                    const crackY = Math.cos(time * (9 - s) + i - j) * Math.sin(time * 7 + i - j) * noise * 1.25 * envelope * energy;

                    ctx.lineTo(a.x + (b.x - a.x) * t + sweepX + crackX, a.y + (b.y - a.y) * t + sweepY + crackY);
                    if (t === reach)
                        break;
                }
            }

            ctx.lineWidth = strands[s].width;
            ctx.strokeStyle = strands[s].colour.toString();
            ctx.globalAlpha = strands[s].alpha;
            ctx.stroke();
        }
    }
}
