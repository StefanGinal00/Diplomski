extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_cinder_walkway_preview_save.json"
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
	for view in [["old_court", Vector2(605, 275), 1.5], ["foundry_steps", Vector2(1540, 205), 1.5], ["kiln_gallery", Vector2(2130, 65), 1.5], ["archive_steps", Vector2(3020, 215), 1.5], ["watch", Vector2(3780, -230), 1.2]]:
		var center: Vector2 = room.to_global(view[1])
		var zoom: float = view[2]
		root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), Vector2(480, 270) - center * zoom)
		room.get_node("PaintedBackdrop")._process(0.1)
		room.get_node("NameplateLayout")._rescan()
		room.get_node("NameplateLayout").refresh_layout()
		await _capture("cinder_walkway_" + view[0])
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
