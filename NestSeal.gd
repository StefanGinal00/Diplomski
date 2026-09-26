extends StaticBody2D

signal opened

@export var completion_event: String = "echo_nest_cleared"

var is_open: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var veil: Polygon2D = $Veil
@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	call_deferred("_restore_or_watch")


func _restore_or_watch() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and bool(game_state.unlocked_shortcuts.get(completion_event, false)):
		_open(false)
		return
	var traversal := get_parent().get_node_or_null("LongTraversal")
	if traversal != null and traversal.has_method("is_population_loaded") and not bool(traversal.call("is_population_loaded")):
		status_label.text = "BROOD DORMANT"
		return
	refresh_brood_watch()


func refresh_brood_watch() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and bool(game_state.unlocked_shortcuts.get(completion_event, false)):
		_open(false)
		return
	for brood in get_tree().get_nodes_in_group("nest_brood"):
		if not get_parent().is_ancestor_of(brood):
			continue
		var callback := Callable(self, "_on_brood_defeated")
		if brood.has_signal("defeated") and not brood.is_connected("defeated", callback):
			brood.connect("defeated", callback)
	_on_brood_defeated()


func _on_brood_defeated() -> void:
	if is_open:
		return
	var remaining := 0
	for brood in get_tree().get_nodes_in_group("nest_brood"):
		if is_instance_valid(brood) and get_parent().is_ancestor_of(brood) and not bool(brood.get("is_dead")):
			remaining += 1
	if remaining == 0:
		_open(true)
	else:
		status_label.text = "BROOD REMAINING %d" % remaining


func _open(record_progress: bool) -> void:
	if is_open:
		return
	is_open = true
	if record_progress:
		var game_state := get_node_or_null("/root/GameState")
		if game_state != null:
			game_state.unlock_shortcut(completion_event)
	collision_shape.set_deferred("disabled", true)
	veil.color = Color(0.2, 0.82, 0.73, 0.16)
	status_label.text = "NEST CLEARED"
	opened.emit()
