@tool
extends Node2D

## Art-only pilot. No colliders, actors, save flags or gameplay changes.
## Attached only to Echo Grotto and the Starfall market district.
@export_enum("grotto", "city") var theme := "grotto"
const ATMOSPHERE := preload("res://art/visual_slice/atmosphere.gdshader")
var plates: Array[Polygon2D] = []
var surfaces: Array[Rect2] = []
var elapsed := 0.0
var redraw_clock := 0.0
var built := false
var ambient: Node2D


func _ready() -> void:
	z_index = -1
	call_deferred("_build")


func _build() -> void:
	if built or not is_inside_tree():
		return
	built = true
	var room := get_parent()
	var texture := load("res://art/visual_slice/%s_backdrop.png" % theme) as Texture2D
	if theme == "grotto":
		_plate("EntrancePainting", Rect2(0, -230, 980, 410), texture, -2)
		for named in ["Arch", "InnerGlow", "CrystalDepth", "CrystalLeft", "CrystalRight", "CrystalFar", "ResonanceLine"]:
			var old := room.get_node_or_null(named) as CanvasItem
			if old != null:
				old.hide()
		var route := room.get_node("LongTraversal")
		for tier in range(9):
			var bounds: Rect2 = route._chamber_rect(tier)
			var plate := _plate("GalleryPainting%02d" % tier, bounds.grow(30), texture, -7)
			plate.polygon = route._echo_chamber_silhouette(bounds, tier)
			_set_uv(plate, bounds.grow(30), texture)
	else:
		_plate("MarketSkyPainting", Rect2(2740, -180, 1640, 600), texture, -5, 0.08)
		for named in ["MarketArch", "MarketArchRoof", "MarketHall", "MarketHallRoof", "MarketStallWest", "MarketStallEast", "ApothecaryHouse", "ApothecaryRoof"]:
			room.get_node(named).hide()
		for detail in room.find_children("MarketLifeDetails", "Node2D", true, false):
			for child in detail.get_children():
				if String(child.name).begins_with("Canopy") or String(child.name).begins_with("Counter") or String(child.name).begins_with("Post") or String(child.name).begins_with("Goods"):
					child.hide()
	for body in room.find_children("*", "StaticBody2D", true, false):
		if body.is_in_group("breakable"):
			continue
		var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or not collision.shape is RectangleShape2D:
			continue
		var size: Vector2 = collision.shape.size
		if size.y > 22 or size.x < 80:
			continue
		var at := to_local(collision.global_position)
		var rect := Rect2(at - size * 0.5, size)
		if theme == "city":
			rect = rect.intersection(Rect2(2820, 0, 1460, 435))
			if not rect.has_area():
				continue
		else:
			var visual := body.get_node_or_null("Visual") as CanvasItem
			if visual != null:
				visual.hide()
		surfaces.append(rect)
	ambient = Node2D.new()
	ambient.name = "AmbientMotion"
	add_child(ambient)
	ambient.draw.connect(_draw_ambient)
	ambient.queue_redraw()
	queue_redraw()
	if Engine.is_editor_hint():
		set_process(false)


func _plate(node_name: String, bounds: Rect2, texture: Texture2D, layer: int, fade := 0.0) -> Polygon2D:
	var plate := Polygon2D.new()
	plate.name = node_name
	plate.z_index = layer
	plate.z_as_relative = false
	plate.polygon = PackedVector2Array([bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)])
	plate.texture = texture
	plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var material := ShaderMaterial.new()
	material.shader = ATMOSPHERE
	var ratio := bounds.size.x / bounds.size.y / (float(texture.get_width()) / texture.get_height())
	material.set_shader_parameter("crop", Vector2(minf(ratio, 1.0), minf(1.0 / ratio, 1.0)))
	material.set_shader_parameter("edge_fade", fade)
	plate.material = material
	plate.set_meta("art_bounds", bounds)
	_set_uv(plate, bounds, texture)
	add_child(plate)
	plates.append(plate)
	return plate


func _set_uv(plate: Polygon2D, bounds: Rect2, texture: Texture2D) -> void:
	var uv := PackedVector2Array()
	for point in plate.polygon:
		uv.append((point - bounds.position) / bounds.size * texture.get_size())
	plate.uv = uv


