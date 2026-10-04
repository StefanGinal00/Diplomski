shader_type canvas_item;
// Recolor only cold crystal highlights, retaining bronze and dark stone.
void fragment() {
	float cold = clamp((COLOR.b - COLOR.r) * 3.0, 0.0, 1.0);
	float energy = max(COLOR.g, COLOR.b);
	COLOR.rgb = mix(COLOR.rgb, vec3(energy, energy * 0.46, energy * 0.12), cold);
}
