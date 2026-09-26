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
	state.save_path = "res://_tmp_memory_sigils_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	var player: Player = game.get_node("Player")
	var cistern: Node2D = game.get_node("BlackwaterCistern")
	var chapel: Node2D = game.get_node("AshChapel")
	var gate = game.get_node("StarfallSunlessPassage/HollowThroneDoor")
	state.set_current_room("shaft_cistern")
	var lamp = cistern.get_node("CisternLamp")
	player.global_position = lamp.get_node("RespawnPoint").global_position
	_check(lamp._save_progress(player), "Could not save before collecting Memory Sigils")
	state.unlock_shortcut("shaft_cistern_pump")
	state.unlock_shortcut("ash_chapel_bells")
	_check(cistern.get_node("MemoryReliquary").open(player) and chapel.get_node("MemoryReliquary").open(player), "Solved puzzles did not open Memory Sigil reliquaries")
	_check(state.has_item("memory_sigil_shaft") and state.has_item("memory_sigil_ash") and not gate._requirements_met(), "Memory Sigils ignored other final gate requirements")
	_check(state.load_game(), "Could not load the pre-sigil lamp snapshot")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	player = game.get_node("Player")
	cistern = game.get_node("BlackwaterCistern")
	chapel = game.get_node("AshChapel")
	_check(not state.has_item("memory_sigil_shaft") and not state.has_item("memory_sigil_ash"), "Unsaved Memory Sigils survived lamp rollback")
	_check(not cistern.get_node("MemoryReliquary").opened and not chapel.get_node("MemoryReliquary").opened, "Unsaved sigil reliquaries remained open")
	_check(not cistern.get_node("MemoryReliquary").open(player) and not chapel.get_node("MemoryReliquary").open(player), "Rolled-back puzzle gates remained open")
	state.unlock_shortcut("shaft_cistern_pump")
	state.unlock_shortcut("ash_chapel_bells")
	_check(cistern.get_node("MemoryReliquary").open(player) and chapel.get_node("MemoryReliquary").open(player), "Sigils could not be recovered after rollback")
	state.set_current_room("ash_chapel")
	lamp = chapel.get_node("ChapelLamp")
	player.global_position = lamp.get_node("RespawnPoint").global_position
	_check(lamp._save_progress(player) and state.load_game(), "Could not save and reload both Memory Sigils")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	_check(state.has_item("memory_sigil_shaft") and state.has_item("memory_sigil_ash"), "Saved Memory Sigils were lost")
	_check(game.get_node("BlackwaterCistern/MemoryReliquary").opened and game.get_node("AshChapel/MemoryReliquary").opened, "Saved sigil reliquaries reset")
	game.get_node("UI")._update_route_summary()
	_check("MEMORY SIGILS  2/3" in game.get_node("UI").map_route_label.text, "Map did not show collected Memory Sigils")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("MEMORY SIGILS TEST PASSED")
		quit(0)
	else:
		print("MEMORY SIGILS TEST FAILED: ", failures)
		quit(1)
