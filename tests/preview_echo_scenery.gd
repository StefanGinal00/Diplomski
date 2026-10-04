extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_scenery_preview_save.json"
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
	for art in game.find_children("SceneryArt", "Node2D", true, false):
		if art.get_script() != preload("res://EchoSceneryArt.gd"):
			continue
		var route := art.get_parent() as Node2D
		var room: Node2D = route if art.theme == "depths" else route.get_parent()
		var id: String = "echo_depths" if art.theme == "depths" else String(route.RETURN_TARGETS[art.theme][0])
		state.set_current_room(id)
		await process_frame
		room.show()
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var rect: Rect2 = route._main_rect(2) if art.theme == "depths" else route._chamber_rect(2)
		var center := route.to_global(Vector2(rect.get_center().x, rect.end.y - 130))
		root.canvas_transform = Transform2D(Vector2(1.6, 0), Vector2(0, 1.6), Vector2(640, 360) - center * 1.6)
		game.get_node("Background/BiomeBackdrop")._set_room(id, true)
		for named in ["PaintedDepth", "RemainingArt", "VisualStyleSlice"]:
			if room.has_node(named):
				room.get_node(named)._process(0.1)
		await _capture("echo_scenery_" + art.theme)
		room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
