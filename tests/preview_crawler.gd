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
	var result := root.get_texture().get_image().save_png("res://art/characters/preview_crawler_%s.png" % file_name)
	print("CRAWLER PREVIEW ", file_name, ": ", result)


func _render() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_crawler_preview_save.json"
	state.start_new_game("normal")
	var gallery := Node2D.new()
	root.add_child(gallery)
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)])
	background.color = Color("172b38")
	gallery.add_child(background)
	_label(gallery, "SHAFT CRAWLER - six poses, both directions (enlarged)", Vector2(40, 30), 25)
	var captions := ["Idle", "Stride A", "Stride B", "Warning", "Charge", "Recover / hit"]
	var art_script = load("res://CrawlerAppearance.gd")
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
			_label(gallery, captions[pose], Vector2(55 + pose * 211, 300 + row * 280))
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
	player.position = Vector2(410, 148)
	player.get_node("Appearance")._apply_pose(0, false, false)
	var crawlers: Array[Node] = []
	for index in range(3):
		var crawler: CharacterBody2D = load("res://ShaftCrawler.tscn").instantiate()
		crawler.position = Vector2(490 + index * 82, 149)
		root.add_child(crawler)
		crawler.process_mode = Node.PROCESS_MODE_DISABLED
		crawler.direction = -1
		crawler.state = [crawler.State.PATROL, crawler.State.WARNING, crawler.State.RECOVER][index]
		crawler.warning_icon.visible = index == 1
		crawler.get_node("Appearance")._process(0.0)
		crawlers.append(crawler)
	root.canvas_transform = Transform2D(Vector2(2.5, 0), Vector2(0, 2.5), Vector2(640, 360) - Vector2(525, 65) * 2.5)
	room.get_node("VisualStyleSlice")._process(0.1)
	await _capture("gameplay")
	for crawler in crawlers:
		crawler.queue_free()
	room.queue_free()
	player.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
