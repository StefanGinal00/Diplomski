extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_starfall_props_preview_save.json"
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
	var city := game.get_node("StarfallCitadel") as Node2D
	var outskirts := game.get_node("StarfallOutskirts") as Node2D
	var shots := []
	for index in range(4):
		var place := city.get_node("UpperCity/Workplace%d" % index) as Node2D
		shots.append([city, "starfall_citadel", place.global_position + Vector2(0, -80), "workplace%d" % index, 1.7])
	shots.append([city, "starfall_citadel", city.to_global(Vector2(4640, -680)), "gardens", 1.2])
	var selected := {}
	for prop in outskirts.get_node("PropArt").props:
		if prop.kind in ["wagon", "barricade"] and not selected.has(prop.kind):
			selected[prop.kind] = true
			shots.append([outskirts, "starfall_outskirts", outskirts.to_global(prop.rect.get_center()), "%s%d" % [prop.kind, shots.size()], 1.4])
	for data in shots:
		state.set_current_room(data[1])
		game.get_node("Background/BiomeBackdrop")._set_room(data[1], true)
		data[0].show()
		var zoom: float = data[4]
		root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(640, 360) - data[2] * zoom)
		for named in ["RemainingArt", "PaintedDepth"]:
			var art: Node = data[0].get_node_or_null(named)
			if art != null:
				art._process(0.1)
		await _capture("starfall_props_" + data[3])
		data[0].hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
