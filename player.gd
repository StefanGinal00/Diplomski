class_name Player
extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal mana_changed(current_mana: int, maximum_mana: int)
signal combat_message(message: String)
signal second_breath_changed(is_active: bool)
signal second_breath_triggered
signal progression_changed(current_xp: int, required_xp: int, skill_points: int)
signal double_jump_state_changed(is_unlocked: bool)
signal dash_state_changed(is_unlocked: bool)
signal weapon_changed(weapon_id: String, arrow_type: String)
signal respawned
signal died

@export_category("Movement")
@export var move_speed: float = 165.0
@export var acceleration: float = 900.0
@export var friction: float = 1100.0
@export var crouch_speed_multiplier: float = 0.45
@export_range(0.3, 1.0, 0.05) var crouch_sprite_height_multiplier: float = 0.65

@export_category("Jump")
@export var jump_force: float = -420.0
@export var gravity: float = 1000.0
@export var fall_gravity_multiplier: float = 1.4
@export_range(0.0, 0.3, 0.01) var coyote_time: float = 0.12
@export_range(0.0, 0.3, 0.01) var jump_buffer_time: float = 0.12
@export_range(0.2, 0.9, 0.05) var jump_release_multiplier: float = 0.5

@export_category("Dash")
@export var dash_speed: float = 360.0
@export_range(0.05, 0.5, 0.01) var dash_duration: float = 0.16
@export_range(0.1, 2.0, 0.05) var dash_cooldown: float = 0.45

@export_category("Health")
@export_range(1, 100, 1) var max_health: int = 5
@export_range(0.1, 5.0, 0.1) var invulnerability_duration: float = 0.8

@export_category("Progression")
@export_range(1, 999, 1) var xp_per_level: int = 3
@export_range(1, 10, 1) var double_jump_cost: int = 1
@export_range(1, 10, 1) var dash_cost: int = 1

@export_category("Combat")
@export_range(1, 100, 1) var attack_damage: int = 1
@export_range(8.0, 80.0, 1.0) var attack_offset: float = 24.0
@export_range(0.05, 2.0, 0.05) var attack_cooldown: float = 0.35
@export_range(0.02, 1.0, 0.01) var attack_visual_duration: float = 0.12
@export var attack_knockback: Vector2 = Vector2(170.0, -70.0)
@export var arrow_scene: PackedScene
@export var magic_projectile_scene: PackedScene
@export_range(1, 30, 1) var max_mana: int = 6
@export_range(0.1, 5.0, 0.1) var mana_regen_rate: float = 1.0
@export_range(0.0, 5.0, 0.1) var mana_regen_delay: float = 1.25

var current_health: int
var xp: int = 0
var skill_points: int = 0
var double_jump_unlocked: bool = false
var dash_unlocked: bool = false
var second_breath_active: bool = false
var current_mana: int
var sword_mastery_unlocked: bool = false
var bow_mastery_unlocked: bool = false
var staff_mastery_unlocked: bool = false
var sword_reach_unlocked: bool = false
var bow_piercing_unlocked: bool = false
var staff_flow_unlocked: bool = false

var jump_count: int = 0
var coyote_time_remaining: float = 0.0
var jump_buffer_remaining: float = 0.0
var dash_time_remaining: float = 0.0
var dash_cooldown_remaining: float = 0.0
var is_dashing: bool = false
var is_crouching: bool = false
var is_invulnerable: bool = false
var is_dead: bool = false
var is_safe_resting: bool = false
var rest_previous_invulnerability: bool = false
var rest_previous_invulnerability_time: float = 0.0
var mana_regen_delay_remaining: float = 0.0
var mana_regen_progress: float = 0.0
var facing_direction: float = 1.0
var respawn_position: Vector2

