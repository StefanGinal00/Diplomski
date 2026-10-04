extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_starfall_arena_art_save.json"
	state.start_new_game("normal")
	var images := {}
	for named in ["StarfallEmptyCourt", "StarfallHollowThrone"]:
		var room: Node2D = load("res://%s.tscn" % named).instantiate()
		var art := room.get_node("ArenaArt")
		art.owner = null
		room.remove_child(art)
		root.add_child(room)
		await process_frame
		await process_frame
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var before := _physics_snapshot(room)
		var originals := {}
		for node in room.find_children("*", "Node2D", true, false):
			originals[node] = [node.transform, node.visible, node.z_index, node.polygon.duplicate() if node is Polygon2D else null]
		room.add_child(art)
		await process_frame
		_check(art.built and art.plates.size() == 1, "Missing arena painting")
		_check(art.surfaces.size() == 8, "Missing arena stone surfaces")
		_check(art.retired.size() == (3 if named == "StarfallEmptyCourt" else 5), "Wrong retired scenery scope")
		_check(_physics_snapshot(room) == before, "Arena art changed colliders or one-way platforms")
		_check(art.find_children("*", "CollisionObject2D", true, false).is_empty(), "Arena art added colliders")
		var floor_bottom: float = room.get_node("Floor").position.y + 9
		_check(art.foundation.z_index == -2 and is_equal_approx(art.foundation.polygon[0].y, floor_bottom), "Foundation covers the walking surface")
		for node in originals:
			var old: Array = originals[node]
			_check(node.transform == old[0] and node.z_index == old[2], "Arena art moved original node")
			if art.retired.has(node):
				_check(not node.visible and node.get_child_count() == 0, "Retirement touched gameplay parent")
			else:
				_check(node.visible == old[1], "Arena art hid original gameplay node")
			if node is Polygon2D:
				_check(node.polygon == old[3], "Arena art changed silhouette")
		var plate: Polygon2D = art.plates[0]
		images[plate.texture.resource_path] = true
		_check(plate.z_index == -9 and plate.material == art.material_shared, "Backdrop draws above combat")
		_check(plate.texture.get_width() == 1024 and plate.texture.get_image().has_mipmaps(), "Arena texture import budget invalid")
		for index in range(plate.polygon.size()):
			var expected: Vector2 = (art.to_local(plate.to_global(plate.polygon[index])) - art.art_bounds.position) / art.art_bounds.size * plate.texture.get_size()
			_check(plate.uv[index].distance_to(expected) < 0.01, "Arena UV does not follow original shape")
		for surface in art.surfaces:
			_check(surface.texture.resource_path.ends_with("starfall_masonry_v1.png") and surface.uv.size() == surface.polygon.size(), "Stone material missing")
			var rim: Line2D
			for candidate in art.trims:
				if candidate.get_parent() == surface:
					rim = candidate
					break
			_check(rim != null and is_equal_approx(rim.points[0].y, surface.polygon[0].y + 1), "Stone rim moved jump edge")
		var center: Vector2 = art.to_global(art.art_bounds.get_center())
		for zoom in [0.65, 1.3]:
			root.canvas_transform = Transform2D(Vector2(zoom, 0), Vector2(0, zoom), root.get_visible_rect().size * 0.5 - center * zoom)
			art._process(0.1)
			var initial: Vector2 = art.material_shared.get_shader_parameter("camera_shift")
			root.canvas_transform.origin -= Vector2(110, 35) * zoom
			art._process(0.1)
			var moved: Vector2 = art.material_shared.get_shader_parameter("camera_shift")
			var haze: Vector2 = art.material_shared.get_shader_parameter("haze_shift")
			_check(moved.x < initial.x and moved.y < initial.y and moved.length() > haze.length(), "Arena parallax does not have two depth speeds")
		var stable: Vector2 = art.material_shared.get_shader_parameter("camera_shift")
		room.position += Vector2(22000, -10000)
		root.canvas_transform.origin -= Vector2(22000, -10000) * 1.3
		art._process(0.1)
		_check((art.material_shared.get_shader_parameter("camera_shift") as Vector2).distance_to(stable) < 0.0001, "Editor room layout affects arena parallax")
		if named == "StarfallHollowThrone":
			var seat: Sprite2D = art.throne
			_check(seat != null and seat.z_index == -5, "Throne missing or obscures combat")
			var bitmap := seat.texture.get_image()
			_check(bitmap.get_width() == 512 and bitmap.has_mipmaps(), "Throne import budget wrong")
			_check(bitmap.get_pixel(0, 0).a < 0.01 and bitmap.get_pixel(511, 511).a < 0.01 and not bitmap.is_invisible(), "Throne has no genuine alpha background")
			var used := bitmap.get_used_rect()
			var bottom := seat.position.y + used.end.y * seat.scale.y
			_check(absf(bottom - 425) < 0.01 and used.size.y * seat.scale.y <= 250.1, "Throne floats or is too large")
			_check(not room.get_node("ThroneLamp").visible, "New art exposed victory lamp before defeat")
		var updates: int = art.update_count
		room.hide()
		art._process(1)
		_check(art.update_count == updates, "Hidden arena keeps processing")
		var trim_count: int = art.trims.size()
		art._build()
		_check(art.trims.size() == trim_count and art.plates.size() == 1, "Duplicate arena art build")
		print("ARENA ART COVERAGE ", named, ": ", art.surfaces.size(), " surfaces, ", trim_count, " trims")
		room.queue_free()
		await process_frame
	_check(images.size() == 2, "Arena backgrounds were duplicated")
	root.canvas_transform = Transform2D.IDENTITY
	state.delete_save()
	if failures.is_empty():
		print("STARFALL ARENA ART TEST PASSED: two paintings, 16 stone surfaces, two foundations, transparent grounded throne, unchanged geometry/physics, scoped leaf retirement, parallax and hidden-room sleep")
		quit(0)
	else:
		quit(1)
