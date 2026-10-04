extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_settlement_walkway_art_save.json"
	var room: Node2D = load("res://CinderHearth.tscn").instantiate()
	room.position = Vector2(18000, -9000)
	var art := room.get_node("WalkwayArt")
	art.owner = null
	room.remove_child(art)
	root.add_child(room)
	await process_frame
	room.process_mode = Node.PROCESS_MODE_DISABLED
	var physics_before := _physics_snapshot(room)
	var originals := {}
	var polygons := {}
	for node in room.find_children("*", "Node2D", true, false):
		originals[node] = [node.global_transform, node.visible, node.z_index]
		if node is Polygon2D:
			polygons[node] = node.polygon.duplicate()
	var count := room.find_children("*", "", true, false).size()
	room.add_child(art)
	await process_frame
	_check(art.built and art.surfaces.size() == 44 and art.retired.size() == 44, "Incomplete walkway coverage")
	_check(art.z_index == -1 and art.get_index() == room.get_child_count() - 1, "Walkways do not sort above roofs and behind actors")
	_check(not art.is_processing() and not art.is_physics_processing(), "Art adds processing")
	_check(art.get_child_count() == 0 and room.find_children("*", "", true, false).size() == count + 1, "Art changes node count")
	_check(_physics_snapshot(room) == physics_before, "Art changes physics or one-way flags")
	for node in originals:
		_check(node.global_transform == originals[node][0] and node.z_index == originals[node][2], "Art moves/re-layers existing node")
		var retired: bool = node is Polygon2D and node in art.retired
		_check(node.visible == (false if retired else originals[node][1]), "Art unexpectedly hides an object")
	for node in polygons:
		_check(node.polygon == polygons[node], "Art changes original polygon")
	var counts := {}
	var bodies := {}
	for surface in art.surfaces:
		_check(not bodies.has(surface.body), "Platform registered twice")
		bodies[surface.body] = true
		counts[surface.kind] = int(counts.get(surface.kind, 0)) + 1
		var collider: CollisionShape2D = surface.collision
		var top_left: Vector2 = art.to_local(collider.to_global(-collider.shape.size * 0.5))
		var bottom_right: Vector2 = art.to_local(collider.to_global(collider.shape.size * 0.5))
		_check(surface.rect == Rect2(top_left, bottom_right - top_left), "Visual surface detached from collision")
		_check(surface.rect.has_area(), "Invalid surface bounds")
		_check(collider.one_way_collision == (surface.kind != "street"), "Wrong surface category")
	for plate in art.retired:
		_check(plate.get_child_count() == 0 and bodies.has(plate.get_parent()), "Retired unrelated or gameplay visual")
	_check(counts == {"street": 3, "bridge": 5, "step": 36}, "Incorrect street/gallery/stair coverage")
	art._build()
	_check(art.surfaces.size() == 44 and art.retired.size() == 44, "Non-idempotent walkway build")
	room.hide()
	_check(not art.is_visible_in_tree(), "Inactive-town art remains visible")
	room.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("SETTLEMENT WALKWAY ART TEST PASSED: 44 aligned surfaces, exact coverage, unchanged physics/one-way flags/geometry/routes, scoped plate hiding, static/idempotent draw")
		quit(0)
	else:
		quit(1)
