extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal defeated

@export var zone_id: String = "starfall_reach"
@export var max_health: int = 6
@export var patrol_speed: float = 31.0
@export var patrol_radius: float = 90.0
@export var detection_range: float = 150.0
@export var xp_orb_scene: PackedScene
@export var gold_pickup_scene: PackedScene
@export var xp_reward: int = 3
@export var gold_reward: int = 24

var current_health: int
var is_dead: bool = false
var zone_tier: int = 0
var anchor_x: float
var patrol_direction: float = 1.0
var facing: float = 1.0
var phase: String = "patrol"
var phase_remaining: float = 0.0
var attack_cooldown: float = 0.8
var hit_player: bool = false
var target_player: Player

@onready var body_visual: Polygon2D = $BodyVisual
@onready var warning_line: Line2D = $WarningLine
@onready var strike_area: Area2D = $StrikeArea
@onready var health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	anchor_x = global_position.x
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		zone_tier = game_state.get_zone_tier(zone_id)
		max_health += zone_tier
		gold_reward += zone_tier * 4
		game_state.zone_tier_changed.connect(_on_zone_tier_changed)
	current_health = max_health
	health_bar.max_value = max_health
	health_bar.value = current_health
	target_player = get_tree().get_first_node_in_group("player") as Player
	warning_line.hide()
	strike_area.monitoring = false


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_on_floor():
		velocity.y += 1000.0 * delta
	else:
		velocity.y = 0.0
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Player
	match phase:
		"patrol":
			if _player_in_attack_range() and is_zero_approx(attack_cooldown):
				_begin_warning()
			else:
				if absf(global_position.x - anchor_x) >= patrol_radius:
					patrol_direction = -signf(global_position.x - anchor_x)
				velocity.x = patrol_direction * patrol_speed
		"warning":
			velocity.x = 0.0
			phase_remaining = maxf(phase_remaining - delta, 0.0)
			warning_line.modulate.a = 0.55 + 0.35 * sin(Time.get_ticks_msec() * 0.025)
			if is_zero_approx(phase_remaining):
				_begin_burst()
		"burst":
			velocity.x = 0.0
			phase_remaining = maxf(phase_remaining - delta, 0.0)
			if strike_area.monitoring and not hit_player:
				for body in strike_area.get_overlapping_bodies():
					if body is Player and not body.is_dead:
						body.take_damage(2, Vector2(facing * 170.0, -190.0))
						hit_player = true
						break
			if is_zero_approx(phase_remaining):
				_begin_recovery()
		"recovery":
			velocity.x = 0.0
			phase_remaining = maxf(phase_remaining - delta, 0.0)
			if is_zero_approx(phase_remaining):
				phase = "patrol"
	move_and_slide()


func _player_in_attack_range() -> bool:
	return is_instance_valid(target_player) and not target_player.is_dead and absf(target_player.global_position.x - global_position.x) <= detection_range and absf(target_player.global_position.y - global_position.y) <= 75.0


func _begin_warning() -> void:
	phase = "warning"
	phase_remaining = 0.7 if zone_tier == 0 else 0.55
	velocity.x = 0.0
	facing = -1.0 if target_player.global_position.x < global_position.x else 1.0
	strike_area.position.x = facing * 51.0
	warning_line.points = PackedVector2Array([Vector2(facing * 8.0, 25.0), Vector2(facing * 105.0, 25.0)])
	warning_line.show()
	body_visual.color = Color(0.91, 0.63, 0.43, 1.0)


func _begin_burst() -> void:
	phase = "burst"
	phase_remaining = 0.34
	hit_player = false
	warning_line.default_color = Color(1.0, 0.83, 0.48, 1.0)
	body_visual.scale = Vector2(1.25, 1.3)
	strike_area.set_deferred("monitoring", true)


func _begin_recovery() -> void:
	phase = "recovery"
	phase_remaining = 0.8
	attack_cooldown = 1.2
	strike_area.set_deferred("monitoring", false)
	warning_line.hide()
	warning_line.default_color = Color(1.0, 0.66, 0.35, 0.9)
	body_visual.scale = Vector2.ONE
	body_visual.color = Color(0.46, 0.65, 0.43, 1.0)


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
	health_changed.emit(current_health, max_health)


func take_damage(amount: int, _knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or amount <= 0:
		return
	current_health = maxi(current_health - amount, 0)
	health_bar.value = current_health
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		die()
		return
	if phase == "warning" or phase == "burst":
		_begin_recovery()
	body_visual.modulate = Color(1.7, 0.6, 0.6, 1.0)
	create_tween().tween_property(body_visual, "modulate", Color.WHITE, 0.16)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	strike_area.set_deferred("monitoring", false)
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
