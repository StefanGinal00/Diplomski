extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_cinder_civic_preview_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	state.set_current_room("ash_hearth")
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.get_node("UI").hide()
	game.get_node("Player/Camera2D").enabled = false
	game.get_node("Player").hide()
	var room := game.get_node("CinderHearth") as Node2D
	for entry in room.get_node("CivicArt").landmarks:
		var rect: Rect2 = entry.bounds
		var center := room.to_global(Vector2(rect.get_center().x, 205))
		root.canvas_transform = Transform2D(Vector2(1.5, 0), Vector2(0, 1.5), Vector2(480, 270) - center * 1.5)
		room.get_node("PaintedBackdrop")._process(0.1)
		room.get_node("NameplateLayout")._rescan()
		room.get_node("NameplateLayout").refresh_layout()
		await _capture("cinder_civic_" + entry.role)
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
