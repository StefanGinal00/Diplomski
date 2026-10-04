extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_starfall_task_preview_save.json"
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
	for data in [["StarfallOutskirts", "starfall_outskirts"], ["StarfallSilentGate", "starfall_silent_gate"], ["StarfallRootedHall", "starfall_rooted_hall"], ["StarfallSunlessPassage", "starfall_sunless_passage"]]:
		state.set_current_room(data[1])
		await process_frame
		var room := game.get_node(data[0]) as Node2D
		room.process_mode = Node.PROCESS_MODE_DISABLED
		room.show()
		game.get_node("Background/BiomeBackdrop")._set_room(data[1], true)
		var ops := room.get_node("ExpandedRoute/StarfallDescent/FieldOperations")
		var station: Node2D = ops.controls[0]
		var register := room.get_node("ExpandedRoute/FieldDressing/Site1") as Node2D
		for complete in [false, true]:
			if complete:
				# Staged state preview only; activation semantics have separate tests.
				for event_id in station.required_event_ids:
					state.unlock_shortcut(event_id)
				state.unlock_shortcut(station.shortcut_id)
				await process_frame
			var zoom := 2.0
			root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(640, 400) - station.global_position * zoom)
			room.get_node("PaintedDepth")._process(0.1)
			await _capture("task_%s_%s" % [data[1], "done" if complete else "initial"])
			if data[0] == "StarfallOutskirts":
				zoom = 1.2
				root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(640, 430) - register.global_position * zoom)
				await _capture("task_register_%s" % ("partial" if complete else "initial"))
		room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
