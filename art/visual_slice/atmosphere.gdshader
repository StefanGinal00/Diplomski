shader_type canvas_item;
render_mode unshaded;
uniform vec2 camera_shift = vec2(0.0);
uniform vec2 crop = vec2(1.0);
uniform float edge_fade = 0.0;
void fragment() {
	vec2 uv = (UV - vec2(0.5)) * crop * 0.86 + vec2(0.5) + camera_shift;
	vec4 paint = texture(TEXTURE, clamp(uv, vec2(0.001), vec2(0.999)));
	float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	paint.a *= edge_fade > 0.0 ? smoothstep(0.0, edge_fade, edge) : 1.0;
	COLOR = paint * COLOR;
}
