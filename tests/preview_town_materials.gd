extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_town_material_preview_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.get_node("UI").hide()
	game.get_node("Player/Camera2D").enabled = false
	game.get_node("Player").hide()
	for data in [["EchoHaven", "echo_haven", Vector2(650, 35), 1.5, "echo_court"], ["EchoHaven", "echo_haven", Vector2.ZERO, 1.5, "echo_district"], ["StarfallCitadel", "starfall_citadel", Vector2(3530, 220), 1.2, "starfall_market"], ["StarfallCitadel", "starfall_citadel", Vector2(4570, 220), 1.2, "starfall_library"], ["StarfallCitadel", "starfall_citadel", Vector2.ZERO, 1.2, "starfall_upper"]]:
		state.set_current_room(data[1])
		game.get_node("Background/BiomeBackdrop")._set_room(data[1], true)
		var town := game.get_node(data[0]) as Node2D
		var center: Vector2 = town.to_global(data[2])
		if data[4] == "echo_district":
			center = town.get_node("NewDistricts/Tier02RoofNook").global_position + Vector2(0, -40)
		elif data[4] == "starfall_upper":
			for plate in town.get_node("MaterialExpansion").painted:
				if plate.name == &"Facade":
					center = plate.global_position + Vector2(0, -75)
					break
		var zoom: float = data[3]
		root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(480, 270) - center * zoom)
		if town.has_node("PaintedBackdrop"):
			town.get_node("PaintedBackdrop")._process(0.1)
		if town.has_node("VisualStyleSlice"):
			town.get_node("VisualStyleSlice")._process(0.1)
		town.get_node("NameplateLayout")._rescan()
		town.get_node("NameplateLayout").refresh_layout()
		await _capture("town_material_" + data[4])
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
