shader_type canvas_item;
render_mode unshaded;

uniform vec2 camera_shift = vec2(0.0);
uniform vec2 haze_shift = vec2(0.0);
uniform vec2 crop = vec2(1.0);
uniform vec2 texture_phase = vec2(0.0);
uniform float scene_scale = 1.0;
uniform vec4 haze_color : source_color = vec4(0.15, 0.24, 0.29, 1.0);
uniform float brightness = 0.66;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	// One UV space across all pockets: intersections cannot restart the image.
	vec2 uv = (UV - vec2(0.5)) * crop * 0.88 * scene_scale + vec2(0.5) + camera_shift + texture_phase;
	// Mirrored continuation limits magnification across huge late-game rooms.
	// All chamber masks still sample one continuous room-wide image space.
	uv.x = 1.0 - abs(mod(uv.x, 2.0) - 1.0);
	// Vertical mirror repetition turns towers and aqueducts upside down.
	// Keep every repeat upright and soften the join between its endpoints.
	uv.y = fract(uv.y);
	vec4 paint = texture(TEXTURE, clamp(uv, vec2(0.001), vec2(0.999)));
	vec4 seam = 0.5 * (texture(TEXTURE, vec2(uv.x, 0.001)) + texture(TEXTURE, vec2(uv.x, 0.999)));
	paint = mix(seam, paint, smoothstep(0.0, 0.045, min(uv.y, 1.0 - uv.y)));
	// A second, quieter depth plane. No TIME animation when a room is inactive.
	vec2 mist_uv = UV + haze_shift;
	float mist = smoothstep(0.2, 0.95, 0.5 + 0.25 * sin(mist_uv.x * 19.0 + mist_uv.y * 7.0) + 0.25 * sin(mist_uv.y * 27.0 - mist_uv.x * 4.0));
	vec3 distant = paint.rgb * brightness;
	COLOR = vec4(mix(distant, haze_color.rgb, mist * 0.10), paint.a) * vertex_tint;
}
