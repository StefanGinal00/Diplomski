shader_type canvas_item;
// Preserve painted structure/alpha while distinguishing player spell colors.
uniform vec4 accent : source_color = vec4(0.86, 0.62, 1.0, 1.0);
void fragment() {
	float energy = max(COLOR.r, max(COLOR.g, COLOR.b));
	float highlight = min(COLOR.r, min(COLOR.g, COLOR.b)) / max(energy, 0.001);
	vec3 palette = mix(accent.rgb, vec3(1.0), highlight * highlight * 0.4);
	COLOR.rgb = mix(COLOR.rgb, palette * energy, 0.85);
}
