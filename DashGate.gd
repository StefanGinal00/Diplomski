extends Area2D

signal traversed

@export_range(10.0, 80.0, 1.0) var push_distance: float = 26.0
@export_range(50.0, 500.0, 10.0) var push_speed: float = 190.0
@export_range(0.5, 10.0, 0.5) var pulse_speed: float = 3.0

var pulse_time: float = 0.0
var has_been_traversed: bool = false

@onready var energy_field: Polygon2D = $EnergyField
@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	pulse_time += delta
	energy_field.modulate.a = 0.65 + sin(pulse_time * pulse_speed) * 0.2


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player") or not body is CharacterBody2D:
		return

	if body.get("is_dashing") == true:
		if not has_been_traversed:
			has_been_traversed = true
			status_label.text = "DASH CLEARED"
			traversed.emit()
		return

	var push_direction := -1.0 if body.global_position.x < global_position.x else 1.0
	body.global_position.x = global_position.x + push_direction * push_distance
	body.velocity.x = push_direction * push_speed