@onready var sprite: Sprite2D = $Sprite2D
@onready var player_collision: CollisionShape2D = $CollisionShape2D
@onready var invulnerability_timer: Timer = $InvulnerabilityTimer
@onready var attack_cast: ShapeCast2D = $AttackCast
@onready var attack_visual: Polygon2D = $AttackCast/AttackVisual
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var attack_visual_timer: Timer = $AttackVisualTimer
@onready var dash_visual: Polygon2D = $DashVisual
@onready var bow_visual: Polygon2D = get_node_or_null("BowVisual") as Polygon2D
@onready var staff_visual: Polygon2D = get_node_or_null("StaffVisual") as Polygon2D
@onready var weapon_aura: Polygon2D = $WeaponAura
@onready var weapon_aura_halo: Polygon2D = $WeaponAura/Halo

var standing_sprite_scale: Vector2


func _ready() -> void:
	current_health = max_health
	current_mana = max_mana
	var game_state := _get_game_state()
	if game_state != null:
		game_state.apply_to_player(self)
		if not game_state.equipment_changed.is_connected(_on_equipment_changed):
			game_state.equipment_changed.connect(_on_equipment_changed)
	respawn_position = global_position
	standing_sprite_scale = sprite.scale
	invulnerability_timer.wait_time = invulnerability_duration
	attack_cooldown_timer.wait_time = attack_cooldown
	attack_visual_timer.wait_time = attack_visual_duration
	attack_visual.hide()
	if bow_visual != null:
		bow_visual.hide()
	if staff_visual != null:
		staff_visual.hide()
	dash_visual.hide()
	attack_visual_timer.timeout.connect(_on_attack_visual_timer_timeout)
	_update_attack_direction()
	_refresh_weapon_aura()
	_emit_current_state()


func _process(_delta: float) -> void:
	if weapon_aura.visible:
		weapon_aura.modulate.a = 0.7 + 0.25 * sin(Time.get_ticks_msec() * 0.005)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_update_dash_timers(delta)
	_update_mana(delta)
	if Input.is_action_just_pressed("dash"):
		try_dash()
	if Input.is_action_just_pressed("weapon_swap"):
		swap_weapon()
	if Input.is_action_just_pressed("special_ammo"):
		cycle_weapon_mode()
	if is_dashing:
		velocity = Vector2(dash_speed * facing_direction, 0.0)
		move_and_slide()
		return

	_update_jump_windows(delta)
	_apply_gravity(delta)

	var should_crouch := is_on_floor() and Input.is_action_pressed("ui_down")
	_set_crouching(should_crouch)

	var direction := Input.get_axis("ui_left", "ui_right")
	var current_speed := move_speed
	if is_crouching:
		current_speed *= crouch_speed_multiplier

	if not is_zero_approx(direction):
		velocity.x = move_toward(velocity.x, direction * current_speed, acceleration * delta)
		facing_direction = signf(direction)
		sprite.flip_h = facing_direction < 0.0
		_update_attack_direction()
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if Input.is_action_just_pressed("ui_accept") and not is_crouching:
		jump_buffer_remaining = jump_buffer_time
	if Input.is_action_just_released("ui_accept"):
		_cut_jump_short()
	_try_buffered_jump()
	if Input.is_action_just_pressed("attack"):
		try_attack()

	move_and_slide()


func _update_dash_timers(delta: float) -> void:
	dash_cooldown_remaining = maxf(dash_cooldown_remaining - delta, 0.0)
	if not is_dashing:
		return

	dash_time_remaining = maxf(dash_time_remaining - delta, 0.0)
	if is_zero_approx(dash_time_remaining):
		is_dashing = false
		dash_visual.hide()
		velocity.x = facing_direction * move_speed


func try_dash() -> bool:
	if is_dead or not dash_unlocked or is_dashing or dash_cooldown_remaining > 0.0:
		return false
	if is_crouching or Input.is_action_pressed("ui_down"):
		return false

	is_dashing = true
	dash_time_remaining = dash_duration
	dash_cooldown_remaining = get_effective_dash_cooldown()
	jump_buffer_remaining = 0.0
	velocity = Vector2(dash_speed * facing_direction, 0.0)
	dash_visual.scale.x = facing_direction
	dash_visual.show()
	return true


func get_effective_dash_cooldown() -> float:
	var game_state := _get_game_state()
	return dash_cooldown * 0.75 if game_state != null and game_state.get_equipped_defense_id() == "wind_cloak" else dash_cooldown


