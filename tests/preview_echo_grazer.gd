extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_grazer_preview_save.json"
	state.start_new_game("normal")
	var gallery := Node2D.new()
	root.add_child(gallery)
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)])
	bg.color = Color("172b38")
	gallery.add_child(bg)
	_label(gallery, "ECHO GRAZER / six poses, both directions (5x art scale)", Vector2(35, 24), 24)
	var captions := ["Sleeping", "Idle", "Stride A", "Stride B", "Provoked", "Hit"]
	var art_script = load("res://EchoGrazerAppearance.gd")
	for row in range(2):
		for pose in range(6):
			var sprite := Sprite2D.new()
			sprite.texture = art_script.SHEET
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			sprite.hframes = 3
			sprite.vframes = 2
			sprite.frame = pose
			sprite.flip_h = row == 1
			sprite.offset = Vector2(256, 256) - art_script.PIVOTS[pose]
			if sprite.flip_h:
				sprite.offset.x = -sprite.offset.x
			sprite.scale = Vector2.ONE * art_script.PIXEL_SCALE * 5
			sprite.position = Vector2(105 + pose * 211, 280 + row * 280)
			gallery.add_child(sprite)
			_label(gallery, captions[pose], Vector2(55 + pose * 211, 310 + row * 280))
	await _capture("echo_grazer_poses")
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
	for data in [["TideWell", "echo_tide_well", "Grazer10_0", false], ["EchoNest", "echo_nest", "Grazer3_0", false], ["EchoNest", "echo_nest", "Grazer3_0", true]]:
		state.set_current_room(data[1])
		await process_frame
		await process_frame
		var room: Node2D = game.get_node(data[0])
		room.show()
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var actor := room.get_node("LongTraversal/FieldDressing/" + data[2])
		if data[3]:
			actor.restore_streamed_state({"current_health": 2, "is_hostile": true, "resting": false, "grace_remaining": 0.4, "direction": -1})
		actor.get_node("EchoAppearance")._process(0)
		root.canvas_transform = Transform2D(Vector2(3, 0), Vector2(0, 3), Vector2(640, 570) - actor.global_position * 3)
		game.get_node("Background/BiomeBackdrop")._set_room(data[1], true)
		for named in ["PaintedDepth", "RemainingArt"]:
			if room.has_node(named):
				room.get_node(named)._process(0.1)
		await _capture("echo_grazer_" + data[0] + ("_provoked" if data[3] else "_sleeping"))
		room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
