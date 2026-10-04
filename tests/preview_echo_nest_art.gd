extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_nest_art_preview_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.get_node("UI").hide()
	game.get_node("Player/Camera2D").enabled = false
	game.get_node("Player").hide()
	game.get_node("Player").set_physics_process(false)
	state.set_current_room("echo_nest")
	await process_frame
	await process_frame
	var room: Node2D = game.get_node("EchoNest")
	room.show()
	room.process_mode = Node.PROCESS_MODE_DISABLED
	for data in [[1, "west_occupied"], [5, "east_occupied"], [1, "west_cleared"], [5, "east_cleared"]]:
		if "cleared" in data[1]:
			state.unlock_shortcut("echo_nest_field_station_%d" % (0 if data[0] == 1 else 1))
		var site: Node2D = room.get_node("LongTraversal/FieldDressing/Site%d" % data[0])
		root.canvas_transform = Transform2D(Vector2(2, 0), Vector2(0, 2), Vector2(640, 550) - site.global_position * 2)
		game.get_node("Background/BiomeBackdrop")._set_room("echo_nest", true)
		for named in ["PaintedDepth", "RemainingArt"]:
			if room.has_node(named):
				room.get_node(named)._process(0.1)
		await _capture("echo_nest_" + data[1])
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
