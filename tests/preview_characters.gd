extends SceneTree


func _initialize() -> void:
	call_deferred("_render")


func _label(parent: Node, text: String, at: Vector2, size: int = 18) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://art/characters/preview_%s.png" % file_name)
	print("CHARACTER PREVIEW ", file_name, ": ", result)


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_character_preview_save.json"
	state.start_new_game("normal")
	var gallery := Node2D.new()
	root.add_child(gallery)
	var backdrop := Polygon2D.new()
	backdrop.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)])
	backdrop.color = Color("172b38")
	gallery.add_child(backdrop)
	_label(gallery, "WAYFARER / SHAFT WISP - pose review (enlarged, not gameplay scale)", Vector2(40, 22), 24)
	var captions := ["Idle", "Stride A", "Stride B", "Air / dash", "Attack", "Hurt"]
	var wisp_captions := ["Hover A", "Hover B", "Telegraph", "Dive", "Recover", "Hit"]
	for pose in range(6):
		var hero := Sprite2D.new()
		hero.set_script(load("res://PlayerAppearance.gd"))
		# Read pure pose registration off-tree, then render a plain sprite;
		# no invented Player/AI signals or simulated combat in this gallery.
		hero.texture = load("res://art/characters/wayfarer_v1.png")
		hero.hframes = 3
		hero.vframes = 2
		hero._apply_pose(pose, false, false)
		var hero_pose := Sprite2D.new()
		hero_pose.texture = hero.texture
		hero_pose.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		hero_pose.hframes = 3
		hero_pose.vframes = 2
		hero_pose.frame = pose
		hero_pose.offset = hero.offset
		hero_pose.scale = hero.scale * 5
		hero_pose.position = Vector2(110 + pose * 207, 290)
		gallery.add_child(hero_pose)
		hero.free()
		_label(gallery, captions[pose], Vector2(65 + pose * 207, 315))
		var wisp := Sprite2D.new()
		wisp.set_script(load("res://WispAppearance.gd"))
		wisp.hframes = 3
		wisp.vframes = 2
		wisp._apply_pose(pose, Vector2.RIGHT, Vector2.ONE, Color.WHITE)
		var wisp_pose := Sprite2D.new()
		wisp_pose.texture = load("res://art/characters/shaft_wisp_v1.png")
		wisp_pose.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		wisp_pose.hframes = 3
		wisp_pose.vframes = 2
		wisp_pose.frame = pose
		wisp_pose.offset = wisp.offset
		wisp_pose.scale = wisp.scale * 4
		wisp_pose.position = Vector2(110 + pose * 207, 490)
		gallery.add_child(wisp_pose)
		wisp.free()
		_label(gallery, wisp_captions[pose], Vector2(65 + pose * 207, 600))
	await _capture("poses")
	gallery.queue_free()
	await process_frame
	var room: Node2D = load("res://EchoGrotto.tscn").instantiate()
	root.add_child(room)
	await process_frame
	await process_frame
	room.process_mode = Node.PROCESS_MODE_DISABLED
	var template: Node = load("res://Game.tscn").instantiate()
	var player := template.get_node("Player") as Player
	template.remove_child(player)
	template.free()
	root.add_child(player)
	player.get_node("Camera2D").enabled = false
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.position = Vector2(455, 148)
	player.get_node("Appearance")._apply_pose(0, false, false)
	var wisp: Node2D = load("res://ShaftWisp.tscn").instantiate()
	root.add_child(wisp)
	wisp.process_mode = Node.PROCESS_MODE_DISABLED
	wisp.position = Vector2(540, 90)
	wisp.get_node("Appearance")._apply_pose(2, Vector2.RIGHT, Vector2.ONE, Color.WHITE)
	root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(640, 360) - Vector2(460, 65) * 2.5)
	room.get_node("VisualStyleSlice")._process(0.1)
	await _capture("grotto_gameplay")
	room.queue_free()
	player.queue_free()
	wisp.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
