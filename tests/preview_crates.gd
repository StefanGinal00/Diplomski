extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_crate_preview_save.json"
	state.start_new_game("normal")
	var gallery := Node2D.new()
	root.add_child(gallery)
	var backdrop := Polygon2D.new()
	backdrop.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)])
	backdrop.color = Color("17212b")
	gallery.add_child(backdrop)
	_label(gallery, "SUPPLY CRATES / native 2D detail", Vector2(45, 25), 26)
	_label(gallery, "Intact / damaged / heavily damaged (5x inspection); bottom row: actual game size", Vector2(45, 63), 18)
	for column in range(4):
		var room := Node2D.new()
		room.name = ["TravelCamp", "EchoGrotto", "CinderHearth", "StarfallCitadel"][column]
		gallery.add_child(room)
		_label(gallery, ["Travel supplies", "Echo / rope & patina", "Ash / iron seal", "Starfall / wax seal"][column], Vector2(35 + column * 315, 110), 19)
		for row in range(4):
			var crate = load("res://DestructibleCrate.tscn").instantiate()
			crate.max_health = 4
			crate.position = Vector2(155 + column * 315, 205 + row * 135)
			crate.scale = Vector2.ONE * (1 if row == 3 else 5)
			room.add_child(crate)
			crate.current_health = [4, 2, 1, 4][row]
	await _capture("supply_crates")
	gallery.queue_free()
	await process_frame
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.get_node("UI").hide()
	game.get_node("Player/Camera2D").enabled = false
	game.get_node("Player").hide()
	game.get_node("Player").set_physics_process(false)
	for data in [["EchoGrotto", "echo_grotto"], ["StarfallMemoryVault", "starfall_memory_vault"]]:
		state.set_current_room(data[1])
		await process_frame
		var room := game.get_node(data[0]) as Node2D
		room.show()
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var crate := room.get_node("WildCrate0") as Node2D
		root.canvas_transform = Transform2D(Vector2(2, 0), Vector2(0, 2), Vector2(640, 510) - crate.global_position * 2)
		game.get_node("Background/BiomeBackdrop")._set_room(data[1], true)
		if room.has_node("PaintedDepth"):
			room.get_node("PaintedDepth")._process(0.1)
		await _capture("crate_context_" + data[1])
		room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
