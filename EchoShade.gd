extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal defeated

@export var zone_id: String = "echo_grotto"
@export var max_health: int = 4
@export var move_speed: float = 64.0
@export var dash_speed: float = 255.0
@export var detection_range: float = 225.0
@export var patrol_radius: float = 95.0
@export var xp_orb_scene: PackedScene
@export var gold_pickup_scene: PackedScene
@export var xp_reward: int = 2
@export var gold_reward: int = 14

var current_health: int
var is_dead: bool = false
var target_player: Player
var anchor_x: float
var patrol_direction: float = 1.0
var attack_cooldown: float = 1.2
var telegraph_remaining: float = 0.0
var dash_remaining: float = 0.0
var recovery_remaining: float = 0.0
var contact_cooldown: float = 0.0
var dash_direction: float = 1.0
var zone_tier: int = 0
var echo_followup_ready: bool = false

@onready var body_visual: Polygon2D = $BodyVisual
@onready var telegraph: Line2D = $Telegraph
@onready var contact_area: Area2D = $ContactArea
@onready var health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	anchor_x = global_position.x
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		zone_tier = game_state.get_zone_tier(zone_id)
		max_health += zone_tier
		gold_reward += zone_tier * 4
		_apply_attack_tier()
		game_state.zone_tier_changed.connect(_on_zone_tier_changed)
	current_health = max_health
	health_bar.max_value = max_health
	health_bar.value = current_health
	target_player = get_tree().get_first_node_in_group("player") as Player
	telegraph.hide()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_on_floor():
		velocity.y += 1000.0 * delta
	else:
		velocity.y = 0.0
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	contact_cooldown = maxf(contact_cooldown - delta, 0.0)
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Player
	if telegraph_remaining > 0.0:
		telegraph_remaining = maxf(telegraph_remaining - delta, 0.0)
		velocity.x = 0.0
		telegraph.modulate.a = 0.55 + sin(Time.get_ticks_msec() * 0.025) * 0.3
		if is_zero_approx(telegraph_remaining):
			telegraph.hide()
			dash_remaining = 0.42
	elif dash_remaining > 0.0:
		dash_remaining = maxf(dash_remaining - delta, 0.0)
		velocity.x = dash_direction * dash_speed
		if is_zero_approx(dash_remaining):
			if echo_followup_ready and is_instance_valid(target_player) and not target_player.is_dead and absf(target_player.global_position.x - global_position.x) < detection_range and absf(target_player.global_position.y - global_position.y) < 85.0:
				echo_followup_ready = false
				_start_dash(target_player.global_position.x - global_position.x, true)
			else:
				recovery_remaining = 0.55
	elif recovery_remaining > 0.0:
		recovery_remaining = maxf(recovery_remaining - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, 650.0 * delta)
	else:
		body_visual.color = Color(0.28, 0.68, 0.72, 1.0) if zone_tier >= 1 else Color(0.43, 0.35, 0.7, 1.0)
		if target_player != null and not target_player.is_dead and global_position.distance_to(target_player.global_position) <= detection_range:
			var horizontal_distance := target_player.global_position.x - global_position.x
			velocity.x = signf(horizontal_distance) * move_speed if absf(horizontal_distance) > 54.0 else 0.0
			if is_zero_approx(attack_cooldown) and absf(horizontal_distance) < 165.0 and absf(target_player.global_position.y - global_position.y) < 75.0:
				_start_dash(horizontal_distance)
		else:
			if absf(global_position.x - anchor_x) >= patrol_radius:
				patrol_direction = -signf(global_position.x - anchor_x)
			velocity.x = patrol_direction * move_speed * 0.5
	move_and_slide()
	if dash_remaining > 0.0 and is_on_wall():
		dash_remaining = 0.0
		echo_followup_ready = false
		recovery_remaining = 0.55
	_try_contact_damage()


func _start_dash(horizontal_distance: float, followup: bool = false) -> void:
	dash_direction = signf(horizontal_distance)
	if is_zero_approx(dash_direction):
		dash_direction = 1.0
	telegraph_remaining = 0.48 if followup else 0.58
	attack_cooldown = 2.4 if zone_tier >= 1 else 2.7
	echo_followup_ready = zone_tier >= 1 and not followup
	velocity.x = 0.0
	telegraph.points = PackedVector2Array([Vector2.ZERO, Vector2(dash_direction * 130.0, 0.0)])
	telegraph.show()
	body_visual.color = Color(0.96, 0.4, 0.68, 1.0)


func _apply_attack_tier() -> void:
	if zone_tier >= 1:
		move_speed = 76.0
		dash_speed = 275.0
		detection_range = 250.0
		telegraph.default_color = Color(0.42, 1.0, 0.88, 1.0)


func _on_zone_tier_changed(changed_zone_id: String, new_tier: int) -> void:
	if changed_zone_id != zone_id or new_tier <= zone_tier or is_dead:
		return
	var difference := new_tier - zone_tier
	zone_tier = new_tier
	max_health += difference
	current_health += difference
	gold_reward += difference * 4
	health_bar.max_value = max_health
	health_bar.value = current_health
	_apply_attack_tier()
	health_changed.emit(current_health, max_health)


func _try_contact_damage() -> void:
	if contact_cooldown > 0.0:
		return
	for body in contact_area.get_overlapping_bodies():
		if body is Player and not body.is_dead:
			var direction := signf(body.global_position.x - global_position.x)
			body.take_damage(1, Vector2(direction * 155.0, -115.0))
			contact_cooldown = 0.9
			return


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or amount <= 0:
		return
	current_health = maxi(current_health - amount, 0)
	health_bar.value = current_health
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		die()
		return
	telegraph_remaining = 0.0
	echo_followup_ready = false
	telegraph.hide()
	dash_remaining = 0.0
	recovery_remaining = 0.3
	velocity = knockback * 0.45
	body_visual.modulate = Color(1.8, 0.6, 0.75, 1.0)
	create_tween().tween_property(body_visual, "modulate", Color.WHITE, 0.16)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	defeated.emit()
	var drop_parent := get_parent() as Node2D
	if drop_parent != null:
		if xp_orb_scene != null and xp_reward > 0:
			var orb := xp_orb_scene.instantiate() as Area2D
			orb.set("xp_value", xp_reward)
			orb.position = drop_parent.to_local(global_position + Vector2(-8.0, -14.0))
			drop_parent.call_deferred("add_child", orb)
		if gold_pickup_scene != null and gold_reward > 0:
			var gold := gold_pickup_scene.instantiate() as Area2D
			gold.set("gold_value", gold_reward)
			gold.position = drop_parent.to_local(global_position + Vector2(8.0, -12.0))
			drop_parent.call_deferred("add_child", gold)
	queue_free()
