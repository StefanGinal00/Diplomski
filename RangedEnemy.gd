extends StaticBody2D

signal health_changed(current_health: int, maximum_health: int)
signal defeated

@export var max_health: int = 2
@export var detection_range: float = 220.0
@export var shot_interval: float = 1.4
@export var projectile_scene: PackedScene
@export var xp_orb_scene: PackedScene
@export var xp_reward: int = 1
@export var gold_pickup_scene: PackedScene
@export_range(0, 999, 1) var gold_reward: int = 8

var current_health: int
var shot_cooldown_remaining: float = 0.6
var is_dead: bool = false
var target_player: Node2D
var default_sprite_modulate: Color

@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	current_health = max_health
	default_sprite_modulate = sprite.modulate
	health_bar.max_value = max_health
	health_bar.value = current_health
	target_player = get_tree().get_first_node_in_group("player") as Node2D


func _process(delta: float) -> void:
	if is_dead:
		return
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Node2D
	if target_player == null or target_player.get("is_dead") == true:
		return

	var distance_to_player := global_position.distance_to(target_player.global_position)
	if distance_to_player > detection_range:
		shot_cooldown_remaining = minf(shot_cooldown_remaining + delta, shot_interval)
		return

	var horizontal_direction := -1.0 if target_player.global_position.x < global_position.x else 1.0
	sprite.flip_h = horizontal_direction < 0.0
	muzzle.position.x = 13.0 * horizontal_direction
	shot_cooldown_remaining = maxf(shot_cooldown_remaining - delta, 0.0)
	if is_zero_approx(shot_cooldown_remaining):
		_shoot_at_player()


func _shoot_at_player() -> void:
	if projectile_scene == null or target_player == null or get_parent() == null:
		return

	var projectile := projectile_scene.instantiate() as Area2D
	if projectile == null:
		return
	get_parent().add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.setup(
		(target_player.global_position - muzzle.global_position).normalized(),
		self
	)
	shot_cooldown_remaining = shot_interval


func take_damage(amount: int, _knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or amount <= 0:
		return

	current_health = maxi(current_health - amount, 0)
	health_bar.value = current_health
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		die()
		return

	sprite.modulate = Color(1.0, 0.35, 0.35, 1.0)
	var flash_tween := create_tween()
	flash_tween.tween_property(sprite, "modulate", default_sprite_modulate, 0.12)


func die() -> void:
	if is_dead:
		return

	is_dead = true
	var quest_manager := get_tree().get_first_node_in_group("quest_manager")
	if quest_manager != null and quest_manager.has_method("report_enemy_defeated"):
		quest_manager.report_enemy_defeated()
	defeated.emit()
	_drop_xp_reward()
	_drop_gold_reward()
	queue_free()


func _drop_xp_reward() -> void:
	var drop_parent := get_parent() as Node2D
	if xp_reward <= 0 or xp_orb_scene == null or drop_parent == null:
		return

	var orb := xp_orb_scene.instantiate() as Area2D
	if orb == null:
		return
	orb.set("xp_value", xp_reward)
	orb.position = drop_parent.to_local(global_position + Vector2(0.0, -12.0))
	drop_parent.call_deferred("add_child", orb)


func _drop_gold_reward() -> void:
	var drop_parent := get_parent() as Node2D
	if gold_reward <= 0 or gold_pickup_scene == null or drop_parent == null:
		return
	var pickup := gold_pickup_scene.instantiate() as Area2D
	pickup.set("gold_value", gold_reward)
	pickup.position = drop_parent.to_local(global_position + Vector2(9.0, -10.0))
	drop_parent.call_deferred("add_child", pickup)
