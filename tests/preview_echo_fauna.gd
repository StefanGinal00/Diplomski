extends "res://tests/preview_characters.gd"


func _render() -> void:
	root.size = Vector2i(1280, 850)
	root.content_scale_size = Vector2i(1280, 850)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_fauna_preview_save.json"
	state.start_new_game("normal")
	var art_script = load("res://EchoFaunaAppearance.gd")
	for left in [false, true]:
		var gallery := Node2D.new()
		root.add_child(gallery)
		var bg := Polygon2D.new()
		bg.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 850), Vector2(0, 850)])
		bg.color = Color("172b38")
		gallery.add_child(bg)
		_label(gallery, "ECHO FAUNA / four poses / enlarged 3.5x", Vector2(30, 20), 25)
		var row := 0
		for kind in art_script.SHEETS:
			_label(gallery, kind.to_upper(), Vector2(25, 140 + row * 140))
			for pose in range(4):
				var sprite := Sprite2D.new()
				sprite.texture = art_script.SHEETS[kind]
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				sprite.hframes = 2
				sprite.vframes = 2
				sprite.frame = pose
				sprite.flip_h = left
				sprite.offset = sprite.texture.get_size() * 0.25 - art_script.PIVOTS[kind][pose]
				if left:
					sprite.offset.x = -sprite.offset.x
				sprite.scale = Vector2.ONE * art_script.SCALES[kind] * 3.5
				sprite.position = Vector2(290 + pose * 270, 170 + row * 140)
				gallery.add_child(sprite)
			row += 1
		for i in range(4):
			_label(gallery, ["Rest", "Motion A", "Motion B", "Startled / hit"][i], Vector2(235 + i * 270, 60))
		await _capture("echo_fauna_poses_" + ("left" if left else "right"))
		gallery.queue_free()
		await process_frame
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.get_node("UI").hide()
	game.get_node("Player").set_physics_process(false)
	game.get_node("Player").hide()
	game.get_node("Player/Camera2D").enabled = false
	for data in [["EchoGallery", "echo_gallery"], ["TideWell", "echo_tide_well"], ["CrystalCauseway", "echo_causeway"], ["UndertowVault", "echo_vault"], ["EchoNest", "echo_nest"]]:
		state.set_current_room(data[1])
		var room := game.get_node(data[0]) as Node2D
		room.show()
		for tick in range(25):
			await physics_frame
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var actor := room.get_node("LongTraversal/QuietCaveLife0") as Node2D
		actor.get_node("FaunaAppearance")._process(0)
		root.canvas_transform = Transform2D(Vector2(3, 0), Vector2(0, 3), Vector2(640, 530) - actor.global_position * 3)
		_backdrop(game, room, data[1])
		await _capture("echo_fauna_" + data[0])
		room.hide()
	for data in [["EchoGrotto", "echo_grotto"], ["EchoGallery", "echo_gallery"], ["PrismArchive", "echo_archive"], ["EchoNest", "echo_nest"], ["EchoHavenOutskirts", "echo_haven_outskirts"]]:
		state.set_current_room(data[1])
		await process_frame
		var room := game.get_node(data[0]) as Node2D
		room.show()
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var art := room.get_node("EchoEntryGrowthArt")
		var rect: Rect2 = art.props[0].rect
		var center := room.to_global(Vector2(rect.get_center().x, rect.end.y - 65))
		root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(640, 425) - center * 2.5)
		_backdrop(game, room, data[1])
		await _capture("echo_entry_growth_" + data[0])
		room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)


func _backdrop(game: Node, room: Node, id: String) -> void:
	game.get_node("Background/BiomeBackdrop")._set_room(id, true)
	for named in ["PaintedDepth", "RemainingArt", "VisualStyleSlice"]:
		if room.has_node(named):
			room.get_node(named)._process(0.1)
