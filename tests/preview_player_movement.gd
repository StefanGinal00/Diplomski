extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_player_movement_preview_save.json"
	state.start_new_game("normal")
	var gallery := Node2D.new()
	root.add_child(gallery)
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)])
	background.color = Color("172b38")
	gallery.add_child(background)
	_label(gallery, "WAYFARER - movement poses / both directions (enlarged)", Vector2(40, 25), 24)
	var poses := [0, 3, 6, 7, 8, 9]
	var captions := ["Idle (existing)", "Jump (existing)", "Crouch", "Fall", "Dash", "Landing"]
	for row in range(2):
		for index in range(6):
			var presenter := Sprite2D.new()
			presenter.set_script(load("res://PlayerAppearance.gd"))
			presenter._apply_pose(poses[index], row == 1, false)
			var sprite := Sprite2D.new()
			sprite.texture = presenter.texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			sprite.hframes = presenter.hframes
			sprite.vframes = presenter.vframes
			sprite.frame = presenter.frame
			sprite.offset = presenter.offset
			sprite.flip_h = presenter.flip_h
			sprite.scale = presenter.scale * 5
			sprite.position = Vector2(100 + index * 210, 290 + row * 280)
			gallery.add_child(sprite)
			presenter.free()
			_label(gallery, captions[index], Vector2(40 + index * 210, 320 + row * 280), 17)
	await _capture("player_movement_poses")
	gallery.queue_free()
	await process_frame
	var room: Node2D = load("res://EchoGrotto.tscn").instantiate()
	root.add_child(room)
	await process_frame
	await process_frame
	room.process_mode = Node.PROCESS_MODE_DISABLED
	var actors: Array[Node] = []
	for index in range(4):
		var template := load("res://Game.tscn").instantiate() as Node
		var actor := template.get_node("Player") as Player
		template.remove_child(actor)
		template.free()
		root.add_child(actor)
		actor.get_node("Camera2D").enabled = false
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		actor.position = Vector2(410 + index * 75, 148 if index in [0, 3] else 118)
		actor.get_node("Appearance")._apply_pose(6 + index, false, false)
		actors.append(actor)
	root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(640, 360) - Vector2(525, 65) * 2.5)
	room.get_node("VisualStyleSlice")._process(0.1)
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	_label(overlay, "STAGED MOVEMENT ART: crouch / fall / dash / landing - normal camera zoom", Vector2(30, 20), 20)
	await _capture("player_movement_gameplay")
	for actor in actors:
		actor.queue_free()
	room.queue_free()
	overlay.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
