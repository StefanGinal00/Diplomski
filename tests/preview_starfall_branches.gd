extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_starfall_branch_preview_save.json"
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
	for data in [["StarfallOutskirts", "starfall_outskirts"], ["StarfallSilentGate", "starfall_silent_gate"], ["StarfallMemoryVault", "starfall_memory_vault"], ["StarfallRootedHall", "starfall_rooted_hall"], ["StarfallSoulCrucible", "starfall_soul_crucible"], ["StarfallSunlessPassage", "starfall_sunless_passage"], ["BlackwaterCistern", "shaft_cistern"]]:
		state.set_current_room(data[1])
		await process_frame
		var room := game.get_node(data[0]) as Node2D
		room.process_mode = Node.PROCESS_MODE_DISABLED
		room.show()
		game.get_node("Background/BiomeBackdrop")._set_room(data[1], true)
		var path := "ExpandedRoute/AuthoredDescent" if data[0] == "BlackwaterCistern" else "ExpandedRoute/StarfallDescent"
		var floor_node := room.get_node(path + "/Branch1_Chamber") as Node2D
		var zoom := 1.2
		root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(640, 470) - floor_node.global_position * zoom)
		room.get_node("PaintedDepth")._process(0.1)
		await _capture("branch_" + data[1])
		if data[0] == "StarfallOutskirts":
			var niche := room.get_node(path + "/Niche4_Crest") as Node2D
			root.canvas_transform.origin = Vector2(640, 470) - niche.global_position * zoom
			room.get_node("PaintedDepth")._process(0.1)
			await _capture("branch_upper_reserve")
		room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
