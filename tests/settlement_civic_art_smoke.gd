extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_settlement_civic_art_save.json"
	var room: Node2D = load("res://CinderHearth.tscn").instantiate()
	room.position = Vector2(12000, -5000)
	var art := room.get_node("CivicArt")
	art.owner = null
	room.remove_child(art)
	root.add_child(room)
	await process_frame
	room.process_mode = Node.PROCESS_MODE_DISABLED
	var before := _physics_snapshot(room)
	var originals := {}
	for node in room.find_children("*", "Node2D", true, false):
		originals[node] = [node.global_transform, node.visible]
	var polygons := {}
	for node in room.find_children("*", "Polygon2D", true, false):
		polygons[node] = node.polygon.duplicate()
	room.add_child(art)
	await process_frame
	_check(art.built and art.landmarks.size() == 6, "Six civic landmarks missing")
	_check(not art.is_processing() and art.get_child_count() == 0, "Civic art adds runtime actors or frame work")
	_check(_physics_snapshot(room) == before, "Civic art changes collision")
	for node in originals:
		_check([node.global_transform, node.visible] == originals[node], "Original actor/route/door moved or hidden")
	for node in polygons:
		_check(node.polygon == polygons[node], "Original building geometry changed")
	var roles := {}
	for entry in art.landmarks:
		_check(not roles.has(entry.role), "Duplicated civic treatment")
		roles[entry.role] = true
		var home := room.get_node("EasternDistricts/" + entry.name) as Polygon2D
		var bottom: Vector2 = art.to_local(home.to_global(home.polygon[0]))
		_check(is_equal_approx(entry.bounds.end.y, bottom.y), "Art detached from existing building")
		_check(entry.bounds.has_area(), "Empty civic bounds")
	art._build()
	_check(art.landmarks.size() == 6, "Repeated civic build")
	room.hide()
	_check(not art.is_visible_in_tree(), "Inactive-town art remains visible")
	room.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("SETTLEMENT CIVIC ART TEST PASSED: six distinct static landmarks, original geometry/visibility/physics/transforms, translated room, idempotence and inactive town")
		quit(0)
	else:
		quit(1)
