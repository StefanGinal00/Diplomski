@tool
extends Sprite2D
## Presentation only: the broodling still owns every AI/contact/reward rule.
const SHEET := preload("res://art/characters/echo_broodling_v1.png")
const PIXEL_SCALE := 0.09
const PIVOTS := [Vector2(262, 424), Vector2(256, 424), Vector2(254, 423), Vector2(259, 410), Vector2(256, 410), Vector2(248, 410)]
var previous_position := Vector2.ZERO
var stride_distance := 0.0
var walk_grace := 0.0


func _ready() -> void:
	texture = SHEET
	hframes = 3
	vframes = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	previous_position = get_parent().global_position
	# The non-tool AI script does not expose runtime fields in editor previews.
	var face_left := false
	if not Engine.is_editor_hint():
		face_left = get_parent().direction < 0
	_apply_pose(0, face_left, Color.WHITE)
	preload("res://MobDefeatEcho.gd").hook(self, "broodling")
	visibility_changed.connect(_on_visibility_changed)
	for named in ["BodyVisual", "BackSpines", "Eye"]:
		var leaf := get_parent().get_node_or_null(named)
		if leaf is Polygon2D and leaf.get_child_count() == 0:
			leaf.hide()
	if Engine.is_editor_hint():
		set_process(false)


func _on_visibility_changed() -> void:
	if not Engine.is_editor_hint() and not is_visible_in_tree():
		walk_grace = 0
		stride_distance = 0
		previous_position = get_parent().global_position
		_apply_pose(0, flip_h, Color.WHITE)

func _process(delta: float) -> void:
	var actor := get_parent()
	var displacement: Vector2 = actor.global_position - previous_position
	previous_position = actor.global_position
	if not is_visible_in_tree():
		walk_grace = 0.0
		return
	walk_grace = maxf(0.0, walk_grace - delta)
	if displacement.length() >= 40:
		walk_grace = 0.0
	elif actor.state == actor.State.PATROL and actor.is_on_floor() and absf(displacement.x) > 0.01:
		stride_distance += absf(displacement.x)
		# Preserve pose between physics ticks without running in place at a wall.
		walk_grace = 0.04
	var pose := 0
	var tint: Color = actor.body_visual.modulate
	match actor.state:
		actor.State.WINDUP:
			pose = 3
			tint *= Color(1.15, 0.8, 0.85)
		actor.State.LEAP:
			pose = 4
		actor.State.RECOVER:
			pose = 5
		_:
			if actor.is_on_floor() and walk_grace > 0:
				pose = 1 + int(stride_distance / 4.0) % 2
	if actor.zone_tier >= 1:
		tint *= Color(0.85, 1.0, 1.1)
	_apply_pose(pose, actor.direction < 0, tint)


func _apply_pose(pose: int, face_left: bool, tint: Color) -> void:
	frame = pose
	flip_h = face_left
	offset = Vector2(256, 256) - PIVOTS[pose]
	if face_left:
		offset.x = -offset.x
	position = Vector2(0, 9)
	scale = Vector2.ONE * PIXEL_SCALE
	modulate = tint
