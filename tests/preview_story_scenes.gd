extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_story_scenes_preview.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := game.get_node("UI")
	ui._start_new_mode("normal")
	ui.story_player._tick(2.3)
	await _capture("cinema_text_reveal")
	ui.story_player.advance()
	await _capture("cinema_opening")
	ui.story_player.advance()
	ui.story_player._tick(0.4)
	await _capture("cinema_crossfade")
	ui.story_player.advance()
	await _capture("cinema_eldric")
	ui.story_player.advance()
	ui.story_player.advance()
	await _capture("cinema_opening_third")
	ui.story_player.finish()
	for index in range(6):
		for goal in preload("res://MainQuest.gd").STEPS[index].goals:
			match goal[0]:
				"boss": state.defeated_bosses[goal[1]] = true
				"item": state.inventory[goal[1]] = 1
				"event": state.unlocked_shortcuts[goal[1]] = true
				"room": state.discovered_rooms[goal[1]] = true
	for id in ["haven", "memories"]:
		ui.story_player.play(id)
		ui.story_player.advance()
		await _capture("cinema_" + id)
		ui.story_player.advance()
		ui.story_player.advance()
		await _capture("cinema_" + id + "_second")
		ui.story_player.advance()
		ui.story_player.advance()
		await _capture("cinema_" + id + "_third")
		ui.story_player.finish()
	ui._toggle_quests()
	await _capture("cinema_journal_actions")
	ui.get_node("QuestPanel/StoryScenesButton").pressed.emit()
	await _capture("cinema_library")
	ui.story_player.finish()
	ui._close_side_panels()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
