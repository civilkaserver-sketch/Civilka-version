#version 150

uniform sampler2D InSampler;

in vec2 texCoord;

out vec4 fragColor;

const vec3 LumaWeights = vec3(0.299, 0.587, 0.114);

void main() {
    vec4 baseColor = texture(InSampler, texCoord);

    // 1. Desaturation to 10% (0.10 normal saturation, 0.90 greyscale)
    float luma = dot(baseColor.rgb, LumaWeights);
    vec3 desat = mix(vec3(luma), baseColor.rgb, 0.10);

    // 2. Tunnel vision (slight dark vignette towards peripheral vision)
    vec2 uv = texCoord - 0.5;
    float dist = length(uv);
    // Smooth transition from 0.30 to 0.70
    float vignette = smoothstep(0.70, 0.30, dist);
    // Tunnel vision: edges darken to ~22%, center remains 100%
    vec3 finalColor = desat * (0.22 + 0.78 * vignette);

    fragColor = vec4(finalColor, baseColor.a);
}
