shader_type canvas_item;

uniform float piece_height = 300.0;
uniform vec4 bedrock : source_color = vec4(0.019608, 0.039216, 0.050980, 1.0);
varying float piece_y;

void vertex() {
	piece_y = VERTEX.y / max(piece_height, 1.0);
}

void fragment() {
	// Preserve the authored alpha silhouette and let the hanging tips retain
	// their material, but conceal the cutout's upper join in buried earth.
	COLOR.rgb = mix(bedrock.rgb,COLOR.rgb,smoothstep(0.06,0.54,piece_y));
	// At its clipped top the source is wider than the chipped geological core.
	// Feather that join rather than painting a little horizontal black shelf.
	COLOR.a *= smoothstep(0.04,0.35,piece_y);
}
