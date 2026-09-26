extends CharacterBody2D

signal battle_started
signal health_changed(current_health: int, maximum_health: int)
signal phase_changed(phase: int)
signal defeated

const PROJECTILE_SCENE: PackedScene = preload("res://EnemyProjectile.tscn")
const CLEAR_EVENT := "starfall_court_cleared"
const ROOM_ID := "starfall_empty_court"

@export var boss_id: String = "starfall_guardian"
@export var boss_name: String = "Starfall Guardian"
@export var max_health: int = 20
@export var activation_range: float = 265.0
@export var arena_left_x: float = 545.0
@export var arena_right_x: float = 1380.0

var current_health: int
var phase: int = 1
var active: bool = false
var is_dead: bool = false
var is_rematch: bool = false
var target_player: Player
var starting_position: Vector2
var charge_cooldown: float = 2.4
var volley_cooldown: float = 1.5
var pulse_cooldown: float = 3.5
var charge_windup: float = 0.0
var charge_remaining: float = 0.0
var volley_windup: float = 0.0
var pulse_windup: float = 0.0
var pulse_flash: float = 0.0
var recovery_remaining: float = 0.0
var contact_cooldown: float = 0.0
var charge_direction: float = -1.0
var volley_aim: Vector2 = Vector2.LEFT
var pulse_indices: Array[int] = []

@onready var armor: Polygon2D = $Armor
@onready var eye: Polygon2D = $Eye
@onready var charge_line: Line2D = $ChargeLine
@onready var volley_line: Line2D = $VolleyLine
@onready var muzzle: Marker2D = $Muzzle
@onready var contact_area: Area2D = $ContactArea
@onready var health_bar: ProgressBar = $HealthBar
@onready var floor_marks := [$FloorMarkLeft, $FloorMarkCenter, $FloorMarkRight]


func _ready() -> void:
	starting_position = position
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		if bool(game_state.defeated_bosses.get(boss_id, false)):
			is_dead = true
			queue_free()
			return
		game_state.room_changed.connect(_on_room_changed)
	current_health = max_health
	health_bar.max_value = max_health
	health_bar.value = current_health
	target_player = get_tree().get_first_node_in_group("player") as Player
	charge_line.hide()
	volley_line.hide()
	_hide_floor_marks()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Player
	velocity.y = minf(velocity.y + 1000.0 * delta, 600.0) if not is_on_floor() else 0.0
	if target_player == null or target_player.is_dead:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		move_and_slide()
		return
	if not active:
		var game_state := get_node_or_null("/root/GameState")
		if game_state == null or game_state.current_room_id != ROOM_ID or global_position.distance_to(target_player.global_position) > activation_range:
			move_and_slide()
			return
		_begin_battle()
	charge_cooldown = maxf(charge_cooldown - delta, 0.0)
	volley_cooldown = maxf(volley_cooldown - delta, 0.0)
	pulse_cooldown = maxf(pulse_cooldown - delta, 0.0)
	contact_cooldown = maxf(contact_cooldown - delta, 0.0)
	if pulse_flash > 0.0:
		pulse_flash = maxf(pulse_flash - delta, 0.0)
		if is_zero_approx(pulse_flash):
			_hide_floor_marks()
	if charge_windup > 0.0:
		charge_windup = maxf(charge_windup - delta, 0.0)
		velocity.x = 0.0
		charge_line.modulate.a = 0.6 + 0.3 * sin(Time.get_ticks_msec() * 0.025)
		if is_zero_approx(charge_windup):
			charge_line.hide()
			armor.color = _resting_armor_color()
			charge_remaining = 0.5 if phase == 1 else 0.62
	elif volley_windup > 0.0:
		volley_windup = maxf(volley_windup - delta, 0.0)
		velocity.x = 0.0
		volley_aim = (target_player.global_position - muzzle.global_position).normalized()
		volley_line.points = PackedVector2Array([muzzle.position, muzzle.position + volley_aim * 230.0])
		volley_line.modulate.a = 0.55 + 0.35 * sin(Time.get_ticks_msec() * 0.027)
		if is_zero_approx(volley_windup):
			_fire_volley()
	elif pulse_windup > 0.0:
		pulse_windup = maxf(pulse_windup - delta, 0.0)
		velocity.x = 0.0
		for index in pulse_indices:
			floor_marks[index].modulate.a = 0.55 + 0.35 * sin(Time.get_ticks_msec() * 0.024)
		if is_zero_approx(pulse_windup):
			_release_pulse()
	elif charge_remaining > 0.0:
		charge_remaining = maxf(charge_remaining - delta, 0.0)
		velocity.x = charge_direction * (255.0 if phase == 1 else 315.0)
		if is_zero_approx(charge_remaining):
			recovery_remaining = 0.55
	elif recovery_remaining > 0.0:
		recovery_remaining = maxf(recovery_remaining - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, 850.0 * delta)
	else:
		var horizontal_distance: float = target_player.global_position.x - global_position.x
		velocity.x = signf(horizontal_distance) * (52.0 if phase == 1 else 67.0) if absf(horizontal_distance) > 85.0 else 0.0
		muzzle.position.x = 26.0 * (-1.0 if horizontal_distance < 0.0 else 1.0)
		if is_zero_approx(pulse_cooldown):
			_start_pulse()
		elif is_zero_approx(charge_cooldown) and absf(horizontal_distance) > 90.0:
			_start_charge()
		elif is_zero_approx(volley_cooldown):
			_start_volley()
	move_and_slide()
	position.x = clampf(position.x, arena_left_x, arena_right_x)
	if charge_remaining > 0.0 and is_on_wall():
		charge_remaining = 0.0
		recovery_remaining = 0.55
	_try_contact_damage()


