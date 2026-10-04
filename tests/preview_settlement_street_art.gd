extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_settlement_street_preview_save.json"
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
	for data in [["EchoHaven", "echo_haven", "stall", "echo_market_details"], ["EchoHaven", "echo_haven", "plant", "echo_garden_details"], ["CinderHearth", "ash_hearth", "stall", "cinder_market_details"], ["CinderHearth", "ash_hearth", "cart", "cinder_cart_details"]]:
		state.set_current_room(data[1])
		var room := game.get_node(data[0]) as Node2D
		var art := room.get_node("StreetArt") as Node2D
		var center := Vector2.ZERO
		for prop in art.props:
			if prop.kind == data[2]:
				center = art.to_global(prop.bounds.get_center() + Vector2(0, 10))
				break
		root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(480, 270) - center * 2.5)
		room.get_node("PaintedBackdrop")._process(0.1)
		await _capture(data[3])
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
