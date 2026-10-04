@tool
extends Node2D
## Two static depth-separated passes. Collision remains the walkway authority.

@export_enum("walkways", "skyline") var layer := "walkways"
const MASONRY := preload("res://art/visual_slice/city_wall_citadel_v1.png")
const Architecture := preload("res://CityArchitectureAtlas.gd")
var surfaces: Array[Dictionary] = []
var windows: Array[Rect2] = []
var towers: Array[Rect2] = []
var arcades: Array[Dictionary] = []
var masonry: Array[Polygon2D] = []
var retired: Array[Polygon2D] = []
var built := false


func _ready() -> void:
	z_index = -1 if layer == "walkways" else -6
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)
	_build()


func _bounds(plate: Polygon2D) -> Rect2:
	var bounds := Rect2(to_local(plate.to_global(plate.polygon[0])), Vector2.ZERO)
	for point in plate.polygon:
		bounds = bounds.expand(to_local(plate.to_global(point)))
	return bounds


func _build() -> void:
	if built:
		return
	if layer == "walkways":
		for index in range(get_parent().DISTRICTS.size()):
			var district: Array = get_parent().DISTRICTS[index]
			var plate := get_parent().get_node(String(district[0]) + "/TerraceArches") as Polygon2D
			arcades.append({"rect": _bounds(plate), "district": index})
			plate.hide()
			retired.append(plate)
		for plate in get_parent().get_children():
			if plate is Polygon2D and String(plate.name).ends_with("StairMasonry"):
				_dress_masonry(plate, Color("596074"))
		for named in ["BellArchWest", "BellArchEast", "BellArchLintel"]:
			_dress_masonry(get_parent().get_node("BellSquare/" + named), Color("9991ac"))
	for child in get_parent().get_children():
		if layer == "walkways" and child is StaticBody2D:
			var collision := child.get_node_or_null("CollisionShape2D") as CollisionShape2D
			var stone := child.get_node_or_null("Stone") as Polygon2D
			if collision == null or stone == null or not collision.shape is RectangleShape2D:
				continue
			var size: Vector2 = collision.shape.size
			var origin := to_local(collision.to_global(-size * 0.5))
			var kind := "step" if String(child.name).contains("Step") else "terrace"
			if child.name == &"CrossCitySkybridge":
				kind = "bridge"
			surfaces.append({"rect": Rect2(origin, size), "kind": kind, "body": child})
			stone.hide()
			retired.append(stone)
		elif layer == "skyline" and String(child.name).begins_with("UpperSkyline"):
			towers.append(_bounds(child.get_node("SteppedSilhouette")))
			for plate in child.get_children():
				if plate is Polygon2D and String(plate.name).begins_with("Window"):
					windows.append(_bounds(plate))
					plate.hide()
					retired.append(plate)
	built = true
	queue_redraw()


func _dress_masonry(plate: Polygon2D, tint: Color) -> void:
	plate.texture = MASONRY
	plate.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	plate.color = tint
	var uv := PackedVector2Array()
	for point in plate.polygon:
		uv.append(point / 180.0 * MASONRY.get_size())
	plate.uv = uv
	masonry.append(plate)


func _draw() -> void:
	if layer == "walkways":
		for arcade in arcades:
			_arcade(arcade.rect, arcade.district)
		for surface in surfaces:
			_walkway(surface.rect, surface.kind)
	else:
		for tower in towers:
			_tower(tower)
		for index in range(windows.size()):
			_window(windows[index], index)


func _walkway(rect: Rect2, kind: String) -> void:
	var base := Color("57556e")
	var cap := Color("b7b3c9")
	var shadow := Color("303447")
	var metal := Color("9b8a70")
	if kind == "bridge":
		base = Color("4c596a")
	elif kind == "terrace":
		base = Color("646077")
	draw_rect(rect, shadow)
	# This pass replaces Stone, so it must carry the painted material itself.
	# World-scaled UVs keep the same stone grain on short steps and long terraces;
	# stretching the entire atlas into a 14px strip erases all useful texture.
	_masonry_face(Rect2(rect.position + Vector2(0, 1), rect.size - Vector2(0, 2)), base.lightened(0.38))
	# The highlighted edge sits on the original collision top, not above it.
	draw_line(rect.position + Vector2(0, 0.5), Vector2(rect.end.x, rect.position.y + 0.5), cap.darkened(0.15), 1)
	draw_line(Vector2(rect.position.x, rect.end.y - 2), rect.end - Vector2(0, 2), base.darkened(0.25), 2)
	if kind == "step":
		for end in [rect.position.x + 1, rect.end.x - 5]:
			draw_rect(Rect2(end, rect.position.y + 3, 4, rect.size.y - 5), metal)
	elif kind == "bridge":
		# Rivets and shallow metal brackets; no railing across jump approaches.
		for at in range(int(rect.position.x + 24), int(rect.end.x - 10), 104):
			draw_rect(Rect2(at - 3, rect.position.y + 3, 6, rect.size.y - 3), metal)
			draw_circle(Vector2(at, rect.position.y + 5), 1, cap)
			draw_polyline(PackedVector2Array([Vector2(at - 12, rect.end.y), Vector2(at, rect.end.y + 8), Vector2(at + 12, rect.end.y)]), shadow, 2, true)
	else:
		# Flush inlaid diamonds make the four broad district walks distinct from steps.
		for at in range(int(rect.position.x + 40), int(rect.end.x - 20), 208):
			var center := Vector2(at, rect.position.y + 8)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-4, 0), center + Vector2(0, -3), center + Vector2(4, 0), center + Vector2(0, 3)]), metal)


