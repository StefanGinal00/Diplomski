@tool
extends Sprite2D

## Presentation only: attack timers and collision stay owned by Player.
const SHEET = preload("res://art/characters/wayfarer_v1.png")
const MOVEMENT_SHEET = preload("res://art/characters/wayfarer_movement_v1.png")
const COMBAT_SHEET = preload("res://art/characters/wayfarer_combat_v1.png")
const Impact = preload("res://ProjectileImpact.gd")
const PIXEL_SCALE := 0.062
const PIVOTS := [Vector2(286, 484), Vector2(276, 484), Vector2(278, 484), Vector2(296, 420), Vector2(292, 450), Vector2(306, 456)]
const MOVEMENT_SCALE := 0.05
const MOVEMENT_PIVOTS := [Vector2(320, 602), Vector2(302, 614), Vector2(360, 504), Vector2(302, 532)]
const COMBAT_PIVOTS := [Vector2(270, 490), Vector2(274, 490), Vector2(268, 490), Vector2(270, 454), Vector2(274, 456), Vector2(268, 458)]
const GROUND_ROWS := [486, 486, 486]
const MOVEMENT_GROUND_ROWS := {0: 604, 3: 533}
const COMBAT_GROUND_ROWS := [491, 492, 492, 456, 457, 459]
enum Pose { IDLE, WALK_A, WALK_B, JUMP, ATTACK, HURT, CROUCH, FALL, DASH, LAND }
var current_pose := Pose.IDLE
var elapsed := 0.0
var hurt_remaining := 0.0
var previous_health := -1
var previous_position := Vector2.ZERO
var stride_distance := 0.0
var walk_direction := 0.0
var walk_grace := 0.0
var landing_remaining := 0.0
var was_falling := false
var attack_class := ""
var attack_weapon_id := ""
var attack_direction := Vector2.RIGHT
var attack_duration := 0.0
var attack_reach := 34.0
var damage_flash_remaining := 0.0
var damage_flash_color := Color.WHITE
var damage_burst: Node2D


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
		get_parent().damage_received.connect(_on_damage_received)
		var state := get_node_or_null("/root/GameState")
		if state != null:
			state.room_changed.connect(_clear_damage_feedback)
			state.checkpoint_resting.connect(_clear_damage_feedback)
			state.room_changed.connect(_on_motion_boundary)
			state.checkpoint_resting.connect(_on_motion_boundary)
		var transition := get_node_or_null("/root/RoomTransition")
		if transition != null:
			transition.transition_started.connect(_clear_damage_feedback)
			transition.transition_started.connect(_on_motion_boundary)
		visibility_changed.connect(_on_visibility_changed)
		_reset_motion()


func _on_health_changed(current: int, _maximum: int) -> void:
	if previous_health >= 0 and current < previous_health:
		hurt_remaining = 0.16
		attack_class = ""
		_reset_stride()
	previous_health = current


func _on_respawned() -> void:
	_clear_damage_feedback()
	hurt_remaining = 0.0
	elapsed = 0.0
	_reset_motion()


func _reset_motion() -> void:
	previous_position = get_parent().global_position
	_reset_stride()
	landing_remaining = 0.0
	was_falling = false
	attack_class = ""


func _reset_stride() -> void:
	stride_distance = 0.0
	walk_grace = 0.0
	walk_direction = 0.0


func _on_motion_boundary(_unused: String = "") -> void:
	_reset_motion()


func _on_visibility_changed() -> void:
	_reset_motion()
	if not is_visible_in_tree():
		hurt_remaining = 0.0
		_clear_damage_feedback()


func _clear_damage_feedback(_unused: String = "") -> void:
	hurt_remaining = 0.0
	damage_flash_remaining = 0.0
	self_modulate = Color.WHITE
	if is_instance_valid(damage_burst):
		damage_burst.queue_free()
	damage_burst = null


func _exit_tree() -> void:
	_clear_damage_feedback()


func _on_damage_received(_amount: int, knockback: Vector2, outcome: String) -> void:
	_clear_damage_feedback()
	if outcome == "fatal" or not is_visible_in_tree():
		return # Death still uses the existing hide/respawn behavior.
	hurt_remaining = 0.16
	attack_class = ""
	_reset_stride()
	var rescued := outcome == "second_breath"
	# Modulation above 1 keeps the dark hurt sprite readable through the
	# existing 0.5 invulnerability alpha, without changing that alpha itself.
	damage_flash_color = Color(2.0, 1.85, 1.25) if rescued else Color(2.0, 1.4, 1.25)
	damage_flash_remaining = 0.12
	self_modulate = damage_flash_color
	var actor := get_parent() as Player
	# Direction is the existing knockback direction, not an invented attacker
	# position. Zero-knockback hazards get an upward cue.
	var aim := Vector2(signf(knockback.x), 0) if not is_zero_approx(knockback.x) else Vector2.UP
	damage_burst = Impact.spawn(actor, actor.global_position + Vector2(0, -3), aim, "player_rescue" if rescued else "player_hurt", Color("f5ce7a") if rescued else Color("f38677"), "actor")


func _on_attack_performed(weapon_class: String, direction: Vector2) -> void:
	if not is_visible_in_tree():
		return
	_reset_stride()
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
	damage_flash_remaining = maxf(0.0, damage_flash_remaining - delta)
	self_modulate = Color.WHITE.lerp(damage_flash_color, damage_flash_remaining / 0.12)
	hurt_remaining = maxf(0.0, hurt_remaining - delta)
	walk_grace = maxf(0.0, walk_grace - delta)
	landing_remaining = maxf(0.0, landing_remaining - delta)
	if actor.attack_visual_timer.is_stopped():
		attack_class = ""
	if displacement.length() >= 80:
		# Door travel/respawn must not be counted as an enormous stride.
		_reset_motion()
	elif not actor.is_on_floor() or actor.is_dashing or actor.is_crouching or actor.is_safe_resting or actor.is_dead or hurt_remaining > 0 or not attack_class.is_empty():
		# Attack, knockback recoil and airborne travel are not walking distance.
		_reset_stride()
	elif absf(actor.velocity.x) > 8 and absf(displacement.x) > 0.01:
		var next_direction := signf(displacement.x)
		if next_direction != walk_direction:
			stride_distance = 0.0
		walk_direction = next_direction
		stride_distance += absf(displacement.x)
		# Preserve the current stride between physics ticks at high refresh.
		walk_grace = 0.04
	elif walk_grace <= 0:
		# Remember the final distance for diagnostics, but restart the next stride.
		walk_direction = 0.0
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
	# Only supporting-foot poses are re-registered. Jump/fall/dash keep their
	# authored tucked legs, and this does not change the physics body's y.
	if not movement and pose <= Pose.WALK_B: offset.y = 256 - GROUND_ROWS[pose]
	elif movement and MOVEMENT_GROUND_ROWS.has(frame): offset.y = 313.5 - MOVEMENT_GROUND_ROWS[frame]
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
	offset.y = 256 - COMBAT_GROUND_ROWS[frame]
	if face_left:
		offset.x = -offset.x
	position = Vector2(0, 10)
	scale = Vector2(PIXEL_SCALE, PIXEL_SCALE * (crouch_multiplier if crouching else 1.0))
