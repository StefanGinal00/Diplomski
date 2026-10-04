extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_world_story_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := game.get_node("UI")
	state.defeated_bosses["echo_matriarch"] = true
	state.inventory["memory_sigil_shaft"] = 1
	ui._on_npc_interaction_requested(game.get_node("EchoHaven/Neris"))
	await _capture("world_story_neris")
	ui._close_dialogue()
	for key in ["memory_sigil_echo", "memory_sigil_ash"]: state.inventory[key] = 1
	ui._on_npc_interaction_requested(game.get_node("StarfallCitadel/Atley"))
	await _capture("world_story_atley")
	ui._close_dialogue()
	state.defeated_bosses["hollow_sovereign"] = true
	ui._on_npc_interaction_requested(game.get_node("EchoHaven/Vey"))
	await _capture("world_story_homecoming")
	ui._close_dialogue()
	ui._show_final_ending()
	await _capture("world_story_ending")
	ui.get_node("EndingPanel/StoryScroll").scroll_vertical = 1000
	await _capture("world_story_ending_last")
	ui._close_final_ending()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
