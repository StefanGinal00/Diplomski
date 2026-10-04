extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_starfall_arena_preview_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.get_node("UI").hide()
	var player := game.get_node("Player")
	player.get_node("Camera2D").enabled = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for data in [["StarfallEmptyCourt", "starfall_empty_court"], ["StarfallHollowThrone", "starfall_hollow_throne"]]:
		state.set_current_room(data[1])
		game.get_node("Background/BiomeBackdrop")._set_room(data[1], true)
		var room := game.get_node(data[0]) as Node2D
		room.show()
		var art := room.get_node("ArenaArt")
		var center := Vector2(960, 235) if data[0] == "StarfallEmptyCourt" else Vector2(1150, 265)
		player.global_position = room.to_global(Vector2(center.x - 270, 370 if data[0] == "StarfallEmptyCourt" else 410))
		for zoom in [1.0, 0.5]:
			root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(480, 270) - room.to_global(center) * zoom)
			art._process(0.1)
			await _capture("arena_" + String(art.arena_style) + ("_close" if zoom == 1.0 else "_wide"))
		root.canvas_transform = Transform2D(Vector2(1, 0), Vector2(0, 1), Vector2(480, 270) - room.to_global(center))
		art._process(0.1)
		var boss := room.get_node("Guardian") if data[0] == "StarfallEmptyCourt" else room.get_node("HollowSovereign")
		# Real attack warnings, held for a deterministic visual readability check.
		if data[0] == "StarfallEmptyCourt":
			boss._start_charge()
			boss._start_pulse()
		else:
			boss._start_pattern("lunge")
		await _capture("arena_" + String(art.arena_style) + "_warning")
		room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
