extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_quest_narrative_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := game.get_node("UI")
	var quests := game.get_node("QuestManager")
	quests.echo_survey_state = 2
	ui._on_npc_interaction_requested(get_first_node_in_group("surveyor_npc"))
	await _capture("mission_lyra_ready")
	ui._close_dialogue()
	quests.starfall_route_state = 3
	quests.starfall_courier_state = 0
	ui._on_npc_interaction_requested(get_first_node_in_group("starfall_route_npc"))
	await _capture("mission_rook_courier")
	ui._close_dialogue()
	state.defeated_bosses["hollow_sovereign"] = true
	quests.dawn_archive_state = 0
	ui._on_npc_interaction_requested(get_first_node_in_group("dawn_archive_npc"))
	await _capture("mission_atley_archive")
	ui._close_dialogue()
	quests.echo_survey_state = 3
	quests.hearth_fan_state = 1
	ui._toggle_quests()
	await _capture("mission_story_journal")
	ui.quest_tracker_label.get_parent().scroll_vertical = 420
	await _capture("mission_story_outcomes")
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
