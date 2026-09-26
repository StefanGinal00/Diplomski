@tool
extends Sprite2D

## Presentation only: attack timers and collision stay owned by Player.
const SHEET = preload("res://art/characters/wayfarer_v1.png")
const MOVEMENT_SHEET = preload("res://art/characters/wayfarer_movement_v1.png")
const COMBAT_SHEET = preload("res://art/characters/wayfarer_combat_v1.png")
const PIXEL_SCALE := 0.062
const PIVOTS := [Vector2(286, 484), Vector2(276, 484), Vector2(278, 484), Vector2(296, 420), Vector2(292, 450), Vector2(306, 456)]
const MOVEMENT_SCALE := 0.05
const MOVEMENT_PIVOTS := [Vector2(320, 602), Vector2(302, 614), Vector2(360, 504), Vector2(302, 532)]
const COMBAT_PIVOTS := [Vector2(270, 490), Vector2(274, 490), Vector2(268, 490), Vector2(270, 454), Vector2(274, 456), Vector2(268, 458)]
enum Pose { IDLE, WALK_A, WALK_B, JUMP, ATTACK, HURT, CROUCH, FALL, DASH, LAND }
var current_pose := Pose.IDLE
var elapsed := 0.0
var hurt_remaining := 0.0
var previous_health := -1
var previous_position := Vector2.ZERO
var stride_distance := 0.0
var walk_grace := 0.0
var landing_remaining := 0.0
var was_falling := false
var attack_class := ""
var attack_weapon_id := ""
var attack_direction := Vector2.RIGHT
var attack_duration := 0.0
var attack_reach := 34.0


func _ready() -> void:
	texture = SHEET
	hframes = 3
	vframes = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_apply_pose(0, false, false)
	if Engine.is_editor_hint():
		set_process(false)
	else:
		get_parent().health_changed.connect(_on_health_changed)
		get_parent().respawned.connect(_on_respawned)
		get_parent().attack_performed.connect(_on_attack_performed)
		get_parent().weapon_changed.connect(_on_weapon_changed)
		visibility_changed.connect(_on_visibility_changed)
		_reset_motion()


func _on_health_changed(current: int, _maximum: int) -> void:
	if previous_health >= 0 and current < previous_health:
		hurt_remaining = 0.16
		attack_class = ""
	previous_health = current


func _on_respawned() -> void:
	hurt_remaining = 0.0
	elapsed = 0.0
	_reset_motion()


func _reset_motion() -> void:
	previous_position = get_parent().global_position
	stride_distance = 0.0
	walk_grace = 0.0
	landing_remaining = 0.0
	was_falling = false
	attack_class = ""


func _on_visibility_changed() -> void:
	_reset_motion()
	if not is_visible_in_tree():
		hurt_remaining = 0.0


func _on_attack_performed(weapon_class: String, direction: Vector2) -> void:
	if not is_visible_in_tree():
		return
	attack_class = weapon_class
	attack_direction = direction
	var actor := get_parent() as Player
	attack_duration = actor.attack_visual_timer.time_left
	attack_reach = actor.attack_cast.shape.size.x
	var state := actor._get_game_state()
	attack_weapon_id = state.get_active_weapon_id() if state != null else "worn_sword"


func _on_weapon_changed(weapon_id: String, _mode: String) -> void:
	if not attack_class.is_empty() and weapon_id != attack_weapon_id:
		attack_class = ""
		# Direct inventory equip also cancels the old weapon's effects.
		# Timers/cooldowns remain owned by Player and are not restarted.
		get_parent()._on_attack_visual_timer_timeout()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var actor := get_parent() as Player
	if actor == null:
		return
	var displacement := actor.global_position - previous_position
	previous_position = actor.global_position
	elapsed += delta
	hurt_remaining = maxf(0.0, hurt_remaining - delta)
	walk_grace = maxf(0.0, walk_grace - delta)
	landing_remaining = maxf(0.0, landing_remaining - delta)
	if actor.attack_visual_timer.is_stopped():
		attack_class = ""
	if displacement.length() >= 80:
		# Door travel/respawn must not be counted as an enormous stride.
		stride_distance = 0.0
		walk_grace = 0.0
		landing_remaining = 0.0
		was_falling = false
		attack_class = ""
	elif actor.is_on_floor() and not actor.is_dashing and absf(actor.velocity.x) > 8 and absf(displacement.x) > 0.01:
		stride_distance += absf(displacement.x)
		# Preserve the current stride between physics ticks at high refresh.
		walk_grace = 0.04
	if actor.is_on_floor():
		if was_falling:
			landing_remaining = 0.09
		was_falling = false
	else:
		was_falling = actor.velocity.y > 30 and not actor.is_dashing
	var pose := Pose.IDLE
	if actor.is_dead or hurt_remaining > 0:
		pose = Pose.HURT
	elif not attack_class.is_empty():
		_apply_attack_pose(attack_class, actor.attack_visual_timer.time_left < attack_duration * 0.45, attack_direction.x < 0, actor.is_crouching, actor.crouch_sprite_height_multiplier)
		return
	elif actor.is_dashing:
		pose = Pose.DASH
	elif not actor.is_on_floor():
		pose = Pose.FALL if actor.velocity.y > 30 else Pose.JUMP
	elif actor.is_crouching:
		pose = Pose.CROUCH
	elif landing_remaining > 0 and absf(actor.velocity.x) < 8:
		# Visual compression only: never locks movement or delays attacks.
		pose = Pose.LAND
	elif walk_grace > 0:
		pose = Pose.WALK_A + int(stride_distance / 18.0) % 2
	_apply_pose(pose, actor.facing_direction < 0, actor.is_crouching, actor.crouch_sprite_height_multiplier)


func _apply_pose(pose: int, face_left: bool, crouching: bool, crouch_multiplier: float = 0.65) -> void:
	current_pose = pose
	var movement := pose >= Pose.CROUCH
	var selected_texture: Texture2D = MOVEMENT_SHEET if movement else SHEET
	if texture != selected_texture:
		frame = 0
		texture = selected_texture
		hframes = 2 if movement else 3
		vframes = 2
	frame = pose - Pose.CROUCH if movement else pose
	flip_h = face_left
	# Registration keeps feet on the original collider's y=10 floor.
	offset = Vector2(313.5, 313.5) - MOVEMENT_PIVOTS[frame] if movement else Vector2(256, 256) - PIVOTS[pose]
	if face_left:
		offset.x = -offset.x
	position = Vector2(0, 10)
	if movement:
		# Authored crouch already bends the knees; do not squash it twice.
		scale = Vector2.ONE * MOVEMENT_SCALE
	else:
		scale = Vector2(PIXEL_SCALE, PIXEL_SCALE * (crouch_multiplier if crouching else 1.0))


func _apply_attack_pose(weapon_class: String, follow_through: bool, face_left: bool, crouching: bool, crouch_multiplier: float = 0.65) -> void:
	current_pose = Pose.ATTACK
	if texture != COMBAT_SHEET:
		frame = 0
		texture = COMBAT_SHEET
		hframes = 3
		vframes = 2
	var column := 1 if weapon_class == "bow" else (2 if weapon_class == "staff" else 0)
	frame = column + (3 if follow_through else 0)
	flip_h = face_left
	offset = Vector2(256, 256) - COMBAT_PIVOTS[frame]
	if face_left:
		offset.x = -offset.x
	position = Vector2(0, 10)
	scale = Vector2(PIXEL_SCALE, PIXEL_SCALE * (crouch_multiplier if crouching else 1.0))