func _update_jump_windows(delta: float) -> void:
	if is_on_floor():
		jump_count = 0
		coyote_time_remaining = coyote_time
	else:
		coyote_time_remaining = maxf(coyote_time_remaining - delta, 0.0)

	jump_buffer_remaining = maxf(jump_buffer_remaining - delta, 0.0)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	var gravity_multiplier := fall_gravity_multiplier if velocity.y > 0.0 else 1.0
	velocity.y += gravity * gravity_multiplier * delta


func _try_buffered_jump() -> void:
	if jump_buffer_remaining <= 0.0:
		return
	if _try_jump():
		jump_buffer_remaining = 0.0


func _try_jump() -> bool:
	if is_on_floor() or (coyote_time_remaining > 0.0 and jump_count == 0):
		velocity.y = jump_force
		jump_count = 1
		coyote_time_remaining = 0.0
		return true
	elif double_jump_unlocked and jump_count < 2:
		velocity.y = jump_force
		jump_count = 2
		return true
	return false


func _cut_jump_short() -> void:
	if velocity.y < 0.0:
		velocity.y *= jump_release_multiplier


func _set_crouching(should_crouch: bool) -> void:
	if is_crouching == should_crouch:
		return

	is_crouching = should_crouch
	sprite.scale = standing_sprite_scale
	if is_crouching:
		sprite.scale.y *= crouch_sprite_height_multiplier


func _update_attack_direction() -> void:
	var game_state := _get_game_state()
	var weapon_range: float = attack_offset + 10.0
	if game_state != null:
		var definition: Dictionary = game_state.get_item_definition(game_state.get_active_weapon_id())
		if str(definition.get("weapon_class", "sword")) == "sword":
			weapon_range = float(definition.get("range", weapon_range))
	weapon_range += 16.0 if sword_reach_unlocked else 0.0
	attack_cast.position.x = (weapon_range * 0.5 + 7.0) * facing_direction
	var melee_shape := attack_cast.shape as RectangleShape2D
	if melee_shape != null:
		melee_shape.size.x = weapon_range
	attack_visual.scale.x = facing_direction * weapon_range / 34.0
	if bow_visual != null:
		bow_visual.position.x = 11.0 * facing_direction
		bow_visual.scale.x = facing_direction
	if staff_visual != null:
		staff_visual.position.x = 10.0 * facing_direction
		staff_visual.scale.x = facing_direction
	weapon_aura.position.x = 17.0 * facing_direction
	weapon_aura.scale.x = facing_direction


func try_attack() -> bool:
	if is_dead or not attack_cooldown_timer.is_stopped():
		return false
	var game_state := _get_game_state()
	var weapon_id := "worn_sword"
	var definition: Dictionary = {}
	if game_state != null:
		weapon_id = game_state.get_active_weapon_id()
		definition = game_state.get_item_definition(weapon_id)
	if str(definition.get("weapon_class", "sword")) == "bow":
		return _try_bow_attack(definition)
	if str(definition.get("weapon_class", "sword")) == "staff":
		return _try_staff_attack(definition)
	return _try_melee_attack(definition)


func _try_melee_attack(definition: Dictionary) -> bool:
	var game_state := _get_game_state()
	var weapon_id: String = game_state.get_active_weapon_id() if game_state != null else "worn_sword"
	var cooldown_multiplier: float = game_state.get_weapon_cooldown_multiplier(weapon_id) if game_state != null else 1.0
	var upgrade_bonus: int = game_state.get_weapon_damage_bonus(weapon_id) if game_state != null else 0
	var cooldown: float = float(definition.get("cooldown", attack_cooldown)) * cooldown_multiplier
	var damage: int = int(definition.get("damage", attack_damage)) + (1 if sword_mastery_unlocked else 0) + upgrade_bonus

	attack_cooldown_timer.start(cooldown)
	attack_visual.show()
	if bow_visual != null:
		bow_visual.hide()
	if staff_visual != null:
		staff_visual.hide()
	attack_visual_timer.start()
	attack_cast.force_shapecast_update()

	var hit_targets: Dictionary = {}
	for collision_index in range(attack_cast.get_collision_count()):
		var target := attack_cast.get_collider(collision_index) as Node
		if target == null or not is_instance_valid(target) or target.is_queued_for_deletion():
			continue
		if not target.is_in_group("enemy") and not target.is_in_group("breakable"):
			continue

		var target_id := target.get_instance_id()
		if hit_targets.has(target_id) or not target.has_method("take_damage"):
			continue

		hit_targets[target_id] = true
		var knockback := Vector2(
			attack_knockback.x * facing_direction,
			attack_knockback.y
		)
		var target_bonus: int = game_state.get_weapon_target_bonus(weapon_id, target) if game_state != null else 0
		target.take_damage(damage + target_bonus, knockback)

	return true


