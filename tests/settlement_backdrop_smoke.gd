extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_settlement_backdrop_save.json"
	state.start_new_game("normal")
	for scene_name in ["EchoHaven", "CinderHearth"]:
		var room: Node2D = load("res://%s.tscn" % scene_name).instantiate()
		var art := room.get_node("PaintedBackdrop")
		art.owner = null
		room.remove_child(art)
		root.add_child(room)
		await process_frame
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var physics_before := _physics_snapshot(room)
		var geometry := {}
		for path in art.plate_paths:
			var plate: Polygon2D = room.get_node(path)
			geometry[path] = [plate.polygon, plate.transform, plate.z_index]
		var child_count := room.find_children("*", "", true, false).size()
		room.add_child(art)
		await process_frame
		await process_frame
		_check(art.built, "Backdrop did not build")
		_check(art.plates.size() == (12 if scene_name == "EchoHaven" else 2), "Missing settlement art")
		_check(_physics_snapshot(room) == physics_before, "Backdrop changed physics")
		_check(room.find_children("*", "", true, false).size() == child_count + 1, "Backdrop added gameplay objects")
		for path in geometry:
			var plate: Polygon2D = room.get_node(path)
			_check(geometry[path] == [plate.polygon, plate.transform, plate.z_index], "Backdrop changed room geometry")
			_check(plate.texture == art.backdrop_texture and plate.texture.get_width() == 1536, "Missing/shared texture budget")
			_check(plate.uv.size() == plate.polygon.size(), "Invalid UV count")
			var fade: float = plate.material.get_shader_parameter("top_fade")
			_check(fade > 0.0 and fade <= 0.45 if path in art.top_fade_paths else is_zero_approx(fade), "Edge fade applied to wrong plate")
			for uv in plate.uv:
				_check(uv.is_finite(), "Non-finite UV")
		if scene_name == "EchoHaven":
			var first_pocket := room.get_node("NewDistricts/DistrictPocket00")
			for plate in art.plates:
				if plate.get_parent() == first_pocket.get_parent():
					_check(plate.get_meta("settlement_art_bounds") == first_pocket.get_meta("settlement_art_bounds"), "District painting repeats per floor instead of sharing continuous UV space")
		art._build()
		_check(art.plates.size() == art.plate_paths.size(), "Repeated build duplicated art")
		var first: Polygon2D = art.plates[0]
		root.canvas_transform = Transform2D.IDENTITY
		art._process(0.1)
		var before: Vector2 = first.material.get_shader_parameter("camera_shift")
		root.canvas_transform.origin += Vector2(90, 20)
		art._process(0.1)
		_check(first.material.get_shader_parameter("camera_shift") != before, "No camera parallax")
		room.hide()
		var clock_before: float = art.update_clock
		art._process(1.0)
		_check(art.update_clock == clock_before, "Hidden settlement kept updating")
		room.queue_free()
		await process_frame
	root.canvas_transform = Transform2D.IDENTITY
	state.delete_save()
	if failures.is_empty():
		print("SETTLEMENT BACKDROP TEST PASSED: two shared paintings, fourteen existing polygons, continuous district UVs, unchanged physics/geometry, idempotence, camera parallax, hidden-room sleep")
		quit(0)
	else:
		quit(1)
