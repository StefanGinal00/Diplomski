extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_main_story_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := game.get_node("UI")
	ui._toggle_quests()
	await _capture("story_opening_journal")
	for boss in ["void_sentinel", "abyss_warden", "echo_matriarch", "ash_castellan"]:
		state.defeated_bosses[boss] = true
	state.inventory["memory_sigil_echo"] = 1
	ui._on_quest_updated()
	await _capture("story_missing_memories")
	ui._close_side_panels()
	state.defeated_bosses.clear()
	ui._on_npc_interaction_requested(game.get_node("Caretaker"))
	await _capture("story_eldric_offer")
	ui._close_dialogue()
	ui._on_npc_interaction_requested(game.get_node("EchoHaven/LyraSurveyor"))
	await _capture("story_lyra_offer")
	ui._close_dialogue()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
