shader_type canvas_item;
uniform vec2 edge_points[6];
uniform vec2 source_band = vec2(0.002, 0.331);
uniform float texture_offset = 0.0;
uniform float mass_width = 240.0;
uniform vec4 bedrock : source_color = vec4(0.019608, 0.039216, 0.050980, 1.0);
varying vec2 local_position;
varying vec4 stone_tint;
void vertex() {
	local_position = VERTEX;
	stone_tint = COLOR;
}
void fragment() {
	float edge_y = edge_points[5].y;
	for (int i = 0; i < 5; i++) {
		if (local_position.x >= edge_points[i].x && local_position.x <= edge_points[i+1].x) {
			float t = clamp((local_position.x-edge_points[i].x)/max(1.0,edge_points[i+1].x-edge_points[i].x),0.0,1.0);
			edge_y = mix(edge_points[i].y,edge_points[i+1].y,t);
		}
	}
	float bottom_depth = max(0.0, edge_y-local_position.y);
	float side_depth = max(0.0,min(local_position.x,mass_width-local_position.x)-7.0);
	float depth = min(bottom_depth,side_depth);
	// The floor atlas has surface stone at the top, deep soil at the bottom.
	// Distance into this ceiling reverses that direction without stretching it.
	vec2 bottom_uv = vec2(fract(local_position.x/396.0+texture_offset),
		mix(source_band.x,source_band.y,clamp(bottom_depth/88.0,0.0,1.0)));
	vec2 side_uv = vec2(fract(local_position.y/396.0+texture_offset),
		mix(source_band.x,source_band.y,clamp(side_depth/88.0,0.0,1.0)));
	// Blend samples, not the two differently oriented coordinates: interpolated
	// UVs stretch the grain into long streaks around the lower corners.
	vec4 strata = mix(texture(TEXTURE,side_uv),texture(TEXTURE,bottom_uv),
		smoothstep(-12.0,12.0,side_depth-bottom_depth))*stone_tint;
	vec3 stone = mix(strata.rgb,bedrock.rgb,smoothstep(24.0,82.0,depth));
	// An opaque companion polygon closes any transparent pixels in the atlas.
	COLOR = vec4(stone, smoothstep(0.0,2.0,depth));
}
