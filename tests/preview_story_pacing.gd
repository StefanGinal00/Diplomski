extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_story_pacing_preview.json"
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
	var cinema: Node = game.get_node("UI").story_player
	for id in ["guardian", "memories"]:
		cinema.play(id)
		cinema.page = 2
		cinema._show_page()
		cinema.advance()
		await _capture("story_pacing_" + id)
		cinema.cancel()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
