@tool
extends Sprite2D

## Reads AI state; never starts an attack or modifies contact damage.
const SHEET = preload("res://art/characters/shaft_wisp_v1.png")
const PIXEL_SCALE := 0.085
const PIVOTS := [Vector2(276, 280), Vector2(256, 294), Vector2(248, 282), Vector2(392, 256), Vector2(256, 256), Vector2(278, 262)]
var elapsed := 0.0
var hurt_remaining := 0.0
var previous_health := -1


func _ready() -> void:
	texture = SHEET
	hframes = 3
	vframes = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_apply_pose(0, Vector2.RIGHT, Vector2.ONE, Color.WHITE)
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
	if not is_visible_in_tree():
		return
	var actor := get_parent()
	elapsed += delta
	hurt_remaining = maxf(0.0, hurt_remaining - delta)
	var pose := int(elapsed * 8.0) % 2
	if hurt_remaining > 0:
		pose = 5
	elif actor.state == actor.State.TELEGRAPH:
		pose = 2
	elif actor.state == actor.State.DIVE:
		pose = 3
	elif actor.state == actor.State.RECOVER:
		pose = 4
	var tint: Color = actor.body_visual.modulate
	# Preserve the old awakened tier's cooler identity, but never wash out
	# the warm warning or the red damage flash.
	if actor.zone_tier >= 1 and pose in [0, 1, 4]:
		tint *= Color(0.72, 1.0, 1.25, 1.0)
	_apply_pose(pose, actor.dive_direction, actor.body_visual.scale, tint)


func _apply_pose(pose: int, direction: Vector2, pulse: Vector2, tint: Color) -> void:
	frame = pose
	offset = Vector2(256, 256) - PIVOTS[pose]
	# Dive texture faces right; rotate around its core, not trailing wings.
	rotation = direction.angle() if pose == 3 else 0.0
	scale = Vector2.ONE * PIXEL_SCALE * pulse
	modulate = tint
