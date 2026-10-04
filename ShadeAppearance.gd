@tool
extends Sprite2D
## Reads native state only; no attack timers, hitboxes or movement are changed.
const SHEET := preload("res://art/characters/echo_shade_v1.png")
const PIXEL_SCALE := 0.09
const PIVOTS := [Vector2(275, 481), Vector2(286, 467), Vector2(286, 467), Vector2(348, 432), Vector2(270, 450), Vector2(272, 449)]
var previous_position := Vector2.ZERO
var glide_grace := 0.0
var face_left := false


func _ready() -> void:
	texture = SHEET
	hframes = 3
	vframes = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	previous_position = get_parent().global_position
	_apply_pose(0, false, Color.WHITE)
	preload("res://MobDefeatEcho.gd").hook(self, "shade")
	visibility_changed.connect(_on_visibility_changed)
	for named in ["Mantle", "BodyVisual", "Eyes"]:
		var leaf := get_parent().get_node_or_null(named)
		if leaf is Polygon2D and leaf.get_child_count() == 0:
			leaf.hide()
	if Engine.is_editor_hint():
		set_process(false)


func _on_visibility_changed() -> void:
	if not Engine.is_editor_hint() and not is_visible_in_tree():
		glide_grace = 0
		previous_position = get_parent().global_position
		_apply_pose(0, face_left, Color.WHITE)

func _process(delta: float) -> void:
	var actor := get_parent()
	var displacement: Vector2 = actor.global_position - previous_position
	previous_position = actor.global_position
	if not is_visible_in_tree() or actor.is_dead:
		glide_grace = 0
		return
	glide_grace = maxf(0, glide_grace - delta)
	var attacking: bool = actor.telegraph_remaining > 0 or actor.dash_remaining > 0
	if displacement.length() >= 40 or attacking or actor.recovery_remaining > 0:
		glide_grace = 0
	elif actor.is_on_floor() and absf(displacement.x) > 0.01:
		glide_grace = 0.04
		face_left = displacement.x < 0
	if attacking:
		face_left = actor.dash_direction < 0
	var pose := 0
	var tint: Color = actor.body_visual.modulate
	if tint.r > 1.05:
		pose = 5
	elif actor.telegraph_remaining > 0:
		pose = 2
		tint *= Color(1.15, 0.8, 0.9)
	elif actor.dash_remaining > 0:
		pose = 3
	elif actor.recovery_remaining > 0:
		pose = 4
	elif glide_grace > 0 and actor.is_on_floor():
		pose = 1
	if actor.zone_tier >= 1:
		tint *= Color(0.8, 1.1, 1.05)
	_apply_pose(pose, face_left, tint)


func _apply_pose(pose: int, facing_left: bool, tint: Color) -> void:
	frame = pose
	flip_h = facing_left
	offset = Vector2(256, 256) - PIVOTS[pose]
	if facing_left:
		offset.x = -offset.x
	position = Vector2(0, 17.5)
	scale = Vector2.ONE * PIXEL_SCALE
	modulate = tint
