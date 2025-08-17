shader_type canvas_item;

uniform bool outline_enabled = false;
uniform float outline_size = 1.0;               // base outline thickness
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.8, 1.0); // glow color

// Glow animation controls
uniform float pulse_speed = 4.0;                // how fast it pulses
uniform float min_opacity = 0.5;                // lowest alpha (never disappears)
uniform float size_pulse_strength = 0.1;        // tiny size wobble (set 0 to disable)

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    // Always draw the base sprite
    if (tex_color.a > 0.0) {
        COLOR = tex_color;
    }
    else if (outline_enabled) {
        bool near_edge = false;

        // Triangle wave for snappy up/down glow
        float t = fract(TIME * pulse_speed);
        float wave = t < 0.5 ? t * 2.0 : (1.0 - t) * 2.0; // goes 0 → 1 → 0

        // Outline thickness with small wobble
        float animated_size = outline_size + wave * size_pulse_strength;

        for (float x = -animated_size; x <= animated_size; x++) {
            for (float y = -animated_size; y <= animated_size; y++) {
                vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
                if (texture(TEXTURE, UV + offset).a > 0.0) {
                    near_edge = true;
                }
            }
        }

        if (near_edge) {
            // Glow alpha between min_opacity → 1.0
            float pulse = min_opacity + (1.0 - min_opacity) * wave;
            COLOR = vec4(outline_color.rgb, outline_color.a * pulse);
        } else {
            discard;
        }
    }
    else {
        discard;
    }
}
