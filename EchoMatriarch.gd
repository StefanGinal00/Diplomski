extends CharacterBody2D

signal battle_started
signal health_changed(current_health: int, maximum_health: int)
signal phase_changed(phase: int)
signal defeated

@export var boss_id: String = "echo_matriarch"
@export var boss_name: String = "Echo Matriarch"
@export var zone_id: String = "echo_grotto"
@export var max_health: int = 20
@export var activation_range: float = 310.0
@export var move_speed: float = 76.0
@export var projectile_scene: PackedScene
@export var xp_orb_scene: PackedScene
@export var gold_pickup_scene: PackedScene
@export var gold_reward: int = 110

var current_health: int
var phase: int = 1
var active: bool = false
var is_dead: bool = false
var is_rematch: bool = false
var target_player: Player
var anchor_position: Vector2
var age: float = 0.0
var shot_cooldown: float = 1.4
var pulse_cooldown: float = 4.0
var pulse_windup: float = 0.0
var contact_cooldown: float = 0.0

@onready var body_visual: Polygon2D = $BodyVisual
@onready var wing_left: Polygon2D = $WingLeft
@onready var wing_right: Polygon2D = $WingRight
@onready var pulse_ring: Line2D = $PulseRing
@onready var contact_area: Area2D = $ContactArea
@onready var muzzle: Marker2D = $Muzzle
@onready var challenge_prompt: Label = $ChallengePrompt


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and bool(game_state.defeated_bosses.get(boss_id, false)):
		if bool(game_state.boss_rematches.get(boss_id, false)):
			is_dead = true
			queue_free()
			return
		is_rematch = true
		boss_name = "Awakened Matriarch"
		max_health = 34
		move_speed = 98.0
		gold_reward = 165
		body_visual.color = Color(0.38, 0.85, 0.83, 1.0)
	anchor_position = global_position
	current_health = max_health
	target_player = get_tree().get_first_node_in_group("player") as Player
	pulse_ring.hide()
	challenge_prompt.visible = is_rematch


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	age += delta
	wing_left.rotation = -0.08 + sin(age * 7.0) * 0.16
	wing_right.rotation = 0.08 - sin(age * 7.0) * 0.16
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Player
	if target_player == null or target_player.is_dead:
		velocity = velocity.move_toward(Vector2.ZERO, 220.0 * delta)
		move_and_slide()
		return
	if not active:
		if is_rematch or global_position.distance_to(target_player.global_position) > activation_range:
			return
		active = true
		battle_started.emit()
	shot_cooldown = maxf(shot_cooldown - delta, 0.0)
	pulse_cooldown = maxf(pulse_cooldown - delta, 0.0)
	contact_cooldown = maxf(contact_cooldown - delta, 0.0)
	if pulse_windup > 0.0:
		pulse_windup = maxf(pulse_windup - delta, 0.0)
		velocity = velocity.move_toward(Vector2.ZERO, 420.0 * delta)
		pulse_ring.scale = Vector2.ONE * (1.0 + sin(age * 17.0) * 0.15)
		pulse_ring.modulate.a = 0.5 + sin(age * 20.0) * 0.28
		if is_zero_approx(pulse_windup):
			pulse_ring.hide()
			_fire_ring()
			pulse_cooldown = (3.4 if phase == 1 else 2.5) if is_rematch else (4.0 if phase == 1 else 3.0)
	else:
		var desired_x := clampf(target_player.global_position.x, anchor_position.x - 220.0, anchor_position.x + 220.0)
		var desired_y := anchor_position.y + sin(age * 1.8) * 14.0
		velocity = (Vector2(desired_x, desired_y) - global_position).limit_length(move_speed * (1.3 if phase >= 2 else 1.0))
		if is_zero_approx(pulse_cooldown):
			_start_pulse()
		elif is_zero_approx(shot_cooldown):
			_fire_fan()
	move_and_slide()
	global_position.x = clampf(global_position.x, anchor_position.x - 220.0, anchor_position.x + 220.0)
	global_position.y = clampf(global_position.y, anchor_position.y - 18.0, anchor_position.y + 18.0)
	_try_contact_damage()


func _start_pulse() -> void:
	pulse_windup = 0.72 if phase == 1 else (0.48 if phase == 3 else 0.55)
	shot_cooldown = maxf(shot_cooldown, pulse_windup + 0.2)
	velocity = Vector2.ZERO
	pulse_ring.scale = Vector2.ONE
	pulse_ring.show()
	body_visual.color = Color(0.52, 1.0, 0.92, 1.0) if is_rematch else Color(1.0, 0.55, 0.72, 1.0)


