extends CharacterBody2D

signal battle_started
signal health_changed(current_health: int, maximum_health: int)
signal phase_changed(phase: int)
signal defeated

@export var boss_id: String = "abyss_warden"
@export var boss_name: String = "Abyss Warden"
@export var zone_id: String = "sunken_shaft"
@export var max_health: int = 16
@export var gravity: float = 1000.0
@export var movement_speed: float = 42.0
@export var charge_speed: float = 260.0
@export var activation_range: float = 265.0
@export var arena_left_offset: float = -200.0
@export var arena_right_offset: float = 200.0
@export var projectile_scene: PackedScene
@export var xp_orb_scene: PackedScene
@export var gold_pickup_scene: PackedScene
@export var gold_reward: int = 85

var current_health: int
var phase: int = 1
var active: bool = false
var is_dead: bool = false
var is_rematch: bool = false
var arena_anchor_x: float
var target_player: Player
var shot_cooldown: float = 1.4
var charge_cooldown: float = 3.2
var windup_remaining: float = 0.0
var charge_remaining: float = 0.0
var recovery_remaining: float = 0.0
var charge_direction: float = 1.0
var contact_cooldown: float = 0.0

@onready var body_visual: Polygon2D = $BodyVisual
@onready var eye: Polygon2D = $Eye
@onready var telegraph: Line2D = $Telegraph
@onready var contact_area: Area2D = $ContactArea
@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and bool(game_state.defeated_bosses.get(boss_id, false)):
		if bool(game_state.boss_rematches.get(boss_id, false)):
			is_dead = true
			queue_free()
			return
		is_rematch = true
		boss_name = "Awakened Warden"
		max_health = 25
		movement_speed = 58.0
		charge_speed = 305.0
		gold_reward = 125
		body_visual.color = Color(0.61, 0.24, 0.72, 1.0)
	arena_anchor_x = global_position.x
	current_health = max_health
	target_player = get_tree().get_first_node_in_group("player") as Player
	telegraph.hide()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Player
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	if target_player == null or target_player.is_dead:
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		move_and_slide()
		return
	if not active:
		if global_position.distance_to(target_player.global_position) > activation_range:
			move_and_slide()
			return
		active = true
		battle_started.emit()

	contact_cooldown = maxf(contact_cooldown - delta, 0.0)
	shot_cooldown = maxf(shot_cooldown - delta, 0.0)
	charge_cooldown = maxf(charge_cooldown - delta, 0.0)
	if windup_remaining > 0.0:
		windup_remaining = maxf(windup_remaining - delta, 0.0)
		velocity.x = 0.0
		telegraph.modulate.a = 0.5 + sin(Time.get_ticks_msec() * 0.03) * 0.35
		if is_zero_approx(windup_remaining):
			telegraph.hide()
			charge_remaining = (0.62 if phase == 2 else 0.5) if is_rematch else (0.56 if phase == 2 else 0.46)
	elif charge_remaining > 0.0:
		charge_remaining = maxf(charge_remaining - delta, 0.0)
		velocity.x = charge_direction * (charge_speed * (1.15 if phase == 2 else 1.0))
		if is_zero_approx(charge_remaining):
			recovery_remaining = 0.9
	elif recovery_remaining > 0.0:
		recovery_remaining = maxf(recovery_remaining - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, 650.0 * delta)
		body_visual.color = Color(0.35, 0.55, 0.65, 1.0)
	else:
		body_visual.color = _combat_color()
		_move_toward_player()
		if is_zero_approx(charge_cooldown):
			_start_charge_windup()
		elif is_zero_approx(shot_cooldown):
			_fire_volley()
	move_and_slide()
	global_position.x = clampf(global_position.x, arena_anchor_x + arena_left_offset, arena_anchor_x + arena_right_offset)
	if charge_remaining > 0.0 and is_on_wall():
		charge_remaining = 0.0
		recovery_remaining = 0.9
	_try_contact_damage()


func _combat_color() -> Color:
	if is_rematch:
		return Color(0.82, 0.22, 0.72, 1.0) if phase == 2 else Color(0.52, 0.28, 0.76, 1.0)
	return Color(0.65, 0.2, 0.48, 1.0) if phase == 2 else Color(0.21, 0.46, 0.57, 1.0)


