extends CharacterBody2D

signal battle_started
signal health_changed(current_health: int, maximum_health: int)
signal phase_changed(phase: int)
signal defeated

@export var boss_name: String = "Void Sentinel"
@export var boss_id: String = "void_sentinel"
@export var max_health: int = 10
@export var move_speed: float = 42.0
@export var phase_two_speed: float = 62.0
@export var gravity: float = 1000.0
@export var activation_range: float = 260.0
@export var arena_left: float = 900.0
@export var arena_right: float = 1280.0
@export var contact_damage: int = 2
@export var contact_cooldown: float = 1.0
@export var shot_interval: float = 1.55
@export var phase_two_shot_interval: float = 0.9
@export var projectile_scene: PackedScene
@export var xp_orb_scene: PackedScene
@export var gold_pickup_scene: PackedScene
@export_range(0, 9999, 1) var gold_reward: int = 40

var current_health: int
var phase: int = 1
var active: bool = false
var is_dead: bool = false
var shot_cooldown: float = 0.7
var damage_cooldown: float = 0.0
var target_player: Player
var default_color: Color

@onready var sprite: Polygon2D = $BodyVisual
@onready var eye: Polygon2D = $Eye
@onready var contact_area: Area2D = $ContactArea
@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and bool(game_state.defeated_bosses.get(boss_id, false)):
		is_dead = true
		queue_free()
		return
	current_health = max_health
	default_color = sprite.color
	target_player = get_tree().get_first_node_in_group("player") as Player


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Player
	if target_player == null or target_player.is_dead:
		velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
		_apply_gravity(delta)
		move_and_slide()
		return

	if not active:
		if global_position.distance_to(target_player.global_position) <= activation_range:
			active = true
			battle_started.emit()
		else:
			_apply_gravity(delta)
			move_and_slide()
			return

	damage_cooldown = maxf(damage_cooldown - delta, 0.0)
	shot_cooldown = maxf(shot_cooldown - delta, 0.0)
	_apply_gravity(delta)
	_move_toward_player()
	move_and_slide()
	_try_contact_damage()
	if is_zero_approx(shot_cooldown):
		_fire_volley()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0


func _move_toward_player() -> void:
	var distance_x := target_player.global_position.x - global_position.x
	var direction := signf(distance_x)
	if absf(distance_x) < 54.0:
		velocity.x = move_toward(velocity.x, 0.0, 10.0)
	else:
		var speed := phase_two_speed if phase == 2 else move_speed
		velocity.x = direction * speed
	global_position.x = clampf(global_position.x, arena_left, arena_right)
	eye.position.x = 7.0 * direction
	muzzle.position.x = 18.0 * direction


func _try_contact_damage() -> void:
	if damage_cooldown > 0.0:
		return
	for body in contact_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			var direction := -1.0 if body.global_position.x < global_position.x else 1.0
			body.take_damage(contact_damage, Vector2(direction * 210.0, -170.0))
			damage_cooldown = contact_cooldown
			return


func _fire_volley() -> void:
	if projectile_scene == null or target_player == null or get_parent() == null:
		return
	var base_direction := (target_player.global_position - muzzle.global_position).normalized()
	var angles: Array[float] = []
	if phase == 2:
		angles.assign([-0.16, 0.0, 0.16])
	else:
		angles.append(0.0)
	for angle in angles:
		var projectile := projectile_scene.instantiate() as Area2D
		get_parent().add_child(projectile)
		projectile.global_position = muzzle.global_position
		projectile.setup(base_direction.rotated(angle), self)
		projectile.set("speed", 145.0 if phase == 2 else 125.0)
	shot_cooldown = phase_two_shot_interval if phase == 2 else shot_interval


func take_damage(amount: int, _knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or amount <= 0:
		return
	if not active:
		active = true
		battle_started.emit()
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		die()
		return
	if phase == 1 and current_health <= max_health * 0.5:
		phase = 2
		default_color = Color(0.92, 0.2, 0.46, 1.0)
		sprite.color = default_color
		phase_changed.emit(phase)
	sprite.modulate = Color(1.0, 2.0, 2.0, 1.0)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.mark_boss_defeated(boss_id)
	defeated.emit()
	for index in range(2):
		_drop_xp(index)
	_drop_gold()
	queue_free()


func _drop_xp(index: int) -> void:
	var drop_parent := get_parent() as Node2D
	if xp_orb_scene == null or drop_parent == null:
		return
	var orb := xp_orb_scene.instantiate() as Area2D
	orb.position = drop_parent.to_local(global_position + Vector2(-8.0 + index * 16.0, -16.0))
	drop_parent.call_deferred("add_child", orb)


func _drop_gold() -> void:
	var drop_parent := get_parent() as Node2D
	if gold_pickup_scene == null or gold_reward <= 0 or drop_parent == null:
		return
	var pickup := gold_pickup_scene.instantiate() as Area2D
	pickup.set("gold_value", gold_reward)
	pickup.position = drop_parent.to_local(global_position + Vector2(0.0, -28.0))
	drop_parent.call_deferred("add_child", pickup)
