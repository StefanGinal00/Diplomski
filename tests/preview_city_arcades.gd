extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_city_arcades_preview_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	state.set_current_room("starfall_citadel")
	game.get_node("Background/BiomeBackdrop")._set_room("starfall_citadel", true)
	game.get_node("UI").hide()
	game.get_node("Player/Camera2D").enabled = false
	game.get_node("Player").hide()
	var city := game.get_node("StarfallCitadel") as Node2D
	city.show()
	await process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for data in [["whole", Vector2(3125, -650), 0.2], ["artisan", Vector2(1650, -300), 1.0], ["garden", Vector2(4750, -620), 1.0], ["bells", Vector2(3260, -1080), 1.0], ["crown", Vector2(5150, -1600), 1.0], ["masonry", Vector2(2850, -800), 0.8]]:
		var zoom: float = data[2]
		root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(640, 360) - city.to_global(data[1]) * zoom)
		city.get_node("RemainingArt")._process(0.1)
		await _capture("city_arcades_" + data[0])
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
