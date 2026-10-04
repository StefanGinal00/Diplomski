shader_type canvas_item;
// Only the incoming left join fades. The prior strip stays opaque underneath,
// avoiding a dark transparent seam while blending mismatched source edges.
uniform vec4 source_rect=vec4(0.0,0.0,1.0,1.0);
void fragment() {
	float x=(UV.x-source_rect.x)/source_rect.z;
	COLOR.a*=smoothstep(0.0,0.085,x);
}