func _move_toward_player() -> void:
	var difference := target_player.global_position.x - global_position.x
	if absf(difference) < 76.0:
		velocity.x = move_toward(velocity.x, 0.0, 220.0)
	else:
		velocity.x = signf(difference) * movement_speed * (1.25 if phase == 2 else 1.0)
	muzzle.position.x = 22.0 * signf(difference)
	eye.position.x = 8.0 * signf(difference)


func _start_charge_windup() -> void:
	charge_direction = signf(target_player.global_position.x - global_position.x)
	windup_remaining = 0.68 if phase == 1 else 0.5
	charge_cooldown = (3.0 if phase == 1 else 2.35) if is_rematch else (3.8 if phase == 1 else 2.9)
	velocity.x = 0.0
	telegraph.points = PackedVector2Array([Vector2.ZERO, Vector2(charge_direction * 155.0, 0.0)])
	telegraph.show()
	body_visual.color = Color(1.0, 0.33, 0.35, 1.0)


func _fire_volley() -> void:
	shot_cooldown = (1.5 if phase == 1 else 1.0) if is_rematch else (1.85 if phase == 1 else 1.2)
	if projectile_scene == null or get_parent() == null:
		return
	var base_direction := (target_player.global_position - muzzle.global_position).normalized()
	var angles: Array[float] = [0.0]
	if phase == 2 or is_rematch:
		angles = [-0.18, 0.0, 0.18]
	for angle in angles:
		var projectile := projectile_scene.instantiate() as Area2D
		get_parent().add_child(projectile)
		projectile.global_position = muzzle.global_position
		projectile.setup(base_direction.rotated(angle), self)
		projectile.set("speed", 145.0 if phase == 1 else 175.0)
		(projectile.get_node("Core") as Polygon2D).color = Color(0.91, 0.42, 1.0, 1.0) if is_rematch else Color(0.38, 0.98, 0.95, 1.0)


func _try_contact_damage() -> void:
	if contact_cooldown > 0.0:
		return
	for body in contact_area.get_overlapping_bodies():
		if body is Player and not body.is_dead:
			var direction := -1.0 if body.global_position.x < global_position.x else 1.0
			body.take_damage(2 if phase == 2 else 1, Vector2(direction * 210.0, -180.0))
			contact_cooldown = 1.0
			return


func take_damage(amount: int, _knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or amount <= 0:
		return
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		die()
		return
	if phase == 1 and current_health <= max_health * 0.5:
		phase = 2
		charge_cooldown = minf(charge_cooldown, 1.0)
		phase_changed.emit(phase)
	body_visual.modulate = Color(1.8, 0.65, 0.65, 1.0)
	var flash := create_tween()
	flash.tween_property(body_visual, "modulate", Color.WHITE, 0.15)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	telegraph.hide()
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		if is_rematch:
			if game_state.mark_boss_rematch_cleared(boss_id):
				game_state.add_item("warden_heart")
				if is_instance_valid(target_player):
					target_player.increase_max_health(1)
		else:
			game_state.add_item("warden_seal", 1)
			game_state.set_zone_tier(zone_id, maxi(game_state.get_zone_tier(zone_id), 1))
			game_state.set_zone_tier("training_passage", 1)
			game_state.mark_boss_defeated(boss_id)
	defeated.emit()
	var drop_parent := get_parent() as Node2D
	if drop_parent != null:
		if xp_orb_scene != null:
			for index in range(3):
				var xp := xp_orb_scene.instantiate() as Area2D
				xp.position = drop_parent.to_local(global_position + Vector2((index - 1) * 17.0, -22.0))
				drop_parent.call_deferred("add_child", xp)
		if gold_pickup_scene != null:
			var gold := gold_pickup_scene.instantiate() as Area2D
			gold.set("gold_value", gold_reward)
			gold.position = drop_parent.to_local(global_position + Vector2(0.0, -16.0))
			drop_parent.call_deferred("add_child", gold)
	queue_free()