func _try_bow_attack(definition: Dictionary) -> bool:
	if arrow_scene == null or get_parent() == null:
		return false
	var game_state := _get_game_state()
	var weapon_id: String = game_state.get_active_weapon_id() if game_state != null else "hunter_bow"
	var upgrade_bonus: int = game_state.get_weapon_damage_bonus(weapon_id) if game_state != null else 0
	var cooldown_multiplier: float = game_state.get_weapon_cooldown_multiplier(weapon_id) if game_state != null else 1.0
	var arrow_type := "basic_arrow"
	if game_state != null:
		arrow_type = game_state.selected_arrow_type
		if arrow_type == "ember_arrow" and not game_state.remove_item("ember_arrow", 1):
			arrow_type = "basic_arrow"
			game_state.selected_arrow_type = "basic_arrow"
	var aim_direction := _get_bow_aim_direction()
	var arrow := arrow_scene.instantiate() as Area2D
	get_parent().add_child(arrow)
	arrow.global_position = global_position + aim_direction * 20.0 + Vector2(0.0, -3.0)
	arrow.setup(aim_direction, self, arrow_type, (1 if bow_mastery_unlocked else 0) + upgrade_bonus, 1 if bow_piercing_unlocked and arrow_type == "basic_arrow" else 0, weapon_id, int(definition.get("damage", 1)), float(definition.get("range", 520.0)))
	attack_cooldown_timer.start(float(definition.get("cooldown", 0.58)) * cooldown_multiplier)
	attack_visual.hide()
	if bow_visual != null:
		bow_visual.scale = Vector2.ONE
		bow_visual.rotation = aim_direction.angle()
		bow_visual.show()
	attack_visual_timer.start(0.16)
	weapon_changed.emit(weapon_id, game_state.selected_arrow_type if game_state != null else "basic_arrow")
	return true


func _try_staff_attack(definition: Dictionary) -> bool:
	if magic_projectile_scene == null or get_parent() == null:
		return false
	var game_state := _get_game_state()
	if game_state == null:
		return false
	var weapon_id: String = game_state.get_active_weapon_id()
	var upgrade_bonus: int = game_state.get_weapon_damage_bonus(weapon_id)
	var cooldown_multiplier: float = game_state.get_weapon_cooldown_multiplier(weapon_id)
	if game_state.unlocked_spells.is_empty():
		game_state.unlock_spell("arc_bolt")
	var spell_id: String = game_state.selected_spell
	var mana_cost := 2 if spell_id == "frost_orb" else 1
	if current_mana < mana_cost:
		combat_message.emit("NOT ENOUGH MANA")
		return false
	current_mana -= mana_cost
	mana_regen_delay_remaining = mana_regen_delay
	mana_regen_progress = 0.0
	mana_changed.emit(current_mana, max_mana)
	var cast_direction := _get_bow_aim_direction()
	var projectile := magic_projectile_scene.instantiate() as Area2D
	get_parent().add_child(projectile)
	projectile.global_position = global_position + cast_direction * 19.0 + Vector2(0.0, -4.0)
	projectile.setup(cast_direction, self, spell_id, (1 if staff_mastery_unlocked else 0) + upgrade_bonus, weapon_id, int(definition.get("damage", 2)), float(definition.get("range", 440.0)))
	attack_cooldown_timer.start(float(definition.get("cooldown", 0.72)) * cooldown_multiplier)
	attack_visual.hide()
	if bow_visual != null:
		bow_visual.hide()
	if staff_visual != null:
		staff_visual.scale = Vector2.ONE
		staff_visual.rotation = cast_direction.angle()
		staff_visual.show()
	attack_visual_timer.start(0.18)
	weapon_changed.emit(weapon_id, spell_id)
	return true


