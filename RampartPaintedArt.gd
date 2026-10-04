@tool
extends "res://RoomPaintedDepth.gd"
## Art-only pass for the separate Broken Ramparts expedition graph.

var surfaces: Array[Polygon2D] = []
var retired: Array[CanvasItem] = []
var pillars: Array[Sprite2D] = []
var pillar_anchors: Array[Vector2] = []
var pillar_foot_y := 0


func _style() -> Dictionary:
	return {"region": "starfall", "background": "broken_ramparts_depth_v1", "surface": "starfall_masonry_v1", "tint": Color("9795aa"), "haze": Color("292f43"), "rim": Color("b2aabc"), "retire": ["Ruin"]}


func _old_polygon(named: String, style: Dictionary) -> bool:
	for token in style["retire"]:
		if named.contains(token):
			return true
	return false


func _build() -> void:
	var style := _style()
	if built or get_parent().region != style["region"]:
		return
	var wing := get_parent()
	var texture := load("res://art/visual_slice/%s.png" % style["background"]) as Texture2D
	if texture == null:
		return
	for node in wing.get_children():
		var named := String(node.name)
		var chamber := named.begins_with("MainChamber") or named.begins_with("BranchChamber")
		if node is Polygon2D and ((chamber and named.ends_with("Backdrop")) or named.begins_with("MainShaft") or named.begins_with("BranchPassage") or named == "OptionalLoop"):
			plates.append(node)
		elif chamber and node.get_child_count() == 0 and ((node is Polygon2D and _old_polygon(named, style)) or (node is Line2D and named.contains("Outline"))):
			# Distant architecture is now in the painting. Retire only old scenery.
			node.hide()
			retired.append(node)
	if plates.is_empty():
		return
	var first := true
	for plate in plates:
		for point in plate.polygon:
			var local := to_local(plate.to_global(point))
			if first:
				art_bounds = Rect2(local, Vector2.ZERO)
				first = false
			else:
				art_bounds = art_bounds.expand(local)
	material_shared = ShaderMaterial.new()
	material_shared.shader = DEPTH_SHADER
	var ratio := art_bounds.size.x / art_bounds.size.y / (texture.get_width() / float(texture.get_height()))
	material_shared.set_shader_parameter("crop", Vector2(minf(ratio, 1), minf(1 / ratio, 1)))
	material_shared.set_shader_parameter("scene_scale", maxf(1, art_bounds.size.x / 2700.0))
	material_shared.set_shader_parameter("brightness", 0.60)
	material_shared.set_shader_parameter("haze_color", style["haze"])
	for plate in plates:
		var uv := PackedVector2Array()
		for point in plate.polygon:
			uv.append((to_local(plate.to_global(point)) - art_bounds.position) / art_bounds.size * texture.get_size())
		plate.texture = texture
		plate.uv = uv
		plate.color = Color.WHITE
		plate.material = material_shared
		plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var stone := load("res://art/visual_slice/%s.png" % style["surface"]) as Texture2D
	for body in wing.get_children():
		if not body is StaticBody2D:
			continue
		var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		var visual := body.get_node_or_null("Visual") as Polygon2D
		if collision == null or visual == null or not collision.shape is RectangleShape2D:
			continue
		if collision.shape.size.x <= collision.shape.size.y:
			continue # Do not decorate the giant world-boundary collision walls.
		visual.texture = stone
		visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		visual.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		visual.color = style["tint"]
		var uv := PackedVector2Array()
		for point in visual.polygon:
			uv.append(point * 3.0)
		visual.uv = uv
		surfaces.append(visual)
		var rim := Line2D.new()
		rim.name = "StoneRim"
		rim.points = PackedVector2Array([visual.polygon[0] + Vector2(1, 1), visual.polygon[1] + Vector2(-1, 1)])
		rim.width = 1.5
		rim.default_color = style["rim"]
		visual.add_child(rim)
	# Schematic previews have no floor bodies, and must not invent walkable props.
	if not surfaces.is_empty():
		_build_props()
	built = true


func _build_props() -> void:
	var texture := load("res://art/visual_slice/broken_watch_pillar_v1.png") as Texture2D
	if texture == null:
		return
	var used := texture.get_image().get_used_rect()
	# Almost transparent generation fringes can extend below the stone itself.
	# Inspect alpha only; preserve source pixels and anchor the visible base.
	var bitmap := texture.get_image()
	pillar_foot_y = used.end.y
	for row in range(used.end.y - 1, used.position.y - 1, -1):
		var solid_pixels := 0
		for column in range(used.position.x, used.end.x):
			if bitmap.get_pixel(column, row).a >= 0.5:
				solid_pixels += 1
		if solid_pixels >= 3:
			pillar_foot_y = row + 1
			break
	var wing := get_parent()
	for index in [0, 2, 4, 7]:
		var chamber: Rect2 = wing._main_rect(index)
		var anchor: Vector2 = wing._supported_point(index, false, chamber.position.x + chamber.size.x * 0.66, 9, 90)
		var height: float = 125.0 + (index % 3) * 18.0
		var fit: float = height / used.size.y
		var sprite := Sprite2D.new()
		sprite.name = "WatchPillar%d" % index
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.centered = false
		sprite.scale = Vector2.ONE * fit
		sprite.position = anchor - Vector2(used.position.x + used.size.x * 0.5, pillar_foot_y) * fit
		sprite.z_index = -7
		sprite.modulate = Color("878397")
		add_child(sprite)
		pillars.append(sprite)
		pillar_anchors.append(anchor)
