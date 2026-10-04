extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_starfall_upper_art_preview_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	state.set_current_room("starfall_citadel")
	game.get_node("Background/BiomeBackdrop")._set_room("starfall_citadel", true)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.get_node("UI").hide()
	game.get_node("Player/Camera2D").enabled = false
	game.get_node("Player").hide()
	var city := game.get_node("StarfallCitadel") as Node2D
	for data in [["artisans", Vector2(1620, -410)], ["gardens", Vector2(4730, -730)], ["bells", Vector2(3270, -1200)], ["crown", Vector2(5520, -1710)], ["bridge", Vector2(3330, -720)], ["skyline", Vector2(2800, -1220)]]:
		var center := city.to_global(data[1])
		var zoom := 1.2
		root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(480, 270) - center * zoom)
		city.get_node("VisualStyleSlice")._process(0.1)
		city.get_node("NameplateLayout")._rescan()
		city.get_node("NameplateLayout").refresh_layout()
		await _capture("starfall_upper_" + data[0])
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
