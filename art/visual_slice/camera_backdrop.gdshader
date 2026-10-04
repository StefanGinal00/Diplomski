shader_type canvas_item;
render_mode unshaded;
uniform vec2 camera_uv = vec2(0.0);
uniform vec2 view_uv = vec2(0.5);
uniform vec4 fog_color : source_color = vec4(0.04, 0.10, 0.14, 1.0);
uniform float brightness = 0.64;
uniform float wind_time = 0.0;
uniform bool city_horizon = false;

void fragment() {
	vec2 scene = camera_uv + (UV - vec2(0.5)) * view_uv + vec2(0.5);
	// Continuous across the viewport, independent of room polygons. Horizontal
	// reflection avoids hard tile seams; vertical joins dissolve into cave haze.
	vec2 uv = vec2(1.0 - abs(mod(scene.x, 2.0) - 1.0), city_horizon ? clamp(scene.y,0.002,0.998) : fract(scene.y));
	vec3 paint = texture(TEXTURE, clamp(uv, vec2(0.002), vec2(0.998))).rgb * brightness;
	float join = 1.0 - smoothstep(0.0, 0.12, min(uv.y, 1.0 - uv.y));
	if (city_horizon) { join *= 0.5; paint *= 0.65; }
	float mist = 0.045 * (1.0 + sin(scene.x * 11.0 - scene.y * 8.0 + wind_time * 0.09));
	COLOR = vec4(mix(paint, fog_color.rgb, clamp(join * 0.88 + mist, 0.0, 1.0)), 1.0);
}