func _get_bow_aim_direction() -> Vector2:
	var vertical_aim := Input.get_axis("ui_up", "ui_down")
	if not is_zero_approx(vertical_aim):
		return Vector2(facing_direction, vertical_aim).normalized()
	return Vector2(facing_direction, 0.0)


func swap_weapon() -> bool:
	var game_state := _get_game_state()
	if game_state == null or not game_state.cycle_weapon():
		return false
	attack_visual.hide()
	if bow_visual != null:
		bow_visual.hide()
	if staff_visual != null:
		staff_visual.hide()
	return true


func toggle_arrow_type() -> bool:
	var game_state := _get_game_state()
	if game_state == null or str(game_state.get_item_definition(game_state.get_active_weapon_id()).get("weapon_class", "")) != "bow":
		return false
	game_state.toggle_arrow_type()
	return true


func cycle_weapon_mode() -> bool:
	var game_state := _get_game_state()
	if game_state == null:
		return false
	var weapon_class := str(game_state.get_item_definition(game_state.get_active_weapon_id()).get("weapon_class", "sword"))
	if weapon_class == "bow":
		return toggle_arrow_type()
	if weapon_class == "staff":
		if game_state.cycle_spell():
			return true
		combat_message.emit("FIND ANOTHER SPELL TO SWITCH")
	return false


func _on_attack_visual_timer_timeout() -> void:
	attack_visual.hide()
	if bow_visual != null:
		bow_visual.hide()
	if staff_visual != null:
		staff_visual.hide()


func _on_equipment_changed() -> void:
	var game_state := _get_game_state()
	if game_state == null:
		return
	_update_attack_direction()
	_refresh_weapon_aura()
	weapon_changed.emit(game_state.get_active_weapon_id(), game_state.selected_arrow_type)


func _refresh_weapon_aura() -> void:
	var game_state := _get_game_state()
	if game_state == null:
		weapon_aura.hide()
		return
	var weapon_id: String = game_state.get_active_weapon_id()
	var awakened: bool = game_state.get_weapon_upgrade_level(weapon_id) >= game_state.MAX_WEAPON_UPGRADE
	weapon_aura.visible = awakened
	var is_spiritglass := weapon_id == "spiritglass_blade"
	if is_spiritglass:
		attack_visual.color = Color(0.65, 1.2, 1.45, 1.0) if awakened else Color(0.35, 0.95, 1.0, 0.85)
	else:
		attack_visual.color = Color(1.0, 0.92, 0.55, 1.0) if awakened else Color(1.0, 0.78, 0.16, 0.82)
	if bow_visual != null:
		bow_visual.color = Color(0.7, 1.35, 0.75, 1.0) if awakened else Color(0.82, 0.58, 0.25, 1.0)
	if staff_visual != null:
		staff_visual.color = Color(1.25, 0.75, 1.6, 1.0) if awakened else Color(0.72, 0.42, 1.0, 1.0)
	if is_spiritglass:
		weapon_aura.color = Color(0.6, 1.35, 1.6, 0.9)
		weapon_aura_halo.color = Color(0.35, 0.9, 1.3, 0.18)
		return
	match str(game_state.get_item_definition(weapon_id).get("weapon_class", "sword")):
		"bow":
			weapon_aura.color = Color(0.55, 1.4, 0.7, 0.9)
			weapon_aura_halo.color = Color(0.35, 1.0, 0.55, 0.18)
		"staff":
			weapon_aura.color = Color(1.2, 0.7, 1.5, 0.9)
			weapon_aura_halo.color = Color(0.8, 0.35, 1.0, 0.18)
		_:
			weapon_aura.color = Color(1.5, 1.15, 0.4, 0.9)
			weapon_aura_halo.color = Color(1.2, 0.9, 0.35, 0.18)


