shader_type canvas_item;
uniform vec4 source_rect = vec4(0.0,0.0,1.0,1.0);
void fragment() {
	float y=(UV.y-source_rect.y)/source_rect.w;
	COLOR.a *= smoothstep(0.0,0.1,y) * (1.0-smoothstep(0.90,1.0,y));
}
