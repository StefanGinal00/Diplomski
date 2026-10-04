shader_type canvas_item;
render_mode unshaded;
uniform vec2 camera_shift = vec2(0.0);
uniform vec2 haze_shift = vec2(0.0);
void fragment() {
	// One opaque canvas for the entire city, no separate market/upper image.
	// Preserve source aspect at city height; repeat ONLY horizontally.
	float u = UV.x * (6250.0 / 2450.0 / 1.5) + camera_shift.x;
	u = 1.0 - abs(mod(u, 2.0) - 1.0);
	float v = clamp(UV.y * 0.9 + 0.05 + camera_shift.y, 0.001, 0.999);
	vec4 paint = texture(TEXTURE, vec2(u, v));
	float mist = 0.025 * sin((UV.y + haze_shift.y) * 12.0);
	COLOR = vec4(paint.rgb * 0.72 + vec3(mist * 0.3), 1.0);
}
