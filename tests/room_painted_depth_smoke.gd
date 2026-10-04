extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_room_painted_depth_save.json"
	state.start_new_game("normal")
	var room_counts := {"BlackwaterCistern": 20, "PrismArchive": 22, "CinderForge": 14, "StarfallMemoryVault": 19, "StarfallOutskirts": 19, "StarfallSilentGate": 19, "StarfallRootedHall": 19, "StarfallSoulCrucible": 19, "StarfallSunlessPassage": 19}
	var texture_paths := {}
	for named in room_counts:
		var room: Node2D = load("res://%s.tscn" % named).instantiate()
		var art := room.get_node("PaintedDepth")
		art.owner = null
		room.remove_child(art)
		root.add_child(room)
		await process_frame
		await process_frame
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var physics_before := _physics_snapshot(room)
		var originals := {}
		for node in room.find_children("*", "Node2D", true, false):
			originals[node] = [node.transform, node.visible, node.z_index, node.polygon.duplicate() if node is Polygon2D else null]
		room.add_child(art)
		await process_frame
		var expected_count: int = room_counts[named]
		_check(art.built and art.plates.size() == expected_count, "Missing chamber painting: " + named)
		if String(named).begins_with("Starfall"):
			_check(is_equal_approx(float(art.material_shared.get_shader_parameter("scene_scale")), maxf(1, art.art_bounds.size.x / 1800.0)), "Late-game painting is overstretched")
		_check(_physics_snapshot(room) == physics_before, "Painting changed collision: " + named)
		for node in originals:
			var before: Array = originals[node]
			_check(node.transform == before[0] and node.z_index == before[2], "Painting moved original node")
			_check(node.visible == before[1] or node in art.finish_report.retired, "Painting hid a gameplay node")
			if node is Polygon2D:
				_check(node.polygon == before[3], "Painting changed silhouette")
		for plate in art.plates:
			texture_paths[plate.texture.resource_path] = true
			_check(plate.material == art.material_shared and plate.z_index <= -3, "Painting overlaps actors or uses unnecessary materials")
			_check(plate.texture.get_width() == 1536 and plate.texture.get_image().has_mipmaps(), "Painting lost source detail or has no mipmaps")
			_check(plate.uv.size() == plate.polygon.size(), "Invalid painted UVs")
			for index in range(plate.polygon.size()):
				var point: Vector2 = art.to_local(plate.to_global(plate.polygon[index]))
				var expected: Vector2 = (point - art.art_bounds.position) / art.art_bounds.size * plate.texture.get_size()
				_check(plate.uv[index].distance_to(expected) < 0.01, "Adjacent chamber images do not share UV space")
		if named == "CinderForge":
			_check(art.created.size() == 13 and room.get_node("AshSwitchback").painted_depth_enabled, "Forge painting does not replace original fill")
		else:
			_check(art.created.is_empty(), "Unnecessary new background geometry")
		var center: Vector2 = art.to_global(art.art_bounds.get_center())
		for zoom in [0.8, 1.5]:
			root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), root.get_visible_rect().size * 0.5 - center * zoom)
			art._process(0.1)
			var initial: Vector2 = art.material_shared.get_shader_parameter("camera_shift")
			root.canvas_transform.origin -= Vector2(160, 80) * zoom
			art._process(0.1)
			var moved: Vector2 = art.material_shared.get_shader_parameter("camera_shift")
			var haze: Vector2 = art.material_shared.get_shader_parameter("haze_shift")
			_check(moved.x < initial.x and moved.y < initial.y, "Far layer does not oppose camera movement on both axes")
			_check(moved.length() > haze.length(), "Depth planes move at identical speeds")
		var stable_shift: Vector2 = art.material_shared.get_shader_parameter("camera_shift")
		room.position += Vector2(25000, -18000)
		root.canvas_transform.origin -= Vector2(25000, -18000) * 1.5
		art._process(0.1)
		_check((art.material_shared.get_shader_parameter("camera_shift") as Vector2).distance_to(stable_shift) < 0.0001, "Room origin changes parallax")
		var updates: int = art.update_count
		room.hide()
		art._process(1)
		_check(art.update_count == updates, "Hidden room keeps updating parallax")
		var count: int = art.plates.size()
		art._build()
		_check(art.plates.size() == count, "Duplicate painting build")
		print("ROOM DEPTH COVERAGE ", named, ": ", count)
		room.queue_free()
		await process_frame
	_check(texture_paths.size() == 9, "Rooms are reusing a painting instead of their own background")
	root.canvas_transform = Transform2D.IDENTITY
	state.delete_save()
	if failures.is_empty():
		print("ROOM PAINTED DEPTH TEST PASSED: nine distinct images / 170 surfaces including side branches/niches, clipped shared UVs, two depth speeds, camera zoom/origin safety, hidden-room sleep and unchanged physics")
		quit(0)
	else:
		quit(1)
