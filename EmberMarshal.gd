extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal phase_changed(phase: int)
signal defeated

const PROJECTILE_SCENE: PackedScene = preload("res://EnemyProjectile.tscn")

@export var max_health: int = 16
@export var gravity: float = 1000.0
@export var walk_speed: float = 48.0
@export var charge_speed: float = 245.0

var current_health: int
var phase: int = 1
var is_dead: bool = false
var target_player: Player
var arena_left_x: float = 350.0
var arena_right_x: float = 1220.0
var charge_cooldown: float = 2.2
var volley_cooldown: float = 1.7
var windup_remaining: float = 0.0
var charge_remaining: float = 0.0
var recovery_remaining: float = 0.0
var contact_cooldown: float = 0.0
var charge_direction: float = -1.0

@onready var armor: Polygon2D = $Armor
@onready var eye: Polygon2D = $Eye
@onready var telegraph: Line2D = $Telegraph
@onready var contact_area: Area2D = $ContactArea
@onready var muzzle: Marker2D = $Muzzle
@onready var health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		var tier: int = game_state.get_zone_tier("ashen_bastion")
		max_health += tier * 5
		charge_speed += tier * 25.0
	current_health = max_health
	health_bar.max_value = max_health
	health_bar.value = current_health
	target_player = get_tree().get_first_node_in_group("player") as Player
	telegraph.hide()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Player
	velocity.y = minf(velocity.y + gravity * delta, 600.0) if not is_on_floor() else 0.0
	if target_player == null or target_player.is_dead:
		velocity.x = move_toward(velocity.x, 0.0, 450.0 * delta)
		move_and_slide()
		return
	charge_cooldown = maxf(charge_cooldown - delta, 0.0)
	volley_cooldown = maxf(volley_cooldown - delta, 0.0)
	contact_cooldown = maxf(contact_cooldown - delta, 0.0)
	if windup_remaining > 0.0:
		windup_remaining = maxf(windup_remaining - delta, 0.0)
		velocity.x = 0.0
		telegraph.modulate.a = 0.55 + 0.35 * sin(Time.get_ticks_msec() * 0.028)
		if is_zero_approx(windup_remaining):
			telegraph.hide()
			charge_remaining = 0.53 if phase == 1 else 0.64
	elif charge_remaining > 0.0:
		charge_remaining = maxf(charge_remaining - delta, 0.0)
		velocity.x = charge_direction * charge_speed
		if is_zero_approx(charge_remaining):
			recovery_remaining = 0.55
	elif recovery_remaining > 0.0:
		recovery_remaining = maxf(recovery_remaining - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
	else:
		var horizontal_distance: float = target_player.global_position.x - global_position.x
		velocity.x = signf(horizontal_distance) * walk_speed if absf(horizontal_distance) > 95.0 else 0.0
		muzzle.position.x = 24.0 * signf(horizontal_distance)
		eye.position.x = 9.0 * signf(horizontal_distance)
		if is_zero_approx(charge_cooldown):
			_start_charge()
		elif is_zero_approx(volley_cooldown):
			_fire_volley()
	move_and_slide()
	position.x = clampf(position.x, arena_left_x, arena_right_x)
	if charge_remaining > 0.0 and is_on_wall():
		charge_remaining = 0.0
		recovery_remaining = 0.55
	_try_contact_damage()


func _start_charge() -> void:
	charge_direction = signf(target_player.global_position.x - global_position.x)
	if is_zero_approx(charge_direction):
		charge_direction = -1.0
	windup_remaining = 0.75 if phase == 1 else 0.55
	charge_cooldown = 3.2 if phase == 1 else 2.5
	velocity.x = 0.0
	telegraph.points = PackedVector2Array([Vector2.ZERO, Vector2(charge_direction * 190.0, 0.0)])
	telegraph.show()
	armor.color = Color(1.0, 0.65, 0.25, 1)


func _fire_volley() -> void:
	volley_cooldown = 2.2 if phase == 1 else 1.5
	if target_player == null or get_parent() == null:
		return
	var direction: Vector2 = (target_player.global_position - muzzle.global_position).normalized()
	var angles: Array[float] = [0.0]
	if phase == 2:
		angles = [-0.2, 0.0, 0.2]
	for angle in angles:
		var projectile := PROJECTILE_SCENE.instantiate() as Area2D
		get_parent().add_child(projectile)
		projectile.global_position = muzzle.global_position
		projectile.setup(direction.rotated(angle), self)
		projectile.set("speed", 150.0 if phase == 1 else 175.0)
		(projectile.get_node("Core") as Polygon2D).color = Color(1.0, 0.55, 0.15, 1.0)


func _try_contact_damage() -> void:
	if contact_cooldown > 0.0:
		return
	for body in contact_area.get_overlapping_bodies():
		if body is Player and not body.is_dead:
			var direction := -1.0 if body.global_position.x < global_position.x else 1.0
			body.take_damage(2, Vector2(direction * 210.0, -180.0))
			contact_cooldown = 0.9
			return


func take_damage(amount: int, _knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or amount <= 0:
		return
	current_health = maxi(current_health - amount, 0)
	health_bar.value = current_health
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		is_dead = true
		telegraph.hide()
		defeated.emit()
		queue_free()
		return
	if phase == 1 and current_health <= max_health / 2:
		phase = 2
		charge_cooldown = minf(charge_cooldown, 0.8)
		phase_changed.emit(phase)
	armor.modulate = Color(1.7, 0.65, 0.35, 1)
	var flash := create_tween()
	flash.tween_property(armor, "modulate", Color.WHITE, 0.16)
