extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_hearth_readability_preview_save.json"
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
	game.get_node("Background/BiomeBackdrop")._set_room("ash_hearth", true)
	var room := game.get_node("CinderHearth") as Node2D
	for view in [["board_first", Vector2(3900, -135), 1.8], ["watch_sky", Vector2(3780, -330), 1.2], ["watch_sky_pan", Vector2(3610, -400), 1.2], ["board_return", Vector2(3900, -135), 1.8]]:
		if view[0] == "board_return":
			state.unlock_shortcut("ash_causeway_field_complete")
			state.unlock_shortcut("ash_causeway_guarded_niche_cleared")
			state.unlock_shortcut("ash_chapel_field_complete")
			state.unlock_shortcut("ash_chapel_guarded_niche_cleared")
			state.unlock_shortcut("ash_chapel_field_return_complete")
			state.set_zone_tier("ashen_bastion", 1)
		var center: Vector2 = room.to_global(view[1])
		var zoom: float = view[2]
		root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(480, 270) - center * zoom)
		room.get_node("PaintedBackdrop")._process(0.1)
		room.get_node("NameplateLayout")._rescan()
		room.get_node("NameplateLayout").refresh_layout()
		await _capture("hearth_readability_" + view[0])
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
