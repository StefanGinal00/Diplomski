shader_type canvas_item;
// Across-pipe shading follows Line2D's UVs; native route points stay intact.
void fragment() {
	float tube = 0.32 + 0.68 * sin(clamp(UV.y, 0.0, 1.0) * 3.14159265);
	float highlight = pow(max(0.0, 1.0 - abs(UV.y - 0.3) * 5.0), 4.0) * 0.14;
	// Fragment COLOR already contains the texture and native modulation.
	// Sampling/multiplying it a second time crushed the metal into black.
	COLOR.rgb = COLOR.rgb * tube + vec3(highlight) * COLOR.a;
}
