extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_regional_signs_preview_save.json"
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
	for data in [
		["ShaftHollow", "shaft_hollow", "ExpandedRoute/FieldDressing/Site4", "shaft"],
		["CinderForge", "ash_forge", "AshSwitchback/FieldDressing/Site0", "forge_shelter"],
		["SlagReservoir", "ash_reservoir", "AshSwitchback/FieldDressing/Site5", "reservoir"],
		["StarfallOutskirts", "starfall_outskirts", "ExpandedRoute/FieldDressing/Site6", "starfall"],
	]:
		state.set_current_room(data[1])
		await process_frame
		await process_frame
		var room: Node2D = game.get_node(data[0])
		room.show()
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var site: Node2D = room.get_node(data[2])
		var clue: Label = site.get_node("RouteClue")
		var center := (site.global_position + clue.global_position + clue.size * 0.5) * 0.5
		root.canvas_transform = Transform2D(Vector2(1.5, 0), Vector2(0, 1.5), Vector2(640, 360) - center * 1.5)
		game.get_node("Background/BiomeBackdrop")._set_room(data[1], true)
		for named in ["PaintedDepth", "RemainingArt", "VisualStyleSlice"]:
			if room.has_node(named): room.get_node(named)._process(0.1)
		await _capture("regional_sign_" + data[3])
		room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
