shader_type canvas_item;
uniform vec4 source_rect = vec4(0.0,0.0,1.0,1.0);
uniform vec2 spans[64];
uniform bool heated = false;
void fragment() {
	float row=(UV.y-source_rect.y)/source_rect.w;
	int band=clamp(int(row*64.0),0,63);
	if(UV.x<spans[band].x || UV.x>spans[band].y || row<0.0 || row>1.0) {discard;}
	if(heated) {
		float cyan=clamp((COLOR.g+COLOR.b)*0.5-COLOR.r,0.0,1.0);
		COLOR.rgb=mix(COLOR.rgb,vec3(max(COLOR.b,COLOR.g),COLOR.g*0.43,COLOR.b*0.16),cyan*1.7);
	}
}
