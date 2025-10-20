shader_type canvas_item;

uniform sampler2D noise_texture;
uniform float edge_steepness = 0.5;
uniform float noise_strength = 0.5;
uniform float noise_scale = 1.0;

// The polygon's signed distance field (SDF).
// A helper function to create a normal based on distance.
vec3 get_sdf_normal(vec2 uv, sampler2D input_texture) {
    // This is the core of the edge steepness.
    // It samples multiple points to calculate the gradient.
    float d = texture(input_texture, uv).r;
    float dx = texture(input_texture, uv + vec2(0.005, 0.0)).r - d;
    float dy = texture(input_texture, uv + vec2(0.0, 0.005)).r - d;
    
    // The Z component is always 1 for a 2D normal.
    return normalize(vec3(dx, dy, edge_steepness));
}

// A helper function to get a normal from a noise texture.
vec3 get_noise_normal(vec2 uv) {
    // We sample the noise texture to get the height information.
    vec2 scaled_uv = uv * noise_scale;
    float d = texture(noise_texture, scaled_uv).r;
    float dx = texture(noise_texture, scaled_uv + vec2(0.005, 0.0)).r - d;
    float dy = texture(noise_texture, scaled_uv + vec2(0.0, 0.005)).r - d;

    return normalize(vec3(dx, dy, 1.0));
}

void fragment() {
    // This will represent our rock's final normal.
    vec3 final_normal;
    
    // Get the base normal from the polygon's distance field.
    vec3 sdf_normal = get_sdf_normal(UV, TEXTURE);
    
    // Sample the noise texture to get the bumpy detail normal.
    vec3 bumpy_normal = get_noise_normal(UV);
    
    // Mix the two normals. We use the distance from the polygon's edge to determine the mix.
    float dist = texture(TEXTURE, UV).r;
    float mix_factor = clamp(dist * 10.0, 0.0, 1.0);
    
    // Mix the normals based on the mix_factor.
    // This makes the edges use the smooth sdf_normal and the interior use the bumpy_normal.
    final_normal = mix(sdf_normal, bumpy_normal, mix_factor * noise_strength);
    
    NORMAL = final_normal;
    COLOR = texture(TEXTURE, UV);
}
