extends CharacterBody2D

signal battle_started
signal health_changed(current_health: int, maximum_health: int)
signal phase_changed(phase: int)
signal defeated

const PROJECTILE_SCENE: PackedScene = preload("res://EnemyProjectile.tscn")
const ROOM_ID := "starfall_hollow_throne"
const CLEAR_EVENT := "starfall_sovereign_defeated"
const LANE_X := [620.0, 970.0, 1320.0]

@export var boss_id: String = "hollow_sovereign"
@export var boss_name: String = "Hollow Sovereign"
@export var max_health: int = 36
@export var activation_range: float = 365.0
@export var arena_left_x: float = 480.0
@export var arena_right_x: float = 1570.0

var current_health: int
var phase: int = 1
var active: bool = false
var is_dead: bool = false
var target_player: Player
var starting_position: Vector2
var attack_index: int = 0
var attack_delay: float = 1.0
var current_pattern: String = ""
var windup_remaining: float = 0.0
var charge_remaining: float = 0.0
var recovery_remaining: float = 0.0
var impact_flash: float = 0.0
var contact_cooldown: float = 0.0
var charge_direction: float = -1.0
var aim_direction: Vector2 = Vector2.LEFT
var locked_point: Vector2 = Vector2.ZERO
var rune_indices: Array[int] = []
var star_columns: Array[float] = []
var cue_streams: Dictionary = {}

