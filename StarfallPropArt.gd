@tool
extends Node2D
## Explicit decoration replacements. Never creates loot, colliders or actors.

@export_enum("city", "outskirts") var theme := "city"
const BOTANY := preload("res://StarfallBotany.gd")
const WOOD := Color("665663")
const IRON := Color("303a49")
const EDGE := Color("9b8fa3")
const MASONRY := preload("res://art/visual_slice/starfall_masonry_v1.png")
const FacadePaint := preload("res://FacadePropAtlas.gd")
const Architecture := preload("res://CityArchitectureAtlas.gd")
const TaskPaint := preload("res://StarfallTaskAtlas.gd")
var props: Array[Dictionary] = []
var masonry: Array[Polygon2D] = []
var retired: Array[Polygon2D] = []
var built := false
var scenery_floors: Array[Rect2] = []


func _ready() -> void:
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_process(false)
	call_deferred("_build")


func _retire(plate: Polygon2D) -> void:
	if plate.visible and plate.get_child_count() == 0:
		plate.hide()
		retired.append(plate)


func _build() -> void:
	if built:
		return
	if theme == "city":
		for index in range(4):
			var place := get_parent().get_node("UpperCity/Workplace%d" % index) as Node2D
			props.append({"kind": "workplace", "index": index, "at": to_local(place.global_position)})
			for child in place.get_children():
				if child is Polygon2D and child.name not in [&"Telescope", &"Tripod"]:
					_retire(child)
	else:
		# Dress the authored ruin silhouettes, without adding new walls or sky.
		for plate in get_parent().get_node("ExpandedRoute/StarfallDescent").get_children():
			if plate is Polygon2D and String(plate.name).begins_with("Identity"):
				plate.texture = MASONRY
				plate.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
				plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				plate.color = Color("55546a")
				var uv := PackedVector2Array()
				for point in plate.polygon:
					uv.append(point * 3.0)
				plate.uv = uv
				masonry.append(plate)
		for plate in get_parent().get_node("ExpandedRoute").find_children("*", "Polygon2D", true, false):
			var parent_name := String(plate.get_parent().name)
			var named := String(plate.name)
			var kind := ""
			if parent_name == "BrokenCaravans" and named.begins_with("Wagon"):
				kind = "wagon"
			elif parent_name == "BrokenCaravans" and named.begins_with("Wheel"):
				kind = "wheel"
			elif parent_name == "SiegeBarricades" and named.begins_with("StakeWall"):
				kind = "barricade"
			if kind.is_empty():
				continue
			var points := PackedVector2Array()
			for point in plate.polygon:
				points.append(to_local(plate.to_global(point)))
			var rect := Rect2(points[0], Vector2.ZERO)
			for point in points:
				rect = rect.expand(point)
			props.append({"kind": kind, "rect": rect, "points": points})
			_retire(plate)
		var nodes: Array[Node] = []
		nodes.assign(get_parent().find_children("*","",true,false))
		scenery_floors = preload("res://WorldSupport.gd").floors(nodes)
	built = true
	# Keep props in front of facade/window ink at the same background depth;
	# actors and interaction markers remain at their existing higher z layers.
	if theme == "city":
		get_parent().move_child(self, -1)
	queue_redraw()


func _draw() -> void:
	var caravan_index := 0
	for prop in props:
		if prop.kind == "workplace":
			draw_set_transform(prop.at)
			_workplace(prop.index)
			draw_set_transform(Vector2.ZERO)
		elif prop.kind == "wagon":
			_draw_route_prop(prop.rect,"caravan_a" if caravan_index%2==0 else "caravan_b",86)
			caravan_index += 1
		elif prop.kind == "wheel":
			pass # Both complete wheels belong to the new correctly sized wagon.
		else:
			_draw_route_prop(prop.rect,"barricade",62)

func _draw_route_prop(rect: Rect2,key: String,width: float) -> void:
	var foot := Vector2(rect.get_center().x,rect.end.y)
	var floor_rect := preload("res://WorldSupport.gd").below(to_global(foot)-Vector2(0,3),scenery_floors,80)
	if floor_rect.has_area(): foot.y = to_local(Vector2(to_global(foot).x,floor_rect.position.y)).y
	TaskPaint.draw_at(self,key,foot,width,72,Color("a6a2b0"))


func _planks(rect: Rect2, tint: Color) -> void:
	draw_rect(rect, tint.darkened(0.3))
	for row in range(maxi(1, int(rect.size.y / 9))):
		var y := rect.position.y + row * 9
		draw_rect(Rect2(rect.position.x + 1, y + 1, rect.size.x - 2, 7), tint.lightened((row % 3) * 0.035))
		draw_line(Vector2(rect.position.x + 6, y + 4), Vector2(rect.end.x - 9, y + 4), tint.darkened(0.13), 1)


