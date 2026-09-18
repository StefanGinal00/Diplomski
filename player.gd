class_name Player
extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal progression_changed(current_xp: int, required_xp: int, skill_points: int)
signal double_jump_state_changed(is_unlocked: bool)
signal dash_state_changed(is_unlocked: bool)
signal died

@export_category("Movement")
@export var move_speed: float = 165.0
@export var acceleration: float = 900.0
@export var friction: float = 1100.0
@export var crouch_speed_multiplier: float = 0.45
@export_range(0.3, 1.0, 0.05) var crouch_sprite_height_multiplier: float = 0.65

@export_category("Jump")
@export var jump_force: float = -420.0
@export var gravity: float = 1000.0
@export var fall_gravity_multiplier: float = 1.4
@export_range(0.0, 0.3, 0.01) var coyote_time: float = 0.12
@export_range(0.0, 0.3, 0.01) var jump_buffer_time: float = 0.12
@export_range(0.2, 0.9, 0.05) var jump_release_multiplier: float = 0.5

@export_category("Dash")
@export var dash_speed: float = 360.0
@export_range(0.05, 0.5, 0.01) var dash_duration: float = 0.16
@export_range(0.1, 2.0, 0.05) var dash_cooldown: float = 0.45

@export_category("Health")
@export_range(1, 100, 1) var max_health: int = 5
@export_range(0.1, 5.0, 0.1) var invulnerability_duration: float = 0.8

@export_category("Progression")
@export_range(1, 999, 1) var xp_per_level: int = 3
@export_range(1, 10, 1) var double_jump_cost: int = 1
@export_range(1, 10, 1) var dash_cost: int = 1

@export_category("Combat")
@export_range(1, 100, 1) var attack_damage: int = 1
@export_range(8.0, 80.0, 1.0) var attack_offset: float = 24.0
@export_range(0.05, 2.0, 0.05) var attack_cooldown: float = 0.35
@export_range(0.02, 1.0, 0.01) var attack_visual_duration: float = 0.12
@export var attack_knockback: Vector2 = Vector2(170.0, -70.0)

var current_health: int
var xp: int = 0
var skill_points: int = 0
var double_jump_unlocked: bool = false
var dash_unlocked: bool = false

var jump_count: int = 0
var coyote_time_remaining: float = 0.0
var jump_buffer_remaining: float = 0.0
var dash_time_remaining: float = 0.0
var dash_cooldown_remaining: float = 0.0
var is_dashing: bool = false
var is_crouching: bool = false
var is_invulnerable: bool = false
var is_dead: bool = false
var facing_direction: float = 1.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var player_collision: CollisionShape2D = $CollisionShape2D
@onready var invulnerability_timer: Timer = $InvulnerabilityTimer
@onready var attack_cast: ShapeCast2D = $AttackCast
@onready var attack_visual: Polygon2D = $AttackCast/AttackVisual
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var attack_visual_timer: Timer = $AttackVisualTimer
@onready var dash_visual: Polygon2D = $DashVisual

var standing_sprite_scale: Vector2


func _ready() -> void:
	current_health = max_health
	standing_sprite_scale = sprite.scale
	invulnerability_timer.wait_time = invulnerability_duration
	attack_cooldown_timer.wait_time = attack_cooldown
	attack_visual_timer.wait_time = attack_visual_duration
	attack_visual.hide()
	dash_visual.hide()
	attack_visual_timer.timeout.connect(_on_attack_visual_timer_timeout)
	_update_attack_direction()
	_emit_current_state()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_update_dash_timers(delta)
	if Input.is_action_just_pressed("dash"):
		try_dash()
	if is_dashing:
		velocity = Vector2(dash_speed * facing_direction, 0.0)
		move_and_slide()
		return

	_update_jump_windows(delta)
	_apply_gravity(delta)

	var should_crouch := is_on_floor() and Input.is_action_pressed("ui_down")
	_set_crouching(should_crouch)

	var direction := Input.get_axis("ui_left", "ui_right")
	var current_speed := move_speed
	if is_crouching:
		current_speed *= crouch_speed_multiplier

	if not is_zero_approx(direction):
		velocity.x = move_toward(velocity.x, direction * current_speed, acceleration * delta)
		facing_direction = signf(direction)
		sprite.flip_h = facing_direction < 0.0
		_update_attack_direction()
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if Input.is_action_just_pressed("ui_accept") and not is_crouching:
		jump_buffer_remaining = jump_buffer_time
	if Input.is_action_just_released("ui_accept"):
		_cut_jump_short()
	_try_buffered_jump()
	if Input.is_action_just_pressed("attack"):
		try_attack()

	move_and_slide()


func _update_dash_timers(delta: float) -> void:
	dash_cooldown_remaining = maxf(dash_cooldown_remaining - delta, 0.0)
	if not is_dashing:
		return

	dash_time_remaining = maxf(dash_time_remaining - delta, 0.0)
	if is_zero_approx(dash_time_remaining):
		is_dashing = false
		dash_visual.hide()
		velocity.x = facing_direction * move_speed


