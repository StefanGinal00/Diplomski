extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_machinery_preview_save.json"
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
	for data in [["TideWell", "echo_tide_well", 5, "pump"], ["UndertowVault", "echo_vault", 6, "vault_pump"], ["TideWell", "echo_tide_well", 3, "lower_active"], ["TideWell", "echo_tide_well", 9, "upper_active"], ["TideWell", "echo_tide_well", 3, "lower_calmed"]]:
		if data[3] == "lower_calmed":
			state.unlock_shortcut("echo_tide_field_station_0")
		state.set_current_room(data[1])
		await process_frame
		await process_frame
		var room: Node2D = game.get_node(data[0])
		room.show()
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var site: Node2D = room.get_node("LongTraversal/FieldDressing/Site%d" % data[2])
		root.canvas_transform = Transform2D(Vector2(2, 0), Vector2(0, 2), Vector2(640, 550) - site.global_position * 2)
		game.get_node("Background/BiomeBackdrop")._set_room(data[1], true)
		for named in ["PaintedDepth", "RemainingArt"]:
			if room.has_node(named):
				room.get_node(named)._process(0.1)
		await _capture("echo_machine_" + data[3])
		room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