func _workplace(index: int) -> void:
	match index:
		0:
			for x in [-76, 67]:
				draw_rect(Rect2(x, -44, 9, 44), WOOD.darkened(0.25))
			_planks(Rect2(-90, -53, 180, 13), WOOD)
			for i in range(3):
				var x := -60 + i * 60
				var rect := Rect2(x - 16, -94 + i % 2 * 7, 32, 38)
				draw_style_box(_lantern_style(), rect)
				for offset in [-8, 0, 8]:
					draw_line(Vector2(x + offset, rect.position.y + 3), Vector2(x + offset, rect.end.y - 3), Color("b58e63"), 1)
				draw_line(Vector2(x - 12, rect.end.y), Vector2(x + 12, rect.end.y), IRON, 3)
				draw_arc(Vector2(x, rect.position.y), 6, PI, TAU, 12, EDGE, 1, true)
			draw_line(Vector2(11, -55), Vector2(30, -69), EDGE, 3)
			for i in range(3):
				draw_rect(Rect2(-35 + i * 2, -56 - i * 3, 24, 3), Color("b0a798"))
		1:
			FacadePaint.draw_at(self,1,0,Vector2(-64,2),46)
			for i in range(3):
				var x := 8 + i * 42
				BOTANY.shrub(self, Vector2(x, -18), 31 + i * 6, i)
				_planks(Rect2(x - 19, -20, 38, 20), Color("5a6770"))
		2:
			for x in [-76, 66]:
				draw_rect(Rect2(x, -27, 10, 27), IRON)
			_planks(Rect2(-95, -39, 190, 14), WOOD)
			for i in range(5):
				var x := -58 + i * 29
				draw_rect(Rect2(x - 6, -43, 12, 4), IRON)
				draw_rect(Rect2(x - 4, -63 + i % 2 * 6, 8, 20 - i % 2 * 6), Color("c4b898"))
				draw_line(Vector2(x - 2, -59), Vector2(x - 2, -46), Color("e3d4aa"), 1)
				draw_circle(Vector2(x, -65 + i % 2 * 6), 2, Color("edca85"))
		3:
			# A painted brass chart mounted on the existing instrument case.
			FacadePaint.draw_at(self,1,1,Vector2(-92,2),27)
			Architecture.fit(self,2,3,Rect2(-103,-23,22,22),Color("afa494"))


func _lantern_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("d2ad77")
	style.border_color = IRON
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style


func draw_ellipse_top(at: Vector2) -> void:
	var ring := PackedVector2Array()
	for i in range(25):
		var angle := i * TAU / 24.0
		ring.append(at + Vector2(cos(angle) * 31, sin(angle) * 6))
	draw_colored_polygon(ring, Color("293c49"))
	draw_polyline(ring, EDGE, 2, true)


func _wheel(at: Vector2, radius: float) -> void:
	draw_arc(at, radius, 0, TAU, 32, IRON, 7, true)
	draw_arc(at, radius - 4, 0, TAU, 32, WOOD.lightened(0.2), 3, true)
	for index in range(8):
		var direction := Vector2.from_angle(index * TAU / 8)
		draw_line(at + direction * 5, at + direction * (radius - 7), WOOD, 4, true)
	draw_circle(at, 7, IRON)
	draw_circle(at, 2, EDGE)


func _wagon(rect: Rect2) -> void:
	var left := rect.position.x
	var floor_y := rect.end.y
	_planks(Rect2(left + 12, floor_y - 42, rect.size.x - 24, 37), WOOD)
	for offset in [30, rect.size.x - 42]:
		draw_rect(Rect2(left + offset, rect.position.y + 5, 7, rect.size.y - 5), IRON)
	draw_polyline(PackedVector2Array([Vector2(left + 30, rect.position.y + 7), Vector2(left + 70, rect.position.y - 8), Vector2(rect.end.x - 42, rect.position.y + 5)]), EDGE.darkened(0.2), 3, true)
	# Torn cloth is deliberately incomplete, unlike the covered city stalls.
	draw_colored_polygon(PackedVector2Array([Vector2(left + 34, rect.position.y + 6), Vector2(left + 72, rect.position.y - 6), Vector2(rect.end.x - 43, rect.position.y + 5), Vector2(rect.end.x - 60, floor_y - 51), Vector2(left + 120, floor_y - 61), Vector2(left + 86, floor_y - 40), Vector2(left + 68, floor_y - 65)]), Color("514c63"))
	_wheel(Vector2(left + 42, floor_y - 20), 29)
	BOTANY.shrub(self, Vector2(rect.end.x + 8, floor_y + 9), 33, 0, true)


func _barricade(rect: Rect2) -> void:
	for index in range(7):
		var x := rect.position.x + 15 + index * (rect.size.x - 30) / 6
		var top := rect.end.y - 43 - (index * 19) % 57
		draw_colored_polygon(PackedVector2Array([Vector2(x - 7, rect.end.y), Vector2(x - 10, top + 16), Vector2(x - 3, top), Vector2(x + 8, top + 13), Vector2(x + 8, rect.end.y)]), WOOD.darkened(0.15))
		draw_line(Vector2(x - 2, top + 18), Vector2(x + 2, rect.end.y - 3), WOOD.lightened(0.2), 1)
	for offset in [17, 35]:
		draw_line(Vector2(rect.position.x, rect.end.y - offset), Vector2(rect.end.x, rect.end.y - offset - 6), IRON, 6)
	for index in range(7):
		var x := rect.position.x + 15 + index * (rect.size.x - 30) / 6
		draw_circle(Vector2(x, rect.end.y - 20), 2, EDGE)
