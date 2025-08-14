shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture;
uniform vec2 cat_position = vec2(0.5, 0.5); // normalized coords
uniform float radius = 0.2;
uniform float feather = 0.05;

void fragment() {
    // Get aspect-corrected UV from SCREEN_UV
    vec2 uv = SCREEN_UV;

    // Correct for aspect ratio difference between Control and viewport
    float aspect = float(textureSize(screen_tex, 0).x) / float(textureSize(screen_tex, 0).y);
    uv.x *= aspect;

    vec4 screen_color = texture(screen_tex, SCREEN_UV);

    vec3 inverted = vec3(1.0) - screen_color.rgb;
    float gray = dot(inverted, vec3(0.299, 0.587, 0.114));

    float dist = distance(uv, vec2(cat_position.x * aspect, cat_position.y));
    float mask = smoothstep(radius, radius - feather, dist);

    COLOR = vec4(vec3(gray) * (1.0 - mask) + screen_color.rgb * mask, 1.0);
}
