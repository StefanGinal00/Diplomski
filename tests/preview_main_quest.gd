extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_main_quest_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := game.get_node("UI")
	var quests := game.get_node("QuestManager")
	var player := game.get_node("Player")
	ui._toggle_quests()
	await _capture("main_quest_start")
	ui._close_side_panels()
	state.mark_boss_defeated("void_sentinel")
	ui._toggle_quests()
	await _capture("main_quest_first_bundle")
	ui.get_node("QuestPanel/MainRewardButton").pressed.emit()
	await _capture("main_quest_next_stage")
	ui._close_side_panels()
	for index in range(1, 8):
		for goal in preload("res://MainQuest.gd").STEPS[index].goals:
			match goal[0]:
				"boss": state.defeated_bosses[goal[1]] = true
				"item": state.inventory[goal[1]] = 1
				"event": state.unlocked_shortcuts[goal[1]] = true
				"room": state.discovered_rooms[goal[1]] = true
		if index < 7: quests.claim_main_reward(index, player)
	ui._toggle_quests()
	await _capture("main_quest_final_bundle")
	ui.get_node("QuestPanel/MainRewardButton").pressed.emit()
	await _capture("main_quest_complete")
	ui._close_side_panels()
	ui._show_final_ending()
	await _capture("main_quest_ending_hint")
	ui._close_final_ending()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
