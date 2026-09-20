extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_lamp_travel_save.json"
	state.start_new_game("normal")
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var upper = game.get_node("VerticalChamber/UpperCheckpoint")
	var crossing = game.get_node("DrownedCrossing/CrossingLamp")
	var upper_position: Vector2 = upper.get_node("RespawnPoint").global_position
	var crossing_position: Vector2 = crossing.get_node("RespawnPoint").global_position
	var ui = game.get_node("UI")
	state.set_current_room("sunken_shaft")
	player.global_position = upper_position
	_check(upper._save_progress(player), "Upper Shaft lamp did not save")
	_check(state.get_discovered_lamps().size() == 1, "First lamp did not register")
	state.set_current_room("shaft_crossing")
	player.global_position = crossing_position
	_check(crossing._save_progress(player), "Crossing lamp did not save")
	_check(state.get_discovered_lamps().size() == 2 and state.checkpoint_lamp_id == "drowned_crossing_lamp", "Crossing lamp is not linked as a destination")
	_check(upper.is_active and crossing.is_active, "Resting at a second lamp deactivated the first")
	ui._open_world_map(true, crossing)
	ui.selected_lamp_id = "sunken_shaft_lamp"
	ui._update_map_details()
	_check(not ui.map_travel_button.disabled, "Upper Shaft is not selectable for travel from Crossing")
	ui._on_map_travel_pressed()
	await create_timer(0.5).timeout
	_check(state.current_room_id == "sunken_shaft" and state.checkpoint_lamp_id == "sunken_shaft_lamp", "Travel to Upper Shaft failed")
	_check(player.global_position.distance_to(upper_position) < 45.0, "Upper Shaft travel placed the player incorrectly")
	ui._open_world_map(true, upper)
	ui.selected_lamp_id = "drowned_crossing_lamp"
	ui._update_map_details()
	_check(not ui.map_travel_button.disabled, "Crossing is not selectable for return travel")
	ui._on_map_travel_pressed()
	await create_timer(0.5).timeout
	_check(state.current_room_id == "shaft_crossing" and state.checkpoint_lamp_id == "drowned_crossing_lamp", "Return travel to Crossing failed")
	_check(player.global_position.distance_to(crossing_position) < 45.0, "Crossing return travel placed the player incorrectly")
	_check(state.load_game(), "Lamp travel save did not reload")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	player = game.get_node("Player")
	upper = game.get_node("VerticalChamber/UpperCheckpoint")
	crossing = game.get_node("DrownedCrossing/CrossingLamp")
	ui = game.get_node("UI")
	_check(upper.is_active and crossing.is_active, "Previously discovered lamps did not relight after loading")
	_check(state.get_discovered_lamps().size() == 2 and state.checkpoint_lamp_id == "drowned_crossing_lamp", "Reload lost lamp links or respawn choice")
	player.global_position = upper.get_node("RespawnPoint").global_position
	upper._on_body_entered(player)
	var travel_event := InputEventAction.new()
	travel_event.action = "fast_travel"
	travel_event.pressed = true
	upper._unhandled_input(travel_event)
	_check(ui.world_map_panel.visible and ui.map_allows_travel, "A discovered non-current lamp cannot open fast travel after loading")
	ui._close_world_map()
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("LAMP TRAVEL TEST PASSED")
		quit(0)
	else:
		print("LAMP TRAVEL TEST FAILED: ", failures)
		quit(1)
