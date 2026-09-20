extends Node

signal transition_started(target_room_id: String)
signal transition_finished(target_room_id: String)

var is_transitioning: bool = false
var overlay: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.01, 0.015, 0.04, 0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.hide()
	layer.add_child(overlay)


func transition_player(player: Player, target_position: Vector2, target_room_id: String) -> bool:
	if is_transitioning or player == null or player.is_dead:
		return false
	is_transitioning = true
	transition_started.emit(target_room_id)
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	overlay.show()
	var fade_out := create_tween()
	fade_out.tween_property(overlay, "color:a", 1.0, 0.18)
	await fade_out.finished

	player.global_position = target_position
	player.velocity = Vector2.ZERO
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.set_current_room(target_room_id)
	await get_tree().process_frame

	var fade_in := create_tween()
	fade_in.tween_property(overlay, "color:a", 0.0, 0.22)
	await fade_in.finished
	overlay.hide()
	player.set_physics_process(true)
	is_transitioning = false
	transition_finished.emit(target_room_id)
	return true
