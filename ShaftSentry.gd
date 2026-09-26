extends StaticBody2D

signal health_changed(current_health: int, maximum_health: int)
signal defeated

@export var zone_id: String = "sunken_shaft"
@export var max_health: int = 3
@export var detection_range: float = 210.0
@export var windup_time: float = 0.65
@export var shot_cooldown: float = 1.8
@export var projectile_scene: PackedScene
@export var xp_orb_scene: PackedScene
@export var gold_pickup_scene: PackedScene
@export var gold_reward: int = 9
@export var projectile_color: Color = Color(0.22, 0.98, 0.88, 1.0)
@export var projectile_glow_color: Color = Color(0.18, 0.9, 0.8, 0.32)
@export var idle_eye_color: Color = Color(0.7, 1.0, 0.9, 1.0)

var current_health: int
var is_dead: bool = false
var windup_remaining: float = 0.0
var cooldown_remaining: float = 0.5
var target_player: Player
var aim_direction: Vector2 = Vector2.LEFT
var zone_tier: int = 0
var spread_rays: Array[Line2D] = []

@onready var eye: Polygon2D = $Eye
@onready var warning_ray: Line2D = $WarningRay
@onready var muzzle: Marker2D = $Muzzle
@onready var health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		zone_tier = game_state.get_zone_tier(zone_id)
		max_health += zone_tier
		gold_reward += zone_tier * 3
		_apply_attack_tier()
		game_state.zone_tier_changed.connect(_on_zone_tier_changed)
	current_health = max_health
	health_bar.max_value = max_health
	health_bar.value = current_health
	warning_ray.hide()
	target_player = get_tree().get_first_node_in_group("player") as Player


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Player
	if target_player == null or target_player.is_dead:
		_cancel_windup()
		return
	var distance := global_position.distance_to(target_player.global_position)
	if distance > detection_range or not _has_clear_shot():
		_cancel_windup()
		cooldown_remaining = minf(cooldown_remaining + delta, shot_cooldown)
		return
	var target_direction := (target_player.global_position - muzzle.global_position).normalized()
	if windup_remaining > 0.0:
		windup_remaining = maxf(windup_remaining - delta, 0.0)
		aim_direction = target_direction
		_update_warning_rays()
		warning_ray.modulate.a = 0.45 + sin(Time.get_ticks_msec() * 0.025) * 0.3
		for index in spread_rays.size():
			spread_rays[index].modulate.a = warning_ray.modulate.a
		eye.color = Color(1.0, 0.35, 0.28, 1.0)
		if is_zero_approx(windup_remaining):
			_fire()
		return
	cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)
	if is_zero_approx(cooldown_remaining):
		windup_remaining = windup_time
		aim_direction = target_direction
		_update_warning_rays()
		warning_ray.show()
		for ray in spread_rays:
			ray.show()
		eye.color = Color(1.0, 0.52, 0.3, 1.0)


func _has_clear_shot() -> bool:
	# Match projectile blockers: bodies on the projectile's world/player layer,
	# not trigger areas. A new clear view always begins a fresh full telegraph.
	var query := PhysicsRayQueryParameters2D.create(muzzle.global_position, target_player.global_position, 1, [get_rid()])
	query.hit_from_inside = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == target_player


func _update_warning_rays() -> void:
	var origin := to_local(muzzle.global_position)
	warning_ray.points = PackedVector2Array([origin, to_local(muzzle.global_position + aim_direction * 160.0)])
	for index in spread_rays.size():
		var direction := aim_direction.rotated(-0.16 if index == 0 else 0.16)
		spread_rays[index].points = PackedVector2Array([origin, to_local(muzzle.global_position + direction * 160.0)])


func _cancel_windup() -> void:
	windup_remaining = 0.0
	warning_ray.hide()
	for ray in spread_rays:
		ray.hide()
	eye.color = idle_eye_color


func _fire() -> void:
	warning_ray.hide()
	for ray in spread_rays:
		ray.hide()
	eye.color = idle_eye_color
	cooldown_remaining = shot_cooldown
	if projectile_scene == null or get_parent() == null:
		return
	var angles: Array[float] = [0.0]
	if zone_tier >= 1:
		angles = [-0.16, 0.0, 0.16]
	for angle in angles:
		var projectile := projectile_scene.instantiate() as Area2D
		get_parent().add_child(projectile)
		projectile.global_position = muzzle.global_position
		projectile.setup(aim_direction.rotated(angle), self)
		projectile.set("speed", 185.0)
		(projectile.get_node("Core") as Polygon2D).color = Color(0.83, 0.48, 1.0, 1.0) if zone_tier >= 1 else projectile_color
		(projectile.get_node("Glow") as Polygon2D).color = Color(0.6, 0.2, 0.85, 0.32) if zone_tier >= 1 else projectile_glow_color


func _apply_attack_tier() -> void:
	if zone_tier < 1:
		return
	detection_range = 230.0
	windup_time = 0.78
	shot_cooldown = 1.65
	if spread_rays.is_empty():
		for angle in [-0.16, 0.16]:
			var ray := Line2D.new()
			ray.width = 2.0
			ray.default_color = Color(0.82, 0.42, 1.0, 0.75)
			ray.points = PackedVector2Array([Vector2.ZERO, Vector2.LEFT.rotated(angle) * 160.0])
			ray.hide()
			add_child(ray)
			spread_rays.append(ray)


func _on_zone_tier_changed(changed_zone_id: String, new_tier: int) -> void:
	if changed_zone_id != zone_id or new_tier <= zone_tier or is_dead:
		return
	var difference := new_tier - zone_tier
	zone_tier = new_tier
	max_health += difference
	current_health += difference
	gold_reward += difference * 3
	health_bar.max_value = max_health
	health_bar.value = current_health
	_apply_attack_tier()
	health_changed.emit(current_health, max_health)


func take_damage(amount: int, _knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or amount <= 0:
		return
	current_health = maxi(current_health - amount, 0)
	health_bar.value = current_health
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		die()
		return
	eye.modulate = Color(1.8, 0.4, 0.4, 1.0)
	var flash := create_tween()
	flash.tween_property(eye, "modulate", Color.WHITE, 0.14)


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
			xp.position = drop_parent.to_local(global_position + Vector2(0.0, -18.0))
			drop_parent.call_deferred("add_child", xp)
		if gold_pickup_scene != null:
			var gold := gold_pickup_scene.instantiate() as Area2D
			gold.set("gold_value", gold_reward)
			gold.position = drop_parent.to_local(global_position + Vector2(9.0, -9.0))
			drop_parent.call_deferred("add_child", gold)
	queue_free()
