extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_room_depth_preview_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.get_node("UI").hide()
	game.get_node("Player/Camera2D").enabled = false
	game.get_node("Player").hide()
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for data in [["BlackwaterCistern", "shaft_cistern"], ["PrismArchive", "echo_archive"], ["CinderForge", "ash_forge"], ["StarfallMemoryVault", "starfall_memory_vault"], ["StarfallOutskirts", "starfall_outskirts"], ["StarfallSilentGate", "starfall_silent_gate"], ["StarfallRootedHall", "starfall_rooted_hall"], ["StarfallSoulCrucible", "starfall_soul_crucible"], ["StarfallSunlessPassage", "starfall_sunless_passage"]]:
		state.set_current_room(data[1])
		game.get_node("Background/BiomeBackdrop")._set_room(data[1], true)
		var room := game.get_node(data[0]) as Node2D
		room.show()
		var art := room.get_node("PaintedDepth")
		var route: Node = room.get_node("AshSwitchback") if data[0] == "CinderForge" else (room.get_node("LongTraversal") if data[0] == "PrismArchive" else room.get_node("ExpandedRoute"))
		var chamber: Rect2 = route._chamber_rect(2)
		var local_center := Vector2(chamber.get_center().x, chamber.end.y - 110)
		var center: Vector2 = route.to_global(local_center)
		for zoom in [1.0, 0.32]:
			root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(480, 270) - center * zoom)
			art._process(0.1)
			await _capture("room_depth_" + String(art.profile) + ("_close" if zoom == 1.0 else "_wide"))
		if data[0] == "BlackwaterCistern":
			root.canvas_transform = Transform2D(Vector2(1, 0), Vector2(0, 1), Vector2(480, 270) - center - Vector2(140, 70))
			art._process(0.1)
			await _capture("room_depth_cistern_shifted")
		room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
