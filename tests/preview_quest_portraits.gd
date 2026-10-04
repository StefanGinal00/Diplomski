extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_quest_portraits_preview_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var ui := game.get_node("UI")
	var hero := game.get_node("Player")
	var quests := game.get_node("QuestManager")
	hero.get_node("Camera2D").enabled = false
	for npc_data in [["Caretaker", "training_passage", "eldric"], ["EchoHaven/LyraSurveyor", "echo_haven", "lyra"]]:
		state.set_current_room(npc_data[1])
		var npc := game.get_node(npc_data[0]) as Node2D
		hero.global_position = npc.global_position + Vector2(-35, -1)
		root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(480, 230) - npc.global_position * 2.5)
		if npc_data[2] == "eldric":
			quests.quest_index = 2
			quests.quest_state = 0
		else:
			quests.echo_survey_state = 2
			for trace_id in quests.ECHO_TRACE_IDS:
				quests.echo_traces[trace_id] = true
		ui._on_npc_interaction_requested(npc)
		if ui.zone_title_tween != null and ui.zone_title_tween.is_valid():
			ui.zone_title_tween.kill()
		ui.zone_title_panel.hide()
		await _capture(npc_data[2] + "_quest")
		ui._close_dialogue()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
