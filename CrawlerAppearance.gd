@tool
extends Sprite2D

## Art only. The crawler owns AI, warning duration, contact damage and drops.
const SHEET = preload("res://art/characters/shaft_crawler_v1.png")
const PIXEL_SCALE := 0.07
const PIVOTS := [Vector2(274, 462), Vector2(270, 462), Vector2(258, 464), Vector2(254, 404), Vector2(266, 404), Vector2(254, 402)]
var previous_position := Vector2.ZERO
var previous_health := -1
var hurt_remaining := 0.0
var stride_distance := 0.0
var walk_grace := 0.0


func _ready() -> void:
	texture = SHEET
	hframes = 3
	vframes = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	previous_position = get_parent().global_position
	_apply_pose(0, false, Color.WHITE)
	if Engine.is_editor_hint():
		set_process(false)
	else:
		get_parent().health_changed.connect(_on_health_changed)
		get_parent().ready.connect(_initialize_health, CONNECT_ONE_SHOT)


func _initialize_health() -> void:
	previous_health = get_parent().current_health


func _on_health_changed(current: int, _maximum: int) -> void:
	if previous_health >= 0 and current < previous_health:
		hurt_remaining = 0.14
	previous_health = current


func _process(delta: float) -> void:
	var actor := get_parent()
	var displacement: Vector2 = actor.global_position - previous_position
	previous_position = actor.global_position
	if not is_visible_in_tree():
		walk_grace = 0.0
		return
	hurt_remaining = maxf(0.0, hurt_remaining - delta)
	walk_grace = maxf(0.0, walk_grace - delta)
	if displacement.length() >= 40:
		walk_grace = 0.0
	elif actor.state == actor.State.PATROL and actor.is_on_floor() and absf(displacement.x) > 0.01:
		stride_distance += absf(displacement.x)
		# Render can run faster than physics: retain the stride between ticks.
		walk_grace = 0.04
	var pose := 0
	if hurt_remaining > 0:
		pose = 5
	elif actor.state == actor.State.WARNING:
		pose = 3
	elif actor.state == actor.State.CHARGE:
		pose = 4
	elif actor.state == actor.State.RECOVER:
		pose = 5
	elif actor.is_on_floor() and walk_grace > 0:
		# Actual travel drives feet, so blocked or relocated actors don't run
		# in place. The same walk is faster when awakened patrol is faster.
		pose = 1 + int(stride_distance / 5.0) % 2
	var tint: Color = actor.body_visual.modulate
	if actor.zone_tier >= 1 and pose in [0, 1, 2, 5] and hurt_remaining <= 0:
		tint *= Color(0.82, 1.0, 1.12, 1.0)
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
