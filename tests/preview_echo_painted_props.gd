extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_painted_props_preview_save.json"
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
	for data in [["EchoNest", "echo_nest", 2, "cart"], ["PrismArchive", "echo_archive", 2, "shelf"], ["TideWell", "echo_tide_well", 2, "fern"], ["EchoDepths", "echo_depths", 6, "depths"], ["EchoGrotto", "echo_grotto", 0, "camp_grotto"], ["TideWell", "echo_tide_well", 0, "camp_tide"], ["EchoNest", "echo_nest", 0, "camp_nest"], ["PrismArchive", "echo_archive", 4, "book_cart"], ["PrismArchive", "echo_archive", 0, "reading_desk"], ["EchoDepths", "echo_depths", 0, "field_desk"], ["PrismArchive", "echo_archive", 7, "unindexed_shelf"]]:
		state.set_current_room(data[1])
		await process_frame
		var room := game.get_node(data[0]) as Node2D
		room.show()
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var dressing := room.get_node("FieldDressing" if data[0] == "EchoDepths" else "LongTraversal/FieldDressing")
		var site := dressing.get_node("Site%d" % data[2]) as Node2D
		root.canvas_transform = Transform2D(Vector2(2, 0), Vector2(0, 2), Vector2(640, 560) - site.global_position * 2)
		if data[0] == "PrismArchive":
			var camera_offset: float = {0: -110.0, 2: 150.0, 4: 160.0}.get(data[2], 0.0)
			root.canvas_transform.origin.x -= camera_offset * 2
		game.get_node("Background/BiomeBackdrop")._set_room(data[1], true)
		for named in ["PaintedDepth", "RemainingArt"]:
			if room.has_node(named):
				room.get_node(named)._process(0.1)
		await _capture("echo_painted_" + data[3])
		room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
