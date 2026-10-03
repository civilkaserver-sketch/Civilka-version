#version 150

uniform sampler2D InSampler;

in vec2 texCoord;

out vec4 fragColor;

const vec3 LumaWeights = vec3(0.299, 0.587, 0.114);

void main() {
    vec4 baseColor = texture(InSampler, texCoord);

    // 1. Cold desaturation (~68% saturation, bleak foggy atmosphere)
    float luma = dot(baseColor.rgb, LumaWeights);
    vec3 coldLuma = vec3(luma * 0.96, luma * 0.98, luma * 1.03);
    vec3 desat = mix(coldLuma, baseColor.rgb, 0.68);

    // 2. Smooth Vignette (darkens peripheral edges smoothly)
    vec2 uv = texCoord - 0.5;
    float dist = length(uv);
    float vignette = smoothstep(0.75, 0.30, dist);
    float vigFactor = 0.40 + 0.60 * vignette;

    vec3 finalColor = desat * vigFactor;

    fragColor = vec4(clamp(finalColor, 0.0, 1.0), baseColor.a);
}
