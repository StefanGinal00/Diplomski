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
	state.save_path = "res://_tmp_world_timeline_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var ui = game.get_node("UI")
	var quest = game.get_node("QuestManager")
	var advances: Array[int] = []
	state.timeline_advanced.connect(func(stage: int, _room_id: String) -> void: advances.append(stage))
	_check(state.timeline_stage == 0, "A new journey did not begin in the prologue")
	state.set_current_room("shaft_hollow")
	_check(state.timeline_stage == 1 and advances == [1], "Entering the Shaft did not advance the world once")
	state.set_current_room("sunken_shaft")
	_check(advances == [1], "Changing rooms inside the Shaft advanced the world again")
	state.set_current_room("echo_grotto")
	_check(state.timeline_stage == 2 and advances == [1, 2], "Echo entry did not advance the world")
	var neris = game.get_node("EchoHaven/Neris")
	_check("crystals hum" in neris.get_next_line(), "Echo resident changed dialogue too early")
	state.set_current_room("echo_haven")
	state.set_current_room("ash_causeway")
	_check(state.timeline_stage == 3 and advances == [1, 2, 3], "Ash entry did not advance the world")
	_check("Ashen Bastion" in neris.get_next_line(), "Echo resident did not react to the Ash chapter")
	var dara = game.get_node("CinderHearth/Dara")
	_check("hearth alive" in dara.get_next_line(), "Ash resident changed dialogue before Starfall")
	state.set_current_room("ash_hearth")
	var ash_lamp = game.get_node("CinderHearth/HearthLamp")
	player.global_position = ash_lamp.get_node("RespawnPoint").global_position
	_check(ash_lamp._save_progress(player), "Ash stage could not be saved at its lamp")
	state.set_current_room("starfall_citadel")
	_check(state.timeline_stage == 4 and advances == [1, 2, 3, 4], "Starfall entry did not advance the world")
	_check("Starfall" in dara.get_next_line(), "Ash resident did not react to Starfall")
	_check("NEW CHAPTER" in ui.zone_subtitle_label.text and ui.zone_title_label.text == "STARFALL CITADEL", "First Starfall visit has no chapter announcement")
	ui._update_route_summary()
	_check("WORLD CHAPTER  4/4" in ui.map_route_label.text, "Map does not display the current story chapter")
	state.set_current_room("echo_haven")
	state.set_current_room("starfall_citadel")
	_check(state.timeline_stage == 4 and advances.size() == 4, "Backtracking advanced the world again")
	_check(state.load_game() and state.timeline_stage == 3 and state.current_room_id == "ash_hearth", "Normal-mode load did not restore the saved chapter")
	_check(advances.size() == 4 and "hearth alive" in dara.get_next_line(), "Loading a previous chapter emitted an advance or kept future dialogue")
	state.set_current_room("starfall_citadel")
	var city_lamp = game.get_node("StarfallCitadel/GateDistrict/GateLamp")
	player.global_position = city_lamp.get_node("RespawnPoint").global_position
	_check(city_lamp._save_progress(player), "Starfall stage could not be saved at its lamp")
	state.set_current_room("hollow_throne")
	_check(state.timeline_stage == 4 and advances.size() == 5, "A Starfall final district advanced the world into a fifth zone")
	_check(state.load_game() and state.timeline_stage == 4 and state.current_room_id == "starfall_citadel", "Starfall lamp did not restore the final-zone chapter")
	var old_save: Dictionary = state._build_save_data().duplicate(true)
	old_save.erase("timeline_stage")
	old_save["current_room_id"] = "ash_hearth"
	old_save["discovered_rooms"] = {"training_passage": true, "echo_grotto": true, "ash_hearth": true}
	old_save["discovered_lamps"] = {}
	state._apply_save_data(old_save)
	_check(state.timeline_stage == 3, "Legacy save did not infer the reached Ash chapter")
	old_save["current_room_id"] = "starfall_ward"
	old_save["discovered_rooms"] = {"training_passage": true, "starfall_ward": true}
	state._apply_save_data(old_save)
	_check(state.timeline_stage == 4 and state.current_room_id == "starfall_citadel", "Legacy city save did not migrate its chapter")
	old_save["timeline_stage"] = 5
	old_save["current_room_id"] = "hollow_throne"
	old_save["discovered_rooms"] = {"training_passage": true, "hollow_throne": true}
	state._apply_save_data(old_save)
	_check(state.timeline_stage == 4, "The provisional fifth chapter was not merged into the final fourth zone")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("WORLD TIMELINE TEST PASSED")
		quit(0)
	else:
		print("WORLD TIMELINE TEST FAILED: ", failures)
		quit(1)
