shader_type canvas_item;
void fragment() {
	vec2 drift=vec2(TIME*0.007,sin(TIME*0.37+UV.x*9.0)*0.003);
	vec3 ripple=texture(TEXTURE,UV+drift).rgb;
	COLOR.rgb=mix(COLOR.rgb,COLOR.rgb*(0.8+ripple*0.8),0.65);
}
