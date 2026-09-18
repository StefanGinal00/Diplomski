extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal defeated

@export var move_speed: float = 50.0
@export var chase_speed: float = 70.0
@export var gravity: float = 1000.0
@export var damage: int = 1
@export_range(0.1, 3.0, 0.1) var contact_damage_cooldown: float = 0.9
@export var contact_knockback: Vector2 = Vector2(150.0, -180.0)
@export var stomp_bounce_force: float = -300.0
@export var stomp_damage: int = 2
@export var max_health: int = 2
@export var hit_stun_duration: float = 0.14
@export var knockback_recovery: float = 900.0
@export var hit_flash_duration: float = 0.1
@export var hit_flash_color: Color = Color(1.0, 0.35, 0.35, 1.0)
@export_category("Rewards")
@export var xp_orb_scene: PackedScene
@export_range(0, 100, 1) var xp_reward: int = 1

var current_health: int
var direction: int = 1
var left_limit: float
var right_limit: float
var is_dead: bool = false
var hit_stun_remaining: float = 0.0
var hit_flash_remaining: float = 0.0
var damage_cooldown_remaining: float = 0.0
var target_player: Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var awareness_area: Area2D = $AwarenessArea
@onready var top_hitbox: Area2D = $TopHitbox
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	current_health = max_health
	health_bar.max_value = max_health
	health_bar.value = current_health

	left_limit = global_position.x + $LeftPoint.position.x
	right_limit = global_position.x + $RightPoint.position.x

	detection_area.body_entered.connect(_on_detection_area_body_entered)
	awareness_area.body_entered.connect(_on_awareness_area_body_entered)
	awareness_area.body_exited.connect(_on_awareness_area_body_exited)
	top_hitbox.body_entered.connect(_on_top_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_update_hit_feedback(delta)
	damage_cooldown_remaining = maxf(damage_cooldown_remaining - delta, 0.0)

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	if hit_stun_remaining > 0.0:
		hit_stun_remaining = maxf(hit_stun_remaining - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, knockback_recovery * delta)
	else:
		_update_horizontal_movement()

	move_and_slide()
	_try_contact_damage()

	if hit_stun_remaining > 0.0:
		return

	if target_player != null:
		return

	if global_position.x >= right_limit:
		direction = -1
		sprite.flip_h = true
	elif global_position.x <= left_limit:
		direction = 1
		sprite.flip_h = false


func _update_horizontal_movement() -> void:
	if is_instance_valid(target_player) and target_player.get("is_dead") != true:
		var horizontal_distance := target_player.global_position.x - global_position.x
		if absf(horizontal_distance) < 4.0:
			velocity.x = 0.0
			return

		var chase_direction := 1 if horizontal_distance > 0.0 else -1
		if chase_direction < 0 and global_position.x <= left_limit:
			velocity.x = 0.0
			return
		if chase_direction > 0 and global_position.x >= right_limit:
			velocity.x = 0.0
			return

		direction = chase_direction
		sprite.flip_h = direction < 0
		velocity.x = direction * chase_speed
		return

	target_player = null
	velocity.x = direction * move_speed


func _update_hit_feedback(delta: float) -> void:
	if hit_flash_remaining <= 0.0:
		return

	hit_flash_remaining = maxf(hit_flash_remaining - delta, 0.0)
	if is_zero_approx(hit_flash_remaining):
		sprite.modulate = Color.WHITE

func _on_detection_area_body_entered(body: Node) -> void:
	_damage_player_if_possible(body)


func _try_contact_damage() -> void:
	if is_dead or damage_cooldown_remaining > 0.0:
		return

	for body in detection_area.get_overlapping_bodies():
		if _damage_player_if_possible(body):
			return


func _damage_player_if_possible(body: Node) -> bool:
	if is_dead or damage_cooldown_remaining > 0.0:
		return false
	if body == self or not body.is_in_group("player") or not body.has_method("take_damage"):
		return false
	if _is_player_above(body):
		return false

	var knockback_direction := -1.0 if body.global_position.x < global_position.x else 1.0
	body.take_damage(
		damage,
		Vector2(contact_knockback.x * knockback_direction, contact_knockback.y)
	)
	damage_cooldown_remaining = contact_damage_cooldown
	return true


func _on_awareness_area_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body is Node2D:
		target_player = body


func _on_awareness_area_body_exited(body: Node) -> void:
	if body == target_player:
		target_player = null

func _on_top_hitbox_body_entered(body: Node) -> void:
	if is_dead:
		return

	if body == self:
		return

	if body.is_in_group("player") and body is CharacterBody2D:
		if _is_player_above(body):
			body.velocity.y = stomp_bounce_force
			take_damage(stomp_damage)

func _is_player_above(body: Node) -> bool:
	if body is Node2D:
		return body.global_position.y < global_position.y - 8.0
	return false

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
		velocity = knockback
		hit_stun_remaining = hit_stun_duration

	sprite.modulate = hit_flash_color
	hit_flash_remaining = hit_flash_duration

func die() -> void:
	if is_dead:
		return

	is_dead = true
	var quest_manager := get_tree().get_first_node_in_group("quest_manager")
	if quest_manager != null and quest_manager.has_method("report_enemy_defeated"):
		quest_manager.report_enemy_defeated()
	defeated.emit()
	_drop_xp_reward()
	queue_free()


func _drop_xp_reward() -> void:
	if xp_reward <= 0 or xp_orb_scene == null or get_parent() == null:
		return

	var orb := xp_orb_scene.instantiate() as Area2D
	if orb == null:
		push_warning("Enemy could not instantiate its XP reward.")
		return

	orb.set("xp_value", xp_reward)
	get_parent().add_child(orb)
	orb.global_position = global_position + Vector2(0.0, -12.0)
