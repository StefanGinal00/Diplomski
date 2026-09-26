extends CharacterBody2D

signal battle_started
signal health_changed(current_health: int, maximum_health: int)
signal phase_changed(phase: int)
signal defeated

const PROJECTILE_SCENE: PackedScene = preload("res://EnemyProjectile.tscn")

@export var boss_id: String = "ash_castellan"
@export var boss_name: String = "Ash Castellan"
@export var zone_id: String = "ashen_bastion"
@export var max_health: int = 26
@export var gravity: float = 1000.0
@export var activation_range: float = 310.0
@export var walk_speed: float = 58.0
@export var charge_speed: float = 270.0
@export var arena_left_x: float = 345.0
@export var arena_right_x: float = 980.0

var current_health: int
var phase: int = 1
var active: bool = false
var is_dead: bool = false
var is_rematch: bool = false
var target_player: Player
var charge_cooldown: float = 2.6
var volley_cooldown: float = 1.7
var eruption_cooldown: float = 3.8
var charge_windup: float = 0.0
var charge_remaining: float = 0.0
var recovery_remaining: float = 0.0
var eruption_windup: float = 0.0
var eruption_flash: float = 0.0
var contact_cooldown: float = 0.0
var charge_direction: float = -1.0

@onready var armor: Polygon2D = $Armor
@onready var crown: Polygon2D = $Crown
@onready var charge_line: Line2D = $ChargeLine
@onready var eruption_marks := [$EruptionLeft, $EruptionMiddle, $EruptionRight]
@onready var muzzle: Marker2D = $Muzzle
@onready var contact_area: Area2D = $ContactArea
@onready var challenge_prompt: Label = $ChallengePrompt


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and bool(game_state.defeated_bosses.get(boss_id, false)):
		if bool(game_state.boss_rematches.get(boss_id, false)):
			is_dead = true
			queue_free()
			return
		is_rematch = true
		boss_name = "Awakened Castellan"
		max_health = 42
		walk_speed = 72.0
		charge_speed = 320.0
		armor.color = Color(0.43, 0.31, 0.48, 1.0)
	current_health = max_health
	target_player = get_tree().get_first_node_in_group("player") as Player
	charge_line.hide()
	_hide_eruption_marks()
	challenge_prompt.visible = is_rematch
	if game_state != null:
		game_state.room_changed.connect(_on_room_changed)


func _on_room_changed(room_id: String) -> void:
	if room_id == "ash_throne" or is_dead or not active:
		return
	active = false
	phase = 1
	current_health = max_health
	position = Vector2(700, 380)
	velocity = Vector2.ZERO
	charge_cooldown = 2.6
	volley_cooldown = 1.7
	eruption_cooldown = 3.8
	charge_windup = 0.0
	charge_remaining = 0.0
	recovery_remaining = 0.0
	eruption_windup = 0.0
	eruption_flash = 0.0
	contact_cooldown = 0.0
	charge_line.hide()
	_hide_eruption_marks()
	armor.color = _combat_color()
	challenge_prompt.visible = is_rematch
	for projectile in get_tree().get_nodes_in_group("enemy_projectile"):
		if projectile.get("source") == self:
			projectile.queue_free()
	health_changed.emit(current_health, max_health)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Player
	velocity.y = minf(velocity.y + gravity * delta, 600.0) if not is_on_floor() else 0.0
	if target_player == null or target_player.is_dead:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		move_and_slide()
		return
	if not active:
		if is_rematch or global_position.distance_to(target_player.global_position) > activation_range:
			move_and_slide()
			return
		_begin_battle()
	charge_cooldown = maxf(charge_cooldown - delta, 0.0)
	volley_cooldown = maxf(volley_cooldown - delta, 0.0)
	eruption_cooldown = maxf(eruption_cooldown - delta, 0.0)
	contact_cooldown = maxf(contact_cooldown - delta, 0.0)
	if eruption_flash > 0.0:
		eruption_flash = maxf(eruption_flash - delta, 0.0)
		if is_zero_approx(eruption_flash):
			_hide_eruption_marks()
	if charge_windup > 0.0:
		charge_windup = maxf(charge_windup - delta, 0.0)
		velocity.x = 0.0
		charge_line.modulate.a = 0.55 + 0.35 * sin(Time.get_ticks_msec() * 0.025)
		if is_zero_approx(charge_windup):
			charge_line.hide()
			charge_remaining = 0.56 if phase == 1 else 0.7
	elif eruption_windup > 0.0:
		eruption_windup = maxf(eruption_windup - delta, 0.0)
		velocity.x = 0.0
		for mark in eruption_marks:
			mark.modulate.a = 0.5 + 0.35 * sin(Time.get_ticks_msec() * 0.02)
		if is_zero_approx(eruption_windup):
			_release_eruption()
	elif charge_remaining > 0.0:
		charge_remaining = maxf(charge_remaining - delta, 0.0)
		velocity.x = charge_direction * charge_speed
		if is_zero_approx(charge_remaining):
			recovery_remaining = 0.5
	elif recovery_remaining > 0.0:
		recovery_remaining = maxf(recovery_remaining - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, 850.0 * delta)
	else:
		var horizontal_distance: float = target_player.global_position.x - global_position.x
		velocity.x = signf(horizontal_distance) * walk_speed if absf(horizontal_distance) > 85.0 else 0.0
		muzzle.position.x = 26.0 * signf(horizontal_distance)
		if is_zero_approx(eruption_cooldown):
			_start_eruption()
		elif is_zero_approx(charge_cooldown):
			_start_charge()
		elif is_zero_approx(volley_cooldown):
			_fire_volley()
	move_and_slide()
	position.x = clampf(position.x, arena_left_x, arena_right_x)
	if charge_remaining > 0.0 and is_on_wall():
		charge_remaining = 0.0
		recovery_remaining = 0.5
	_try_contact_damage()


