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
	state.save_path = "res://_tmp_starfall_courier_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player: Player = game.get_node("Player")
	var quest = game.get_node("QuestManager")
	var ui = game.get_node("UI")
	var rook = game.get_node("StarfallCitadel/Rook")
	quest.starfall_route_state = 3
	state.set_current_room("starfall_citadel")
	rook.interaction_requested.emit(rook)
	_check(ui.dialogue_primary_button.visible and "Whisperlight" in ui.dialogue_text.text, "Rook does not offer the follow-up courier route")
	ui._on_dialogue_primary_pressed()
	_check(int(quest.starfall_courier_state) == 1 and "Courier Circuit 0/2" in ui.quest_tracker_label.text and "TOWN LAMPS 0/2" in ui.objective_label.text, "Courier quest did not start with visible objectives")
	ui._close_dialogue()
	var city_lamp = game.get_node("StarfallCitadel/GateDistrict/GateLamp")
	player.global_position = city_lamp.get_node("RespawnPoint").global_position
	_check(city_lamp._save_progress(player), "Accepted courier route could not be saved")
	state.set_current_room("echo_haven")
	var echo_lamp = game.get_node("EchoHaven/HavenLamp")
	player.global_position = echo_lamp.get_node("RespawnPoint").global_position
	_check(echo_lamp._save_progress(player), "Echo courier stop could not be saved")
	_check(quest.get_starfall_courier_progress() == 1 and int(state.quest_state.get("starfall_courier_state", -1)) == 1, "Echo stop was not included in the same lamp snapshot")
	_check(echo_lamp._save_progress(player) and quest.get_starfall_courier_progress() == 1, "The same courier stop counted twice")
	state.checkpoint_resting.emit("ash_hearth_lamp")
	_check(int(quest.starfall_courier_state) == 2, "Second courier stop did not make the quest ready")
	_check(state.load_game(), "Echo courier save could not be reloaded")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.get_node("Player")
	quest = game.get_node("QuestManager")
	ui = game.get_node("UI")
	rook = game.get_node("StarfallCitadel/Rook")
	_check(int(quest.starfall_courier_state) == 1 and quest.get_starfall_courier_progress() == 1, "Unsaved courier stop did not roll back")
	state.set_current_room("ash_hearth")
	var ash_lamp = game.get_node("CinderHearth/HearthLamp")
	player.global_position = ash_lamp.get_node("RespawnPoint").global_position
	_check(ash_lamp._save_progress(player), "Ash courier stop could not be saved")
	_check(int(state.quest_state.get("starfall_courier_state", -1)) == 2 and quest.get_starfall_courier_progress() == 2, "Completed circuit was not captured by the Ash lamp")
	state.set_current_room("starfall_citadel")
	rook.interaction_requested.emit(rook)
	_check(ui.dialogue_primary_button.visible and "both towns" in ui.dialogue_text.text.to_lower(), "Rook does not offer the courier reward")
	var gold_before: int = state.gold
	var shard_before: int = int(state.inventory.get("resonance_shard", 0))
	ui._on_dialogue_primary_pressed()
	_check(int(quest.starfall_courier_state) == 3 and state.gold == gold_before + 75 and int(state.inventory.get("resonance_shard", 0)) == shard_before + 1, "Courier reward was not paid correctly")
	ui._on_dialogue_primary_pressed()
	_check(state.gold == gold_before + 75, "Courier reward was paid twice")
	ui._close_dialogue()
	city_lamp = game.get_node("StarfallCitadel/GateDistrict/GateLamp")
	player.global_position = city_lamp.get_node("RespawnPoint").global_position
	_check(city_lamp._save_progress(player), "Courier reward could not be saved")
	_check(state.load_game() and int(state.quest_state.get("starfall_courier_state", -1)) == 3 and state.gold == gold_before + 75, "Saved courier completion was lost")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("STARFALL COURIER TEST PASSED")
		quit(0)
	else:
		print("STARFALL COURIER TEST FAILED: ", failures)
		quit(1)
