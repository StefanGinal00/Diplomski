extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal defeated

enum State { PATROL, WARNING, CHARGE, RECOVER }

@export var zone_id: String = "sunken_shaft"
@export var max_health: int = 4
@export var gravity: float = 1000.0
@export var patrol_speed: float = 32.0
@export var charge_speed: float = 245.0
@export var detection_range: float = 155.0
@export var patrol_distance: float = 55.0
@export var damage: int = 1
@export var xp_orb_scene: PackedScene
@export var gold_pickup_scene: PackedScene
@export var item_pickup_scene: PackedScene
@export var gold_reward: int = 10
@export_range(0.0, 1.0, 0.05) var iron_fragment_chance: float = 0.35

var current_health: int
var is_dead: bool = false
var state: State = State.PATROL
var state_remaining: float = 0.0
var attack_cooldown: float = 0.7
var contact_cooldown: float = 0.0
var direction: float = -1.0
var start_x: float
var target_player: Player
var zone_tier: int = 0
var echo_charge_ready: bool = false

@onready var body_visual: Polygon2D = $BodyVisual
@onready var warning_icon: Polygon2D = $WarningIcon
@onready var contact_area: Area2D = $ContactArea
@onready var health_bar: ProgressBar = $HealthBar
@onready var body_collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	start_x = global_position.x
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
	warning_icon.hide()
	target_player = get_tree().get_first_node_in_group("player") as Player


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Player
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	contact_cooldown = maxf(contact_cooldown - delta, 0.0)
	state_remaining = maxf(state_remaining - delta, 0.0)
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	match state:
		State.PATROL:
			_patrol()
			if _can_start_charge():
				echo_charge_ready = zone_tier >= 1
				_start_warning()
		State.WARNING:
			velocity.x = 0.0
			warning_icon.scale = Vector2.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.03) * 0.15)
			if is_zero_approx(state_remaining):
				state = State.CHARGE
				state_remaining = 0.38
				warning_icon.hide()
		State.CHARGE:
			velocity.x = direction * charge_speed
			if is_zero_approx(state_remaining):
				if echo_charge_ready and is_instance_valid(target_player) and not target_player.is_dead and absf(target_player.global_position.x - global_position.x) < detection_range and absf(target_player.global_position.y - global_position.y) < 55.0:
					echo_charge_ready = false
					_start_warning()
				else:
					_begin_recovery()
		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 660.0 * delta)
			if is_zero_approx(state_remaining):
				state = State.PATROL
				body_visual.color = Color(0.42, 0.45, 0.7, 1.0)
	_avoid_ledge(delta)
	move_and_slide()
	if state == State.CHARGE and (is_on_wall() or absf(global_position.x - start_x) > patrol_distance + 85.0):
		_begin_recovery()
	_try_contact_damage()


func _avoid_ledge(delta: float) -> void:
	if not is_on_floor() or is_zero_approx(velocity.x):
		return
	var half: Vector2 = body_collision.shape.size * 0.5
	var heading := signf(velocity.x)
	# Look beyond the leading foot, including this tick's charge movement.
	# This also works on one-way niche floors; airborne crawlers still fall
	# normally and no invisible wall is added for the player.
	var foot := global_position + Vector2(heading * (half.x + maxf(6.0, absf(velocity.x) * delta)), half.y)
	var query := PhysicsRayQueryParameters2D.create(foot + Vector2(0, -5), foot + Vector2(0, 18), collision_mask, [get_rid()])
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.normal.y < -0.5 and hit.collider is StaticBody2D and not hit.collider.is_in_group("enemy"):
		return
	if state == State.PATROL:
		direction = -heading
		velocity.x = direction * patrol_speed
		body_visual.scale.x = direction
	else:
		if state == State.CHARGE:
			_begin_recovery()
		velocity.x = 0.0


func _patrol() -> void:
	if global_position.x < start_x - patrol_distance:
		direction = 1.0
	elif global_position.x > start_x + patrol_distance:
		direction = -1.0
	velocity.x = direction * patrol_speed
	body_visual.scale.x = direction


func _can_start_charge() -> bool:
	return attack_cooldown <= 0.0 and target_player != null and not target_player.is_dead \
		and absf(target_player.global_position.x - global_position.x) <= detection_range \
		and absf(target_player.global_position.y - global_position.y) < 46.0


func _start_warning() -> void:
	state = State.WARNING
	state_remaining = 0.52
	direction = signf(target_player.global_position.x - global_position.x)
	if is_zero_approx(direction):
		direction = 1.0
	velocity.x = 0.0
	warning_icon.show()
	body_visual.color = Color(0.95, 0.36, 0.42, 1.0)


func _apply_attack_tier() -> void:
	if zone_tier >= 1:
		patrol_speed = 38.0
		charge_speed = 275.0
		detection_range = 175.0


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
	echo_charge_ready = false
	state = State.RECOVER
	state_remaining = 0.85
	attack_cooldown = 0.95
	velocity.x *= 0.25
	warning_icon.hide()
	body_visual.color = Color(0.23, 0.68, 0.8, 1.0)


func _try_contact_damage() -> void:
	if contact_cooldown > 0.0:
		return
	for body in contact_area.get_overlapping_bodies():
		if body is Player and not body.is_dead:
			var push := -1.0 if body.global_position.x < global_position.x else 1.0
			body.take_damage(damage, Vector2(push * 170.0, -115.0))
			contact_cooldown = 0.8
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
	body_visual.modulate = Color(1.8, 0.5, 0.5, 1.0)
	var flash := create_tween()
	flash.tween_property(body_visual, "modulate", Color.WHITE, 0.14)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	defeated.emit()
	var quest_manager := get_tree().get_first_node_in_group("quest_manager")
	if quest_manager != null and quest_manager.has_method("report_enemy_defeated"):
		quest_manager.report_enemy_defeated()
	var drop_parent := get_parent() as Node2D
	if drop_parent != null:
		if xp_orb_scene != null:
			var xp := xp_orb_scene.instantiate() as Area2D
			xp.set("xp_value", 2)
			xp.position = drop_parent.to_local(global_position + Vector2(-8.0, -12.0))
			drop_parent.call_deferred("add_child", xp)
		if gold_pickup_scene != null:
			var gold := gold_pickup_scene.instantiate() as Area2D
			gold.set("gold_value", gold_reward)
			gold.position = drop_parent.to_local(global_position + Vector2(9.0, -9.0))
			drop_parent.call_deferred("add_child", gold)
		if item_pickup_scene != null and randf() < iron_fragment_chance:
			var fragment := item_pickup_scene.instantiate() as Area2D
			fragment.configure("iron_fragment", "Iron Fragment")
			fragment.position = drop_parent.to_local(global_position + Vector2(0.0, -20.0))
			drop_parent.call_deferred("add_child", fragment)
	queue_free()