func _process(delta: float) -> void:
	if not built or not is_visible_in_tree() or Engine.is_editor_hint():
		return
	elapsed += delta
	redraw_clock += delta
	if redraw_clock < 0.05:
		return
	redraw_clock = 0.0
	# Canvas inverse also works with camera zoom, editor previews and room origins.
	var center := to_local(get_viewport().canvas_transform.affine_inverse() * (get_viewport_rect().size * 0.5))
	for plate in plates:
		var bounds: Rect2 = plate.get_meta("art_bounds")
		var shift := (center - bounds.get_center()) / bounds.size * 0.04
		shift = shift.clamp(Vector2(-0.055, -0.055), Vector2(0.055, 0.055))
		plate.material.set_shader_parameter("camera_shift", shift)
	# The masonry/rock drawing stays cached; only a few motes/lights redraw.
	ambient.queue_redraw()


func _draw() -> void:
	if not built:
		return
	if theme == "city":
		_house(Vector2(3020, 391), Vector2(270, 202), Color("35465a"), false)
		_house(Vector2(3595, 391), Vector2(580, 270), Color("46475e"), true)
		_house(Vector2(4110, 391), Vector2(330, 184), Color("3b5356"), false)
		# An apothecary herb sign, distinct from transition doors and quest icons.
		draw_line(Vector2(4165, 225), Vector2(4210, 225), Color("8c8a7d"), 3)
		draw_line(Vector2(4204, 225), Vector2(4204, 240), Color("8c8a7d"), 2)
		draw_rect(Rect2(4190, 240, 28, 34), Color("1c3134"))
		draw_polyline(PackedVector2Array([Vector2(4204, 266), Vector2(4204, 249), Vector2(4197, 253), Vector2(4204, 258), Vector2(4211, 251)]), Color("a4bf9b"), 2, true)
	for rect in surfaces:
		_terrain(rect)
	if theme == "city":
		for i in range(5):
			_stall(Vector2(3090 + i * 238, 391), Color("8b5369") if i % 2 == 0 else Color("527d80"))
		for x in [2920.0, 3420.0, 3770.0, 4190.0]:
			_lantern(Vector2(x, 306))
		for x in [3330.0, 3890.0, 4130.0]:
			_planter(Vector2(x, 391))


func _draw_ambient() -> void:
	if theme == "city":
		for x in [2920.0, 3420.0, 3770.0, 4190.0]:
			ambient.draw_circle(Vector2(x, 306), 26, Color(1.0, 0.76, 0.41, 0.06 + 0.015 * sin(elapsed * 1.7 + x)))
	else:
		# Sparse motes, not collision-looking circles or heavy particle systems.
		for i in range(24):
			var x := 35.0 + fmod(i * 137.0, 900.0) + sin(elapsed * 0.3 + i) * 8
			var y := -115.0 + fmod(i * 47.0, 240.0) + cos(elapsed * 0.24 + i) * 7
			ambient.draw_circle(Vector2(x, y), 1.0, Color(0.57, 0.9, 0.85, 0.3 + 0.15 * sin(elapsed + i)))


func _terrain(rect: Rect2) -> void:
	var top := rect.position.y
	var deep := 34.0 if rect.size.x > 400 else 13.0
	var base := Color("152d3a") if theme == "grotto" else Color("292b3b")
	var rim := Color("6aa6a6") if theme == "grotto" else Color("a39784")
	var contour := PackedVector2Array([rect.position, Vector2(rect.end.x, top)])
	for i in range(8, -1, -1):
		contour.append(Vector2(lerpf(rect.position.x, rect.end.x, i / 8.0), top + deep + 8 * sin(i * 1.7 + rect.position.x)))
	draw_colored_polygon(contour, base)
	draw_line(rect.position, Vector2(rect.end.x, top), rim, 2.0, true)
	var count := mini(60, int(rect.size.x / 26))
	for i in range(count):
		var x := rect.position.x + 12 + i * 26
		var tone := base.lightened(0.06 + float(i % 3) * 0.025)
		draw_line(Vector2(x, top + 11), Vector2(x + 17, top + 14 + i % 4), tone, 3)
		if theme == "grotto" and (i + int(absf(rect.position.y))) % 5 == 0:
			var height := 5.0 + fposmod(x * 0.13, 5.0)
			for leaf in range(3):
				var side := float(leaf - 1)
				var stem := PackedVector2Array([Vector2(x, top), Vector2(x + side * 2, top - height * 0.35), Vector2(x + side * 4, top - height * 0.8), Vector2(x + side * 7, top - height)])
				draw_polyline(stem, Color("477b79"), 1.0, true)
				if leaf == 1 and i % 2 == 0:
					draw_circle(stem[-1], 1.4, Color("98c6b5"))
		elif theme == "city":
			draw_line(Vector2(x, top + 3), Vector2(x - 3, top + 11), Color("66616a"), 1, true)