func _begin_battle() -> void:
	if active or is_dead:
		return
	active = true
	challenge_prompt.hide()
	battle_started.emit()


func _start_charge() -> void:
	if target_player == null or target_player.is_dead:
		return
	charge_direction = signf(target_player.global_position.x - global_position.x)
	if is_zero_approx(charge_direction):
		charge_direction = -1.0
	charge_windup = 0.78 if phase == 1 else (0.48 if phase == 3 else 0.6)
	charge_cooldown = 3.1 if phase == 1 else (2.0 if phase == 3 else 2.5)
	velocity.x = 0.0
	charge_line.points = PackedVector2Array([Vector2.ZERO, Vector2(charge_direction * 200.0, 0.0)])
	charge_line.show()
	armor.color = Color(0.93, 0.48, 0.2, 1.0)


func _fire_volley() -> void:
	if target_player == null or target_player.is_dead or get_parent() == null:
		return
	var direction := (target_player.global_position - muzzle.global_position).normalized()
	var angles: Array[float] = [-0.12, 0.12]
	if phase == 3:
		angles = [-0.4, -0.2, 0.0, 0.2, 0.4]
	elif phase == 2:
		angles = [-0.23, 0.0, 0.23]
	for angle in angles:
		var projectile := PROJECTILE_SCENE.instantiate() as Area2D
		get_parent().add_child(projectile)
		projectile.global_position = muzzle.global_position
		projectile.setup(direction.rotated(angle), self)
		projectile.set("speed", 165.0 if phase == 1 else (215.0 if phase == 3 else 190.0))
		(projectile.get_node("Core") as Polygon2D).color = Color(1.0, 0.49, 0.16, 1.0)
	volley_cooldown = 2.0 if phase == 1 else (1.15 if phase == 3 else 1.5)
	armor.color = _combat_color()


func _start_eruption() -> void:
	eruption_windup = 0.9 if phase == 1 else (0.58 if phase == 3 else 0.72)
	eruption_cooldown = 4.3 if phase == 1 else (2.8 if phase == 3 else 3.5)
	velocity.x = 0.0
	var spacing := 150.0 if phase == 1 else 130.0
	for index in range(eruption_marks.size()):
		var mark: Polygon2D = eruption_marks[index]
		mark.position.x = (float(index) - 1.0) * spacing
		mark.color = Color(1.0, 0.58, 0.18, 0.5)
		mark.show()


func _release_eruption() -> void:
	eruption_windup = 0.0
	eruption_flash = 0.22
	for mark in eruption_marks:
		mark.color = Color(1.0, 0.21, 0.09, 0.85)
		mark.modulate.a = 1.0
	if target_player != null and not target_player.is_dead and target_player.global_position.y > global_position.y - 48.0:
		for mark in eruption_marks:
			if absf(target_player.global_position.x - (global_position.x + mark.position.x)) < 32.0:
				var push := signf(target_player.global_position.x - global_position.x)
				target_player.take_damage(2 if phase >= 2 else 1, Vector2(push * 160.0, -210.0))
				break
	armor.color = _combat_color()


func _hide_eruption_marks() -> void:
	for mark in eruption_marks:
		mark.hide()


func _try_contact_damage() -> void:
	if contact_cooldown > 0.0:
		return
	for body in contact_area.get_overlapping_bodies():
		if body is Player and not body.is_dead:
			var direction := -1.0 if body.global_position.x < global_position.x else 1.0
			body.take_damage(2, Vector2(direction * 210.0, -170.0))
			contact_cooldown = 0.9
			return


func _combat_color() -> Color:
	return Color(0.54, 0.32, 0.57, 1.0) if is_rematch else Color(0.54, 0.21, 0.18, 1.0)


func take_damage(amount: int, _knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or amount <= 0:
		return
	if is_rematch and not active:
		var game_state := get_node_or_null("/root/GameState")
		if game_state == null or game_state.current_room_id != "ash_throne":
			return
	_begin_battle()
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		_die()
		return
	if phase == 1 and current_health <= max_health / 2:
		phase = 2
		charge_cooldown = minf(charge_cooldown, 0.9)
		phase_changed.emit(phase)
	elif is_rematch and phase == 2 and current_health <= max_health / 3:
		phase = 3
		eruption_cooldown = minf(eruption_cooldown, 0.6)
		phase_changed.emit(phase)
	armor.modulate = Color(1.6, 0.75, 0.53, 1.0)
	create_tween().tween_property(armor, "modulate", Color.WHITE, 0.16)


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	charge_line.hide()
	_hide_eruption_marks()
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		if is_rematch:
			if game_state.mark_boss_rematch_cleared(boss_id):
				game_state.add_item("castellan_heart")
				game_state.add_item("iron_fragment", 2)
				game_state.add_gold(120)
				if is_instance_valid(target_player):
					target_player.increase_max_health(1)
					target_player.add_xp(6)
		elif game_state.mark_boss_defeated(boss_id):
			game_state.add_item("castellan_seal")
			game_state.add_item("iron_fragment")
			game_state.add_gold(150)
			game_state.set_zone_tier(zone_id, maxi(game_state.get_zone_tier(zone_id), 1))
			if is_instance_valid(target_player):
				target_player.add_xp(9)
	defeated.emit()
	queue_free()
