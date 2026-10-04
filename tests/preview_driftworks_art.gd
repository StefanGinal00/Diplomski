extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_driftworks_art_preview_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	state.set_current_room("shaft_drift")
	await process_frame
	game.get_node("UI").hide()
	game.get_node("Player/Camera2D").enabled = false
	game.get_node("Player").hide()
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.get_node("Background/BiomeBackdrop")._set_room("shaft_drift", true)
	var wing := game.get_node("ShaftDriftworks")
	wing.show()
	var art := wing.get_node("DriftworksArt")
	for data in [["intake", 0, false], ["pressure", 3, false], ["side_pump", 1, true], ["outflow", 7, false]]:
		var room: Rect2 = wing._branch_rect(data[1]) if data[2] else wing._main_rect(data[1])
		var local_center := Vector2(room.position.x + room.size.x * 0.72, room.end.y - 125)
		if not data[2]:
			var cart_index := [0, 3, 5, 7].find(data[1])
			local_center = art.cart_anchors[cart_index] + Vector2(0, -125)
		var center: Vector2 = wing.to_global(local_center)
		root.canvas_transform = Transform2D(Vector2(1, 0), Vector2(0, 1), Vector2(480, 270) - center)
		art._process(0.1)
		await _capture("driftworks_art_" + data[0])
	var center: Vector2 = wing.to_global(wing._main_rect(3).get_center())
	root.canvas_transform = Transform2D(Vector2(0.28, 0), Vector2(0, 0.28), Vector2(480, 270) - center * 0.28)
	art._process(0.1)
	await _capture("driftworks_art_wide")
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
