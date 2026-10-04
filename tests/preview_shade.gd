extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_shade_preview_save.json"
	state.start_new_game("normal")
	var gallery := Node2D.new()
	root.add_child(gallery)
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)])
	background.color = Color("172b38")
	gallery.add_child(background)
	_label(gallery, "ECHO SHADE / six poses, both directions (5x art scale)", Vector2(35, 24), 24)
	var captions := ["Idle", "Glide", "Windup", "Dash", "Recover", "Hit"]
	var art_script = load("res://ShadeAppearance.gd")
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
	await _capture("shade_poses")
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
	state.set_current_room("echo_gallery")
	await process_frame
	var room: Node2D = game.get_node("EchoGallery")
	room.show()
	room.process_mode = Node.PROCESS_MODE_DISABLED
	var shade := room.get_node("NearShade")
	root.canvas_transform = Transform2D(Vector2(3, 0), Vector2(0, 3), Vector2(640, 440) - shade.global_position * 3)
	game.get_node("Background/BiomeBackdrop")._set_room("echo_gallery", true)
	for named in ["PaintedDepth", "RemainingArt"]:
		if room.has_node(named):
			room.get_node(named)._process(0.1)
	shade.get_node("Appearance")._process(1)
	await _capture("shade_gallery_idle")
	shade._start_dash(-100)
	shade.get_node("Appearance")._process(0)
	await _capture("shade_gallery_warning")
	shade.zone_tier = 1
	shade._apply_attack_tier()
	shade._start_dash(100, true)
	shade.get_node("Appearance")._process(0)
	await _capture("shade_gallery_awakened")
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
