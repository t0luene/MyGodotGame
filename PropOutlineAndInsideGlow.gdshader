shader_type canvas_item;

uniform bool outline_enabled = false;
uniform bool glow_enabled = false;

uniform float outline_size = 3.0;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.8, 1.0);

uniform float pulse_speed = 4.0;
uniform float min_opacity = 0.5;
uniform float size_pulse_strength = 0.1;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 0.8, 0.5);
uniform float glow_strength = 0.4;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    // discard fully transparent pixels
    if (tex_color.a <= 0.0) {
        discard;
    }

    // Triangle wave for animation
    float t = fract(TIME * pulse_speed);
    float wave = t < 0.5 ? t * 2.0 : (1.0 - t) * 2.0;

    // Base sprite
    COLOR = tex_color;

    // Glow overlay
    if (glow_enabled) {
        float glow_alpha = min_opacity + (1.0 - min_opacity) * wave;
        COLOR.rgb = mix(COLOR.rgb, glow_color.rgb, glow_strength * glow_alpha);
    }

    // Outline
    if (outline_enabled) {
        float animated_size = outline_size + wave * size_pulse_strength;
        bool near_edge = false;

        // Loop around neighbors
        for (float x = -animated_size; x <= animated_size; x += 0.5) {
            for (float y = -animated_size; y <= animated_size; y += 0.5) {
                if (x == 0.0 && y == 0.0) continue;

                vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
                vec4 sample = texture(TEXTURE, UV + offset);

                // If neighbor is transparent, we're near an edge
                if (sample.a <= 0.0) {
                    near_edge = true;
                }
            }
        }

        if (near_edge) {
            float pulse = min_opacity + (1.0 - min_opacity) * wave;
            COLOR = vec4(outline_color.rgb, outline_color.a * pulse);
        }
    }
}
