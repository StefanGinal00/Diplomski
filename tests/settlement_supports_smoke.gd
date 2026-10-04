extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_settlement_supports_save.json"
	for scene_name in ["EchoHaven", "CinderHearth"]:
		var room: Node2D = load("res://%s.tscn" % scene_name).instantiate()
		room.position = Vector2(12000, -5000)
		var art := room.get_node("BuildingSupports")
		art.owner = null
		room.remove_child(art)
		root.add_child(room)
		await process_frame
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var before := _physics_snapshot(room)
		var transforms := {}
		for node in room.find_children("*", "Node2D", true, false):
			transforms[node] = node.global_transform
		room.add_child(art)
		await process_frame
		_check(art.built and art.supports.size() == 2, "Missing balcony supports")
		_check(art.foundations.size() == (6 if scene_name == "CinderHearth" else 0), "Wrong foundation coverage")
		_check(art.get_child_count() == 0 and not art.is_processing(), "Supports added objects or per-frame work")
		_check(_physics_snapshot(room) == before, "Support art changed collision")
		for node in transforms:
			_check(node.global_transform == transforms[node], "Support art moved an actor/route/door")
		for rect in art.supports + art.foundations:
			_check(rect.has_area() and rect.size.y < 100, "Invalid or oversized support")
			_check(is_equal_approx(rect.end.y, art.floor_top), "Support fails to reach existing floor")
		var count: int = art.supports.size() + art.foundations.size()
		art._build()
		_check(art.supports.size() + art.foundations.size() == count, "Repeated supports")
		room.queue_free()
		await process_frame
	state.delete_save()
	if failures.is_empty():
		print("SETTLEMENT SUPPORTS TEST PASSED: four supported balcony houses, six foundations, floor alignment, unchanged physics/routes, static idempotent drawing")
		quit(0)
	else:
		quit(1)
