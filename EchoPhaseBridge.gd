extends StaticBody2D

@export var solid_duration: float = 2.1
@export var warning_duration: float = 0.65
@export var ghost_duration: float = 1.1
@export var initial_offset: float = 0.0

var phase: String = "solid"
var phase_remaining: float = 1.0
var cycle_speed: float = 1.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var crystal: Polygon2D = $Crystal
@onready var edge: Line2D = $Edge


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.zone_tier_changed.connect(_on_zone_tier_changed)
		_on_zone_tier_changed("echo_grotto", game_state.get_zone_tier("echo_grotto"))
	phase_remaining = solid_duration + initial_offset
	_update_visuals()


func _process(delta: float) -> void:
	phase_remaining -= delta * cycle_speed
	if phase_remaining <= 0.0:
		_advance_phase()
	if phase == "warning":
		crystal.modulate.a = 0.45 + 0.38 * sin(Time.get_ticks_msec() * 0.027)


func _advance_phase() -> void:
	match phase:
		"solid":
			phase = "warning"
			phase_remaining = warning_duration
		"warning":
			phase = "ghost"
			phase_remaining = ghost_duration
			collision_shape.set_deferred("disabled", true)
		"ghost":
			phase = "solid"
			phase_remaining = solid_duration
			collision_shape.set_deferred("disabled", false)
	_update_visuals()


func _on_zone_tier_changed(zone_id: String, tier: int) -> void:
	if zone_id == "echo_grotto":
		cycle_speed = 1.25 if tier >= 1 else 1.0


func _update_visuals() -> void:
	match phase:
		"solid":
			crystal.color = Color(0.31, 0.82, 0.94, 0.95)
			edge.default_color = Color(0.78, 1.0, 1.0, 0.95)
			crystal.modulate.a = 1.0
		"warning":
			crystal.color = Color(0.83, 0.58, 0.94, 0.9)
			edge.default_color = Color(1.0, 0.74, 0.95, 0.95)
		"ghost":
			crystal.color = Color(0.24, 0.51, 0.68, 0.22)
			edge.default_color = Color(0.39, 0.73, 0.84, 0.28)
			crystal.modulate.a = 1.0
