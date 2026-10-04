extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_starfall_prop_art_save.json"
	state.start_new_game("normal")
	for named in ["StarfallCitadel", "StarfallOutskirts"]:
		var room: Node2D = load("res://%s.tscn" % named).instantiate()
		room.position = Vector2(12000, -8000)
		var art := room.get_node("PropArt")
		art.owner = null
		room.remove_child(art)
		root.add_child(room)
		await process_frame
		await process_frame
		room.process_mode = Node.PROCESS_MODE_DISABLED
		var before := _physics_snapshot(room)
		var originals := {}
		for node in room.find_children("*", "Node2D", true, false):
			originals[node] = [node.transform, node.z_index, node.visible, node.polygon.duplicate() if node is Polygon2D else null]
		room.add_child(art)
		await process_frame
		_check(art.built and art.z_index == -1 and not art.is_processing(), "Missing static prop art")
		_check(art.props.size() == (4 if named == "StarfallCitadel" else 14), "Missing workplace/caravan/barricade coverage")
		_check(art.get_child_count() == 0, "Decoration adds nodes/actors")
		_check(_physics_snapshot(room) == before, "Decoration changed colliders")
		var counts := {}
		for prop in art.props:
			counts[prop.kind] = counts.get(prop.kind, 0) + 1
		if named == "StarfallOutskirts":
			_check(counts == {"wagon": 4, "wheel": 4, "barricade": 6}, "Unexpected siege-site decoration")
			_check(art.masonry.size() >= 20, "Deep route ruin silhouettes are still untextured")
			for plate in art.masonry:
				_check(plate.texture == art.MASONRY and plate.uv.size() == plate.polygon.size(), "Invalid ruin material")
		for node in originals:
			var old: Array = originals[node]
			_check(node.transform == old[0] and node.z_index == old[1], "Prop art moved/reordered existing content")
			var replaced: bool = node is Polygon2D and node in art.retired
			_check(node.visible == (false if replaced else old[2]), "Prop art hid unrelated content")
			if node is Polygon2D:
				_check(node.polygon == old[3], "Prop art edited authored geometry")
		for node in art.retired:
			_check(node.get_child_count() == 0 and node is Polygon2D, "Unsafe subtree retirement")
		var count: int = art.retired.size()
		art._build()
		_check(art.retired.size() == count, "Prop art duplicated on rebuild")
		room.hide()
		_check(not art.is_visible_in_tree(), "Off-room prop art is visible")
		print("PROP COVERAGE ", named, ": ", counts, " retired=", count, " masonry=", art.masonry.size())
		room.queue_free()
		await process_frame
	state.delete_save()
	if failures.is_empty():
		print("STARFALL PROP ART TEST PASSED: four workplaces, four caravans, six barricades; static and collision-safe")
		quit(0)
	else:
		quit(1)
