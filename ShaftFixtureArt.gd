@tool
extends Node2D
## Small painted landmarks replacing the old overview-sized field diagrams.
const SHEET := preload("res://art/visual_slice/shaft_fixtures_v1.png")
const CROPS := [Rect2(48,8,472,496), Rect2(580,7,430,496), Rect2(1094,8,354,496), Rect2(13,693,580,284), Rect2(594,512,370,469), Rect2(986,618,520,350)]
const KINDS := {"pressure_lower":0, "pressure_upper":0, "dial_guide":0, "tank":1, "water":1, "relay_board":2, "moor":3, "counterweight":4, "memorial":5, "survey":5}
var kind := ""
var body: Sprite2D
var age := 0.0
var retired: Array[CanvasItem] = []

static func attach(site: Node2D, style: String) -> void:
	if not KINDS.has(style) or site.has_node("ShaftFixture"): return
	var art := new()
	art.kind = style
	art.name = "ShaftFixture"
	site.add_child(art)

func _ready() -> void:
	set_process(false)
	var index: int = KINDS[kind]
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	var ratio := SHEET.get_size() / Vector2(1536, 1024)
	atlas.region = Rect2(CROPS[index].position * ratio, CROPS[index].size * ratio)
	atlas.filter_clip = true
	body = Sprite2D.new()
	body.name = "PaintedMechanism"
	body.texture = atlas
	body.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var height: float = [66, 74, 64, 38, 80, 47][index]
	body.scale = Vector2.ONE * height / atlas.get_height()
	body.position.y = -height * 0.5
	add_child(body)
	for old in get_parent().get_children():
		if (old is Polygon2D or old is Line2D) and old.get_child_count() == 0:
			old.self_modulate.a = 0 # Controllers may still set visible and color.
			retired.append(old)
	for old in get_parent().get_children():
		if old is Label and String(old.name).begins_with("DialName"): old.hide()
	if not Engine.is_editor_hint():
		set_meta("ambient_motion", true)
		call_deferred("_fit")

func _fit() -> void:
	var room := get_parent().get_parent().room as Node2D
	var surfaces := preload("res://WorldSupport.gd").floors(room.find_children("*", "", true, false))
	var floor_rect := preload("res://WorldSupport.gd").below(global_position - Vector2(0, 18), surfaces, 40)
	if floor_rect.has_area(): global_position.y = floor_rect.position.y
	# Keep furniture below actual low ceilings, with original aspect ratio.
	var desired := body.texture.get_height() * body.scale.y
	var clearance := desired
	for floor_part in surfaces:
		if floor_part.end.y < global_position.y - 8 and floor_part.end.x > global_position.x - 25 and floor_part.position.x < global_position.x + 25:
			clearance = minf(clearance, global_position.y - floor_part.end.y - 4)
	scale = Vector2.ONE * clampf(clearance / desired, 0.4, 1.0)

func animate(value: float) -> void:
	age = value
	queue_redraw()

func rest() -> void:
	age = 0
	queue_redraw()

func _draw() -> void:
	if Engine.is_editor_hint() or body == null: return
	var lens := get_parent().get_node_or_null("RelayLight") as Polygon2D
	if lens != null:
		var active := lens.color.g > 0.7
		var tint := Color(0.28, 0.94, 0.8, (0.1 + 0.04 * sin(age * 3)) if active else 0.018)
		for i in 5: draw_circle(Vector2(-5, -44), 3.0 + i * 1.2, tint)
	var status := get_parent().get_node_or_null("StatusLight") as Polygon2D
	if status != null:
		var tint := status.color
		tint.a = 0.17
		for i in 3: draw_circle(Vector2(2, -39), 2 + i, tint)
