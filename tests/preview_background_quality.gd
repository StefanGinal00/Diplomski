extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_background_quality_preview_save.json"
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
	var shots := [
		["BlackwaterCistern", "shaft_cistern", Vector2(500, 225), 1.0, "cistern_entry"],
		["BlackwaterCistern", "shaft_cistern", Vector2(500, 225), 0.65, "cistern_join"],
		["StarfallOutskirts", "starfall_outskirts", Vector2(850, 225), 0.75, "outskirts_entry"],
		["StarfallCitadel", "starfall_citadel", Vector2(3500, 100), 0.85, "city_market"],
		["StarfallCitadel", "starfall_citadel", Vector2(1700, 80), 0.85, "city_west"],
		["StarfallCitadel", "starfall_citadel", Vector2(5300, 80), 0.85, "city_east"],
		["StarfallCitadel", "starfall_citadel", Vector2(3125, -600), 0.22, "city_full"],
	]
	var cistern := game.get_node("BlackwaterCistern")
	var tank := cistern.find_children("CisternPressureCell*", "Polygon2D", true, false)[0]
	var center: Vector2 = cistern.to_local(tank.to_global(tank.polygon[2].lerp(tank.polygon[5], 0.5)))
	shots.append(["BlackwaterCistern", "shaft_cistern", center, 1.0, "cistern_tank"])
	for data in shots:
		state.set_current_room(data[1])
		game.get_node("Background/BiomeBackdrop")._set_room(data[1], true)
		var room: Node2D = game.get_node(data[0])
		room.show()
		var zoom: float = data[3]
		root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(640, 360) - room.to_global(data[2]) * zoom)
		for art in room.find_children("*", "Node2D", true, false):
			if art.get_script() != null and art.get_script().resource_path in ["res://RoomPaintedDepth.gd", "res://RemainingRoomArt.gd", "res://VisualStyleSlice.gd"]:
				art._process(0.1)
		await _capture("quality_" + data[4])
		room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
