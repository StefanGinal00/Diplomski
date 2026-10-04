shader_type canvas_item;
// Preserve the exact atlas mask. Only this short-lived snapshot dissolves.
uniform vec4 frame_bounds = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 exclude_upper_left = vec2(0.0);
uniform vec2 frame_grid = vec2(4.0, 3.0);
uniform float dissolve_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color : source_color = vec4(0.7, 0.8, 1.0, 1.0);
uniform bool use_living_mask = false;
uniform vec4 source_rect = vec4(0.0,0.0,1.0,1.0);
uniform vec2 spans[64];

void fragment() {
	vec2 cell_uv = fract(UV * frame_grid);
	if (use_living_mask) {
		float row=(UV.y-source_rect.y)/source_rect.w;
		int band=clamp(int(row*64.0),0,63);
		if(UV.x<spans[band].x || UV.x>spans[band].y || row<0.0 || row>1.0) {discard;}
		cell_uv=(UV-source_rect.xy)/source_rect.zw;
	}
	if (cell_uv.x < frame_bounds.x || cell_uv.y < frame_bounds.y || cell_uv.x > frame_bounds.z || cell_uv.y > frame_bounds.w) {
		discard;
	}
	if (cell_uv.x < exclude_upper_left.x && cell_uv.y < exclude_upper_left.y) {
		discard;
	}
	if (dissolve_progress > 0.0) {
		vec2 local_uv = clamp((cell_uv - frame_bounds.xy) / max(frame_bounds.zw - frame_bounds.xy, vec2(0.001)), vec2(0.0), vec2(1.0));
		vec2 grain = floor(local_uv * vec2(42.0, 54.0));
		float noise = fract(sin(dot(grain, vec2(12.9898, 78.233))) * 43758.5453);
		float threshold = (1.0 - local_uv.y) * 0.75 + noise * 0.25;
		if (threshold < dissolve_progress) {
			discard;
		}
		float edge = 1.0 - smoothstep(0.0, 0.055, threshold - dissolve_progress);
		COLOR.rgb = mix(COLOR.rgb, edge_color.rgb, edge * 0.6);
	}
}