func _masonry_face(rect: Rect2, tint: Color) -> void:
	var points := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var uv := PackedVector2Array()
	for point in points:
		uv.append(point / 180.0)
	draw_polygon(points, PackedColorArray([tint]), uv, MASONRY)


func _tower(rect: Rect2) -> void:
	var center := rect.get_center().x
	var crown := rect.position.y + 35
	var trim := Color("33394f")
	# Shallow recessed bays and paired pilasters break the broad masonry into
	# architecture, not new solid supports. All remain behind playable terraces.
	for side in [-1, 1]:
		var pier_x: float = center + side * rect.size.x * 0.38
		draw_rect(Rect2(pier_x - 8, crown + 170, 16, rect.end.y - crown - 170), Color("222b3b"))
		draw_line(Vector2(pier_x - 8, crown + 170), Vector2(pier_x - 8, rect.end.y), trim, 2)
	for row in range(int((rect.end.y - crown - 215) / 230)):
		var bay := Rect2(center - rect.size.x * 0.27, crown + 205 + row * 230, rect.size.x * 0.54, 180)
		var outline := _arched_bay(bay)
		draw_colored_polygon(outline, Color(0.055, 0.073, 0.12, 0.48))
		draw_polyline(outline, trim, 3, true)
		draw_line(Vector2(bay.position.x - 9, bay.end.y), bay.end + Vector2(9, 0), trim.lightened(0.05), 4)
	# Detail follows the existing stepped silhouette; no new giant columns.
	for side in [-1, 1]:
		var x: float = center + side * rect.size.x * 0.29
		draw_line(Vector2(center, crown + 10), Vector2(x, crown + 90), trim, 3)
		draw_line(Vector2(x, crown + 92), Vector2(x, rect.end.y), Color("222a3f"), 5)
		draw_line(Vector2(center + side * (rect.size.x * 0.5 - 10), crown + 165), Vector2(center + side * (rect.size.x * 0.5 - 10), rect.end.y), trim.darkened(0.16), 2)
	var medallion := Vector2(center, crown + 100)
	Architecture.fit(self,2,3,Rect2(medallion-Vector2(23,23),Vector2(46,46)),Color("39465c"))


func _arched_bay(rect: Rect2) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(rect.position.x, rect.end.y)])
	for i in range(17):
		var angle := PI + PI * i / 16.0
		points.append(Vector2(rect.get_center().x, rect.position.y + 45) + Vector2(cos(angle) * rect.size.x * 0.5, sin(angle) * 45))
	points.append(rect.end)
	return points


func _arcade(rect: Rect2, district: int) -> void:
	# Transparent openings show the same parallax city, never a fake sky.
	for piece in _arcade_pieces(rect,district):
		draw_texture_rect(Architecture.texture_for(0,piece.index),piece.rect,false,Color("a5a7b2"))


func _arcade_pieces(rect: Rect2, district: int) -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	var count := maxi(1, ceili(rect.size.x / 280.0))
	var width := rect.size.x / count
	var index := 1 if district == 1 else (2 if district >= 2 else 0)
	var texture := Architecture.texture_for(0,index)
	var height := texture.get_height() * width / texture.get_width()
	for bay in count:
		pieces.append({"index":index,"rect":Rect2(rect.position + Vector2(bay*width,7),Vector2(width,height))})
	return pieces


func _window(rect: Rect2, index: int) -> void:
	var radius := rect.size.x * 0.5
	var center := rect.position + Vector2(radius, radius)
	var points := PackedVector2Array([Vector2(rect.position.x, rect.end.y)])
	for i in range(9):
		var angle := PI + PI * i / 8.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	points.append(rect.end)
	# Most windows are unlit; warm accents stay much dimmer than foreground lamps.
	var glass := Color("535363") if index % 7 == 0 else Color("252f43")
	draw_colored_polygon(points, glass)
	draw_polyline(points, Color("394258"), 1, true)
	draw_line(Vector2(center.x, rect.position.y + 3), Vector2(center.x, rect.end.y), Color("182237"), 2)
	draw_line(rect.position + Vector2(0, 21), Vector2(rect.end.x, rect.position.y + 21), Color("182237"), 2)
	draw_rect(Rect2(rect.position.x - 3, rect.end.y, rect.size.x + 6, 3), Color("394258"))
