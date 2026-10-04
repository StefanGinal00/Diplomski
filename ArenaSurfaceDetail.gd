@tool
extends Node2D
## Bounded material accents within the original horizontal surface. Never
## changes its polygon, collision, UVs or primary texture.
var bounds := Rect2()
var style := 0
var stone: Texture2D
var fill_base := false
const PALETTES := [Color("aa7957"), Color("739b91"), Color("668e92"), Color("8e859d")]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	queue_redraw()

func _draw() -> void:
	if not bounds.has_area() or stone == null:
		return
	var tint: Color = PALETTES[style]
	var top := bounds.position.y
	var bottom := bounds.end.y
	# A stone bevel, with source variation per slab instead of one stretched strip.
	for index in range(ceili(bounds.size.x / 48.0)):
		var x := bounds.position.x + index * 48
		var width := minf(46, bounds.end.x - x)
		if width < 8:
			continue
		var source := Rect2(Vector2(31 + (index * 137) % 600, 61 + (index * 97) % 500), Vector2(width * 3, 18))
		if fill_base:
			draw_texture_rect_region(stone, Rect2(x, top, minf(48, bounds.end.x - x), bounds.size.y), Rect2(source.position, Vector2(width * 3, bounds.size.y * 3)), Color(tint.darkened(0.15), 1))
		draw_texture_rect_region(stone, Rect2(x, top + 1, width, minf(3, bounds.size.y - 2)), source, Color(tint.lightened(0.18), 0.8))
		var seam_x := x + minf(width - 2, 21 + (index * 7) % 23)
		var depth := minf(bounds.size.y - 2, 3 + (index * 11) % 7)
		draw_polyline(PackedVector2Array([Vector2(seam_x, top + 2), Vector2(seam_x - 2, top + depth * 0.6), Vector2(seam_x + 1, top + depth)]), Color("272735"), 0.65, true)
		# Soot for ash, damp mineral flecks for water, pale wear for Starfall.
		var grain := Color(tint.darkened(0.3), 0.5)
		for chip in range(3):
			var px := x + 4 + fmod(index * 13 + chip * 11, maxf(5, width - 7))
			var py := minf(bottom - 1, top + 4 + chip % 2)
			draw_line(Vector2(px, py), Vector2(minf(px + 2, bounds.end.x), py), grain, 0.8, true)
	draw_line(Vector2(bounds.position.x, bottom - 1), Vector2(bounds.end.x, bottom - 1), Color("20222d"), 1.0, true)
