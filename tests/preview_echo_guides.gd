extends "res://tests/preview_echo_fauna.gd"


func _guide_regions() -> Array:
	return ["gallery", "archive", "nest"]


func _instrument_kinds() -> Array:
	return ["resonator", "receiver"]


func _capture_prefix() -> String:
	return "echo_guides"


func _room_cases() -> Array:
	return [["EchoGallery", "echo_gallery", "LongTraversal/FieldDressing/FieldGuide"], ["PrismArchive", "echo_archive", "LongTraversal/FieldDressing/FieldGuide"], ["EchoNest", "echo_nest", "LongTraversal/FieldDressing/FieldGuide"], ["EchoGrotto", "echo_grotto", "LowerResonator"], ["EchoGallery", "echo_gallery", "LongTraversal/FieldDiscoveries/ListeningPost0"], ["EchoDepths", "echo_depths", "FieldOperations/Signal0"]]


func _render() -> void:
	root.size = Vector2i(1280, 850)
	root.content_scale_size = Vector2i(1280, 850)
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_guides_preview_save.json"
	state.start_new_game("normal")
	var script = load("res://EchoGuideAppearance.gd")
	for left in [false, true]:
		var gallery := Node2D.new()
		root.add_child(gallery)
		var bg := Polygon2D.new()
		bg.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 850), Vector2(0, 850)])
		bg.color = Color("172b38")
		gallery.add_child(bg)
		_label(gallery, "ECHO GUIDES / 4 poses / enlarged 4x", Vector2(25, 20), 25)
		var row := 0
		for region in _guide_regions():
			_label(gallery, region.to_upper(), Vector2(20, 220 + row * 260))
			for pose in range(4):
				var sprite := Sprite2D.new()
				sprite.texture = script.SHEETS[region]
				sprite.hframes = 2
				sprite.vframes = 2
				sprite.frame = pose
				sprite.flip_h = left
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				sprite.offset = sprite.texture.get_size() * 0.25 - script.PIVOTS[region][pose]
				if left:
					sprite.offset.x = -sprite.offset.x
				sprite.scale = Vector2.ONE * script.SCALES[region] * 4
				sprite.position = Vector2(285 + pose * 265, 270 + row * 260)
				gallery.add_child(sprite)
			row += 1
		await _capture(_capture_prefix() + "_poses_" + ("left" if left else "right"))
		gallery.queue_free()
		await process_frame
	var devices := Node2D.new()
	root.add_child(devices)
	var device_bg := Polygon2D.new()
	device_bg.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 850), Vector2(0, 850)])
	device_bg.color = Color("172b38")
	devices.add_child(device_bg)
	_label(devices, "ECHO DEVICES / cosmetic states / enlarged 4x", Vector2(25, 20), 25)
	var kinds := _instrument_kinds()
	var row_height := 340 if kinds.size() == 2 else 240
	var row_origin := 280 if kinds.size() == 2 else 220
	for row in range(kinds.size()):
		var kind: String = kinds[row]
		_label(devices, kind.to_upper(), Vector2(25, row_origin - 60 + row * row_height))
		for column in range(3):
			var host := Node2D.new()
			host.position = Vector2(330 + column * 330, row_origin + row * row_height)
			devices.add_child(host)
			var art := preload("res://EchoDeviceArt.gd").attach(host, kind)
			art.scale = Vector2.ONE * 4
			art.set_status(column == 1, column == 2)
			_label(devices, ["Idle", "Active", "Listening (cosmetic)"][column], Vector2(265 + column * 330, row_origin + 110 + row * row_height))
	await _capture(_capture_prefix() + "_device_states")
	devices.queue_free()
	await process_frame
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("UI").hide()
	game.get_node("Player").set_physics_process(false)
	game.get_node("Player").hide()
	game.get_node("Player/Camera2D").enabled = false
	for data in _room_cases():
		state.set_current_room(data[1])
		await process_frame
		var room := game.get_node(data[0]) as Node2D
		room.show()
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var actor := room.get_node_or_null(data[2]) as Node2D
		if actor == null:
			push_error("Missing preview target: " + str(data))
			quit(1)
			return
		if actor.has_node("FieldAppearance"):
			actor.get_node("FieldAppearance")._apply_pose(3, false)
			actor.get_node("InteractionPrompt").show()
		elif actor.has_node("InteractionPrompt"):
			actor.get_node("InteractionPrompt").show()
		root.canvas_transform = Transform2D(Vector2(3, 0), Vector2(0, 3), Vector2(640, 530) - actor.global_position * 3)
		_backdrop(game, room, data[1])
		await _capture(_capture_prefix() + "_" + data[0] + "_" + String(actor.name))
		room.hide()
	game.queue_free()
	await process_frame
	state.delete_save()
	quit(0)
