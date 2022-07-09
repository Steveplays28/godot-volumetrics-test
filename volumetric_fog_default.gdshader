
// NOTE: Shader automatically converted from Godot Engine 4.0.alpha.mono's FogMaterial.

shader_type fog;

uniform float density : hint_range(0, 1, 0.0001) = 1.0;
uniform vec4 albedo : hint_color = vec4(1.0);
uniform vec4 emission : hint_color = vec4(0, 0, 0, 1);
uniform float height_falloff = 0.0;
uniform float edge_fade = 0.1;
uniform sampler3D density_texture: hint_white;


void fog() {
    DENSITY = density * clamp(exp2(-height_falloff * (WORLD_POSITION.y - OBJECT_POSITION.y)), 0.0, 1.0);
    DENSITY *= texture(density_texture, UVW).r;
    DENSITY *= pow(clamp(-SDF / min(min(EXTENTS.x, EXTENTS.y), EXTENTS.z), 0.0, 1.0), edge_fade);
    ALBEDO = albedo.rgb;
    EMISSION = emission.rgb;
}