func _update_mana(delta: float) -> void:
	if current_mana >= max_mana:
		mana_regen_progress = 0.0
		return
	if mana_regen_delay_remaining > 0.0:
		mana_regen_delay_remaining = maxf(mana_regen_delay_remaining - delta, 0.0)
		return
	var game_state := _get_game_state()
	var regen_multiplier := 1.5 if game_state != null and game_state.has_item("echo_charm") else 1.0
	if staff_flow_unlocked and game_state != null and str(game_state.get_item_definition(game_state.get_active_weapon_id()).get("weapon_class", "")) == "staff":
		regen_multiplier *= 1.5
	mana_regen_progress += mana_regen_rate * regen_multiplier * delta
	if mana_regen_progress < 1.0:
		return
	var restored := int(floor(mana_regen_progress))
	mana_regen_progress -= restored
	current_mana = mini(current_mana + restored, max_mana)
	mana_changed.emit(current_mana, max_mana)


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or is_invulnerable or amount <= 0:
		return

	var game_state := _get_game_state()
	if game_state != null and game_state.get_equipped_defense_id() == "guardian_band":
		amount = maxi(amount - 1, 1)
	current_health = maxi(current_health - amount, 0)
	if current_health <= 0 and second_breath_active:
		second_breath_active = false
		current_health = maxi(ceili(max_health * 0.2), 1)
		_persist_state()
		health_changed.emit(current_health, max_health)
		second_breath_changed.emit(false)
		second_breath_triggered.emit()
		is_invulnerable = true
		modulate.a = 0.5
		invulnerability_timer.start()
		return
	_persist_state()
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		die()
		return

	if not knockback.is_zero_approx():
		velocity = knockback

	is_invulnerable = true
	modulate.a = 0.5
	invulnerability_timer.start()


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	current_health = mini(current_health + amount, max_health)
	_persist_state()
	health_changed.emit(current_health, max_health)


func begin_safe_rest() -> void:
	if is_dead or is_safe_resting:
		return
	is_safe_resting = true
	rest_previous_invulnerability = is_invulnerable
	rest_previous_invulnerability_time = invulnerability_timer.time_left
	invulnerability_timer.stop()
	is_invulnerable = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	modulate.a = 0.78


func end_safe_rest() -> void:
	if not is_safe_resting:
		return
	is_safe_resting = false
	set_physics_process(true)
	if rest_previous_invulnerability and rest_previous_invulnerability_time > 0.0:
		is_invulnerable = true
		modulate.a = 0.5
		invulnerability_timer.start(rest_previous_invulnerability_time)
	else:
		is_invulnerable = false
		modulate.a = 1.0
	rest_previous_invulnerability = false
	rest_previous_invulnerability_time = 0.0


func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_dashing = false
	dash_visual.hide()
	velocity = Vector2.ZERO
	invulnerability_timer.stop()
	set_physics_process(false)
	player_collision.set_deferred("disabled", true)
	visible = false
	_persist_state()
	var game_state := _get_game_state()
	if game_state != null:
		game_state.handle_hardcore_death()
	died.emit()


func set_checkpoint(checkpoint_position: Vector2) -> void:
	respawn_position = checkpoint_position


func respawn() -> void:
	if not is_dead:
		return

	for projectile in get_tree().get_nodes_in_group("enemy_projectile"):
		projectile.queue_free()

	is_dead = false
	is_dashing = false
	dash_time_remaining = 0.0
	dash_cooldown_remaining = 0.0
	jump_count = 0
	jump_buffer_remaining = 0.0
	velocity = Vector2.ZERO
	global_position = respawn_position
	_set_crouching(false)
	attack_visual.hide()
	dash_visual.hide()
	current_health = max_health
	_persist_state()
	visible = true
	player_collision.set_deferred("disabled", false)
	set_physics_process(true)
	is_invulnerable = true
	modulate.a = 0.5
	invulnerability_timer.start()
	health_changed.emit(current_health, max_health)
	respawned.emit()


