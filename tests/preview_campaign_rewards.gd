extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_campaign_rewards_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var campaign = preload("res://MainQuest.gd")
	for step in campaign.STEPS:
		for goal in step.goals:
			match goal[0]:
				"boss": state.defeated_bosses[goal[1]] = true
				"item": state.inventory[goal[1]] = 1
				"event": state.unlocked_shortcuts[goal[1]] = true
				"room": state.discovered_rooms[goal[1]] = true
	state.story_scenes_seen = {"opening": true, "ending": true}
	var ui := game.get_node("UI")
	var quests := game.get_node("QuestManager")
	for claimed in [0, 7, 8]:
		quests.main_quest_rewards.clear()
		for index in range(claimed): quests.main_quest_rewards[campaign.STEPS[index].id] = true
		ui._show_final_ending()
		await _capture("campaign_rewards_%d_pending" % (8 - claimed))
		ui._close_final_ending()
	quests.main_quest_rewards.erase("road_remains")
	ui._show_final_ending()
	ui.get_node("EndingPanel/RewardsButton").pressed.emit()
	await _capture("campaign_rewards_journal_handoff")
	ui._close_side_panels()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