func _begin_battle() -> void:
	if active or is_dead:
		return
	active = true
	battle_started.emit()


func _start_charge() -> void:
	charge_direction = -1.0 if target_player.global_position.x < global_position.x else 1.0
	charge_windup = 0.72 if phase == 1 else 0.55
	charge_cooldown = 3.0 if phase == 1 else 2.45
	velocity.x = 0.0
	charge_line.points = PackedVector2Array([Vector2.ZERO, Vector2(charge_direction * 220.0, 0.0)])
	charge_line.show()
	armor.color = Color(0.8, 0.59, 1.0, 1.0)


func _start_volley() -> void:
	volley_windup = 0.65 if phase == 1 else 0.5
	volley_cooldown = 2.6 if phase == 1 else 2.0
	velocity.x = 0.0
	volley_line.show()
	eye.color = Color(1.0, 0.9, 0.61, 1.0)


func _fire_volley() -> void:
	volley_line.hide()
	eye.color = Color(0.83, 0.98, 1.0, 1.0)
	if get_parent() == null:
		return
	var angles: Array[float] = [-0.2, 0.0, 0.2]
	if phase == 2:
		angles = [-0.36, -0.18, 0.0, 0.18, 0.36]
	for angle in angles:
		var projectile := PROJECTILE_SCENE.instantiate() as Area2D
		get_parent().add_child(projectile)
		projectile.global_position = muzzle.global_position
		projectile.setup(volley_aim.rotated(angle), self)
		projectile.set("speed", 165.0 if phase == 1 else 195.0)
		(projectile.get_node("Core") as Polygon2D).color = Color(0.62, 0.78, 1.0, 1.0)
		(projectile.get_node("Glow") as Polygon2D).color = Color(0.35, 0.56, 1.0, 0.36)
	recovery_remaining = 0.35


