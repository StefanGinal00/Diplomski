extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_settlement_building_art_save.json"
	state.start_new_game("normal")
	for scene_name in ["EchoHaven", "CinderHearth"]:
		var room: Node2D = load("res://%s.tscn" % scene_name).instantiate()
		var art := room.get_node("PaintedBuildings")
		art.owner = null
		room.remove_child(art)
		root.add_child(room)
		await process_frame
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var physics_before := _physics_snapshot(room)
		var geometry := {}
		for node in room.find_children("*", "Polygon2D", true, false):
			geometry[node] = [node.polygon, node.global_transform, node.z_index, node.visible]
		var markers := {}
		for node in room.find_children("*", "Marker2D", true, false):
			markers[node] = node.global_transform
		room.add_child(art)
		await process_frame
		await process_frame
		_check(art.built and art.painted.size() == (65 if scene_name == "EchoHaven" else 33), "Missing or extra building surfaces: " + scene_name)
		_check(not art.is_processing(), "Static building art has a per-frame update")
		_check(_physics_snapshot(room) == physics_before, "Building art changed physics")
		for node in geometry:
			_check(geometry[node] == [node.polygon, node.global_transform, node.z_index, node.visible], "Building art changed original geometry/visibility")
		for node in markers:
			_check(node.global_transform == markers[node], "Building art moved an NPC route/door marker")
		for texture in [art.wall_texture, art.roof_texture, art.door_texture]:
			_check(texture != null and texture.get_width() == 512 and texture.get_height() == 512, "Building texture budget")
			_check(texture.get_image().has_mipmaps(), "Building surface lacks mipmaps")
		for plate in art.painted:
			_check(plate.uv.size() == plate.polygon.size(), "Invalid facade UV")
			_check(plate.z_index < 0, "Facade obscures actors")
			for uv in plate.uv:
				_check(uv.is_finite(), "Non-finite facade UV")
		_check(art.find_children("*", "CollisionObject2D", true, false).is_empty(), "Decorative roof became a collider")
		_check(art.window_frames.size() == (35 if scene_name == "EchoHaven" else 24), "Missing window trim")
		var count: int = art.painted.size()
		art._build()
		_check(art.painted.size() == count, "Duplicate facade build")
		print("BUILDING SURFACES ", scene_name, ": ", count, "; windows: ", art.window_frames.size())
		room.queue_free()
		await process_frame
	state.delete_save()
	if failures.is_empty():
		print("SETTLEMENT BUILDING ART TEST PASSED: six textures, two settlements, unchanged silhouettes/physics/routes, mipmaps, static updates and idempotence")
		quit(0)
	else:
		quit(1)
