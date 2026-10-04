extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_settlement_nameplate_preview_save.json"
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
	for data in [
		["EchoHaven", "echo_haven", Vector2(565, 34), 1.5, "echo_nameplates_supports"],
		["CinderHearth", "ash_hearth", Vector2(600, 260), 1.5, "cinder_nameplates_supports"],
		["CinderHearth", "ash_hearth", Vector2(2680, 140), 1.0, "cinder_foundations"],
		["StarfallCitadel", "starfall_citadel", Vector2(3520, 310), 1.5, "starfall_nameplates"],
	]:
		state.set_current_room(data[1])
		var room := game.get_node(data[0]) as Node2D
		var center: Vector2 = room.to_global(data[2])
		var zoom: float = data[3]
		root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(480, 270) - center * zoom)
		if room.has_node("PaintedBackdrop"):
			room.get_node("PaintedBackdrop")._process(0.1)
		room.get_node("NameplateLayout")._rescan()
		room.get_node("NameplateLayout").refresh_layout()
		await _capture(data[4])
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
