extends "res://tests/preview_characters.gd"

func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_remaining_art_preview_save.json"
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
	for art in game.find_children("*", "Node2D", true, false):
		if art.get_script() == null or art.get_script().resource_path != "res://RemainingRoomArt.gd":
			continue
		var room: Node2D = art.get_parent()
		var id := "training_passage"
		for key in preload("res://WorldLayout.gd").ROOM_NODES:
			if preload("res://WorldLayout.gd").ROOM_NODES[key] == String(room.name):
				id = key
				break
		state.set_current_room(id)
		game.get_node("Background/BiomeBackdrop")._set_room(id, true)
		room.show()
		var candidates: Array[Rect2] = []
		for plate in art.plates:
			var bounds := Rect2(art.to_local(plate.to_global(plate.polygon[0])), Vector2.ZERO)
			for point in plate.polygon:
				bounds = bounds.expand(art.to_local(plate.to_global(point)))
			if bounds.size.x > 650 and bounds.size.y > 150:
				candidates.append(bounds)
		var bounds: Rect2 = candidates[mini(2, candidates.size() - 1)] if not candidates.is_empty() else art.art_bounds
		var local_center := Vector2(bounds.get_center().x, bounds.end.y - 125)
		if art.layout == "city":
			local_center = Vector2(4000, -1250)
		var center: Vector2 = art.to_global(local_center)
		for zoom in [1.0, 0.32]:
			root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(480, 270) - center * zoom)
			art._process(0.1)
			await _capture("remaining_" + String(art.artwork) + ("_close" if zoom == 1.0 else "_wide"))
		room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
