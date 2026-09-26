extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal defeated

enum State { HOVER, TELEGRAPH, DIVE, RECOVER }

@export_category("Combat")
@export var max_health: int = 3
@export var contact_damage: int = 1
@export var detection_range: float = 230.0
@export var hover_speed: float = 72.0
@export var dive_speed: float = 235.0
@export var telegraph_duration: float = 0.48
@export var dive_duration: float = 0.58
@export var recover_duration: float = 1.15
@export var contact_cooldown: float = 0.8

@export_category("Rewards")
@export var xp_orb_scene: PackedScene
@export var gold_pickup_scene: PackedScene
@export var item_pickup_scene: PackedScene
@export var xp_reward: int = 1
@export var gold_reward: int = 7
@export_range(0.0, 1.0, 0.05) var ether_dust_chance: float = 0.35
@export var zone_id: String = "sunken_shaft"

var current_health: int
var is_dead: bool = false
var state: State = State.HOVER
var state_time: float = 0.85
var contact_cooldown_remaining: float = 0.0
var target_player: Player
var anchor_position: Vector2
var dive_direction: Vector2 = Vector2.DOWN
var age: float = 0.0
var default_body_color: Color
var zone_tier: int = 0

@onready var body_visual: Polygon2D = $BodyVisual
@onready var left_wing: Polygon2D = $LeftWing
@onready var right_wing: Polygon2D = $RightWing
@onready var eye: Polygon2D = $Eye
@onready var contact_area: Area2D = $ContactArea
@onready var health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	anchor_position = global_position
	default_body_color = body_visual.color
	target_player = get_tree().get_first_node_in_group("player") as Player
	_apply_zone_tier()
	current_health = max_health
	health_bar.max_value = max_health
	health_bar.value = current_health


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	age += delta
	state_time = maxf(state_time - delta, 0.0)
	contact_cooldown_remaining = maxf(contact_cooldown_remaining - delta, 0.0)
	_animate_wings()
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Player
	if target_player == null or target_player.is_dead:
		_hover_near_anchor(delta)
		move_and_slide()
		return

	var player_distance := global_position.distance_to(target_player.global_position)
	var acquiring := state == State.HOVER or state == State.TELEGRAPH
	if acquiring and (player_distance > detection_range or not _has_clear_view()):
		# Adjacent galleries are close in world space, but solid terrain must
		# separate their encounters. Losing sight cancels an unlaunched dive;
		# an already launched dive still follows its committed direction.
		if state == State.TELEGRAPH:
			state = State.HOVER
			state_time = 0.75
			body_visual.scale = Vector2.ONE
		_hover_near_anchor(delta)
	else:
		_update_attack_state(delta)
	move_and_slide()
	if state == State.DIVE and get_slide_collision_count() > 0:
		state = State.RECOVER
		state_time = recover_duration
		body_visual.color = Color(0.35, 0.7, 0.82, 1.0)
	_try_contact_damage()


func _has_clear_view() -> bool:
	var excluded: Array[RID] = [get_rid()]
	# One-way scaffold planks and other actors are not opaque walls. Resolve
	# past them, but stop at the first solid terrain/crate collider.
	for pass_index in range(16):
		var query := PhysicsRayQueryParameters2D.create(global_position, target_player.global_position, 1, excluded)
		query.hit_from_inside = true
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or hit.collider == target_player:
			return true
		var body := hit.collider as CollisionObject2D
		if body is StaticBody2D:
			var owner_id := body.shape_find_owner(hit.shape)
			var shape_owner := body.shape_owner_get_owner(owner_id) as CollisionShape2D
			if shape_owner == null or not shape_owner.one_way_collision:
				return false
		excluded.append(body.get_rid())
	return false


func _hover_near_anchor(delta: float) -> void:
	var desired := anchor_position + Vector2(sin(age * 1.4) * 22.0, cos(age * 1.9) * 10.0)
	velocity = velocity.move_toward((desired - global_position).normalized() * hover_speed * 0.45, 240.0 * delta)
	body_visual.color = default_body_color


