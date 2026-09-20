extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal defeated

enum State { PATROL, WINDUP, LEAP, RECOVER }

@export var zone_id: String = "echo_grotto"
@export var max_health: int = 3
@export var patrol_speed: float = 28.0
@export var leap_speed: float = 165.0
@export var leap_force: float = -310.0
@export var detection_range: float = 165.0
@export var patrol_radius: float = 72.0
@export var xp_orb_scene: PackedScene
@export var gold_pickup_scene: PackedScene
@export var xp_reward: int = 2
@export var gold_reward: int = 13
@export var counts_for_nest: bool = true

var current_health: int
var is_dead: bool = false
var state: State = State.PATROL
var state_remaining: float = 0.0
var attack_cooldown: float = 0.8
var contact_cooldown: float = 0.0
var direction: float = -1.0
var anchor_x: float
var target_player: Player
var zone_tier: int = 0

@onready var body_visual: Polygon2D = $BodyVisual
@onready var warning_icon: Polygon2D = $WarningIcon
@onready var contact_area: Area2D = $ContactArea
@onready var health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	if not counts_for_nest:
		remove_from_group("nest_brood")
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
	warning_icon.hide()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Player
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	contact_cooldown = maxf(contact_cooldown - delta, 0.0)
	state_remaining = maxf(state_remaining - delta, 0.0)
	if not is_on_floor():
		velocity.y += 1000.0 * delta
	else:
		velocity.y = 0.0
	match state:
		State.PATROL:
			_patrol()
			if _can_leap():
				state = State.WINDUP
				state_remaining = 0.48
				direction = signf(target_player.global_position.x - global_position.x)
				if is_zero_approx(direction):
					direction = 1.0
				velocity.x = 0.0
				warning_icon.show()
				body_visual.color = Color(1.0, 0.45, 0.58, 1.0)
		State.WINDUP:
			velocity.x = 0.0
			warning_icon.scale = Vector2.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.03) * 0.14)
			if is_zero_approx(state_remaining):
				state = State.LEAP
				state_remaining = 0.95
				velocity = Vector2(direction * leap_speed, leap_force)
				warning_icon.hide()
		State.LEAP:
			if is_on_floor() and state_remaining < 0.75 or is_zero_approx(state_remaining):
				_begin_recovery()
		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 540.0 * delta)
			if is_zero_approx(state_remaining):
				state = State.PATROL
				body_visual.color = Color(0.35, 0.75, 0.79, 1.0)
	move_and_slide()
	_try_contact_damage()


func _patrol() -> void:
	if global_position.x < anchor_x - patrol_radius:
		direction = 1.0
	elif global_position.x > anchor_x + patrol_radius:
		direction = -1.0
	velocity.x = direction * patrol_speed
	body_visual.scale.x = direction


func _can_leap() -> bool:
	return is_on_floor() and attack_cooldown <= 0.0 and target_player != null and not target_player.is_dead \
		and absf(target_player.global_position.x - global_position.x) <= detection_range \
		and absf(target_player.global_position.y - global_position.y) < (110.0 if zone_tier >= 1 else 70.0)


func _apply_attack_tier() -> void:
	if zone_tier >= 1:
		patrol_speed = 36.0
		leap_speed = 190.0
		leap_force = -350.0
		detection_range = 195.0


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


func _begin_recovery() -> void:
	state = State.RECOVER
	state_remaining = 0.58
	attack_cooldown = 1.25
	velocity.x *= 0.35
	warning_icon.hide()
	body_visual.color = Color(0.2, 0.55, 0.66, 1.0)


func _try_contact_damage() -> void:
	if contact_cooldown > 0.0:
		return
	for body in contact_area.get_overlapping_bodies():
		if body is Player and not body.is_dead:
			var push := -1.0 if body.global_position.x < global_position.x else 1.0
			body.take_damage(1, Vector2(push * 150.0, -135.0))
			contact_cooldown = 0.85
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
	velocity.x = knockback.x * 0.45
	_begin_recovery()
	body_visual.modulate = Color(1.7, 0.6, 0.6, 1.0)
	create_tween().tween_property(body_visual, "modulate", Color.WHITE, 0.15)


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
			orb.position = drop_parent.to_local(global_position + Vector2(-8.0, -10.0))
			drop_parent.call_deferred("add_child", orb)
		if gold_pickup_scene != null and gold_reward > 0:
			var gold := gold_pickup_scene.instantiate() as Area2D
			gold.set("gold_value", gold_reward)
			gold.position = drop_parent.to_local(global_position + Vector2(8.0, -8.0))
			drop_parent.call_deferred("add_child", gold)
	queue_free()
