#version 150

uniform sampler2D InSampler;

in vec2 texCoord;

out vec4 fragColor;

const vec3 LumaWeights = vec3(0.299, 0.587, 0.114);

void main() {
    vec4 baseColor = texture(InSampler, texCoord);

    // 1. Cold ashen desaturation (40% color, 60% desaturated cold ash)
    float luma = dot(baseColor.rgb, LumaWeights);
    // Neutral cold ash luminance with zero purple/magenta
    vec3 ashLuma = vec3(luma * 0.97, luma * 0.98, luma * 1.01);
    vec3 desat = mix(ashLuma, baseColor.rgb, 0.40);

    // 2. Smooth cinematic vignette (darkens edges smoothly without blinding center)
    vec2 uv = texCoord - 0.5;
    float dist = length(uv);
    float vignette = smoothstep(0.85, 0.32, dist);
    float vigFactor = 0.52 + 0.48 * vignette;

    // 3. Gloom curve (moody overcast ashen tone)
    vec3 finalColor = desat * vigFactor;
    finalColor = pow(finalColor, vec3(1.06));

    fragColor = vec4(clamp(finalColor, 0.0, 1.0), baseColor.a);
}
