#version 440
// Zone-C electric border: vien hinh chu nhat bo goc bi "lam nhieu" bang fbm noise
// (tuong duong feTurbulence + feDisplacementMap trong CSS/SVG), chay tren GPU.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;        // kich thuoc item (px)
    vec4 rect;        // x, y, w, h cua vien ben trong item (px)
    float radius;     // bo goc
    float time;       // giay
    float amp;        // do rung (px)
    float surgeSpeed; // vong / giay
    vec4 glowColor;
    vec4 boltColor;
    vec4 coreColor;
};

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = p * 2.03 + 17.1;
        a *= 0.5;
    }
    return v;
}

float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
    vec2 px = qt_TexCoord0 * size;
    vec2 c = rect.xy + rect.zw * 0.5;
    vec2 p = px - c;
    vec2 halfSize = rect.zw * 0.5;

    // Luong dien chay vong quanh vien (theo goc quanh tam)
    float ang = atan(p.y, p.x) / 6.2831853 + 0.5;
    float surge = 0.0;
    for (int k = 0; k < 3; k++) {
        float head = fract(time * surgeSpeed + float(k) / 3.0);
        float dd = ang - head;
        dd -= floor(dd + 0.5);
        float x = dd < 0.0 ? dd / 0.07 : dd / 0.012;
        surge += exp(-x * x);
    }
    surge = min(surge, 1.0);

    float a1 = amp * (1.0 + 1.3 * surge);

    // Tia chinh: dich chuyen vi tri bang turbulence dong
    vec2 disp1 = vec2(fbm(px * 0.030 + vec2(time * 1.6, -time * 1.1)),
                      fbm(px * 0.030 + vec2(-time * 1.3, time * 1.7) + 7.3)) - 0.5;
    float d1 = sdRoundBox(p + disp1 * a1 * 2.0, halfSize, radius);

    // Tia phu mong, tan so cao hon -> lach tach
    vec2 disp2 = vec2(fbm(px * 0.070 + vec2(time * 2.6, time * 1.9) + 3.1),
                      fbm(px * 0.070 + vec2(-time * 2.2, -time * 2.8) + 11.7)) - 0.5;
    float d2 = sdRoundBox(p + disp2 * a1 * 2.4, halfSize, radius);

    // Duong vien goc (khong rung) cho quang sang mem
    float d0 = sdRoundBox(p, halfSize, radius);

    float ad1 = abs(d1), ad2 = abs(d2);
    float core  = exp(-pow(ad1 / (0.8 + surge * 0.9), 2.0));
    float bolt  = exp(-pow(ad1 / (2.0 + surge * 1.6), 2.0));
    float crack = exp(-pow(ad2 / 0.7, 2.0)) * (0.45 + 0.55 * surge);
    float glowFall = d0 < 0.0 ? 0.35 : 1.0;   // quang sang ben trong cua so nhe hon
    float glow  = exp(-abs(d0) / (6.0 + surge * 10.0)) * (0.30 + 0.70 * surge) * glowFall;

    vec3 col = glowColor.rgb * glow
             + boltColor.rgb * (bolt * 0.9 + crack)
             + coreColor.rgb * core * (0.7 + 0.8 * surge);
    float alpha = clamp(glow * 0.85 + bolt + crack + core, 0.0, 1.0);
    col = min(col, vec3(alpha));   // premultiplied alpha

    fragColor = vec4(col, alpha) * qt_Opacity;
}
