@tool
extends Node2D

## Movement-driven painted poses; never moves the native resident, interaction
## reach, labels or route markers. Contact follows cached real terrain.
const Support := preload("res://WorldSupport.gd")
const Layout := preload("res://WorldLayout.gd")
const Paint := preload("res://ResidentPaintedArt.gd")
var elapsed := 0.0
var phase := 0.0
var stride := 0.0
var facing := 1.0
var previous_position := Vector2.ZERO
var redraw_clock := 0.0
var coat: Polygon2D
var face: Polygon2D
var accent: Polygon2D
var origins: Array[Vector2] = []
var painted: Sprite2D
var surfaces: Array[Rect2] = []
var foot_y := 14.0


func _ready() -> void:
	coat = get_parent().get_node("Coat")
	face = get_parent().get_node("Face")
	accent = get_parent().get_node("Accent")
	origins.assign([coat.position, face.position, accent.position])
	previous_position = get_parent().position
	visibility_changed.connect(_reset_hidden)
	painted = Paint.new()
	painted.name = "PaintedBody"
	add_child(painted)
	painted.configure(get_parent())
	for old in [coat, face, accent]: old.hide()
	call_deferred("_bootstrap_contacts")
	if Engine.is_editor_hint():
		set_process(false)


func _bootstrap_contacts() -> void:
	# WorldPresentationFinish provides one shared room survey in the game.
	# Standalone F6 town scenes also work, without scanning unrelated rooms.
	var scope := get_parent().get_parent()
	var cursor := scope
	var found_room := false
	while cursor != null and cursor != get_tree().root:
		if cursor.has_node("WorldPresentationFinish"): return
		if not found_room: scope = cursor
		if String(cursor.name) in Layout.ROOM_NODES.values(): found_room = true
		cursor = cursor.get_parent()
	if scope == get_tree().root: return
	var nodes: Array[Node] = []
	if scope != null: nodes.assign(scope.find_children("*", "", true, false))
	supply_surfaces(Support.floors(nodes))


func supply_surfaces(value: Array[Rect2]) -> void:
	surfaces = value
	_update_paint()


func _update_paint() -> void:
	if painted == null: return
	var floor_rect := Support.below(get_parent().global_position, surfaces, 64)
	foot_y = to_local(Vector2(global_position.x, floor_rect.position.y)).y if floor_rect.has_area() else 14.0
	var pose := 3 if _is_speaking() else 0
	if stride > 0.15 and not _is_speaking():
		painted.show_walk(int(fposmod(phase,TAU)/TAU*8), facing, foot_y)
		return
	painted.show_pose(pose, facing, foot_y, elapsed)


func _reset_hidden() -> void:
	previous_position = get_parent().position
	stride = 0.0
	phase = 0.0
	redraw_clock = 0.0
	if origins.size() == 3:
		coat.position = origins[0]
		face.position = origins[1]
		accent.position = origins[2]
	_update_paint()


func _process(delta: float) -> void:
	var resident := get_parent()
	if not is_visible_in_tree():
		previous_position = resident.position
		return
	var movement: Vector2 = resident.position - previous_position
	previous_position = resident.position
	var speed := movement.length() / maxf(delta, 0.001)
	# Room relocation / save restore is not a walking stride.
	if movement.length() > 20:
		speed = 0
		stride = 0
		phase = 0
	if absf(movement.x) > 0.01 and movement.length() <= 20:
		facing = signf(movement.x)
	if not Engine.is_editor_hint() and resident.has_method("get_attention_target"):
		var target = resident.get_attention_target()
		if is_instance_valid(target):
			var distance: float = target.global_position.x - resident.global_position.x
			if absf(distance) > 1:
				facing = signf(distance)
	stride = move_toward(stride, clampf(speed / 30.0, 0.0, 1.0), delta * 8)
	elapsed += delta
	if movement.length() <= 20:
		phase = fposmod(phase + absf(movement.x)/28.0*TAU,TAU)
	redraw_clock += delta
	var low := OS.has_feature("mobile") or bool(ProjectSettings.get_setting("world/ambient/low_cost", false))
	if redraw_clock < (0.1 if low else 0.05):
		return
	redraw_clock = 0.0
	var view: Rect2 = get_viewport().canvas_transform.affine_inverse() * get_viewport().get_visible_rect()
	if view.grow(100).has_point(global_position): _update_paint()


func _is_speaking() -> bool:
	return not Engine.is_editor_hint() and (get_parent().get("player_dialogue_active") == true or get_parent().get_node("SocialBubble").visible)
