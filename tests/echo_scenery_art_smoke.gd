extends "res://tests/visual_style_slice_smoke.gd"


func _run() -> void:
	var state := root.get_node("GameState")
	state.save_path = "res://_tmp_echo_scenery_art_save.json"
	state.start_new_game("normal")
	var game: Node2D = load("res://Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.get_node("Player").set_physics_process(false)
	await process_frame
	await process_frame
	var total := 0
	var styles := []
	for art in game.find_children("SceneryArt", "Node2D", true, false):
		if art.get_script() != preload("res://EchoSceneryArt.gd"):
			continue
		var route := art.get_parent()
		var sentinel := Polygon2D.new()
		sentinel.name = "EchoCrystalGameplayGuard"
		sentinel.add_child(Node.new())
		route.add_child(sentinel)
		var originals := {}
		for node in art.retired:
			node.show()
		for node in route.get_children():
			if node is Polygon2D or node is Line2D:
				originals[node] = [node.transform, node.z_index, node.visible, node.polygon.duplicate() if node is Polygon2D else node.points.duplicate()]
		var physics := _physics_snapshot(route)
		var flags: Dictionary = state.unlocked_shortcuts.duplicate(true)
		art.retired.clear()
		art.masks.clear()
		art.mask_bounds.clear()
		art.shapes.clear()
		art.counts = {"stone": 0, "crystal": 0, "fungus": 0, "backdrop": 0}
		art.built = false
		art._build()
		_check(art.built and not art.is_processing() and art.get_child_count() == 0, "Scenery not static/built")
		_check(_physics_snapshot(route) == physics and state.unlocked_shortcuts == flags, "Scenery changed gameplay")
		_check(art.counts.stone >= 15 and art.counts.crystal >= 15 and art.counts.fungus >= 20, "Missing scenery coverage: " + art.theme)
		for node in originals:
			var old: Array = originals[node]
			_check(node.transform == old[0] and node.z_index == old[1], "Source placement changed")
			_check(node.visible == (false if node in art.retired else old[2]), "Unrelated visual hidden")
			_check((node.polygon if node is Polygon2D else node.points) == old[3], "Source geometry changed")
		for node in art.retired:
			_check(node.get_child_count() == 0, "Gameplay subtree hidden")
		var outside_count := 0
		var tolerant_masks := []
		for mask in art.masks:
			# Clipper -> float32 round trips at world coordinates leave subpixel
			# slivers. Allow 0.02 px, not an art-sized leak outside the chamber.
			tolerant_masks.append(Geometry2D.offset_polygon(mask, 0.02)[0])
		for shape in art.shapes:
			_check(not Geometry2D.triangulate_polygon(shape.points).is_empty(), "Invalid decorative polygon")
			# Intersection must fit one complete authored mask (not only vertices).
			var outside := Geometry2D.clip_polygons(shape.points, tolerant_masks[shape.mask])
			if not outside.is_empty():
				if outside_count == 0:
					print("CLIP DIAGNOSTIC ", art.theme, " source=", shape.points, " mask=", art.masks[shape.mask], " excluded=", outside)
				outside_count += 1
		_check(outside_count == 0, "Decoration escaped room: " + art.theme + " count=" + str(outside_count))
		_check(sentinel.visible and sentinel.get_child_count() == 1, "Matching name hid a gameplay subtree")
		var count: int = art.shapes.size()
		art._build()
		_check(art.shapes.size() == count, "Build duplicates artwork")
		styles.append(art.theme)
		total += art.retired.size()
		print("ECHO SCENERY ", art.theme, ": ", art.counts, " retired=", art.retired.size(), " clipped shapes=", count)
	_check(styles.size() == 8 and "depths" in styles, "Expected seven Echo routes and Depths")
	print("TOTAL ECHO SCENERY REPLACEMENTS ", total)
	game.queue_free()
	await process_frame
	state.delete_save()
	if failures.is_empty():
		print("ECHO SCENERY ART TEST PASSED: eight routes, static/clipped decoration, preserved source geometry/physics/flags")
		quit(0)
	else:
		quit(1)