func _update_attack_state(delta: float) -> void:
	match state:
		State.HOVER:
			var side := -1.0 if global_position.x < target_player.global_position.x else 1.0
			var desired := target_player.global_position + Vector2(side * 72.0, -54.0)
			velocity = velocity.move_toward((desired - global_position).normalized() * hover_speed, 310.0 * delta)
			if is_zero_approx(state_time):
				state = State.TELEGRAPH
				state_time = telegraph_duration
				velocity = Vector2.ZERO
				body_visual.color = Color(1.0, 0.32, 0.62, 1.0)
		State.TELEGRAPH:
			velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			var pulse := 1.0 + sin(age * 24.0) * 0.12
			body_visual.scale = Vector2.ONE * pulse
			if is_zero_approx(state_time):
				dive_direction = (target_player.global_position - global_position).normalized()
				state = State.DIVE
				state_time = dive_duration
				body_visual.scale = Vector2.ONE
		State.DIVE:
			velocity = dive_direction * dive_speed
			if is_zero_approx(state_time):
				state = State.RECOVER
				state_time = recover_duration
				body_visual.color = Color(0.35, 0.7, 0.82, 1.0)
		State.RECOVER:
			velocity = velocity.move_toward(Vector2.ZERO, 360.0 * delta)
			if is_zero_approx(state_time):
				state = State.HOVER
				state_time = 0.75
				body_visual.color = default_body_color


func _animate_wings() -> void:
	var flap := sin(age * 15.0) * 0.22
	left_wing.rotation = -0.18 + flap
	right_wing.rotation = 0.18 - flap
	eye.position.y = sin(age * 3.0) * 0.8


func _try_contact_damage() -> void:
	if contact_cooldown_remaining > 0.0:
		return
	for body in contact_area.get_overlapping_bodies():
		if body is Player and not body.is_dead:
			var knockback_direction := (body.global_position - global_position).normalized()
			body.take_damage(contact_damage, Vector2(knockback_direction.x * 150.0, -115.0))
			contact_cooldown_remaining = contact_cooldown
			if state == State.DIVE:
				state = State.RECOVER
				state_time = recover_duration
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
	if not knockback.is_zero_approx():
		velocity = knockback * 0.65
	state = State.RECOVER
	state_time = 0.45
	body_visual.modulate = Color(2.0, 0.45, 0.55, 1.0)
	var flash := create_tween()
	flash.tween_property(body_visual, "modulate", Color.WHITE, 0.14)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	var quest_manager := get_tree().get_first_node_in_group("quest_manager")
	if quest_manager != null and quest_manager.has_method("report_enemy_defeated"):
		quest_manager.report_enemy_defeated()
	defeated.emit()
	_drop_rewards()
	queue_free()


func _drop_rewards() -> void:
	var drop_parent := get_parent() as Node2D
	if drop_parent == null:
		return
	if xp_orb_scene != null and xp_reward > 0:
		var orb := xp_orb_scene.instantiate() as Area2D
		orb.set("xp_value", xp_reward)
		orb.position = drop_parent.to_local(global_position + Vector2(-7.0, -8.0))
		drop_parent.call_deferred("add_child", orb)
	if gold_pickup_scene != null and gold_reward > 0:
		var gold := gold_pickup_scene.instantiate() as Area2D
		gold.set("gold_value", gold_reward)
		gold.position = drop_parent.to_local(global_position + Vector2(8.0, -5.0))
		drop_parent.call_deferred("add_child", gold)
	if item_pickup_scene != null and randf() <= ether_dust_chance:
		var item := item_pickup_scene.instantiate() as Area2D
		item.configure("ether_dust", "Ether Dust")
		item.position = drop_parent.to_local(global_position + Vector2(0.0, -16.0))
		drop_parent.call_deferred("add_child", item)


func _apply_zone_tier() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return
	zone_tier = game_state.get_zone_tier(zone_id)
	max_health += zone_tier
	contact_damage += floori(zone_tier * 0.5)
	gold_reward += zone_tier * 3
	_apply_attack_tier()
	game_state.zone_tier_changed.connect(_on_zone_tier_changed)


func _apply_attack_tier() -> void:
	if zone_tier >= 1:
		hover_speed = 84.0
		dive_speed = 270.0
		recover_duration = 0.98
		default_body_color = Color(0.52, 0.74, 0.95, 1.0)
		body_visual.color = default_body_color


func _on_zone_tier_changed(changed_zone_id: String, new_tier: int) -> void:
	if changed_zone_id != zone_id or new_tier <= zone_tier or is_dead:
		return
	var old_tier := zone_tier
	zone_tier = new_tier
	max_health += new_tier - old_tier
	current_health += new_tier - old_tier
	contact_damage += floori(new_tier * 0.5) - floori(old_tier * 0.5)
	gold_reward += (new_tier - old_tier) * 3
	health_bar.max_value = max_health
	health_bar.value = current_health
	_apply_attack_tier()
	health_changed.emit(current_health, max_health)
