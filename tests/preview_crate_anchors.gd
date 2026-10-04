extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_crate_anchors_preview_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.get_node("UI").hide()
	game.get_node("Player/Camera2D").enabled = false
	game.get_node("Player").hide()
	game.get_node("Player").set_physics_process(false)
	for data in [
		["ShaftHollow", "shaft_hollow", "ExpandedRoute/AuthoredDescent/DepthCrate4_1"],
		["DrownedCrossing", "shaft_crossing", "ExpandedRoute/FieldDressing/Supply1_0"],
		["FloodedGallery", "shaft_gallery", "ExpandedRoute/AuthoredDescent/DepthCrate4_1"],
		["TideWell", "echo_tide_well", "LongTraversal/HiddenCrate05"],
		["EmberBarracks", "ash_barracks", "AshSwitchback/DrillTarget0"],
		["StarfallMemoryVault", "starfall_memory_vault", "ExpandedRoute/StarfallDescent/SealedRecord0"],
	]:
		state.set_current_room(data[1])
		await process_frame
		var room := game.get_node(data[0]) as Node2D
		room.show()
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var crate := room.get_node(data[2]) as Node2D
		root.canvas_transform = Transform2D(Vector2(1.5, 0), Vector2(0, 1.5), Vector2(640, 490) - crate.global_position * 1.5)
		game.get_node("Background/BiomeBackdrop")._set_room(data[1], true)
		if room.has_node("PaintedDepth"):
			room.get_node("PaintedDepth")._process(0.1)
		await _capture("crate_anchor_" + data[1])
		room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
