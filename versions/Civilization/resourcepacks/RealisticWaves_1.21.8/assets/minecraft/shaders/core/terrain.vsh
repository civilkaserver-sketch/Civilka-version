#version 150

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:globals.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

out float sphericalVertexDistance;
out float cylindricalVertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;

vec4 minecraft_sample_lightmap(sampler2D lightMap, ivec2 uv) {
    return texture(lightMap, clamp(uv / 256.0, vec2(0.5 / 16.0), vec2(15.5 / 16.0)));
}

// REALISTIC WAVES - only vanilla water, texture untouched
bool isWater(vec2 uv) {
    // vanilla water alpha = 180/255 = 0.7059. Proven method from Wavy Water pack.
    float a = textureLod(Sampler0, uv, 0.0).a;
    return abs(a * 255.0 - 180.0) < 2.0;
}

float getRealisticWave(vec3 worldPos) {
    float t = GameTime;
    // 3 smooth travelling waves, diagonal directions for realism
    float w1 = sin((worldPos.x * 0.85 + worldPos.z * 0.65) + t * 1.9);
    float w2 = sin((worldPos.x * -0.45 + worldPos.z * 1.15) + t * 2.6) * 0.6;
    float w3 = sin((worldPos.x * 1.9 - worldPos.z * 1.6) - t * 1.3) * 0.35;
    float combined = (w1 + w2 + w3) / 1.95; // -1..1
    return combined;
}

void main() {
    vec3 pos = Position + ModelOffset;

    if (isWater(UV0)) {
        float h = getRealisticWave(pos);
        pos.y += h * 0.12;
    }

    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);

    sphericalVertexDistance = fog_spherical_distance(pos);
    cylindricalVertexDistance = fog_cylindrical_distance(pos);
    vertexColor = Color * minecraft_sample_lightmap(Sampler2, UV2);
    texCoord0 = UV0;
}