func try_dash() -> bool:
	if is_dead or not dash_unlocked or is_dashing or dash_cooldown_remaining > 0.0:
		return false
	if is_crouching or Input.is_action_pressed("ui_down"):
		return false

	is_dashing = true
	dash_time_remaining = dash_duration
	dash_cooldown_remaining = dash_cooldown
	jump_buffer_remaining = 0.0
	velocity = Vector2(dash_speed * facing_direction, 0.0)
	dash_visual.scale.x = facing_direction
	dash_visual.show()
	return true


func _update_jump_windows(delta: float) -> void:
	if is_on_floor():
		jump_count = 0
		coyote_time_remaining = coyote_time
	else:
		coyote_time_remaining = maxf(coyote_time_remaining - delta, 0.0)

	jump_buffer_remaining = maxf(jump_buffer_remaining - delta, 0.0)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	var gravity_multiplier := fall_gravity_multiplier if velocity.y > 0.0 else 1.0
	velocity.y += gravity * gravity_multiplier * delta


func _try_buffered_jump() -> void:
	if jump_buffer_remaining <= 0.0:
		return
	if _try_jump():
		jump_buffer_remaining = 0.0


func _try_jump() -> bool:
	if is_on_floor() or (coyote_time_remaining > 0.0 and jump_count == 0):
		velocity.y = jump_force
		jump_count = 1
		coyote_time_remaining = 0.0
		return true
	elif double_jump_unlocked and jump_count < 2:
		velocity.y = jump_force
		jump_count = 2
		return true
	return false


func _cut_jump_short() -> void:
	if velocity.y < 0.0:
		velocity.y *= jump_release_multiplier


func _set_crouching(should_crouch: bool) -> void:
	if is_crouching == should_crouch:
		return

	is_crouching = should_crouch
	sprite.scale = standing_sprite_scale
	if is_crouching:
		sprite.scale.y *= crouch_sprite_height_multiplier


func _update_attack_direction() -> void:
	attack_cast.position.x = attack_offset * facing_direction
	attack_visual.scale.x = facing_direction


func try_attack() -> bool:
	if is_dead or not attack_cooldown_timer.is_stopped():
		return false

	attack_cooldown_timer.start()
	attack_visual.show()
	attack_visual_timer.start()
	attack_cast.force_shapecast_update()

	var hit_targets: Dictionary = {}
	for collision_index in range(attack_cast.get_collision_count()):
		var target := attack_cast.get_collider(collision_index) as Node
		if target == null or not is_instance_valid(target) or target.is_queued_for_deletion():
			continue
		if not target.is_in_group("enemy"):
			continue

		var target_id := target.get_instance_id()
		if hit_targets.has(target_id) or not target.has_method("take_damage"):
			continue

		hit_targets[target_id] = true
		var knockback := Vector2(
			attack_knockback.x * facing_direction,
			attack_knockback.y
		)
		target.take_damage(attack_damage, knockback)

	return true


func _on_attack_visual_timer_timeout() -> void:
	attack_visual.hide()


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or is_invulnerable or amount <= 0:
		return

	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		die()
		return

	if not knockback.is_zero_approx():
		velocity = knockback

	is_invulnerable = true
	modulate.a = 0.5
	invulnerability_timer.start()


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_dashing = false
	dash_visual.hide()
	velocity = Vector2.ZERO
	invulnerability_timer.stop()
	set_physics_process(false)
	player_collision.set_deferred("disabled", true)
	visible = false
	died.emit()


func _on_invulnerability_timer_timeout() -> void:
	is_invulnerable = false
	modulate.a = 1.0


func add_xp(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	xp += amount
	while xp >= xp_per_level:
		xp -= xp_per_level
		skill_points += 1

	progression_changed.emit(xp, xp_per_level, skill_points)


func add_skill_points(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	skill_points += amount
	progression_changed.emit(xp, xp_per_level, skill_points)


func increase_max_health(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	max_health += amount
	current_health = max_health
	health_changed.emit(current_health, max_health)


func can_unlock_double_jump() -> bool:
	return not double_jump_unlocked and skill_points >= double_jump_cost


func try_unlock_double_jump() -> bool:
	if not can_unlock_double_jump():
		return false

	skill_points -= double_jump_cost
	double_jump_unlocked = true
	progression_changed.emit(xp, xp_per_level, skill_points)
	double_jump_state_changed.emit(true)
	return true


func can_unlock_dash() -> bool:
	return not dash_unlocked and skill_points >= dash_cost


func try_unlock_dash() -> bool:
	if not can_unlock_dash():
		return false

	skill_points -= dash_cost
	dash_unlocked = true
	progression_changed.emit(xp, xp_per_level, skill_points)
	dash_state_changed.emit(true)
	return true


func _emit_current_state() -> void:
	health_changed.emit(current_health, max_health)
	progression_changed.emit(xp, xp_per_level, skill_points)
	double_jump_state_changed.emit(double_jump_unlocked)
	dash_state_changed.emit(dash_unlocked)
