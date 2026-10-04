shader_type canvas_item;
render_mode unshaded;

uniform vec2 camera_shift = vec2(0.0);
uniform vec2 crop = vec2(1.0);
uniform float top_fade = 0.0;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	// Keep the distant roofline in frame when painting long, shallow rooms.
	vec2 extent = crop * 0.43;
	vec2 focus = clamp(vec2(0.5, 0.32), extent + vec2(0.06), vec2(0.94) - extent);
	vec2 uv = (UV - vec2(0.5)) * extent * 2.0 + focus + camera_shift;
	// Fragment COLOR already includes a texture sample. Use vertex tint instead
	// so the painting is not multiplied by itself and accidentally blackened.
	COLOR = texture(TEXTURE, clamp(uv, vec2(0.001), vec2(0.999))) * vertex_tint;
	// Fade in plate coordinates, not shifted sampling UVs: parallax cannot
	// move the seam. Disabled on enclosed pockets and shafts.
	if (top_fade > 0.0) {
		COLOR.a *= smoothstep(0.0, top_fade, UV.y);
	}
}
