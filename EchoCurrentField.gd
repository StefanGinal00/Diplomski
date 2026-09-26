extends Area2D

# A readable, non-lethal traversal current. It nudges the player toward its
# arrows but never overrides a dash or removes air control, so the basic route
# remains reversible without movement upgrades.
@export var flow_velocity: Vector2 = Vector2(72.0, -24.0)
@export_range(1.0, 400.0, 1.0) var acceleration: float = 105.0
@export var current_tint: Color = Color(0.3, 0.82, 0.94, 0.32)

var age: float = 0.0
var calmed := false

@onready var water: Polygon2D = $Water
@onready var stream_a: Line2D = $StreamA
@onready var stream_b: Line2D = $StreamB
@onready var direction_arrow: Polygon2D = $DirectionArrow


func _ready() -> void:
	water.color = Color(current_tint.r, current_tint.g, current_tint.b, 0.1)
	stream_a.default_color = current_tint
	stream_b.default_color = current_tint.lightened(0.2)
	direction_arrow.color = current_tint.lightened(0.34)
	direction_arrow.rotation = flow_velocity.angle()


func _process(delta: float) -> void:
	age += delta
	stream_a.position.x = fmod(age * 34.0, 44.0) - 22.0
	stream_b.position.x = fmod(age * 24.0 + 20.0, 44.0) - 22.0
	water.modulate.a = 0.72 + sin(age * 2.2) * 0.16


func _physics_process(delta: float) -> void:
	if calmed:
		return
	for body in get_overlapping_bodies():
		if not body is Player or body.is_dead or body.is_dashing or body.is_safe_resting:
			continue
		body.velocity.x = move_toward(body.velocity.x, flow_velocity.x, acceleration * delta)
		# Updrafts help a jump; downward currents remain deliberately mild.
		var vertical_acceleration := acceleration * (0.75 if flow_velocity.y < 0.0 else 0.35)
		body.velocity.y = move_toward(body.velocity.y, flow_velocity.y, vertical_acceleration * delta)


func set_calmed(value: bool) -> void:
	calmed = value
	modulate.a = 0.22 if calmed else 1.0
	direction_arrow.visible = not calmed
