extends Area2D

@export var idle_duration: float = 1.8
@export var warning_duration: float = 0.8
@export var active_duration: float = 0.65
@export var initial_offset: float = 0.0
@export var damage: int = 2
@export var knockback: Vector2 = Vector2(125.0, -210.0)
@export var disabled_by_shortcut_id: String = "ash_forge_fan"

var phase: String = "idle"
var phase_remaining: float = 1.8
var hit_players: Dictionary = {}
var disabled: bool = false

@onready var flame: Polygon2D = $Flame
@onready var warning_line: Line2D = $WarningLine


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.shortcut_changed.connect(_on_shortcut_changed)
		game_state.zone_tier_changed.connect(_on_zone_tier_changed)
		disabled = bool(game_state.unlocked_shortcuts.get(disabled_by_shortcut_id, false))
		_on_zone_tier_changed("ashen_bastion", game_state.get_zone_tier("ashen_bastion"))
	phase_remaining = idle_duration + initial_offset
	monitoring = false
	_update_visuals()


func _process(delta: float) -> void:
	if disabled:
		return
	phase_remaining -= delta
	if phase_remaining <= 0.0:
		_advance_phase()
	if phase == "warning":
		warning_line.modulate.a = 0.5 + 0.35 * sin(Time.get_ticks_msec() * 0.025)
	if phase == "active" and monitoring:
		for body in get_overlapping_bodies():
			if body is Player and not body.is_dead and not hit_players.has(body.get_instance_id()):
				hit_players[body.get_instance_id()] = true
				var push := -1.0 if body.global_position.x < global_position.x else 1.0
				body.take_damage(damage, Vector2(knockback.x * push, knockback.y))


func _advance_phase() -> void:
	match phase:
		"idle":
			phase = "warning"
			phase_remaining = warning_duration
		"warning":
			phase = "active"
			phase_remaining = active_duration
			hit_players.clear()
			set_deferred("monitoring", true)
		"active":
			phase = "idle"
			phase_remaining = idle_duration
			set_deferred("monitoring", false)
	_update_visuals()


func _on_shortcut_changed(event_id: String) -> void:
	if event_id != disabled_by_shortcut_id or disabled:
		return
	disabled = true
	phase = "disabled"
	hit_players.clear()
	set_deferred("monitoring", false)
	_update_visuals()


func _on_zone_tier_changed(zone_id: String, tier: int) -> void:
	if zone_id != "ashen_bastion":
		return
	idle_duration = 1.25 if tier >= 1 else 1.8
	warning_duration = 0.65 if tier >= 1 else 0.8
	active_duration = 0.75 if tier >= 1 else 0.65


func _update_visuals() -> void:
	if disabled:
		flame.color = Color(0.5, 0.23, 0.14, 0.08)
		warning_line.default_color = Color(0.62, 0.38, 0.24, 0.18)
		warning_line.modulate.a = 1.0
		return
	match phase:
		"idle":
			flame.color = Color(0.8, 0.24, 0.08, 0.1)
			warning_line.default_color = Color(0.95, 0.38, 0.18, 0.24)
			warning_line.modulate.a = 1.0
		"warning":
			flame.color = Color(1.0, 0.41, 0.12, 0.3)
			warning_line.default_color = Color(1.0, 0.72, 0.25, 0.9)
		"active":
			flame.color = Color(1.0, 0.6, 0.16, 0.78)
			warning_line.default_color = Color(1.0, 0.9, 0.43, 1.0)
			warning_line.modulate.a = 1.0
