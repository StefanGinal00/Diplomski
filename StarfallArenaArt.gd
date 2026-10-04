@tool
extends "res://RoomPaintedDepth.gd"
## Arena-only art. Never searches inside bosses, doors, lamps or hazard nodes.

@export_enum("empty_court", "hollow_throne") var arena_style := "empty_court"
var retired: Array[CanvasItem] = []
var surfaces: Array[Polygon2D] = []
var trims: Array[Line2D] = []
var throne: Sprite2D
var foundation: Polygon2D


func _build() -> void:
	if built:
		return
	var room := get_parent()
	var texture := load("res://art/visual_slice/%s_depth_v1.png" % arena_style) as Texture2D
	if texture == null:
		return
	var plate := room.get_node("Sky") as Polygon2D
	plates.append(plate)
	art_bounds = Rect2(to_local(plate.to_global(plate.polygon[0])), Vector2.ZERO)
	for point in plate.polygon:
		art_bounds = art_bounds.expand(to_local(plate.to_global(point)))
	material_shared = ShaderMaterial.new()
	material_shared.shader = DEPTH_SHADER
	var ratio := art_bounds.size.x / art_bounds.size.y / (texture.get_width() / float(texture.get_height()))
	material_shared.set_shader_parameter("crop", Vector2(minf(ratio, 1), minf(1 / ratio, 1)))
	material_shared.set_shader_parameter("brightness", 0.64)
	material_shared.set_shader_parameter("haze_color", Color("272b42") if arena_style == "empty_court" else Color("302139"))
	var uv := PackedVector2Array()
	for point in plate.polygon:
		uv.append((to_local(plate.to_global(point)) - art_bounds.position) / art_bounds.size * texture.get_size())
	plate.texture = texture
	plate.uv = uv
	plate.color = Color.WHITE
	plate.material = material_shared
	plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var old_names := ["CourtWalls", "RearPortals", "BrokenHalo"] if arena_style == "empty_court" else ["DistantShards", "PalaceRuin", "BrokenHalo", "HaloInner", "ThroneBack"]
	for named in old_names:
		var old := room.get_node(named) as CanvasItem
		# Only explicitly named decorative leaves are retired.
		if old.get_child_count() == 0:
			old.hide()
			retired.append(old)
	var stone := load("res://art/visual_slice/starfall_masonry_v1.png") as Texture2D
	for body in room.get_children():
		if not body is StaticBody2D:
			continue
		var visual := body.get_node_or_null("Visual") as Polygon2D
		if visual == null:
			continue
		# Retain the existing silhouette, including FallenSpan's broken end.
		visual.texture = stone
		visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		visual.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		visual.color = Color("9394a7") if arena_style == "empty_court" else Color("9b879f")
		var stone_uv := PackedVector2Array()
		for point in visual.polygon:
			stone_uv.append(point * 3.0)
		visual.uv = stone_uv
		surfaces.append(visual)
		var left: Vector2 = visual.polygon[0]
		var right: Vector2 = visual.polygon[1]
		_trim(visual, PackedVector2Array([left + Vector2(1, 1), right + Vector2(-1, 1)]), Color("b5b1c1"), 1.5)
		# Thin seams and metal end straps stay inside the original surface.
		var bottom: float = visual.polygon[visual.polygon.size() - 1].y
		for x in range(int(left.x + 24), int(right.x - 4), 48):
			_trim(visual, PackedVector2Array([Vector2(x, left.y + 3), Vector2(x, bottom - 1)]), Color("343044"), 1.0)
		for x in [left.x + 4, right.x - 4]:
			_trim(visual, PackedVector2Array([Vector2(x, left.y + 3), Vector2(x, bottom - 2)]), Color("8f8190"), 2.0)
	_build_foundation(stone)
	if arena_style == "hollow_throne":
		_build_throne()
	built = true


func _build_foundation(stone: Texture2D) -> void:
	var floor_visual := get_parent().get_node("Floor/Visual") as Polygon2D
	var floor_bottom := to_local(floor_visual.to_global(floor_visual.polygon[2])).y
	foundation = Polygon2D.new()
	foundation.name = "ArenaFoundation"
	foundation.z_index = -2
	foundation.polygon = PackedVector2Array([Vector2(art_bounds.position.x, floor_bottom), Vector2(art_bounds.end.x, floor_bottom), art_bounds.end, Vector2(art_bounds.position.x, art_bounds.end.y)])
	foundation.texture = stone
	foundation.color = Color("383446")
	foundation.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	foundation.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var uv := PackedVector2Array()
	for point in foundation.polygon:
		uv.append(point * 2.0)
	foundation.uv = uv
	add_child(foundation)


func _trim(visual: Polygon2D, points: PackedVector2Array, tint: Color, width: float) -> void:
	var line := Line2D.new()
	line.name = "StoneTrim%d" % trims.size()
	line.points = points
	line.default_color = tint
	line.width = width
	visual.add_child(line)
	trims.append(line)


func _build_throne() -> void:
	var texture := load("res://art/visual_slice/hollow_seat_v1.png") as Texture2D
	if texture == null:
		return
	# Use alpha bounds, not padded image size, to ground the prop precisely.
	var used := texture.get_image().get_used_rect()
	var fit := minf(240.0 / used.size.x, 250.0 / used.size.y)
	throne = Sprite2D.new()
	throne.name = "PaintedThrone"
	throne.texture = texture
	throne.centered = false
	throne.scale = Vector2.ONE * fit
	throne.position = Vector2(1150, 425) - Vector2(used.position.x + used.size.x * 0.5, used.end.y) * fit
	throne.z_index = -5
	throne.modulate = Color("96909f")
	throne.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(throne)
