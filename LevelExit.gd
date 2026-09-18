class_name LevelExit
extends Area2D

signal unlocked
signal level_completed

@export var locked_color: Color = Color(0.38, 0.42, 0.5, 1.0)
@export var unlocked_color: Color = Color(0.18, 0.95, 0.78, 1.0)
@export_range(0.1, 10.0, 0.1) var pulse_speed: float = 3.0

var is_unlocked: bool = false
var remaining_enemies: int = 0
var pulse_time: float = 0.0

@onready var frame: Polygon2D = $Frame
@onready var core: Polygon2D = $Core
@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_set_locked_visuals()
	call_deferred("_track_enemies")


func _process(delta: float) -> void:
	if not is_unlocked:
		return

	pulse_time += delta
	core.modulate.a = 0.55 + sin(pulse_time * pulse_speed) * 0.25


func _track_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	remaining_enemies = enemies.size()
	for enemy in enemies:
		var callback := Callable(self, "_on_enemy_defeated")
		if enemy.has_signal("defeated") and not enemy.is_connected("defeated", callback):
			enemy.connect("defeated", callback)

	if remaining_enemies == 0:
		unlock_exit()


func _on_enemy_defeated() -> void:
	remaining_enemies = maxi(remaining_enemies - 1, 0)
	if remaining_enemies == 0:
		unlock_exit()


func unlock_exit() -> void:
	if is_unlocked:
		return

	is_unlocked = true
	frame.color = unlocked_color
	core.color = Color(unlocked_color.r, unlocked_color.g, unlocked_color.b, 0.7)
	status_label.text = "EXIT"
	status_label.modulate = unlocked_color
	unlocked.emit()


func _set_locked_visuals() -> void:
	frame.color = locked_color
	core.color = Color(0.2, 0.08, 0.12, 0.75)
	core.modulate.a = 1.0
	status_label.text = "LOCKED"
	status_label.modulate = Color(1.0, 0.42, 0.38, 1.0)


func _on_body_entered(body: Node) -> void:
	if not is_unlocked or not body.is_in_group("player"):
		return

	monitoring = false
	level_completed.emit()