func _fire_fan() -> void:
	if projectile_scene == null:
		return
	var base_direction := (target_player.global_position - muzzle.global_position).normalized()
	var angles: Array[float] = [-0.18, 0.0, 0.18]
	if phase == 3:
		angles = [-0.45, -0.3, -0.15, 0.0, 0.15, 0.3, 0.45]
	elif phase == 2:
		angles = [-0.3, -0.15, 0.0, 0.15, 0.3]
	for angle in angles:
		_spawn_projectile(base_direction.rotated(angle), 155.0 if phase == 1 else (210.0 if phase == 3 else 190.0))
	shot_cooldown = 1.45 if is_rematch and phase == 1 else (0.95 if phase == 3 else (1.65 if phase == 1 else 1.15))
	body_visual.color = _combat_color()


func _fire_ring() -> void:
	var count := 14 if phase == 3 else (10 if phase == 2 else 8)
	for index in range(count):
		var angle := TAU * float(index) / float(count) + age * 0.22
		_spawn_projectile(Vector2.RIGHT.rotated(angle), 135.0 if phase == 1 else (185.0 if phase == 3 else 168.0))
	body_visual.color = _combat_color()


func _combat_color() -> Color:
	if is_rematch:
		return Color(0.13, 0.78, 0.82, 1.0) if phase == 1 else Color(0.49, 0.93, 0.91, 1.0)
	return Color(0.57, 0.29, 0.66, 1.0) if phase == 1 else Color(0.88, 0.25, 0.59, 1.0)


func _spawn_projectile(direction: Vector2, projectile_speed: float) -> void:
	var drop_parent := get_parent() as Node2D
	if projectile_scene == null or drop_parent == null:
		return
	var projectile := projectile_scene.instantiate() as Area2D
	drop_parent.add_child(projectile)
	projectile.global_position = muzzle.global_position + direction * 24.0
	projectile.setup(direction, self)
	projectile.set("speed", projectile_speed)
	(projectile.get_node("Core") as Polygon2D).color = Color(0.42, 1.0, 0.91, 1.0) if is_rematch else Color(0.98, 0.48, 0.79, 1.0)


func _try_contact_damage() -> void:
	if contact_cooldown > 0.0:
		return
	for body in contact_area.get_overlapping_bodies():
		if body is Player and not body.is_dead:
			var direction := -1.0 if body.global_position.x < global_position.x else 1.0
			body.take_damage(2 if phase >= 2 else 1, Vector2(direction * 180.0, -150.0))
			contact_cooldown = 0.95
			return


func take_damage(amount: int, _knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or amount <= 0:
		return
	if is_rematch and not active:
		var game_state := get_node_or_null("/root/GameState")
		if game_state == null or game_state.current_room_id != "echo_sanctum":
			return
		active = true
		challenge_prompt.hide()
		battle_started.emit()
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		die()
		return
	if phase == 1 and current_health <= max_health / 2:
		phase = 2
		pulse_cooldown = minf(pulse_cooldown, 1.3)
		phase_changed.emit(phase)
	elif is_rematch and phase == 2 and current_health <= max_health / 3:
		phase = 3
		pulse_cooldown = minf(pulse_cooldown, 0.8)
		phase_changed.emit(phase)
	body_visual.modulate = Color(1.8, 0.7, 0.75, 1.0)
	create_tween().tween_property(body_visual, "modulate", Color.WHITE, 0.15)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	pulse_ring.hide()
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		if is_rematch:
			if game_state.mark_boss_rematch_cleared(boss_id):
				game_state.add_item("matriarch_heart")
				game_state.add_item("resonance_shard")
				if is_instance_valid(target_player):
					target_player.increase_max_mana(1)
		else:
			game_state.add_item("matriarch_seal")
			game_state.set_zone_tier(zone_id, maxi(game_state.get_zone_tier(zone_id), 1))
			if game_state.mark_boss_defeated(boss_id):
				game_state.add_item("resonance_shard")
	defeated.emit()
	var drop_parent := get_parent() as Node2D
	if drop_parent != null:
		if xp_orb_scene != null:
			for index in range(4):
				var orb := xp_orb_scene.instantiate() as Area2D
				orb.position = drop_parent.to_local(global_position + Vector2((index - 1.5) * 15.0, -20.0))
				drop_parent.call_deferred("add_child", orb)
		if gold_pickup_scene != null:
			var gold := gold_pickup_scene.instantiate() as Area2D
			gold.set("gold_value", gold_reward)
			gold.position = drop_parent.to_local(global_position + Vector2(0.0, -12.0))
			drop_parent.call_deferred("add_child", gold)
	queue_free()
