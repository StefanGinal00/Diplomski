extends Area2D

# Reusable, strongly telegraphed hazards for the expanded Sunken Shaft rooms.
# Each mode deliberately gives the player a safe reaction window and only one
# hit per active pulse. Currents never deal damage; they alter footing instead.
@export_enum("rockfall", "pressure", "current") var hazard_kind: String = "rockfall"
@export var idle_duration: float = 2.0
@export var warning_duration: float = 1.1
@export var active_duration: float = 0.55
@export var initial_offset: float = 0.0
@export var damage: int = 1
@export var force: Vector2 = Vector2(0.0, -185.0)
@export var current_speed: float = 92.0
@export var disabled_by_shortcut_id: String = ""

var phase: String = "idle"
var phase_remaining: float = 2.0
var disabled := false
var hit_players: Dictionary = {}

@onready var hazard_fill: Polygon2D = $HazardFill
@onready var warning_line: Line2D = $WarningLine
@onready var direction_marks: Line2D = $DirectionMarks


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.shortcut_changed.connect(_on_shortcut_changed)
		disabled = not disabled_by_shortcut_id.is_empty() and bool(game_state.unlocked_shortcuts.get(disabled_by_shortcut_id, false))
	phase_remaining = idle_duration + initial_offset
	monitoring = hazard_kind == "current" and not disabled
	_update_visuals()


func _physics_process(delta: float) -> void:
	if disabled:
		return
	if hazard_kind == "current":
		warning_line.modulate.a = 0.5 + 0.22 * sin(Time.get_ticks_msec() * 0.006 + initial_offset)
		for body in get_overlapping_bodies():
			if body is Player and not body.is_dead and not body.is_dashing and not body.is_safe_resting:
				# A collision-aware displacement remains perceptible even though the
				# Player controller recalculates horizontal velocity every frame.
				var direction := signf(force.x)
				body.move_and_collide(Vector2(direction * current_speed * delta, 0.0))
				body.velocity.x = move_toward(body.velocity.x, force.x, current_speed * delta * 8.0)
		return
	phase_remaining -= delta
	if phase_remaining <= 0.0:
		_advance_phase()
	if phase == "warning":
		warning_line.modulate.a = 0.46 + 0.42 * sin(Time.get_ticks_msec() * 0.027)
	elif phase == "active" and monitoring:
		for body in get_overlapping_bodies():
			if body is Player and not body.is_dead and not hit_players.has(body.get_instance_id()):
				hit_players[body.get_instance_id()] = true
				body.take_damage(damage, force)


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


func _update_visuals() -> void:
	direction_marks.visible = hazard_kind == "current"
	if disabled:
		hazard_fill.color = Color(0.12, 0.24, 0.27, 0.06)
		warning_line.default_color = Color(0.31, 0.55, 0.58, 0.18)
		warning_line.modulate.a = 1.0
		return
	if hazard_kind == "current":
		hazard_fill.color = Color(0.08, 0.46, 0.64, 0.22)
		warning_line.default_color = Color(0.48, 0.91, 1.0, 0.62)
		direction_marks.default_color = Color(0.71, 0.97, 1.0, 0.8)
		if force.x < 0.0:
			direction_marks.scale.x = -1.0
		return
	var base := Color(0.74, 0.36, 0.18) if hazard_kind == "rockfall" else Color(0.38, 0.84, 0.91)
	match phase:
		"idle":
			hazard_fill.color = Color(base.r, base.g, base.b, 0.06)
			warning_line.default_color = Color(base.r, base.g, base.b, 0.2)
			warning_line.modulate.a = 1.0
		"warning":
			hazard_fill.color = Color(base.r, base.g, base.b, 0.18)
			warning_line.default_color = Color(base.lightened(0.32), 0.95)
		"active":
			hazard_fill.color = Color(base.lightened(0.2), 0.72)
			warning_line.default_color = Color(base.lightened(0.48), 1.0)
			warning_line.modulate.a = 1.0
