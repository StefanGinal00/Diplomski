extends StaticBody2D

const ANCHOR_ID := "starfall_sunless_anchor"

@export var solid_duration: float = 2.5
@export var warning_duration: float = 0.7
@export var ghost_duration: float = 1.0
@export var initial_offset: float = 0.0

var phase: String = "solid"
var phase_remaining: float = 2.5
var cycle_speed: float = 1.0
var stabilized: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var span: Polygon2D = $Span
@onready var edge: Line2D = $Edge


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.shortcut_changed.connect(_on_shortcut_changed)
		game_state.zone_tier_changed.connect(_on_zone_tier_changed)
		_on_zone_tier_changed("starfall_reach", game_state.get_zone_tier("starfall_reach"))
		stabilized = bool(game_state.unlocked_shortcuts.get(ANCHOR_ID, false))
	phase = "stable" if stabilized else "solid"
	phase_remaining = solid_duration + initial_offset
	_update_visuals()


func _process(delta: float) -> void:
	if stabilized:
		return
	phase_remaining -= delta * cycle_speed
	if phase_remaining <= 0.0:
		_advance_phase()
	if phase == "warning":
		span.modulate.a = 0.45 + 0.35 * sin(Time.get_ticks_msec() * 0.027)


func _advance_phase() -> void:
	if stabilized:
		return
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


func _on_shortcut_changed(event_id: String) -> void:
	if event_id != ANCHOR_ID or stabilized:
		return
	stabilized = true
	phase = "stable"
	collision_shape.set_deferred("disabled", false)
	_update_visuals()


func _on_zone_tier_changed(zone_id: String, tier: int) -> void:
	if zone_id == "starfall_reach":
		cycle_speed = 1.2 if tier >= 1 else 1.0


func _update_visuals() -> void:
	match phase:
		"stable":
			span.color = Color(0.49, 0.96, 0.78, 0.96)
			edge.default_color = Color(0.8, 1.0, 0.91, 1.0)
			span.modulate.a = 1.0
		"solid":
			span.color = Color(0.55, 0.64, 0.92, 0.94)
			edge.default_color = Color(0.83, 0.87, 1.0, 0.96)
			span.modulate.a = 1.0
		"warning":
			span.color = Color(0.94, 0.69, 0.97, 0.91)
			edge.default_color = Color(1.0, 0.77, 0.96, 0.96)
		"ghost":
			span.color = Color(0.36, 0.4, 0.69, 0.19)
			edge.default_color = Color(0.49, 0.55, 0.81, 0.24)
			span.modulate.a = 1.0
