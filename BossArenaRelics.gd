@tool
extends Node2D
## Small painted foreground landmarks. They remain after victory and load in the
## editor as well as the game; no collision, trigger, light or background plate.
const ATLAS = preload("res://art/visual_slice/boss_arena_relics_v1.png")
const REGIONS := [Rect2(144, 32, 376, 535), Rect2(756, 64, 434, 513), Rect2(141, 639, 415, 514), Rect2(834, 619, 275, 534)]
const TINTS := [Color("efa566"), Color("cba1ef"), Color("72c3c9"), Color("a9baff")]
@export_enum("Brazier", "Resonance crystal", "Drowned seal", "Astral relic") var style := 0
@export var points := PackedVector2Array([Vector2(-180, 0), Vector2(180, 0)])
@export var height := 65.0
var age := 0.0
var redraw_clock := 0.0
var finished_surfaces: Array[Node2D] = []

func _ready() -> void:
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	queue_redraw()
	call_deferred("_finish_surfaces")

func _finish_surfaces() -> void:
	var room := get_parent()
	# Both passes are deferred; explicitly honor the texture pass dependency
	# instead of relying on sibling ordering in .tscn files.
	for named in ["RemainingArt", "WardenArt", "ArenaArt"]:
		var painter := room.get_node_or_null(named)
		if painter != null and painter.has_method("_build"):
			painter._build()
	if room.name == "TrainingPassageDecor":
		room = room.get_parent()
	_finish_doors(room)
	var left := INF
	var right := -INF
	for point in points:
		left = minf(left, to_global(point).x - 50)
		right = maxf(right, to_global(point).x + 50)
	for body in room.get_children():
		if not body is StaticBody2D:
			continue
		var visual := body.get_node_or_null("Visual") as Polygon2D
		if visual == null:
			visual = body.get_node_or_null("Polygon2D") as Polygon2D
		if visual == null or visual.has_node("ArenaMaterialDetail") or visual.polygon.is_empty():
			continue
		var rect := Rect2(visual.polygon[0], Vector2.ZERO)
		for point in visual.polygon:
			rect = rect.expand(point)
		if rect.size.y > 32 or rect.size.x < 40 or visual.polygon.size() != 4:
			continue
		var rectangular := true
		for point in visual.polygon:
			rectangular = rectangular and (is_equal_approx(point.x, rect.position.x) or is_equal_approx(point.x, rect.end.x)) and (is_equal_approx(point.y, rect.position.y) or is_equal_approx(point.y, rect.end.y))
		if not rectangular:
			continue
		# The Sentinel shares Game's root: only touch his horizontal arena band.
		var origin := visual.to_global(rect.position)
		var end := visual.to_global(rect.end)
		if end.x < left or origin.x > right or absf(origin.y - to_global(points[0]).y) > 300:
			continue
		var clipped_left := maxf(rect.position.x, visual.to_local(Vector2(left, origin.y)).x)
		var clipped_right := minf(rect.end.x, visual.to_local(Vector2(right, origin.y)).x)
		rect.position.x = clipped_left
		rect.size.x = clipped_right - clipped_left
		var detail := preload("res://ArenaSurfaceDetail.gd").new()
		detail.name = "ArenaMaterialDetail"
		detail.style = style
		detail.stone = visual.texture
		if detail.stone == null:
			detail.stone = preload("res://art/visual_slice/echo_path_stone_v1.png")
			detail.fill_base = true
		detail.bounds = rect.grow(-1)
		visual.add_child(detail)
		finished_surfaces.append(detail)

func _finish_doors(room: Node) -> void:
	# Only direct arena doors; no global reskin, logic, transform or collision edits.
	for door in room.get_children():
		if not door.is_in_group("room_door") or door.has_meta("arena_material_finished"):
			continue
		# Game also contains unrelated opening interactions.
		if room == get_parent().get_parent() and get_parent().name == "TrainingPassageDecor" and door.position.x < 900:
			continue
		var frame := door.get_node_or_null("Frame") as Polygon2D
		var core := door.get_node_or_null("Core") as Polygon2D
		if frame == null or core == null: continue
		var stone: Texture2D = preload("res://art/visual_slice/cinder_masonry_v1.png") if style == 0 else preload("res://art/visual_slice/echo_path_stone_v1.png")
		preload("res://RoomArtFinish.gd")._material(frame, stone, Color("b3a49a") if style == 0 else Color("98a8b4"))
		if not Engine.is_editor_hint():
			door.default_frame_color = frame.color
		var wood: Texture2D = preload("res://art/visual_slice/cinder_door_v1.png") if style == 0 else preload("res://art/visual_slice/echo_door_v1.png")
		core.texture = wood
		core.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		core.color = Color("c4b3a0") if style == 0 else Color("a0b4ba")
		core.uv = PackedVector2Array([Vector2.ZERO, Vector2(wood.get_width(), 0), wood.get_size(), Vector2(0, wood.get_height())])
		door.set_meta("arena_material_finished", true)
		if not Engine.is_editor_hint():
			door._update_status_label()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	age += delta
	redraw_clock += delta
	if redraw_clock >= 1.0 / 24.0:
		redraw_clock = 0
		queue_redraw()

func _draw() -> void:
	var region: Rect2 = REGIONS[style]
	var size := region.size * (height / region.size.y)
	for point in points:
		draw_texture_rect_region(ATLAS, Rect2(point - Vector2(size.x * 0.5, size.y), size), region, Color(0.82, 0.85, 0.9))
		var light := point - Vector2(0, height * (0.74 if style == 0 else 0.8))
		draw_circle(light, 7 + sin(age * 2.1) * 1.5, Color(TINTS[style], 0.05))
		for i in range(3):
			var rise := fmod(age * 8 + i * 11, 32)
			draw_circle(light + Vector2(sin(age + i * 2) * 5, -rise), 0.7, Color(TINTS[style], (1 - rise / 32) * 0.45))