func _start_pulse() -> void:
	pulse_windup = 0.9 if phase == 1 else 0.72
	pulse_cooldown = 4.1 if phase == 1 else 3.3
	velocity.x = 0.0
	var parent_origin := (get_parent() as Node2D).global_position
	var closest_lane := clampi(roundi((target_player.global_position.x - parent_origin.x - 650.0) / 300.0), 0, 2)
	pulse_indices = [closest_lane]
	if phase == 2:
		pulse_indices.append((closest_lane + 1) % 3)
	for index in pulse_indices:
		var mark: Polygon2D = floor_marks[index]
		mark.global_position = parent_origin + Vector2(650.0 + index * 300.0, 389.0)
		mark.color = Color(0.61, 0.72, 1.0, 0.52)
		mark.show()


func _release_pulse() -> void:
	pulse_flash = 0.26
	for index in pulse_indices:
		var mark: Polygon2D = floor_marks[index]
		mark.color = Color(0.75, 0.91, 1.0, 0.92)
		mark.modulate.a = 1.0
	if target_player != null and not target_player.is_dead:
		for index in pulse_indices:
			var mark: Polygon2D = floor_marks[index]
			if absf(target_player.global_position.x - mark.global_position.x) < 66.0 and target_player.global_position.y > mark.global_position.y - 65.0:
				var push := -1.0 if target_player.global_position.x < global_position.x else 1.0
				target_player.take_damage(2, Vector2(push * 145.0, -200.0))
				break
	recovery_remaining = 0.4


func _hide_floor_marks() -> void:
	for mark in floor_marks:
		mark.hide()


func _try_contact_damage() -> void:
	if contact_cooldown > 0.0:
		return
	for body in contact_area.get_overlapping_bodies():
		if body is Player and not body.is_dead:
			var push := -1.0 if body.global_position.x < global_position.x else 1.0
			body.take_damage(2, Vector2(push * 180.0, -160.0))
			contact_cooldown = 0.9
			return


func take_damage(amount: int, _knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or amount <= 0:
		return
	_begin_battle()
	current_health = maxi(current_health - amount, 0)
	health_bar.value = current_health
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		_die()
		return
	if phase == 1 and current_health <= max_health * 0.5:
		phase = 2
		charge_cooldown = minf(charge_cooldown, 0.75)
		if is_zero_approx(charge_windup):
			armor.color = _resting_armor_color()
		phase_changed.emit(phase)
	armor.modulate = Color(1.6, 0.75, 1.7, 1.0)
	create_tween().tween_property(armor, "modulate", Color.WHITE, 0.16)


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	charge_line.hide()
	volley_line.hide()
	_hide_floor_marks()
	_clear_projectiles()
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.mark_boss_defeated(boss_id):
		game_state.unlock_shortcut(CLEAR_EVENT)
		game_state.add_gold(110)
		game_state.add_item("resonance_shard")
		if is_instance_valid(target_player):
			target_player.add_xp(6)
	defeated.emit()
	queue_free()


func _on_room_changed(room_id: String) -> void:
	if room_id != ROOM_ID and active and not is_dead:
		_reset_battle()


func _reset_battle() -> void:
	active = false
	phase = 1
	current_health = max_health
	health_bar.value = current_health
	position = starting_position
	velocity = Vector2.ZERO
	charge_cooldown = 2.4
	volley_cooldown = 1.5
	pulse_cooldown = 3.5
	charge_windup = 0.0
	charge_remaining = 0.0
	volley_windup = 0.0
	pulse_windup = 0.0
	pulse_flash = 0.0
	recovery_remaining = 0.0
	contact_cooldown = 0.0
	charge_line.hide()
	volley_line.hide()
	_hide_floor_marks()
	_clear_projectiles()
	armor.color = _resting_armor_color()
	eye.color = Color(0.83, 0.98, 1.0, 1.0)
	health_changed.emit(current_health, max_health)


func _resting_armor_color() -> Color:
	return Color(0.48, 0.51, 0.76, 1.0) if phase == 2 else Color(0.39, 0.46, 0.68, 1.0)


func _clear_projectiles() -> void:
	for projectile in get_tree().get_nodes_in_group("enemy_projectile"):
		if projectile.get("source") == self:
			projectile.queue_free()
