@tool
extends Sprite2D
## Read-only presentation for Echo grazers; other species retain their art.
const SHEET := preload("res://art/characters/echo_grazer_v1.png")
const PIXEL_SCALE := 0.065
const PIVOTS := [Vector2(252, 422), Vector2(255, 431), Vector2(256, 430), Vector2(254, 399), Vector2(246, 400), Vector2(251, 398)]
const CONTACT_ROWS := [421, 430, 429, 397, 400, 397]
var enabled := false
var previous_position := Vector2.ZERO
var stride_distance := 0.0
var walk_grace := 0.0


func _ready() -> void:
	var actor := get_parent()
	var is_grazer: bool = actor.creature_name == "Mossling" or actor.creature_name.ends_with(" Grazer")
	if actor.zone_id not in ["echo_grotto", "training_passage", "sunken_shaft", "ashen_bastion", "starfall_reach"] or not is_grazer:
		hide()
		set_process(false)
		return
	var original := actor.get_node_or_null("Sprite2D") as Sprite2D
	if original == null or original.get_child_count() != 0:
		hide()
		set_process(false)
		return
	enabled = true
	texture = SHEET
	hframes = 3
	vframes = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	previous_position = actor.global_position
	_apply_pose(0 if actor.start_resting else 1, false, Color.WHITE)
	original.hide()
	# Keep the short name below the health bar, out of low overhead steps.
	var name_tag := actor.get_node("NameLabel") as Label
	name_tag.position = Vector2(-100, -25)
	name_tag.size = Vector2(200, 15)
	if Engine.is_editor_hint():
		set_process(false)


func _process(delta: float) -> void:
	if not enabled:
		return
	var actor := get_parent()
	var displacement: Vector2 = actor.global_position - previous_position
	previous_position = actor.global_position
	if not is_visible_in_tree():
		walk_grace = 0.0
		return
	walk_grace = maxf(0, walk_grace - delta)
	var moving_allowed: bool = not actor.resting and actor.grace_remaining <= 0 and actor.hit_stun_remaining <= 0
	if displacement.length() >= 40 or not moving_allowed:
		walk_grace = 0.0
	elif actor.is_on_floor() and absf(displacement.x) > 0.01:
		stride_distance += absf(displacement.x)
		walk_grace = 0.04
	var pose := 1
	if actor.hit_flash_remaining > 0:
		pose = 5
	elif actor.resting and not actor.is_hostile:
		pose = 0
	elif actor.grace_remaining > 0:
		pose = 4
	elif actor.is_on_floor() and walk_grace > 0:
		pose = 2 + int(stride_distance / 3.0) % 2
	elif actor.is_hostile:
		pose = 4
	# Preserve native damage flash. Soften normal biome tints to keep detail.
	var tint: Color = actor.sprite.modulate
	if actor.hit_flash_remaining <= 0:
		tint = tint.lerp(Color.WHITE, 0.55)
	_apply_pose(pose, actor.direction < 0, tint)


func _apply_pose(pose: int, face_left: bool, tint: Color) -> void:
	frame = pose
	flip_h = face_left
	offset = Vector2(256, 256) - PIVOTS[pose]
	offset.y = 256 - CONTACT_ROWS[pose]
	if face_left:
		offset.x = -offset.x
	position = Vector2(0, 9)
	scale = Vector2.ONE * PIXEL_SCALE
	modulate = tint