func _house(at: Vector2, size: Vector2, tone: Color, hall: bool) -> void:
	var left := at.x - size.x / 2
	var top := at.y - size.y
	draw_rect(Rect2(left, top, size.x, size.y), tone)
	draw_rect(Rect2(left + 8, top + 8, size.x - 16, size.y - 8), tone.darkened(0.15), false, 2)
	for row in range(int(size.y / 22)):
		var y := top + 16 + row * 22
		draw_line(Vector2(left + 5, y), Vector2(left + size.x - 5, y), tone.lightened(0.045), 1)
		for col in range(int(size.x / 42)):
			var x := left + 18 + col * 42 + (row % 2) * 19
			draw_line(Vector2(x, y), Vector2(x, y + 15), tone.darkened(0.10), 1)
	var roof := PackedVector2Array([Vector2(left - 18, top + 5), Vector2(at.x, top - 67), Vector2(left + size.x + 18, top + 5), Vector2(left + size.x + 8, top + 16), Vector2(at.x, top - 49), Vector2(left - 8, top + 16)])
	draw_colored_polygon(roof, Color("243444"))
	draw_polyline(PackedVector2Array([roof[0], roof[1], roof[2]]), Color("918c96"), 3, true)
	for row in range(2 if hall else 1):
		for column in range(6 if hall else 3):
			var x := left + 34 + column * (size.x - 68) / (5.0 if hall else 2.0)
			_window(Vector2(x, top + 45 + row * 93))
	# Recessed arch door and metal fittings; scenery, not a fake transition.
	var door := Rect2(at.x - 20, at.y - 65, 40, 65)
	draw_style_box(_arch_style(Color("101d2a"), 18), door)
	draw_line(Vector2(at.x, at.y - 57), Vector2(at.x, at.y - 2), Color("58606a"), 2)
	draw_circle(Vector2(at.x + 9, at.y - 27), 2, Color("cfb886"))
	if hall:
		draw_circle(Vector2(at.x, top - 15), 16, Color("151e30"))
		for ray in range(8):
			var angle := ray * TAU / 8
			draw_line(Vector2(at.x, top - 15), Vector2(at.x, top - 15) + Vector2.from_angle(angle) * 12, Color("c7ae7e"), 1.5, true)


func _arch_style(tone: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = tone
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	return style


func _window(at: Vector2) -> void:
	draw_style_box(_arch_style(Color("162232"), 13), Rect2(at - Vector2(16, 3), Vector2(32, 46)))
	draw_style_box(_arch_style(Color("bda278"), 9), Rect2(at - Vector2(10, 0), Vector2(20, 35)))
	draw_line(at + Vector2(0, 1), at + Vector2(0, 35), Color("4a474b"), 2)
	draw_line(at + Vector2(-10, 17), at + Vector2(10, 17), Color("4a474b"), 2)
	draw_line(at + Vector2(-18, 43), at + Vector2(18, 43), Color("89848c"), 3)


func _stall(at: Vector2, tone: Color) -> void:
	draw_rect(Rect2(at.x - 50, at.y - 28, 100, 28), Color("493d40"))
	for x in [-50, 50]:
		draw_line(at + Vector2(x, 0), at + Vector2(x, -73), Color("706367"), 3)
	for i in range(8):
		var x := at.x - 60 + i * 15
		draw_colored_polygon(PackedVector2Array([Vector2(x + 4, at.y - 79), Vector2(x + 15, at.y - 79), Vector2(x + 15, at.y - 57), Vector2(x, at.y - 57)]), tone if i % 2 == 0 else tone.lightened(0.18))
	for i in range(7):
		draw_circle(at + Vector2(-35 + i * 11, -33 - i % 2 * 3), 4, Color("bc9272") if i < 4 else Color("879b7c"))


func _lantern(at: Vector2) -> void:
	draw_line(at + Vector2(0, 85), at, Color("616072"), 3)
	draw_rect(Rect2(at - Vector2(7, 9), Vector2(14, 19)), Color("202839"))
	draw_rect(Rect2(at - Vector2(4, 6), Vector2(8, 12)), Color("e8c589"))


func _planter(at: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([at + Vector2(-15, -19), at + Vector2(15, -19), at + Vector2(11, 0), at + Vector2(-11, 0)]), Color("695058"))
	draw_line(at + Vector2(-16, -19), at + Vector2(16, -19), Color("af8a82"), 3)
	for i in range(5):
		var stem := at + Vector2(-10 + i * 5, -19)
		var tip := stem + Vector2(-6 + i * 3, -14 - i % 3 * 5)
		draw_line(stem, tip, Color("789c89"), 1.5, true)
		draw_colored_polygon(PackedVector2Array([stem.lerp(tip, 0.4), tip + Vector2(-6, 4), tip, tip + Vector2(5, 6)]), Color("618979"))
