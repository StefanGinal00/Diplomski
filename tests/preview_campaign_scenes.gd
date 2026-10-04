extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_campaign_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for step in preload("res://MainQuest.gd").STEPS:
		for goal in step.goals:
			match goal[0]:
				"boss": state.defeated_bosses[goal[1]] = true
				"item": state.inventory[goal[1]] = 1
				"event": state.unlocked_shortcuts[goal[1]] = true
				"room": state.discovered_rooms[goal[1]] = true
	state.defeated_bosses["starfall_guardian"] = true
	var ui := game.get_node("UI")
	var cinema: Node = ui.story_player
	for id in ["sentinel", "echo", "marshal", "fortress", "castellan", "guardian", "ending"]:
		cinema.play(id)
		for index in range(preload("res://StoryScenes.gd").SCENES[id].pages.size()):
			cinema.advance()
			await _capture("campaign_%s_%d" % [id, index + 1])
			cinema.advance()
	cinema.open_library()
	await _capture("campaign_library_top")
	cinema.replay_list.get_child(9).grab_focus()
	await _capture("campaign_library_bottom")
	cinema.finish()
	ui._show_final_ending()
	await _capture("campaign_epilogue_return")
	ui._close_final_ending()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
