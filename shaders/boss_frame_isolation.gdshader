shader_type canvas_item;
// Keep source PNGs intact; exclude disconnected neighbouring frame fragments.
uniform vec4 frame_bounds = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 exclude_upper_left = vec2(0.0);
uniform vec2 frame_grid = vec2(2.0);
uniform bool hide_paint = false;
void fragment() {
	if (hide_paint) {discard;}
	vec2 cell_uv = fract(UV * frame_grid);
	if (cell_uv.x < frame_bounds.x || cell_uv.y < frame_bounds.y || cell_uv.x > frame_bounds.z || cell_uv.y > frame_bounds.w) {
		discard;
	}
	if (cell_uv.x < exclude_upper_left.x && cell_uv.y < exclude_upper_left.y) {
		discard;
	}
}
