extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_story_route_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := game.get_node("UI")
	var quests := game.get_node("QuestManager")
	for trace in quests.ECHO_TRACE_IDS: quests.echo_traces[trace] = true
	ui._on_npc_interaction_requested(get_first_node_in_group("surveyor_npc"))
	await _capture("story_route_early_survey")
	ui._close_dialogue()
	quests.hearth_fan_state = 3
	ui._on_npc_interaction_requested(get_first_node_in_group("hearth_quest_npc"))
	await _capture("story_route_marshal")
	ui._close_dialogue()
	quests.quest_index = 2
	quests.quest_state = 3
	state.defeated_bosses["hollow_sovereign"] = true
	ui._on_npc_interaction_requested(game.get_node("Caretaker"))
	await _capture("story_route_eldric_homecoming")
	ui._close_dialogue()
	state.defeated_bosses = {"void_sentinel": true, "abyss_warden": true, "echo_matriarch": true}
	state.inventory["barracks_insignia"] = 1
	ui._toggle_quests()
	await _capture("story_route_journal")
	ui._close_side_panels()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