func activate_second_breath() -> bool:
	if is_dead or second_breath_active:
		return false

	second_breath_active = true
	_persist_state()
	second_breath_changed.emit(true)
	return true


func _on_invulnerability_timer_timeout() -> void:
	is_invulnerable = false
	modulate.a = 1.0


func add_xp(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	xp += amount
	while xp >= xp_per_level:
		xp -= xp_per_level
		skill_points += 1
	_persist_state()

	progression_changed.emit(xp, xp_per_level, skill_points)


func add_skill_points(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	skill_points += amount
	_persist_state()
	progression_changed.emit(xp, xp_per_level, skill_points)


func increase_max_health(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	max_health += amount
	current_health = max_health
	_persist_state()
	health_changed.emit(current_health, max_health)


func increase_max_mana(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	max_mana += amount
	current_mana = max_mana
	_persist_state()
	mana_changed.emit(current_mana, max_mana)


func can_unlock_double_jump() -> bool:
	return not double_jump_unlocked and skill_points >= double_jump_cost


func try_unlock_double_jump() -> bool:
	if not can_unlock_double_jump():
		return false

	skill_points -= double_jump_cost
	double_jump_unlocked = true
	_persist_state()
	progression_changed.emit(xp, xp_per_level, skill_points)
	double_jump_state_changed.emit(true)
	return true


func can_unlock_dash() -> bool:
	return not dash_unlocked and skill_points >= dash_cost


func try_unlock_dash() -> bool:
	if not can_unlock_dash():
		return false

	skill_points -= dash_cost
	dash_unlocked = true
	_persist_state()
	progression_changed.emit(xp, xp_per_level, skill_points)
	dash_state_changed.emit(true)
	return true


func can_unlock_weapon_mastery(weapon_class: String) -> bool:
	if skill_points < 1:
		return false
	match weapon_class:
		"sword":
			return not sword_mastery_unlocked
		"bow":
			var game_state := _get_game_state()
			return not bow_mastery_unlocked and game_state != null and game_state.has_weapon_class("bow")
		"staff":
			var game_state := _get_game_state()
			return not staff_mastery_unlocked and game_state != null and game_state.has_weapon_class("staff")
	return false


func try_unlock_weapon_mastery(weapon_class: String) -> bool:
	if not can_unlock_weapon_mastery(weapon_class):
		return false
	skill_points -= 1
	match weapon_class:
		"sword": sword_mastery_unlocked = true
		"bow": bow_mastery_unlocked = true
		"staff": staff_mastery_unlocked = true
	_persist_state()
	progression_changed.emit(xp, xp_per_level, skill_points)
	return true


func can_unlock_advanced_mastery(weapon_class: String) -> bool:
	if skill_points < 1:
		return false
	match weapon_class:
		"sword":
			return sword_mastery_unlocked and not sword_reach_unlocked
		"bow":
			return bow_mastery_unlocked and not bow_piercing_unlocked
		"staff":
			return staff_mastery_unlocked and not staff_flow_unlocked
	return false


func try_unlock_advanced_mastery(weapon_class: String) -> bool:
	if not can_unlock_advanced_mastery(weapon_class):
		return false
	skill_points -= 1
	match weapon_class:
		"sword":
			sword_reach_unlocked = true
			_update_attack_direction()
		"bow": bow_piercing_unlocked = true
		"staff": staff_flow_unlocked = true
	_persist_state()
	progression_changed.emit(xp, xp_per_level, skill_points)
	return true


func _emit_current_state() -> void:
	health_changed.emit(current_health, max_health)
	mana_changed.emit(current_mana, max_mana)
	second_breath_changed.emit(second_breath_active)
	progression_changed.emit(xp, xp_per_level, skill_points)
	double_jump_state_changed.emit(double_jump_unlocked)
	dash_state_changed.emit(dash_unlocked)
	_on_equipment_changed()


func _get_game_state() -> Node:
	return get_node_or_null("/root/GameState")


func _persist_state() -> void:
	var game_state := _get_game_state()
	if game_state != null:
		game_state.capture_player(self)
