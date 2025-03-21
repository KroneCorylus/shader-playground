#ifdef GL_ES
precision mediump float;
#endif

uniform float u_time;
uniform vec2 u_resolution;
uniform vec4 iCursorCurrent;
uniform vec4 iCursorPrevious;
uniform float iTimeCursorChange;

float sdBox(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// //Author: https://iquilezles.org/articles/distfunctions2d/
float sdTrail(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3)
{
    float d = dot(p - v0, p - v0);
    float s = 1.0;

    // Edge from v3 to v0
    {
        vec2 e = v3 - v0;
        vec2 w = p - v0;
        vec2 b = w - e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
        d = min(d, dot(b, b));

        // Compute branchless boolean conditions:
        float c0 = step(0.0, p.y - v0.y); // 1 if (p.y >= v0.y)
        float c1 = 1.0 - step(0.0, p.y - v3.y); // 1 if (p.y <  v3.y)
        float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x); // 1 if (e.x*w.y > e.y*w.x)
        float allCond = c0 * c1 * c2;
        float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
        // If either allCond or noneCond is 1, then flip factor becomes -1.
        float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
        s *= flip;
    }

    // Edge from v0 to v1
    {
        vec2 e = v0 - v1;
        vec2 w = p - v1;
        vec2 b = w - e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
        d = min(d, dot(b, b));

        float c0 = step(0.0, p.y - v1.y);
        float c1 = 1.0 - step(0.0, p.y - v0.y);
        float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
        float allCond = c0 * c1 * c2;
        float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
        float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
        s *= flip;
    }

    // Edge from v1 to v2
    {
        vec2 e = v1 - v2;
        vec2 w = p - v2;
        vec2 b = w - e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
        d = min(d, dot(b, b));

        float c0 = step(0.0, p.y - v2.y);
        float c1 = 1.0 - step(0.0, p.y - v1.y);
        float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
        float allCond = c0 * c1 * c2;
        float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
        float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
        s *= flip;
    }

    // Edge from v2 to v3
    {
        vec2 e = v2 - v3;
        vec2 w = p - v3;
        vec2 b = w - e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
        d = min(d, dot(b, b));

        float c0 = step(0.0, p.y - v3.y);
        float c1 = 1.0 - step(0.0, p.y - v2.y);
        float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
        float allCond = c0 * c1 * c2;
        float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
        float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
        s *= flip;
    }

    return s * sqrt(d);
}

vec2 normalize(vec2 value, float isPosition, vec3 iResolution) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

float easeOutBounce(float x) {
    const float n1 = 7.5625;
    const float d1 = 2.75;

    float t1 = step(1.0 / d1, x);
    float t2 = step(2.0 / d1, x);
    float t3 = step(2.5 / d1, x);

    float b = n1 * x * x;
    b = mix(b, n1 * (x - 1.5 / d1) * (x - 1.5 / d1) + 0.75, t1);
    b = mix(b, n1 * (x - 2.25 / d1) * (x - 2.25 / d1) + 0.9375, t2);
    b = mix(b, n1 * (x - 2.625 / d1) * (x - 2.625 / d1) + 0.984375, t3);

    return b;
}

float easeInOutBounce(float x) {
    return mix(
        (1.0 - easeOutBounce(1.0 - 2.0 * x)) / 2.0,
        (1.0 + easeOutBounce(2.0 * x - 1.0)) / 2.0,
        step(0.5, x)
    );
}

float antialising(float distance, vec3 iResolution) {
    return 1. - smoothstep(0., normalize(vec2(2., 2.), 0., iResolution).x, distance);
}

float determineStartVertexFactor(vec2 a, vec2 b) {
    // Conditions using step
    float condition1 = step(b.x, a.x) * step(a.y, b.y); // a.x < b.x && a.y > b.y
    float condition2 = step(a.x, b.x) * step(b.y, a.y); // a.x > b.x && a.y < b.y

    // If neither condition is met, return 1 (else case)
    return 1.0 - max(condition1, condition2);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec3 iResolution = vec3(u_resolution, 0.);
    float iTime = u_time;

    //Normalization
    vec2 vu = normalize(fragCoord, 1., iResolution);

    //xy will have the normalized position of the center of the cursor, and zw, the width and height normalized too
    vec4 currentCursor = vec4(normalize(iCursorCurrent.xy, 1., iResolution), normalize(iCursorCurrent.zw, 0., iResolution));
    vec4 previousCursor = vec4(normalize(iCursorPrevious.xy, 1., iResolution), normalize(iCursorPrevious.zw, 0., iResolution));

    float vertexFactor = determineStartVertexFactor(currentCursor.xy, previousCursor.xy);
    float invertedVertexFactor = 1.0 - vertexFactor;

    vec2 v0 = vec2(currentCursor.x + currentCursor.z * vertexFactor, currentCursor.y - currentCursor.w);
    vec2 v1 = vec2(currentCursor.x + currentCursor.z * invertedVertexFactor, currentCursor.y);
    vec2 v2 = vec2(previousCursor.x + currentCursor.z * invertedVertexFactor, previousCursor.y);
    vec2 v3 = vec2(previousCursor.x + currentCursor.z * vertexFactor, previousCursor.y - previousCursor.w);

    float d2 = sdTrail(vu, v0, v1, v2, v3);
    fragColor = mix(fragColor, vec4(0., 0., 1., 1.), antialising(d2, iResolution));

    vec2 offsetFactor = vec2(-.5, 0.5);
    float cCursorDistance = sdBox(vu, currentCursor.xy - (currentCursor.zw * offsetFactor), currentCursor.zw * 0.5);
    fragColor = mix(fragColor, vec4(1., 0., 1., 1.), antialising(cCursorDistance, iResolution));

    float pCursorDistance = sdBox(vu, previousCursor.xy - (previousCursor.zw * offsetFactor), previousCursor.zw * 0.5);
    fragColor = mix(fragColor, vec4(.87, .87, .87, 1.), antialising(pCursorDistance, iResolution));
}
void main() {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}
