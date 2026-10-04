shader_type canvas_item;
render_mode unshaded;
void fragment() {
	// Haze reduces background contrast without blurring the original masonry.
	COLOR.rgb = mix(COLOR.rgb, vec3(0.105, 0.125, 0.175), 0.38);
	// Atlas source baselines share the lower part of their sheet. A soft foot
	// dissolves into distant haze; never present a floating solid foundation.
	COLOR.a *= 1.0 - smoothstep(0.81, 0.97, UV.y);
}
