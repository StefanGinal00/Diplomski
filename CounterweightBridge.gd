extends StaticBody2D

@export var shortcut_id: String = "shaft_approach_bridge"

var is_active: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var walkway: Polygon2D = $Walkway
@onready var rail: Line2D = $Rail
@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		is_active = bool(game_state.unlocked_shortcuts.get(shortcut_id, false))
		game_state.shortcut_changed.connect(_on_shortcut_changed)
	_update_visuals()


func _on_shortcut_changed(event_id: String) -> void:
	if event_id != shortcut_id:
		return
	is_active = true
	_update_visuals()


func _update_visuals() -> void:
	collision_shape.set_deferred("disabled", not is_active)
	walkway.color = Color(0.18, 0.5, 0.52, 1.0) if is_active else Color(0.11, 0.4, 0.46, 0.18)
	rail.default_color = Color(0.46, 0.87, 0.81, 0.9) if is_active else Color(0.28, 0.71, 0.74, 0.23)
	status_label.text = "BRIDGE LOWERED" if is_active else "BRIDGE RAISED  •  CLIMB ABOVE"