@onready var aura: Polygon2D = $Aura
@onready var mantle: Polygon2D = $Mantle
@onready var eye: Polygon2D = $Eye
@onready var telegraph_line: Line2D = $TelegraphLine
@onready var rift_mark: Line2D = $RiftMark
@onready var rift_hint: Label = $RiftHint
@onready var nova_ring: Polygon2D = $NovaRing
@onready var lock_mark: Polygon2D = $LockMark
@onready var muzzle: Marker2D = $Muzzle
@onready var contact_area: Area2D = $ContactArea
@onready var health_bar: ProgressBar = $HealthBar
@onready var floor_marks := [$FloorMarkLeft, $FloorMarkCenter, $FloorMarkRight]
@onready var column_marks := [$ColumnMarkLeft, $ColumnMarkRight]
@onready var warning_cue: AudioStreamPlayer2D = $WarningCue
@onready var impact_cue: AudioStreamPlayer2D = $ImpactCue


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
	_hide_warnings()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	aura.modulate.a = (0.55 if not active else 0.78) + 0.18 * sin(Time.get_ticks_msec() * 0.004)
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Player
	velocity.y = minf(velocity.y + 1000.0 * delta, 600.0) if not is_on_floor() else 0.0
	if target_player == null or target_player.is_dead:
		velocity.x = move_toward(velocity.x, 0.0, 750.0 * delta)
		move_and_slide()
		return
	if not active:
		var game_state := get_node_or_null("/root/GameState")
		if game_state == null or game_state.current_room_id != ROOM_ID or global_position.distance_to(target_player.global_position) > activation_range:
			move_and_slide()
			return
		_begin_battle()
	contact_cooldown = maxf(contact_cooldown - delta, 0.0)
	if impact_flash > 0.0:
		impact_flash = maxf(impact_flash - delta, 0.0)
		if is_zero_approx(impact_flash):
			_hide_warnings()
	if windup_remaining > 0.0:
		windup_remaining = maxf(windup_remaining - delta, 0.0)
		velocity.x = 0.0
		telegraph_line.modulate.a = 0.6 + 0.3 * sin(Time.get_ticks_msec() * 0.026)
		if is_zero_approx(windup_remaining):
			_release_pattern()
	elif charge_remaining > 0.0:
		charge_remaining = maxf(charge_remaining - delta, 0.0)
		velocity.x = charge_direction * (300.0 if phase == 1 else 345.0)
		if is_zero_approx(charge_remaining):
			recovery_remaining = 0.48
	elif recovery_remaining > 0.0:
		recovery_remaining = maxf(recovery_remaining - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	else:
		var distance_x := target_player.global_position.x - global_position.x
		velocity.x = signf(distance_x) * (52.0 + phase * 10.0) if absf(distance_x) > 110.0 else 0.0
		muzzle.position.x = 28.0 * (-1.0 if distance_x < 0.0 else 1.0)
		attack_delay = maxf(attack_delay - delta, 0.0)
		if is_zero_approx(attack_delay):
			_choose_pattern()
	move_and_slide()
	position.x = clampf(position.x, arena_left_x, arena_right_x)
	if charge_remaining > 0.0 and is_on_wall():
		charge_remaining = 0.0
		recovery_remaining = 0.48
	_try_contact_damage()


func _begin_battle() -> void:
	if active or is_dead:
		return
	active = true
	battle_started.emit()


func _choose_pattern() -> void:
	var patterns: Array[String] = ["lunge", "volley", "runes"]
	if phase == 2:
		patterns = ["lunge", "starfall", "volley", "nova", "runes", "rift"]
	elif phase == 3:
		patterns = ["lunge", "soul_lock", "starfall", "volley", "nova", "runes", "rift"]
	_start_pattern(patterns[attack_index % patterns.size()])
	attack_index += 1


func _start_pattern(pattern_name: String) -> void:
	if is_dead or not is_instance_valid(target_player):
		return
	_hide_warnings()
	current_pattern = pattern_name
	windup_remaining = 0.85 if phase == 1 else (0.72 if phase == 2 else 0.62)
	attack_delay = 1.1 if phase < 3 else 0.85
	velocity.x = 0.0
	eye.color = Color(1.0, 0.71, 0.9, 1.0)
	_play_cue(pattern_name, false)
	match pattern_name:
		"lunge":
			charge_direction = -1.0 if target_player.global_position.x < global_position.x else 1.0
			telegraph_line.points = PackedVector2Array([Vector2.ZERO, Vector2(charge_direction * 265.0, 0.0)])
			telegraph_line.show()
		"volley":
			aim_direction = (target_player.global_position - muzzle.global_position).normalized()
			telegraph_line.points = PackedVector2Array([muzzle.position, muzzle.position + aim_direction * 300.0])
			telegraph_line.show()
		"runes":
			var local_x := target_player.global_position.x - (get_parent() as Node2D).global_position.x
			var nearest := 0
			for index in range(1, LANE_X.size()):
				if absf(local_x - LANE_X[index]) < absf(local_x - LANE_X[nearest]):
					nearest = index
			rune_indices = [nearest]
			if phase >= 2:
				rune_indices.append((nearest + 1) % LANE_X.size())
			for index in rune_indices:
				floor_marks[index].global_position = (get_parent() as Node2D).global_position + Vector2(LANE_X[index], 427.0)
				floor_marks[index].show()
		"starfall":
			var local_x := target_player.global_position.x - (get_parent() as Node2D).global_position.x
			star_columns = [clampf(local_x, 540.0, 1510.0), clampf(local_x + (220.0 if local_x < 1000.0 else -220.0), 540.0, 1510.0)]
			for index in range(column_marks.size()):
				column_marks[index].global_position = (get_parent() as Node2D).global_position + Vector2(star_columns[index], 220.0)
				column_marks[index].show()
		"nova":
			nova_ring.show()
		"soul_lock":
			locked_point = target_player.global_position
			lock_mark.global_position = locked_point
			lock_mark.show()
		"rift":
			var parent_origin := (get_parent() as Node2D).global_position
			rift_mark.global_position = parent_origin + Vector2(arena_left_x, 427.0)
			rift_mark.default_color = Color(0.91, 0.52, 1.0, 0.65)
			rift_mark.show()
			rift_hint.global_position = parent_origin + Vector2(970.0, 347.0)
			rift_hint.show()


func _release_pattern() -> void:
	windup_remaining = 0.0
	impact_flash = 0.23
	eye.color = Color(0.86, 0.95, 1.0, 1.0)
	telegraph_line.hide()
	_play_cue(current_pattern, true)
	var parent_origin := (get_parent() as Node2D).global_position
	match current_pattern:
		"lunge":
			charge_remaining = 0.48 if phase < 3 else 0.58
		"volley":
			_fire_volley()
		"runes":
			for index in rune_indices:
				floor_marks[index].color = Color(0.9, 0.63, 1.0, 0.92)
				if target_player.global_position.y > parent_origin.y + 345.0 and absf(target_player.global_position.x - floor_marks[index].global_position.x) < 110.0:
					_damage_player(2)
					break
		"starfall":
			for index in range(column_marks.size()):
				column_marks[index].color = Color(0.78, 0.65, 1.0, 0.7)
				if absf(target_player.global_position.x - column_marks[index].global_position.x) < 48.0:
					_damage_player(2)
					break
		"nova":
			nova_ring.color = Color(0.76, 0.45, 0.94, 0.65)
			if target_player.global_position.distance_to(global_position) < 175.0:
				_damage_player(2)
		"soul_lock":
			lock_mark.color = Color(0.91, 0.56, 0.95, 0.88)
			if target_player.global_position.distance_to(locked_point) < 88.0:
				_damage_player(2)
		"rift":
			rift_mark.default_color = Color(1.0, 0.75, 1.0, 1.0)
			if target_player.global_position.y > parent_origin.y + 355.0 and target_player.global_position.x >= parent_origin.x + arena_left_x and target_player.global_position.x <= parent_origin.x + arena_right_x:
				_damage_player(2)
	if current_pattern != "lunge":
		recovery_remaining = 0.38


func _fire_volley() -> void:
	var angles: Array[float] = [-0.22, 0.0, 0.22]
	if phase == 2:
		angles = [-0.34, -0.17, 0.0, 0.17, 0.34]
	elif phase == 3:
		angles = [-0.44, -0.29, -0.14, 0.0, 0.14, 0.29, 0.44]
	for angle in angles:
		var projectile := PROJECTILE_SCENE.instantiate() as Area2D
		get_parent().add_child(projectile)
		projectile.global_position = muzzle.global_position
		projectile.setup(aim_direction.rotated(angle), self)
		projectile.set("speed", 180.0 + phase * 20.0)
		(projectile.get_node("Core") as Polygon2D).color = Color(0.78, 0.57, 1.0, 1.0)
		(projectile.get_node("Glow") as Polygon2D).color = Color(0.59, 0.34, 0.9, 0.38)


func _damage_player(amount: int) -> void:
	if target_player != null and not target_player.is_dead:
		var direction := -1.0 if target_player.global_position.x < global_position.x else 1.0
		target_player.take_damage(amount, Vector2(direction * 170.0, -190.0))


func _try_contact_damage() -> void:
	if contact_cooldown > 0.0:
		return
	for body in contact_area.get_overlapping_bodies():
		if body is Player and not body.is_dead:
			var direction := -1.0 if body.global_position.x < global_position.x else 1.0
			body.take_damage(2, Vector2(direction * 185.0, -160.0))
			contact_cooldown = 0.9
			return


func take_damage(amount: int, _knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or amount <= 0:
		return
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or game_state.current_room_id != ROOM_ID:
		return
	_begin_battle()
	current_health = maxi(current_health - amount, 0)
	health_bar.value = current_health
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		_die()
		return
	if phase == 1 and current_health <= max_health * 0.6:
		phase = 2
		aura.color = Color(0.72, 0.37, 0.79, 0.3)
		phase_changed.emit(phase)
	elif phase == 2 and current_health <= max_health * 0.25:
		phase = 3
		aura.color = Color(0.9, 0.5, 0.87, 0.37)
		phase_changed.emit(phase)
	mantle.modulate = Color(1.5, 0.75, 1.6, 1.0)
	create_tween().tween_property(mantle, "modulate", Color.WHITE, 0.18)


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	_hide_warnings()
	_clear_projectiles()
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.mark_boss_defeated(boss_id):
		game_state.unlock_shortcut(CLEAR_EVENT)
		game_state.add_item("sovereign_crown")
		game_state.add_gold(250)
		if is_instance_valid(target_player):
			target_player.add_xp(14)
	defeated.emit()
	queue_free()


func _on_room_changed(room_id: String) -> void:
	if room_id != ROOM_ID and active and not is_dead:
		_reset_battle()


func _reset_battle() -> void:
	active = false
	phase = 1
	aura.color = Color(0.53, 0.34, 0.77, 0.23)
	current_health = max_health
	health_bar.value = current_health
	position = starting_position
	velocity = Vector2.ZERO
	attack_index = 0
	attack_delay = 1.0
	windup_remaining = 0.0
	charge_remaining = 0.0
	recovery_remaining = 0.0
	impact_flash = 0.0
	contact_cooldown = 0.0
	_hide_warnings()
	_clear_projectiles()
	health_changed.emit(current_health, max_health)


func _hide_warnings() -> void:
	telegraph_line.hide()
	rift_mark.hide()
	rift_hint.hide()
	nova_ring.hide()
	lock_mark.hide()
	for mark in floor_marks:
		mark.hide()
		mark.color = Color(0.63, 0.45, 0.84, 0.5)
	for mark in column_marks:
		mark.hide()
		mark.color = Color(0.5, 0.45, 0.82, 0.27)
	nova_ring.color = Color(0.58, 0.37, 0.81, 0.27)
	lock_mark.color = Color(0.68, 0.45, 0.88, 0.45)


func _play_cue(pattern_name: String, impact: bool) -> void:
	var key := pattern_name + ("_impact" if impact else "_warning")
	if not cue_streams.has(key):
		var frequency := float({"lunge": 164.8, "volley": 246.9, "runes": 196.0, "starfall": 146.8, "nova": 110.0, "soul_lock": 293.7, "rift": 130.8}.get(pattern_name, 174.6))
		cue_streams[key] = _create_cue(frequency, impact)
	var player := impact_cue if impact else warning_cue
	player.stream = cue_streams[key]
	player.play()


func _create_cue(frequency: float, impact: bool) -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.24 if impact else 0.18
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in range(sample_count):
		var time := float(index) / sample_rate
		var progress := time / duration
		var envelope := pow(1.0 - progress, 2.0) if impact else sin(PI * progress)
		var pitch := frequency * (1.3 - progress * 0.5 if impact else 0.8 + progress * 0.45)
		var sample := (sin(TAU * pitch * time) * 0.55 + sin(TAU * pitch * 1.5 * time) * 0.18) * envelope
		data.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _clear_projectiles() -> void:
	for projectile in get_tree().get_nodes_in_group("enemy_projectile"):
		if projectile.get("source") == self:
			projectile.queue_free()
