extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _advance_memory(ui: Node) -> void:
	if ui.memory_reveal_tween != null and ui.memory_reveal_tween.is_valid():
		ui.memory_reveal_tween.kill()
	ui._finish_memory_reveal()


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_memory_revelation_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	var player: Player = game.get_node("Player")
	var ui = game.get_node("UI")
	var cistern_cache = game.get_node("BlackwaterCistern/MemoryReliquary")
	var chapel_cache = game.get_node("AshChapel/MemoryReliquary")
	var archive = game.get_node("PrismArchive")
	_check(not ui.memory_toast_panel.visible and not cistern_cache.core.visible and cistern_cache.rune_halo.visible, "Sealed Shaft reliquary did not show its dormant memory halo")
	state.unlock_shortcut("shaft_cistern_pump")
	state.unlock_shortcut("ash_chapel_bells")
	_check(cistern_cache.core.color != chapel_cache.core.color and cistern_cache.rune_halo.visible and chapel_cache.rune_halo.visible, "Shaft and Ash memories are not visually distinct")
	_check(cistern_cache.open(player), "Shaft memory could not be collected")
	_check(ui.memory_toast_panel.visible and "DROWNED" in ui.memory_title_label.text and "BLACKWATER CISTERN" in ui.memory_status_label.text and not paused, "Shaft memory did not show a non-blocking discovery")
	_check("bell" in str(state.get_item_definition("memory_sigil_shaft")["description"]), "Shaft memory has no persistent inventory story")
	_check(chapel_cache.open(player) and ui.memory_reveal_queue.size() == 1, "A second memory did not queue behind the first")
	_advance_memory(ui)
	_check("CINDERED" in ui.memory_title_label.text and "ASHEN CHAPEL" in ui.memory_status_label.text, "Ash memory did not appear after the Shaft memory")
	for mirror_id in ["root", "star", "echo"]:
		archive.activate_mirror(mirror_id)
	_check(state.has_item("memory_sigil_echo") and ui.memory_reveal_queue.size() == 2, "Echo memory or three-memory synthesis was not queued")
	_advance_memory(ui)
	_check("ECHOING" in ui.memory_title_label.text and "PRISM ARCHIVE" in ui.memory_status_label.text, "Echo memory did not appear")
	_advance_memory(ui)
	_check("THREE MEMORIES" in ui.memory_title_label.text and "GUARDIANS" in ui.memory_status_label.text, "Completed memories did not point toward the final gate")
	_advance_memory(ui)
	_check(not ui.memory_toast_panel.visible and ui.memory_reveal_queue.is_empty() and not paused, "Memory sequence did not clear without interrupting play")
	state.set_current_room("shaft_cistern")
	var lamp = game.get_node("BlackwaterCistern/CisternLamp")
	player.global_position = lamp.get_node("RespawnPoint").global_position
	_check(lamp._save_progress(player) and state.load_game(), "Collected memories could not be saved and reloaded")
	game.queue_free()
	await process_frame
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	_check(game.get_node("UI").memory_reveal_queue.is_empty() and not game.get_node("UI").memory_toast_panel.visible and state.has_item("memory_sigil_ash"), "Saved memories replayed their discovery cards on reload")
	state.delete_save()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if failures.is_empty():
		print("MEMORY REVELATION TEST PASSED")
		quit(0)
	else:
		print("MEMORY REVELATION TEST FAILED: ", failures)
		quit(1)
